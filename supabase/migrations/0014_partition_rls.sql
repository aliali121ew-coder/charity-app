-- ════════════════════════════════════════════════════════════════════════════
-- 0014_partition_rls.sql
-- تفعيل RLS على أقسام (partitions) الجداول المقسّمة activity_logs و notifications.
-- السبب: أقسام الأبناء لا ترث حالة تفعيل RLS من الأب، فتبقى مكشوفة للوصول المباشر
-- عبر REST بمفتاح anon. الوصول الصحيح يتم دائماً عبر الجدول الأب (الذي يحمل السياسات)،
-- لذا تفعيل RLS على الأبناء (منع مباشر) هو التصليب الصحيح ولا يكسر التطبيق.
-- ════════════════════════════════════════════════════════════════════════════
do $$
declare r record;
begin
  for r in
    select c.relname
    from pg_inherits i
    join pg_class c on c.oid = i.inhrelid
    join pg_class p on p.oid = i.inhparent
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and p.relname in ('activity_logs','notifications')
  loop
    execute format('alter table public.%I enable row level security', r.relname);
  end loop;
end $$;
