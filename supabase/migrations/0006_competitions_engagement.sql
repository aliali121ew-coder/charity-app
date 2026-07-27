-- ════════════════════════════════════════════════════════════════════════════
-- 0006_competitions_engagement.sql
-- المسابقات + المشاركة + النقاط + الجوائز + المتجر + الختمة
-- (نظام التفاعل — يخدم 100,000+ مستخدم مجتمعي)
-- ════════════════════════════════════════════════════════════════════════════

do $$ begin create type public.competition_category as enum ('quran','worship','charity','volunteer','knowledge','seasonal'); exception when duplicate_object then null; end $$;
do $$ begin create type public.prize_type          as enum ('digital','physical'); exception when duplicate_object then null; end $$;
do $$ begin create type public.claim_status        as enum ('pending','received','expired'); exception when duplicate_object then null; end $$;
do $$ begin create type public.proof_review_status as enum ('pending','approved','rejected'); exception when duplicate_object then null; end $$;
do $$ begin create type public.juz_status          as enum ('available','reserved','completed'); exception when duplicate_object then null; end $$;
-- أسباب حركة النقاط (مفهوم خادِم بحت — snake_case)
do $$ begin create type public.points_reason as enum
  ('competition_reward','proof_approved','redemption','claim_confirmed','khatma_completed','adjustment','signup_bonus');
  exception when duplicate_object then null; end $$;

