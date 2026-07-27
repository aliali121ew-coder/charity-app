-- ════════════════════════════════════════════════════════════════════════════
-- 0007_works_feed.sql
-- أعمال المؤسسة · Works feed (منشورات + تعليقات + تفاعلات)
-- ════════════════════════════════════════════════════════════════════════════

-- ملاحظة: 'all' في التطبيق قيمة فلترة فقط وليست فئة تخزين، لذا لا تُدرَج هنا.
do $$ begin create type public.work_category as enum
  ('food','financial','medical','educational','seasonal','events','general');
  exception when duplicate_object then null; end $$;

-- ── work_posts · المنشورات ──────────────────────────────────────────────────
create table if not exists public.work_posts (
  id                uuid primary key default gen_random_uuid(),
  author_user_id    uuid references public.profiles(id) on delete set null,
  author_name       text not null default '',
  author_role       text not null default '',
  title             text not null,
  description       text not null default '',
  category          public.work_category not null default 'general',
  location          text not null default '',
  tags              text[] not null default '{}',
  cover_image_url   text,
  image_urls        text[] not null default '{}',   -- صور متعددة (Storage)
  video_url         text,
  beneficiary_count integer not null default 0,
  view_count        integer not null default 0,
  like_count        integer not null default 0,
  comment_count     integer not null default 0,
  share_count       integer not null default 0,
  is_featured       boolean not null default false,
  is_published      boolean not null default true,
  published_at      timestamptz not null default now(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists wp_feed_idx     on public.work_posts (is_published, published_at desc);
create index if not exists wp_category_idx  on public.work_posts (category);
create index if not exists wp_featured_idx  on public.work_posts (is_featured) where is_featured;
create index if not exists wp_tags_gin      on public.work_posts using gin (tags);

drop trigger if exists wp_set_updated_at on public.work_posts;
create trigger wp_set_updated_at before update on public.work_posts
  for each row execute function public.set_updated_at();
alter table public.work_posts enable row level security;

-- ── work_comments · التعليقات ───────────────────────────────────────────────
create table if not exists public.work_comments (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid not null references public.work_posts(id) on delete cascade,
  author_user_id uuid references public.profiles(id) on delete set null,
  author_name    text not null default '',
  author_role    text not null default '',
  text           text not null,
  like_count     integer not null default 0,
  created_at     timestamptz not null default now()
);
create index if not exists wc_post_idx on public.work_comments (post_id, created_at desc);
alter table public.work_comments enable row level security;

-- ── work_reactions · الإعجابات والحفظ ───────────────────────────────────────
create table if not exists public.work_reactions (
  post_id    uuid not null references public.work_posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  kind       text not null default 'like',   -- like | save
  created_at timestamptz not null default now(),
  primary key (post_id, user_id, kind)
);
create index if not exists wr_user_idx on public.work_reactions (user_id);
alter table public.work_reactions enable row level security;

-- مُشغّلات العدّادات: تحافظ على comment_count و like_count متزامنَين.
create or replace function public.on_work_comment_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.work_posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.work_posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end; $$;
drop trigger if exists work_comment_change on public.work_comments;
create trigger work_comment_change after insert or delete on public.work_comments
  for each row execute function public.on_work_comment_change();

create or replace function public.on_work_reaction_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.kind = 'like' then
    update public.work_posts set like_count = like_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' and old.kind = 'like' then
    update public.work_posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end; $$;
drop trigger if exists work_reaction_change on public.work_reactions;
create trigger work_reaction_change after insert or delete on public.work_reactions
  for each row execute function public.on_work_reaction_change();
