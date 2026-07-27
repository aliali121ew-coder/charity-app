-- ════════════════════════════════════════════════════════════════════════════
-- 0013_seed.sql
-- بيانات أولية · Seed (صلاحيات + أدوار + مناطق + بيانات تجريبية + دالة ترقية موظف)
-- ════════════════════════════════════════════════════════════════════════════

-- ── permissions (مطابقة لـ Permission enum في التطبيق) ──────────────────────
insert into public.permissions (key, description) values
  ('viewSubscribers','عرض المشتركين'),('addSubscriber','إضافة مشترك'),
  ('editSubscriber','تعديل مشترك'),('deleteSubscriber','حذف مشترك'),
  ('viewFamilies','عرض العائلات'),('addFamily','إضافة عائلة'),
  ('editFamily','تعديل عائلة'),('deleteFamily','حذف عائلة'),
  ('viewAid','عرض المساعدات'),('addAid','إضافة مساعدة'),
  ('editAid','تعديل مساعدة'),('deleteAid','حذف مساعدة'),
  ('approveAid','اعتماد مساعدة'),('distributeAid','توزيع مساعدة'),
  ('viewReports','عرض التقارير'),('exportReports','تصدير التقارير'),
  ('viewLogs','عرض السجلّ'),('viewSettings','عرض الإعدادات'),
  ('editSettings','تعديل الإعدادات'),('manageUsers','إدارة المستخدمين'),
  ('managePermissions','إدارة الصلاحيات'),('viewDashboard','عرض اللوحة')
on conflict (key) do nothing;

-- ── role_permissions ────────────────────────────────────────────────────────
-- admin: كل الصلاحيات
insert into public.role_permissions (role, permission)
  select 'admin', key from public.permissions on conflict do nothing;
-- supervisor: كل شيء عدا إدارة الصلاحيات
insert into public.role_permissions (role, permission)
  select 'supervisor', key from public.permissions where key <> 'managePermissions'
  on conflict do nothing;
-- delegate (مندوب): مجموعة الموظف كما في defaultPermissions
insert into public.role_permissions (role, permission) values
  ('delegate','viewSubscribers'),('delegate','addSubscriber'),('delegate','editSubscriber'),
  ('delegate','viewFamilies'),('delegate','addFamily'),('delegate','editFamily'),
  ('delegate','viewAid'),('delegate','addAid'),('delegate','editAid'),
  ('delegate','viewReports'),('delegate','viewLogs'),('delegate','viewDashboard')
on conflict do nothing;

-- ── regions (عيّنة محافظات/مناطق عراقية) ────────────────────────────────────
insert into public.regions (governorate, area) values
  ('بغداد','الكرخ'),('بغداد','الرصافة'),('بغداد','الكاظمية'),('بغداد','مدينة الصدر'),
  ('البصرة','المعقل'),('البصرة','الزبير'),
  ('نينوى','الموصل'),('نينوى','تلعفر'),
  ('النجف','مركز النجف'),('كربلاء','مركز كربلاء'),
  ('أربيل','مركز أربيل'),('ذي قار','الناصرية')
on conflict do nothing;

-- ── دالة ترقية مستخدم إلى موظف/مندوب بعد تسجيله في Supabase Auth ─────────────
-- الاستخدام: select public.make_staff('admin@charity.org','admin');
--            select public.make_staff('delegate1@charity.org','delegate','بغداد', array['الكرخ']);
create or replace function public.make_staff(
  p_email text,
  p_role  public.staff_role default 'delegate',
  p_gov   text default null,
  p_areas text[] default '{}'
) returns uuid
language plpgsql security definer set search_path = public, auth as $$
declare uid uuid;
begin
  select id into uid from auth.users where lower(email) = lower(p_email);
  if uid is null then
    raise exception 'لا يوجد مستخدم Auth بالبريد %. أنشئه أولاً عبر Supabase Auth.', p_email;
  end if;
  update public.profiles set user_type = 'staff' where id = uid;
  insert into public.staff_profiles (id, staff_role, assigned_governorate, assigned_areas)
  values (uid, p_role, p_gov, p_areas)
  on conflict (id) do update
    set staff_role = excluded.staff_role,
        assigned_governorate = excluded.assigned_governorate,
        assigned_areas = excluded.assigned_areas;
  return uid;
end; $$;

-- ── بيانات تجريبية للتفاعل (بدون منشئ محدّد — created_by = null) ─────────────
insert into public.prizes (title, description, points_cost, stock, type, instructions, icon_key)
values
  ('سلة غذائية','سلة مواد غذائية أساسية', 500, 100, 'physical', 'استلام من مقر المؤسسة', 'basket'),
  ('شهادة تقدير رقمية','شهادة إلكترونية للمتميّزين', 100, 0, 'digital', '', 'certificate')
on conflict do nothing;

-- مسابقة تجريبية (ختمة قرآنية شهرية)
insert into public.competitions (title, description, category, reward_points, target, winner_count, starts_at, ends_at, prize_type, prize_title)
values ('ختمة القرآن الشهرية','أكمل جزءاً يومياً طوال الشهر', 'quran', 300, 30, 3,
        date_trunc('month', now()), date_trunc('month', now()) + interval '1 month', 'digital', 'شهادة تميّز')
on conflict do nothing;

-- ختمة جماعية تجريبية + أجزاؤها الثلاثون
do $$
declare kid uuid;
begin
  if not exists (select 1 from public.khatmat where title = 'الختمة الجماعية الأولى') then
    insert into public.khatmat (title, type, is_active) values ('الختمة الجماعية الأولى','group', true)
    returning id into kid;
    insert into public.khatma_juz (khatma_id, juz_number)
      select kid, g from generate_series(1,30) as g;
  end if;
end $$;
