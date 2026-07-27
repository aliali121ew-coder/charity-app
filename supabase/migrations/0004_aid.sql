-- ════════════════════════════════════════════════════════════════════════════
-- 0004_aid.sql
-- المساعدات · Aid records (financial / food / medical / seasonal / education)
-- ════════════════════════════════════════════════════════════════════════════

do $$ begin create type public.aid_type   as enum ('financial','food','medical','seasonal','education','other'); exception when duplicate_object then null; end $$;
do $$ begin create type public.aid_status as enum ('pending','approved','rejected','distributed');               exception when duplicate_object then null; end $$;

create table if not exists public.aid_records (
  id                     uuid primary key default gen_random_uuid(),
  reference_number       text not null unique,                    -- رقم مرجعي بشري
  beneficiary_name       text not null,
  family_id              uuid references public.families(id)    on delete set null,
  subscriber_id          uuid references public.subscribers(id) on delete set null,
  type                   public.aid_type   not null,
  amount                 numeric(14,2) not null default 0,
  currency               text not null default 'IQD',
  status                 public.aid_status not null default 'pending',
  notes                  text,
  responsible_staff_id   uuid references public.staff_profiles(id) on delete set null,
  approved_by            uuid references public.staff_profiles(id) on delete set null,
  distributed_by         uuid references public.staff_profiles(id) on delete set null,
  source_help_request_id uuid,          -- FK يُضاف في 0005 بعد إنشاء help_requests
  aid_date               date not null default current_date,
  delivery_date          date,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
create index if not exists aid_status_idx     on public.aid_records (status);
create index if not exists aid_family_idx      on public.aid_records (family_id);
create index if not exists aid_subscriber_idx  on public.aid_records (subscriber_id);
create index if not exists aid_type_idx        on public.aid_records (type);
create index if not exists aid_date_idx        on public.aid_records (aid_date desc);
create index if not exists aid_responsible_idx on public.aid_records (responsible_staff_id);

drop trigger if exists aid_set_updated_at on public.aid_records;
create trigger aid_set_updated_at before update on public.aid_records
  for each row execute function public.set_updated_at();
alter table public.aid_records enable row level security;
comment on table public.aid_records is 'سجلّات المساعدات — مرتبطة بعائلة أو مشترك، وقد تنشأ من طلب مساعدة';
