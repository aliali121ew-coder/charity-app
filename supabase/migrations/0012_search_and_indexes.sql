-- ════════════════════════════════════════════════════════════════════════════
-- 0012_search_and_indexes.sql
-- بحث نصّي + فهارس تقارير · Full-text search & reporting indexes
-- ملاحظة: للأسماء/الهواتف نعتمد pg_trgm (فهارس GIN أُنشئت سابقاً) — مناسب للعربية.
-- ════════════════════════════════════════════════════════════════════════════

-- بحث نصّي على طلبات المساعدة (عنوان + وصف + اسم) — config 'simple' يعمل مع العربية.
alter table public.help_requests
  add column if not exists search_tsv tsvector
  generated always as (
    to_tsvector('simple',
      coalesce(title,'') || ' ' || coalesce(description,'') || ' ' || coalesce(full_name,''))
  ) stored;
create index if not exists hr_search_gin on public.help_requests using gin (search_tsv);

-- بحث نصّي على منشورات الأعمال.
alter table public.work_posts
  add column if not exists search_tsv tsvector
  generated always as (
    to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(description,''))
  ) stored;
create index if not exists wp_search_gin on public.work_posts using gin (search_tsv);

-- فهارس مركّبة تخدم لوحات المعلومات والتقارير الشائعة.
create index if not exists aid_status_date_idx     on public.aid_records (status, aid_date desc);
create index if not exists hr_delegate_time_idx     on public.help_requests (assigned_delegate_id, submitted_at desc);
create index if not exists subs_delegate_created_idx on public.subscribers (assigned_delegate_id, created_at desc);
create index if not exists don_date_status_idx      on public.donations (status, date desc);
