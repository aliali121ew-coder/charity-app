-- ════════════════════════════════════════════════════════════════════════════
-- 0010_storage_buckets.sql
-- تخزين الوسائط · Supabase Storage buckets + سياسات الوصول
-- الصور والتسجيلات الصوتية تُخزَّن هنا — الجداول تحفظ المسار فقط.
-- ════════════════════════════════════════════════════════════════════════════

-- ── Buckets ─────────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public) values
  ('avatars',            'avatars',            true),   -- صور المستخدمين
  ('work-media',         'work-media',         true),   -- صور منشورات الأعمال
  ('competition-covers', 'competition-covers', true),   -- أغلفة المسابقات
  ('campaign-covers',    'campaign-covers',    true),   -- أغلفة حملات التبرع
  ('help-media',         'help-media',         false),  -- مرفقات طلبات المساعدة (خاص)
  ('proof-media',        'proof-media',        false)   -- أدلّة المشاركة (خاص)
on conflict (id) do nothing;

-- ── سياسات القراءة العامة (buckets العامة) ──────────────────────────────────
do $$ begin
  create policy "public read: avatars"     on storage.objects for select using (bucket_id = 'avatars');
  create policy "public read: work-media"  on storage.objects for select using (bucket_id = 'work-media');
  create policy "public read: comp-covers" on storage.objects for select using (bucket_id = 'competition-covers');
  create policy "public read: camp-covers" on storage.objects for select using (bucket_id = 'campaign-covers');
exception when duplicate_object then null; end $$;

-- ── رفع الصور: كل مستخدم يرفع داخل مجلد باسم معرّفه (uid/...) ────────────────
do $$ begin
  create policy "own upload: avatars" on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
  create policy "own modify: avatars" on storage.objects for update to authenticated
    using (bucket_id = 'avatars' and owner = (select auth.uid()));
exception when duplicate_object then null; end $$;

-- ── طلبات المساعدة (خاص): يرفع المستخدم لمجلده، ويقرأ المالك أو الفريق ───────
do $$ begin
  create policy "own upload: help-media" on storage.objects for insert to authenticated
    with check (bucket_id = 'help-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
  create policy "read: help-media" on storage.objects for select to authenticated
    using (bucket_id = 'help-media' and (owner = (select auth.uid()) or public.is_staff()));
exception when duplicate_object then null; end $$;

-- ── أدلّة المشاركة (خاص): نفس المبدأ ─────────────────────────────────────────
do $$ begin
  create policy "own upload: proof-media" on storage.objects for insert to authenticated
    with check (bucket_id = 'proof-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
  create policy "read: proof-media" on storage.objects for select to authenticated
    using (bucket_id = 'proof-media' and (owner = (select auth.uid()) or public.is_staff()));
exception when duplicate_object then null; end $$;

-- ── محتوى الفريق (أغلفة/منشورات): يكتبه الموظفون فقط ─────────────────────────
do $$ begin
  create policy "staff write: work-media" on storage.objects for insert to authenticated
    with check (bucket_id = 'work-media' and public.is_staff());
  create policy "staff write: comp-covers" on storage.objects for insert to authenticated
    with check (bucket_id = 'competition-covers' and public.is_staff());
  create policy "staff write: camp-covers" on storage.objects for insert to authenticated
    with check (bucket_id = 'campaign-covers' and public.is_staff());
exception when duplicate_object then null; end $$;
