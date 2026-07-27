-- ════════════════════════════════════════════════════════════════════════════
-- 0003_beneficiaries.sql
-- المستفيدون · Beneficiaries
-- العائلات + المشتركون + إسناد المندوب (العلاقة المحورية: مندوب ↔ مشترك)
-- ════════════════════════════════════════════════════════════════════════════

-- ── Enums (قيم مطابقة تماماً لـ Dart enum .name) ────────────────────────────
do $$ begin create type public.subscriber_status as enum ('active','inactive','pending','suspended'); exception when duplicate_object then null; end $$;
do $$ begin create type public.family_status     as enum ('eligible','ineligible','pending','suspended'); exception when duplicate_object then null; end $$;
do $$ begin create type public.income_level      as enum ('veryLow','low','medium','aboveAverage');       exception when duplicate_object then null; end $$;
do $$ begin create type public.marital_status    as enum ('married','widowed','divorced','single');       exception when duplicate_object then null; end $$;

-- ── families · العائلات ─────────────────────────────────────────────────────
create table if not exists public.families (
  id                   uuid primary key default gen_random_uuid(),
  head_name            text not null,                          -- اسم رب الأسرة
  members_count        integer not null default 1,
  marital_status       public.marital_status not null default 'married',
  income_level         public.income_level   not null default 'low',
  address              text not null default '',
  governorate          text,
  area                 text not null default '',
  status               public.family_status  not null default 'pending',
  phone                text,
  notes                text,
  aid_count            integer not null default 0,
  total_aid_amount     numeric(14,2) not null default 0,
  assigned_delegate_id uuid references public.staff_profiles(id) on delete set null,
  created_by           uuid references public.profiles(id) on delete set null,
  registration_date    date not null default current_date,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create index if not exists families_delegate_idx on public.families (assigned_delegate_id);
create index if not exists families_area_idx     on public.families (governorate, area);
create index if not exists families_status_idx   on public.families (status);
create index if not exists families_head_trgm    on public.families using gin (head_name gin_trgm_ops);

drop trigger if exists families_set_updated_at on public.families;
create trigger families_set_updated_at before update on public.families
  for each row execute function public.set_updated_at();
alter table public.families enable row level security;

-- ── family_members · أفراد العائلة (توسّعي) ─────────────────────────────────
create table if not exists public.family_members (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families(id) on delete cascade,
  full_name    text not null,
  relation     text,                          -- صلة القرابة
  birth_date   date,
  national_id  text,
  is_dependent boolean not null default true,
  created_at   timestamptz not null default now()
);
create index if not exists family_members_family_idx on public.family_members (family_id);
alter table public.family_members enable row level security;

-- ── subscribers · المشتركون (المستفيدون) ────────────────────────────────────
create table if not exists public.subscribers (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  phone                text not null default '',
  email                text,
  national_id          text,
  address              text not null default '',
  governorate          text,
  area                 text not null default '',
  latitude             double precision,
  longitude            double precision,
  status               public.subscriber_status not null default 'pending',
  notes                text,
  aid_count            integer not null default 0,
  family_id            uuid references public.families(id) on delete set null,
  assigned_delegate_id uuid references public.staff_profiles(id) on delete set null,   -- ← العلاقة المحورية
  linked_user_id       uuid references public.profiles(id) on delete set null,         -- إن كان المشترك مستخدماً في التطبيق
  created_by           uuid references public.profiles(id) on delete set null,
  registration_date    date not null default current_date,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create index if not exists subscribers_delegate_idx on public.subscribers (assigned_delegate_id, status);
create index if not exists subscribers_area_idx     on public.subscribers (governorate, area);
create index if not exists subscribers_family_idx   on public.subscribers (family_id);
create index if not exists subscribers_status_idx   on public.subscribers (status);
create index if not exists subscribers_name_trgm    on public.subscribers using gin (name gin_trgm_ops);
create index if not exists subscribers_phone_trgm   on public.subscribers using gin (phone gin_trgm_ops);
create unique index if not exists subscribers_national_id_key on public.subscribers (national_id) where national_id is not null;

drop trigger if exists subscribers_set_updated_at on public.subscribers;
create trigger subscribers_set_updated_at before update on public.subscribers
  for each row execute function public.set_updated_at();
alter table public.subscribers enable row level security;
comment on table public.subscribers is 'المشتركون/المستفيدون — كلٌّ مُسنَد إلى مندوب عبر assigned_delegate_id';

-- ── subscriber_assignments · سجل إسناد المندوبين (تاريخ + تدقيق) ─────────────
create table if not exists public.subscriber_assignments (
  id            bigint generated always as identity primary key,
  subscriber_id uuid not null references public.subscribers(id) on delete cascade,
  delegate_id   uuid references public.staff_profiles(id) on delete set null,
  assigned_by   uuid references public.profiles(id) on delete set null,
  reason        text,
  assigned_at   timestamptz not null default now(),
  unassigned_at timestamptz
);
create index if not exists sub_assign_sub_idx      on public.subscriber_assignments (subscriber_id);
create index if not exists sub_assign_delegate_idx on public.subscriber_assignments (delegate_id) where unassigned_at is null;
alter table public.subscriber_assignments enable row level security;
