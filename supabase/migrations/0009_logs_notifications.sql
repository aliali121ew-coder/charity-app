-- ════════════════════════════════════════════════════════════════════════════
-- 0009_logs_notifications.sql
-- سجلّ العمليات + الإشعارات · مقسّمة شهرياً (Range partitioning) للحجم العالي
-- ════════════════════════════════════════════════════════════════════════════

do $$ begin create type public.log_action_type as enum
  ('add','edit','delete','approve','reject','distribute','createReport','changeSettings','login','transfer','other');
  exception when duplicate_object then null; end $$;

-- ── دالة مساعدة: تنشئ قسماً شهرياً إن لم يوجد ───────────────────────────────
create or replace function public.ensure_month_partition(parent_table text, month_start date)
returns void language plpgsql as $$
declare
  part_name text;
  start_ts  text := to_char(month_start, 'YYYY-MM-DD');
  end_ts    text := to_char((month_start + interval '1 month')::date, 'YYYY-MM-DD');
begin
  part_name := parent_table || '_' || to_char(month_start, 'YYYY_MM');
  execute format(
    'create table if not exists public.%I partition of public.%I for values from (%L) to (%L)',
    part_name, parent_table, start_ts, end_ts
  );
  -- فعّل RLS على القسم الجديد: الوصول يتم عبر الجدول الأب (الذي يحمل السياسات)،
  -- وهذا يمنع أي وصول مباشر للأقسام عبر REST بمفتاح anon.
  execute format('alter table public.%I enable row level security', part_name);
end; $$;

-- ── activity_logs · سجلّ العمليات (append-only) ─────────────────────────────
create table if not exists public.activity_logs (
  id                bigint generated always as identity,
  actor_user_id     uuid references public.profiles(id) on delete set null,
  actor_name        text,
  action_type       public.log_action_type not null default 'other',
  action_title      text not null default '',
  action_title_ar   text not null default '',
  description       text not null default '',
  description_ar    text not null default '',
  reference_number  text,
  related_entity    text,          -- 'subscriber' | 'aid' | 'help_request' ...
  related_entity_id text,
  metadata          jsonb not null default '{}'::jsonb,
  ip_address        inet,
  created_at        timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);
create index if not exists al_actor_time_idx on public.activity_logs (actor_user_id, created_at desc);
create index if not exists al_entity_idx     on public.activity_logs (related_entity, related_entity_id);
create index if not exists al_action_idx      on public.activity_logs (action_type, created_at desc);
alter table public.activity_logs enable row level security;

-- ── notifications · الإشعارات ───────────────────────────────────────────────
create table if not exists public.notifications (
  id         bigint generated always as identity,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  body       text not null default '',
  type       text not null default 'general',
  data       jsonb not null default '{}'::jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);
create index if not exists notif_user_idx on public.notifications (user_id, is_read, created_at desc);
alter table public.notifications enable row level security;

-- ── إنشاء أقسام من (الشهر الحالي − 3) إلى (+6) + قسم افتراضي احتياطي ────────
do $$
declare base date := (date_trunc('month', now()) - interval '3 months')::date;
begin
  for i in 0..9 loop
    perform public.ensure_month_partition('activity_logs', (base + (i || ' months')::interval)::date);
    perform public.ensure_month_partition('notifications', (base + (i || ' months')::interval)::date);
  end loop;
end $$;

create table if not exists public.activity_logs_default partition of public.activity_logs default;
create table if not exists public.notifications_default partition of public.notifications default;
alter table public.activity_logs_default enable row level security;
alter table public.notifications_default enable row level security;

-- ملاحظة: جدوِل public.ensure_month_partition(...) شهرياً عبر pg_cron (انظر README).
