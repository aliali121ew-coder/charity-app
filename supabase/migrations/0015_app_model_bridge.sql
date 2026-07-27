-- ════════════════════════════════════════════════════════════════════════════
-- 0015_app_model_bridge.sql
-- أعمدة إضافية تجعل الجداول تطابق نماذج التطبيق (lib/shared/models/*Model)
-- بلا فقد بيانات: اشتراكات/متأخرات المشترك + أسماء المندوب/الموظف النصّية.
-- كلها ADD COLUMN IF NOT EXISTS (آمنة وإضافية).
-- ════════════════════════════════════════════════════════════════════════════

-- SubscriberModel: subscriptionAmount / overdueMonths / subscriptionCategory / delegate(name) / avatarUrl
alter table public.subscribers add column if not exists avatar_url            text;
alter table public.subscribers add column if not exists delegate_name         text;   -- اسم المندوب (نصّي كما يستخدمه التطبيق حالياً)
alter table public.subscribers add column if not exists subscription_amount   numeric(14,2) not null default 0;
alter table public.subscribers add column if not exists overdue_months        integer not null default 0;
alter table public.subscribers add column if not exists subscription_category text;   -- الأشهر المتأخرة كنص
create index if not exists subscribers_overdue_idx on public.subscribers (overdue_months) where overdue_months > 0;

-- FamilyModel.delegateName
alter table public.families add column if not exists delegate_name text;

-- AidModel.responsibleEmployee (اسم الموظف نصّي)
alter table public.aid_records add column if not exists responsible_employee text;

comment on column public.subscribers.delegate_name is 'اسم المندوب النصّي (جسر توافق مع التطبيق؛ الإسناد المرجعي عبر assigned_delegate_id)';
