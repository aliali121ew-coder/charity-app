-- ════════════════════════════════════════════════════════════════════════════
-- 0001_extensions_and_reference.sql
-- Charity App — Supabase schema · المخطط الأساسي
-- الامتدادات + الدوال العامة + الجداول المرجعية (المحافظات/المناطق)
-- ════════════════════════════════════════════════════════════════════════════

-- ── Extensions · الامتدادات ─────────────────────────────────────────────────
create extension if not exists pgcrypto;    -- gen_random_uuid()
create extension if not exists pg_trgm;      -- بحث نصي ضبابي للأسماء/الهواتف (Arabic-friendly)
create extension if not exists btree_gin;    -- فهارس GIN مركبة

-- ── Generic updated_at trigger · دالة تحديث updated_at تلقائياً ──────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── regions · المحافظات والمناطق (مرجعي) ────────────────────────────────────
-- تُستخدم لإسناد المندوبين للمناطق وفلترة المشتركين وطلبات المساعدة.
create table if not exists public.regions (
  id           bigint generated always as identity primary key,
  governorate  text not null,                 -- المحافظة
  area         text not null,                 -- المنطقة / القضاء
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  unique (governorate, area)
);
create index if not exists regions_gov_idx on public.regions (governorate);

alter table public.regions enable row level security;

comment on table public.regions is 'المحافظات والمناطق العراقية — مرجعية للإسناد والفلترة';
