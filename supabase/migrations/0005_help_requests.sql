-- ════════════════════════════════════════════════════════════════════════════
-- 0005_help_requests.sql
-- طلبات المساعدة · Help requests (المستخدمون المجتمعيون — حجم عالٍ)
-- ════════════════════════════════════════════════════════════════════════════

do $$ begin create type public.help_request_type   as enum ('generalHelp','doctorBooking','treatment','foodBasket','financial','householdMaterials'); exception when duplicate_object then null; end $$;
do $$ begin create type public.help_request_status as enum ('pending','underReview','approved','rejected','completed'); exception when duplicate_object then null; end $$;
do $$ begin create type public.urgency_level       as enum ('low','medium','high','critical'); exception when duplicate_object then null; end $$;
do $$ begin create type public.attachment_type     as enum ('image','voiceNote'); exception when duplicate_object then null; end $$;

-- ── help_requests · طلبات المساعدة ──────────────────────────────────────────
create table if not exists public.help_requests (
  id                   uuid primary key default gen_random_uuid(),
  request_number       text unique,                                  -- رقم طلب بشري
  requester_user_id    uuid references public.profiles(id) on delete set null,  -- مقدّم الطلب (مستخدم مجتمعي)
  type                 public.help_request_type   not null,
  status               public.help_request_status not null default 'pending',
  urgency              public.urgency_level       not null default 'medium',
  -- المعلومات الأساسية
  title                text not null,
  description          text not null default '',
  full_name            text not null,
  phone                text not null,
  governorate          text not null default '',
  area                 text not null default '',
  full_address         text not null default '',
  family_size          integer,
  notes                text,
  -- الموقع
  latitude             double precision,
  longitude            double precision,
  location_address     text,
  -- الحقول الخاصة بكل نوع طلب (مرنة) — كانت Map<String,String> في التطبيق
  type_data            jsonb not null default '{}'::jsonb,
  -- المعالجة من طرف الفريق
  reviewed_by          uuid references public.staff_profiles(id) on delete set null,
  assigned_delegate_id uuid references public.staff_profiles(id) on delete set null,
  linked_subscriber_id uuid references public.subscribers(id)    on delete set null,
  linked_aid_id        uuid references public.aid_records(id)    on delete set null,
  submitted_at         timestamptz not null default now(),
  decided_at           timestamptz,
  updated_at           timestamptz not null default now()
);
create index if not exists hr_status_time_idx on public.help_requests (status, submitted_at desc);
create index if not exists hr_requester_idx   on public.help_requests (requester_user_id);
create index if not exists hr_delegate_idx     on public.help_requests (assigned_delegate_id, status);
create index if not exists hr_area_idx         on public.help_requests (governorate, area);
create index if not exists hr_type_idx         on public.help_requests (type);
create index if not exists hr_typedata_gin     on public.help_requests using gin (type_data);
create index if not exists hr_name_trgm        on public.help_requests using gin (full_name gin_trgm_ops);
create index if not exists hr_phone_trgm       on public.help_requests using gin (phone gin_trgm_ops);

drop trigger if exists hr_set_updated_at on public.help_requests;
create trigger hr_set_updated_at before update on public.help_requests
  for each row execute function public.set_updated_at();
alter table public.help_requests enable row level security;

-- الآن نربط المساعدة بالطلب الذي ولّدها (FK مؤجّل من 0004)
alter table public.aid_records
  drop constraint if exists aid_source_help_request_fk;
alter table public.aid_records
  add constraint aid_source_help_request_fk
  foreign key (source_help_request_id) references public.help_requests(id) on delete set null;

-- ── help_request_attachments · المرفقات (صور / تسجيلات صوتية) ────────────────
-- الملفات نفسها تُخزَّن في Supabase Storage؛ هنا نحفظ المسار فقط.
create table if not exists public.help_request_attachments (
  id               uuid primary key default gen_random_uuid(),
  help_request_id  uuid not null references public.help_requests(id) on delete cascade,
  type             public.attachment_type not null,
  name             text not null default '',
  storage_path     text not null,             -- المسار داخل bucket (help-media)
  duration_seconds integer,                   -- للتسجيلات الصوتية
  created_at       timestamptz not null default now()
);
create index if not exists hra_request_idx on public.help_request_attachments (help_request_id);
alter table public.help_request_attachments enable row level security;

-- ── help_request_status_history · سجلّ تغيّر الحالة (تدقيق) ──────────────────
create table if not exists public.help_request_status_history (
  id              bigint generated always as identity primary key,
  help_request_id uuid not null references public.help_requests(id) on delete cascade,
  from_status     public.help_request_status,
  to_status       public.help_request_status not null,
  changed_by      uuid references public.profiles(id) on delete set null,
  note            text,
  changed_at      timestamptz not null default now()
);
create index if not exists hrsh_request_idx on public.help_request_status_history (help_request_id, changed_at desc);
alter table public.help_request_status_history enable row level security;
