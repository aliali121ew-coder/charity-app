-- ════════════════════════════════════════════════════════════════════════════
-- 0008_donations_payments.sql
-- التبرعات وبوابات الدفع · Donations & payment gateways (MyFatoorah / ZainCash)
-- يطابق تماماً جداول db.dart الحالية (donations + payment_intents) ثم يضيف تحسينات.
-- ════════════════════════════════════════════════════════════════════════════

-- ── donation_campaigns · حملات التبرع (جديد) ────────────────────────────────
create table if not exists public.donation_campaigns (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text not null default '',
  goal_amount  numeric(14,2) not null default 0,
  raised_amount numeric(14,2) not null default 0,
  currency     text not null default 'IQD',
  cover_image_url text,
  is_active    boolean not null default true,
  starts_at    timestamptz,
  ends_at      timestamptz,
  created_by   uuid references public.staff_profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
alter table public.donation_campaigns enable row level security;

-- ── donations · التبرعات (مطابق لـ db.dart، TEXT id للتوافق) ─────────────────
create table if not exists public.donations (
  id        text primary key,
  donor     text not null,
  amount    double precision not null,
  currency  text not null,
  method    text not null,      -- zainCash | visaCard | masterCard | bankTransfer | cash
  status    text not null,      -- completed | processing | rejected
  reference text not null,
  date      timestamptz not null,
  notes     text
);
create index if not exists donations_date_idx   on public.donations (date desc);
create index if not exists donations_status_idx on public.donations (status);

-- تحسينات إضافية (لا تكسر الباك-إند الحالي)
alter table public.donations add column if not exists donor_user_id   uuid references public.profiles(id) on delete set null;
alter table public.donations add column if not exists campaign_id     uuid references public.donation_campaigns(id) on delete set null;
alter table public.donations add column if not exists help_request_id uuid references public.help_requests(id) on delete set null;
create index if not exists donations_donor_user_idx on public.donations (donor_user_id) where donor_user_id is not null;
create index if not exists donations_campaign_idx    on public.donations (campaign_id) where campaign_id is not null;
alter table public.donations enable row level security;

-- ── payment_intents · نوايا الدفع (مطابق لـ db.dart) ────────────────────────
create table if not exists public.payment_intents (
  id                  text primary key,
  provider            text not null,   -- myfatoorah | zaincash
  method              text not null,   -- visa | mastercard | zaincash | superki
  amount              double precision not null,
  currency            text not null,
  donor_name          text not null,
  donation_id         text not null,
  status              text not null,   -- created|pending|paid|failed|cancelled|expired
  redirect_url        text,
  provider_payment_id text,
  provider_invoice_id text,
  provider_txn_id     text,
  last_error          text,
  created_at          timestamptz not null,
  expires_at          timestamptz not null
);
create index if not exists payment_intents_status_idx on public.payment_intents (status);
create index if not exists payment_intents_donation_idx on public.payment_intents (donation_id);
-- ربط نية الدفع بالتبرع
alter table public.payment_intents drop constraint if exists payment_intents_donation_fk;
alter table public.payment_intents
  add constraint payment_intents_donation_fk
  foreign key (donation_id) references public.donations(id) on delete cascade;
alter table public.payment_intents enable row level security;

comment on table public.donations is 'التبرعات — متوافقة مع الباك-إند الحالي + روابط للمستخدم/الحملة';
comment on table public.payment_intents is 'نوايا الدفع عبر MyFatoorah/ZainCash — مصدر الحقيقة لحالة الدفع';
