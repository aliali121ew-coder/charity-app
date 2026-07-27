-- ════════════════════════════════════════════════════════════════════════════
-- 0016_logs_action_type_text.sql
-- تحويل activity_logs.action_type من enum إلى text.
-- السبب: LogActionType في التطبيق يحوي قيماً غير موجودة في enum لدينا
-- (logout, report, settings, updateFamily, updateSubscriber) — النص يقبلها كلها.
-- ════════════════════════════════════════════════════════════════════════════
alter table public.activity_logs alter column action_type drop default;
alter table public.activity_logs alter column action_type type text using action_type::text;
alter table public.activity_logs alter column action_type set default 'other';
