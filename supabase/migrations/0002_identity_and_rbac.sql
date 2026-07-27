-- ════════════════════════════════════════════════════════════════════════════
-- 0002_identity_and_rbac.sql
-- الهوية والصلاحيات · Identity & RBAC
-- profiles (امتداد لـ auth.users) + المندوبون/الموظفون + الأدوار + دوال RLS
-- ════════════════════════════════════════════════════════════════════════════

-- ── Enums ───────────────────────────────────────────────────────────────────
-- نوع المستخدم: موظف داخل النظام (مندوب/مشرف/مدير) أو مستخدم عام (مجتمعي).
do $$ begin
  create type public.user_type as enum ('staff', 'community');
exception when duplicate_object then null; end $$;

-- دور الموظف. ملاحظة: الدور القديم 'employee' في الباك-إند يُقابله 'delegate'.
do $$ begin
  create type public.staff_role as enum ('admin', 'supervisor', 'delegate');
exception when duplicate_object then null; end $$;

-- ── profiles · امتداد عام لجدول auth.users ──────────────────────────────────
-- كل مستخدم (سواء مندوب أو مستخدم مجتمعي) له صف واحد هنا، مرتبط بهوية Supabase Auth.
-- كل الجداول الأخرى تشير إلى profiles(id) — وليس إلى auth.users مباشرة —
-- كي يبقى مصدر الهوية قابلاً للتبديل من مكان واحد.
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  user_type     public.user_type not null default 'community',
  full_name     text not null default '',
  phone         text,
  avatar_url    text,
  governorate   text,
  area          text,
  locale        text not null default 'ar',   -- ar | en
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create unique index if not exists profiles_phone_key on public.profiles (phone) where phone is not null;
create index if not exists profiles_user_type_idx on public.profiles (user_type);
create index if not exists profiles_area_idx on public.profiles (governorate, area);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
comment on table public.profiles is 'الملف العام لكل مستخدم — مرتبط بـ auth.users (Supabase Auth)';

-- ── staff_profiles · بيانات المندوب/المشرف/المدير ───────────────────────────
create table if not exists public.staff_profiles (
  id                   uuid primary key references public.profiles(id) on delete cascade,
  employee_code        text unique,
  staff_role           public.staff_role not null default 'delegate',
  supervisor_id        uuid references public.staff_profiles(id) on delete set null,
  assigned_governorate text,
  assigned_areas       text[] not null default '{}',   -- المناطق المسندة للمندوب
  max_subscribers      integer not null default 500,   -- السعة القصوى للمندوب
  is_active            boolean not null default true,
  hired_at             date,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create index if not exists staff_role_idx on public.staff_profiles (staff_role);
create index if not exists staff_supervisor_idx on public.staff_profiles (supervisor_id);
create index if not exists staff_areas_idx on public.staff_profiles using gin (assigned_areas);

drop trigger if exists staff_set_updated_at on public.staff_profiles;
create trigger staff_set_updated_at before update on public.staff_profiles
  for each row execute function public.set_updated_at();

alter table public.staff_profiles enable row level security;
comment on table public.staff_profiles is 'المندوبون (delegate) والمشرفون (supervisor) والمدراء (admin)';

-- ── RBAC · صلاحيات مرنة تتوافق مع Permission enum في التطبيق ─────────────────
create table if not exists public.permissions (
  key         text primary key,          -- مثل 'approveAid'
  description text not null default ''
);
create table if not exists public.role_permissions (
  role        public.staff_role not null,
  permission  text not null references public.permissions(key) on delete cascade,
  primary key (role, permission)
);
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;

-- ── RLS helper functions · دوال مساعدة للسياسات ─────────────────────────────
-- SECURITY DEFINER + search_path ثابت لتفادي التكرار اللانهائي في سياسات profiles.
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.user_type = 'staff'
  );
$$;

create or replace function public.current_staff_role()
returns public.staff_role language sql stable security definer set search_path = public as $$
  select s.staff_role from public.staff_profiles s where s.id = (select auth.uid());
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_staff_role() = 'admin';
$$;

create or replace function public.is_supervisor_or_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_staff_role() in ('admin','supervisor');
$$;

-- ── Auto-create profile on signup · إنشاء profile تلقائياً عند التسجيل ───────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone, user_type)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.phone,
    coalesce((new.raw_user_meta_data->>'user_type')::public.user_type, 'community')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
