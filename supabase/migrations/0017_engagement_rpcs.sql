-- ════════════════════════════════════════════════════════════════════════════
-- 0017_engagement_rpcs.sql
-- دوال RPC (SECURITY DEFINER) لتفاعل المسابقات: النقاط + الختمة + المتجر +
-- المشاركات/الأدلّة. مملوكة لـ postgres وتعمل على auth.uid() مع تحقّق من جهة
-- الخادم — لأن سياسة RLS (pl_staff_insert) تمنع المستخدم المجتمعي من الكتابة
-- المباشرة في points_ledger؛ فكل عملية تُغيّر النقاط تمرّ عبر هذه الدوال.
--
-- كل الدوال:
--   • SECURITY DEFINER + set search_path = public (تتجاوز RLS بأمان).
--   • تعمل على v_uid := auth.uid() وترفع استثناءً إن كان null.
--   • create or replace (idempotent) + grant execute to authenticated.
--
-- ملاحظة: القراءات (SELECT لصفوف المستخدم نفسه) مسموحة أصلاً بسياسات RLS،
--        لذا لا نحتاج دوالاً للقراءة عدا رصيد النقاط (اختصار مريح).
-- ════════════════════════════════════════════════════════════════════════════

-- ── award_points · إضافة/خصم نقاط في الدفتر ثم إرجاع الرصيد الجديد ────────────
-- المُشغّل points_ledger_apply يُحدّث user_engagement_stats.total_points تلقائياً.
create or replace function public.award_points(
  p_delta    int,
  p_reason   text default 'adjustment',
  p_ref_type text default null,
  p_ref_id   text default null
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_reason public.points_reason;
  v_balance int;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  -- تحقّق من صحّة السبب مقابل قيم الـ enum، وإلا استخدم 'adjustment'.
  begin
    v_reason := p_reason::public.points_reason;
  exception when others then
    v_reason := 'adjustment'::public.points_reason;
  end;

  insert into public.points_ledger (user_id, delta, reason, ref_type, ref_id)
  values (v_uid, p_delta, v_reason, p_ref_type, p_ref_id);

  select total_points into v_balance
  from public.user_engagement_stats
  where user_id = v_uid;

  return coalesce(v_balance, 0);
end;
$$;

-- ── get_points_balance · رصيد النقاط الحالي (0 إن لا صف) ──────────────────────
create or replace function public.get_points_balance()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_balance int;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  select total_points into v_balance
  from public.user_engagement_stats
  where user_id = v_uid;

  return coalesce(v_balance, 0);
end;
$$;

-- ── redeem_store_prize · استبدال جائزة بالنقاط (عملية ذرّية) ──────────────────
-- تقفل صف الجائزة، تتحقّق من المخزون والرصيد، تُنقص المخزون، تخصم النقاط عبر
-- award_points، ثم تُدرج صف الاستبدال وتُرجعه كاملاً.
create or replace function public.redeem_store_prize(p_prize_id uuid)
returns public.store_redemptions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_prize public.prizes;
  v_row   public.store_redemptions;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  -- قفل صف الجائزة لمنع السباق على آخر قطعة في المخزون.
  select * into v_prize
  from public.prizes
  where id = p_prize_id
  for update;

  if v_prize.id is null then
    raise exception 'prize_not_found';
  end if;
  if not v_prize.is_active or v_prize.stock <= 0 then
    raise exception 'out_of_stock';
  end if;
  if public.get_points_balance() < v_prize.points_cost then
    raise exception 'insufficient_points';
  end if;

  update public.prizes
    set stock = stock - 1
    where id = p_prize_id;

  -- خصم النقاط (delta سالب) عبر الدفتر.
  perform public.award_points(-v_prize.points_cost, 'redemption', 'prize', p_prize_id::text);

  insert into public.store_redemptions (
    user_id, prize_id, prize_title, type, points_cost,
    claim_code, status, redeemed_at, deadline, instructions
  ) values (
    v_uid,
    v_prize.id,
    v_prize.title,
    v_prize.type,
    v_prize.points_cost,
    'ST-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
    'pending',
    now(),
    now() + interval '14 days',
    v_prize.instructions
  ) returning * into v_row;

  return v_row;
end;
$$;

-- ── join_competition · الانضمام لمسابقة (يُرجع الصف دائماً) ────────────────────
-- upsert على (competition_id, user_id): إن كان مشتركاً أصلاً يُرجع صفه الحالي.
-- المُشغّل on_competition_entry_change يزيد participants_count + competitions_joined
-- عند الإدراج الجديد فقط.
create or replace function public.join_competition(p_competition_id uuid)
returns public.competition_entries
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.competition_entries;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  insert into public.competition_entries (competition_id, user_id)
  values (p_competition_id, v_uid)
  on conflict (competition_id, user_id)
    do update set user_id = excluded.user_id  -- no-op تضمن إرجاع الصف
  returning * into v_row;

  return v_row;
end;
$$;

-- ── submit_competition_proof · رفع دليل مشاركة يومي ───────────────────────────
-- يضمن وجود entry (عبر join_competition)، يُدرج الدليل بحالة pending، ثم يزيد
-- progress للـ entry. لا يمنح نقاطاً هنا — النقاط تُمنح عند اعتماد المشرف للدليل
-- (proof_approved) عبر مسار إداري منفصل.
create or replace function public.submit_competition_proof(
  p_competition_id uuid,
  p_text           text default null,
  p_image_url      text default null
) returns public.participation_proofs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_entry    public.competition_entries;
  v_proof    public.participation_proofs;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  -- يضمن وجود مشاركة ويعيد صفها (id مطلوب للدليل).
  v_entry := public.join_competition(p_competition_id);

  insert into public.participation_proofs (
    entry_id, competition_id, user_id, text, image_url, review_status
  ) values (
    v_entry.id, p_competition_id, v_uid, p_text, p_image_url, 'pending'
  ) returning * into v_proof;

  update public.competition_entries
    set progress = progress + 1
    where id = v_entry.id;

  return v_proof;
end;
$$;

-- ── reserve_juz · حجز جزء من الختمة ───────────────────────────────────────────
create or replace function public.reserve_juz(p_khatma_id uuid, p_juz int)
returns public.khatma_juz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.khatma_juz;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  update public.khatma_juz
    set status = 'reserved',
        reserved_by = v_uid,
        reserved_at = now()
    where khatma_id = p_khatma_id
      and juz_number = p_juz
      and status = 'available'
  returning * into v_row;

  if v_row.id is null then
    raise exception 'juz_unavailable';
  end if;

  return v_row;
end;
$$;

-- ── complete_juz · تأكيد إتمام قراءة جزء ──────────────────────────────────────
-- يُعلّم الجزء completed (إن كان محجوزاً باسم المستخدم أو غير محجوز)، يزيد عدّاد
-- khatma_juz_completed في الإحصاءات، ويمنح 10 نقاط (khatma_completed).
create or replace function public.complete_juz(p_khatma_id uuid, p_juz int)
returns public.khatma_juz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.khatma_juz;
begin
  if v_uid is null then
    raise exception 'auth_required';
  end if;

  update public.khatma_juz
    set status = 'completed',
        completed_at = now()
    where khatma_id = p_khatma_id
      and juz_number = p_juz
      and (reserved_by = v_uid or reserved_by is null)
  returning * into v_row;

  if v_row.id is null then
    raise exception 'juz_not_reserved';
  end if;

  -- زيادة عدّاد الأجزاء المكتملة في إحصاءات المستخدم.
  insert into public.user_engagement_stats (user_id, khatma_juz_completed, updated_at)
  values (v_uid, 1, now())
  on conflict (user_id) do update
    set khatma_juz_completed = public.user_engagement_stats.khatma_juz_completed + 1,
        updated_at = now();

  -- مكافأة إتمام جزء.
  perform public.award_points(10, 'khatma_completed', 'khatma', p_khatma_id::text);

  return v_row;
end;
$$;

-- ── الصلاحيات · منح التنفيذ للمستخدمين المصادَقين ─────────────────────────────
grant execute on function public.award_points(int, text, text, text)         to authenticated;
grant execute on function public.get_points_balance()                        to authenticated;
grant execute on function public.redeem_store_prize(uuid)                    to authenticated;
grant execute on function public.join_competition(uuid)                      to authenticated;
grant execute on function public.submit_competition_proof(uuid, text, text)  to authenticated;
grant execute on function public.reserve_juz(uuid, int)                      to authenticated;
grant execute on function public.complete_juz(uuid, int)                     to authenticated;