-- ── competitions · المسابقات ────────────────────────────────────────────────
create table if not exists public.competitions (
  id                 uuid primary key default gen_random_uuid(),
  title              text not null,
  description        text not null default '',
  category           public.competition_category not null,
  max_participants   integer not null default 0,     -- 0 = غير محدود
  participants_count integer not null default 0,     -- عدّاد مخزّن (يُحدَّث بمُشغّل)
  reward_points      integer not null default 0,
  target             integer not null default 7,     -- الهدف (عدد مرات/أيام)
  winner_count       integer not null default 1,
  conditions         text[] not null default '{}',
  steps              text[] not null default '{}',
  prize_type         public.prize_type not null default 'digital',
  prize_title        text not null default '',
  prize_description  text not null default '',
  prize_instructions text,
  cover_image_url    text,
  created_by         uuid references public.staff_profiles(id) on delete set null,
  is_published       boolean not null default true,
  starts_at          timestamptz not null,
  ends_at            timestamptz not null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists comp_dates_idx    on public.competitions (starts_at, ends_at);
create index if not exists comp_category_idx  on public.competitions (category);
create index if not exists comp_published_idx on public.competitions (is_published);

drop trigger if exists comp_set_updated_at on public.competitions;
create trigger comp_set_updated_at before update on public.competitions
  for each row execute function public.set_updated_at();
alter table public.competitions enable row level security;

-- الحالة (active/upcoming/ended) تُحسب من التواريخ — عبر view يحترم RLS.
create or replace view public.competitions_with_status
with (security_invoker = true) as
select c.*,
  case when now() < c.starts_at then 'upcoming'
       when now() > c.ends_at   then 'ended'
       else 'active' end as status
from public.competitions c;

-- ── competition_entries · مشاركة مستخدم في مسابقة (حجم عالٍ) ─────────────────
create table if not exists public.competition_entries (
  id             uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  user_id        uuid not null references public.profiles(id)     on delete cascade,
  joined_at      timestamptz not null default now(),
  earned_points  integer not null default 0,
  progress       integer not null default 0,
  rank           integer,
  unique (competition_id, user_id)           -- يمنع الانضمام المزدوج
);
create index if not exists ce_competition_idx on public.competition_entries (competition_id);
create index if not exists ce_user_idx         on public.competition_entries (user_id);
alter table public.competition_entries enable row level security;

-- ── participation_proofs · أدلّة المشاركة اليومية (حجم عالٍ) ─────────────────
create table if not exists public.participation_proofs (
  id             uuid primary key default gen_random_uuid(),
  entry_id       uuid not null references public.competition_entries(id) on delete cascade,
  competition_id uuid not null references public.competitions(id) on delete cascade,
  user_id        uuid not null references public.profiles(id) on delete cascade,
  text           text,
  image_url      text,                          -- في Supabase Storage
  review_status  public.proof_review_status not null default 'pending',
  reviewed_by    uuid references public.staff_profiles(id) on delete set null,
  submitted_at   timestamptz not null default now()
);
create index if not exists pp_entry_idx      on public.participation_proofs (entry_id);
create index if not exists pp_review_idx      on public.participation_proofs (competition_id, review_status);
create index if not exists pp_user_idx        on public.participation_proofs (user_id);
alter table public.participation_proofs enable row level security;

-- ── prizes · متجر الجوائز ───────────────────────────────────────────────────
create table if not exists public.prizes (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text not null default '',
  points_cost  integer not null default 0,
  stock        integer not null default 0,
  type         public.prize_type not null default 'physical',
  instructions text not null default '',
  icon_key     text,                             -- مفتاح أيقونة (يُترجَم في الواجهة)
  is_active    boolean not null default true,
  created_by   uuid references public.staff_profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
drop trigger if exists prizes_set_updated_at on public.prizes;
create trigger prizes_set_updated_at before update on public.prizes
  for each row execute function public.set_updated_at();
alter table public.prizes enable row level security;

-- ── store_redemptions · استبدال جائزة بالنقاط ───────────────────────────────
create table if not exists public.store_redemptions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  prize_id     uuid references public.prizes(id) on delete set null,
  prize_title  text not null,
  type         public.prize_type not null,
  points_cost  integer not null default 0,
  claim_code   text not null unique,             -- كود الاستلام (QR)
  status       public.claim_status not null default 'pending',
  redeemed_at  timestamptz not null default now(),
  deadline     timestamptz not null,
  instructions text not null default '',
  confirmed_by uuid references public.staff_profiles(id) on delete set null
);
create index if not exists sr_user_idx   on public.store_redemptions (user_id);
create index if not exists sr_status_idx on public.store_redemptions (status);
alter table public.store_redemptions enable row level security;

-- ── claim_cards · بطاقات الفوز بجوائز المسابقات ─────────────────────────────
create table if not exists public.claim_cards (
  id                uuid primary key default gen_random_uuid(),
  competition_id    uuid references public.competitions(id) on delete set null,
  user_id           uuid not null references public.profiles(id) on delete cascade,
  winner_name       text not null,
  prize_title       text not null,
  prize_type        public.prize_type not null,
  claim_code        text not null unique,
  status            public.claim_status not null default 'pending',
  points_cost       integer not null default 0,
  won_at            timestamptz not null default now(),
  deadline          timestamptz not null,
  instructions      text not null default '',
  confirmed_by      uuid references public.staff_profiles(id) on delete set null
);
create index if not exists cc_user_idx   on public.claim_cards (user_id);
create index if not exists cc_status_idx on public.claim_cards (status);
alter table public.claim_cards enable row level security;

-- ── points_ledger · دفتر النقاط (مصدر الحقيقة — إضافة فقط) ───────────────────
create table if not exists public.points_ledger (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  delta      integer not null,                  -- + أو -
  reason     public.points_reason not null,
  ref_type   text,                              -- 'competition' | 'prize' | 'khatma' ...
  ref_id     text,
  note       text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists pl_user_time_idx on public.points_ledger (user_id, created_at desc);
create index if not exists pl_reason_idx      on public.points_ledger (reason);
alter table public.points_ledger enable row level security;

-- ── user_engagement_stats · تجميع سريع للوحة الصدارة (100k+ مستخدم) ──────────
create table if not exists public.user_engagement_stats (
  user_id              uuid primary key references public.profiles(id) on delete cascade,
  total_points         integer not null default 0,
  khatma_juz_completed integer not null default 0,
  competitions_joined  integer not null default 0,
  competitions_won     integer not null default 0,
  area                 text,
  updated_at           timestamptz not null default now()
);
-- فهرس لوحة الصدارة: أعلى النقاط أولاً
create index if not exists ues_points_idx on public.user_engagement_stats (total_points desc);
create index if not exists ues_area_points_idx on public.user_engagement_stats (area, total_points desc);
alter table public.user_engagement_stats enable row level security;

-- مُشغّل: كل حركة في points_ledger تُحدِّث الرصيد المُجمَّع فوراً.
create or replace function public.apply_points_ledger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_engagement_stats (user_id, total_points, updated_at)
  values (new.user_id, new.delta, now())
  on conflict (user_id) do update
    set total_points = public.user_engagement_stats.total_points + new.delta,
        updated_at   = now();
  return new;
end; $$;
drop trigger if exists points_ledger_apply on public.points_ledger;
create trigger points_ledger_apply after insert on public.points_ledger
  for each row execute function public.apply_points_ledger();

-- مُشغّل: تحديث عدّاد المشاركين + عدّاد "شارك في مسابقات".
create or replace function public.on_competition_entry_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    update public.competitions set participants_count = participants_count + 1 where id = new.competition_id;
    insert into public.user_engagement_stats (user_id, competitions_joined, updated_at)
    values (new.user_id, 1, now())
    on conflict (user_id) do update
      set competitions_joined = public.user_engagement_stats.competitions_joined + 1, updated_at = now();
  elsif (tg_op = 'DELETE') then
    update public.competitions set participants_count = greatest(participants_count - 1, 0) where id = old.competition_id;
  end if;
  return null;
end; $$;
drop trigger if exists competition_entry_change on public.competition_entries;
create trigger competition_entry_change
  after insert or delete on public.competition_entries
  for each row execute function public.on_competition_entry_change();

-- ── khatma · الختمة (30 جزءاً) ──────────────────────────────────────────────
create table if not exists public.khatmat (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  type       text not null default 'group',        -- group | individual
  target_juz integer not null default 30,
  is_active  boolean not null default true,
  starts_at  timestamptz,
  ends_at    timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.khatmat enable row level security;

create table if not exists public.khatma_juz (
  id          bigint generated always as identity primary key,
  khatma_id   uuid not null references public.khatmat(id) on delete cascade,
  juz_number  integer not null check (juz_number between 1 and 30),
  status      public.juz_status not null default 'available',
  reserved_by uuid references public.profiles(id) on delete set null,
  reserved_at timestamptz,
  completed_at timestamptz,
  unique (khatma_id, juz_number)
);
create index if not exists kj_khatma_idx   on public.khatma_juz (khatma_id);
create index if not exists kj_reserved_idx on public.khatma_juz (reserved_by) where reserved_by is not null;
alter table public.khatma_juz enable row level security;
