-- ════════════════════════════════════════════════════════════════════════════
-- 0011_rls_policies.sql
-- سياسات الوصول · Row-Level Security policies
-- المبدأ: الموظفون (is_staff) يديرون بيانات العمل؛ المستخدم المجتمعي يرى/يكتب صفوفه فقط.
-- ملاحظة: دور service_role (الباك-إند Dart) يتجاوز RLS تلقائياً — هذه السياسات
--         تحمي الوصول المباشر من تطبيقات الجوال (100k مستخدم) عبر Supabase client.
-- ════════════════════════════════════════════════════════════════════════════

-- ── profiles ────────────────────────────────────────────────────────────────
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.is_staff());
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid()) or public.is_admin());
drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ── staff_profiles / RBAC ───────────────────────────────────────────────────
drop policy if exists staff_select on public.staff_profiles;
create policy staff_select on public.staff_profiles for select to authenticated using (public.is_staff());
drop policy if exists staff_admin_write on public.staff_profiles;
create policy staff_admin_write on public.staff_profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists perms_select on public.permissions;
create policy perms_select on public.permissions for select to authenticated using (public.is_staff());
drop policy if exists perms_admin on public.permissions;
create policy perms_admin on public.permissions for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists roleperms_select on public.role_permissions;
create policy roleperms_select on public.role_permissions for select to authenticated using (public.is_staff());
drop policy if exists roleperms_admin on public.role_permissions;
create policy roleperms_admin on public.role_permissions for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── regions (مرجعي — يقرأه الجميع المصادَق) ─────────────────────────────────
drop policy if exists regions_select on public.regions;
create policy regions_select on public.regions for select to authenticated using (true);
drop policy if exists regions_admin on public.regions;
create policy regions_admin on public.regions for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── families / family_members / subscribers (بيانات إدارية = للموظفين) ──────
drop policy if exists families_staff_rw on public.families;
create policy families_staff_rw on public.families for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

drop policy if exists fam_members_staff_rw on public.family_members;
create policy fam_members_staff_rw on public.family_members for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

drop policy if exists subs_staff_read on public.subscribers;
create policy subs_staff_read on public.subscribers for select to authenticated using (public.is_staff());
drop policy if exists subs_staff_write on public.subscribers;
create policy subs_staff_write on public.subscribers for insert to authenticated with check (public.is_staff());
drop policy if exists subs_staff_update on public.subscribers;
create policy subs_staff_update on public.subscribers for update to authenticated using (public.is_staff()) with check (public.is_staff());
drop policy if exists subs_admin_delete on public.subscribers;
create policy subs_admin_delete on public.subscribers for delete to authenticated using (public.is_supervisor_or_admin());

drop policy if exists sub_assign_staff on public.subscriber_assignments;
create policy sub_assign_staff on public.subscriber_assignments for select to authenticated using (public.is_staff());
drop policy if exists sub_assign_write on public.subscriber_assignments;
create policy sub_assign_write on public.subscriber_assignments for all to authenticated
  using (public.is_supervisor_or_admin()) with check (public.is_supervisor_or_admin());

-- ── aid_records ─────────────────────────────────────────────────────────────
drop policy if exists aid_staff_rw on public.aid_records;
create policy aid_staff_rw on public.aid_records for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- ── help_requests (المستخدم المجتمعي ينشئ طلبه ويقرأه؛ الفريق يرى الكل) ──────
drop policy if exists hr_select on public.help_requests;
create policy hr_select on public.help_requests for select to authenticated
  using (requester_user_id = (select auth.uid()) or public.is_staff());
drop policy if exists hr_insert on public.help_requests;
create policy hr_insert on public.help_requests for insert to authenticated
  with check (requester_user_id = (select auth.uid()) or public.is_staff());
drop policy if exists hr_update on public.help_requests;
create policy hr_update on public.help_requests for update to authenticated
  using (public.is_staff() or (requester_user_id = (select auth.uid()) and status = 'pending'))
  with check (public.is_staff() or requester_user_id = (select auth.uid()));
drop policy if exists hr_delete on public.help_requests;
create policy hr_delete on public.help_requests for delete to authenticated using (public.is_supervisor_or_admin());

drop policy if exists hra_select on public.help_request_attachments;
create policy hra_select on public.help_request_attachments for select to authenticated using (
  public.is_staff() or exists (
    select 1 from public.help_requests r
    where r.id = help_request_id and r.requester_user_id = (select auth.uid())
  ));
drop policy if exists hra_insert on public.help_request_attachments;
create policy hra_insert on public.help_request_attachments for insert to authenticated with check (
  public.is_staff() or exists (
    select 1 from public.help_requests r
    where r.id = help_request_id and r.requester_user_id = (select auth.uid())
  ));

drop policy if exists hrsh_select on public.help_request_status_history;
create policy hrsh_select on public.help_request_status_history for select to authenticated using (
  public.is_staff() or exists (
    select 1 from public.help_requests r
    where r.id = help_request_id and r.requester_user_id = (select auth.uid())
  ));
drop policy if exists hrsh_insert on public.help_request_status_history;
create policy hrsh_insert on public.help_request_status_history for insert to authenticated with check (public.is_staff());

-- ── competitions / prizes / khatma (قراءة عامة للمنشور، كتابة للفريق) ────────
drop policy if exists comp_select on public.competitions;
create policy comp_select on public.competitions for select to authenticated using (is_published or public.is_staff());
drop policy if exists comp_staff_write on public.competitions;
create policy comp_staff_write on public.competitions for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

drop policy if exists prizes_select on public.prizes;
create policy prizes_select on public.prizes for select to authenticated using (is_active or public.is_staff());
drop policy if exists prizes_staff_write on public.prizes;
create policy prizes_staff_write on public.prizes for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists khatmat_select on public.khatmat;
create policy khatmat_select on public.khatmat for select to authenticated using (true);
drop policy if exists khatmat_staff_write on public.khatmat;
create policy khatmat_staff_write on public.khatmat for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists kj_select on public.khatma_juz;
create policy kj_select on public.khatma_juz for select to authenticated using (true);
drop policy if exists kj_reserve on public.khatma_juz;   -- حجز/إكمال جزء من أي مستخدم مصادَق
create policy kj_reserve on public.khatma_juz for update to authenticated
  using (true) with check (reserved_by = (select auth.uid()) or public.is_staff());
drop policy if exists kj_staff_write on public.khatma_juz;
create policy kj_staff_write on public.khatma_juz for insert to authenticated with check (public.is_staff());

-- ── competition_entries / proofs (المستخدم يملك صفوفه) ──────────────────────
drop policy if exists ce_select on public.competition_entries;
create policy ce_select on public.competition_entries for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists ce_insert on public.competition_entries;
create policy ce_insert on public.competition_entries for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists ce_update on public.competition_entries;
create policy ce_update on public.competition_entries for update to authenticated
  using (user_id = (select auth.uid()) or public.is_staff()) with check (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists ce_delete on public.competition_entries;
create policy ce_delete on public.competition_entries for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());

drop policy if exists pp_select on public.participation_proofs;
create policy pp_select on public.participation_proofs for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists pp_insert on public.participation_proofs;
create policy pp_insert on public.participation_proofs for insert to authenticated
  with check (user_id = (select auth.uid()));
drop policy if exists pp_update on public.participation_proofs;
create policy pp_update on public.participation_proofs for update to authenticated
  using (public.is_staff() or (user_id = (select auth.uid()) and review_status = 'pending'))
  with check (public.is_staff() or user_id = (select auth.uid()));

-- ── store_redemptions / claim_cards ─────────────────────────────────────────
drop policy if exists sr_select on public.store_redemptions;
create policy sr_select on public.store_redemptions for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists sr_insert on public.store_redemptions;
create policy sr_insert on public.store_redemptions for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists sr_staff_update on public.store_redemptions;
create policy sr_staff_update on public.store_redemptions for update to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists cc_select on public.claim_cards;
create policy cc_select on public.claim_cards for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists cc_staff_write on public.claim_cards;
create policy cc_staff_write on public.claim_cards for insert to authenticated with check (public.is_staff());
drop policy if exists cc_update on public.claim_cards;
create policy cc_update on public.claim_cards for update to authenticated
  using (user_id = (select auth.uid()) or public.is_staff()) with check (user_id = (select auth.uid()) or public.is_staff());

-- ── points_ledger (إضافة من الفريق/الخادم فقط؛ يقرأ المستخدم رصيده) ─────────
drop policy if exists pl_select on public.points_ledger;
create policy pl_select on public.points_ledger for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists pl_staff_insert on public.points_ledger;
create policy pl_staff_insert on public.points_ledger for insert to authenticated with check (public.is_staff());

-- ── user_engagement_stats (لوحة الصدارة — قراءة لكل مصادَق) ──────────────────
drop policy if exists ues_select on public.user_engagement_stats;
create policy ues_select on public.user_engagement_stats for select to authenticated using (true);

-- ── works feed ──────────────────────────────────────────────────────────────
drop policy if exists wp_select on public.work_posts;
create policy wp_select on public.work_posts for select to authenticated using (is_published or public.is_staff());
drop policy if exists wp_staff_write on public.work_posts;
create policy wp_staff_write on public.work_posts for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists wc_select on public.work_comments;
create policy wc_select on public.work_comments for select to authenticated using (true);
drop policy if exists wc_insert on public.work_comments;
create policy wc_insert on public.work_comments for insert to authenticated with check (author_user_id = (select auth.uid()));
drop policy if exists wc_modify on public.work_comments;
create policy wc_modify on public.work_comments for update to authenticated
  using (author_user_id = (select auth.uid()) or public.is_staff()) with check (author_user_id = (select auth.uid()) or public.is_staff());
drop policy if exists wc_delete on public.work_comments;
create policy wc_delete on public.work_comments for delete to authenticated
  using (author_user_id = (select auth.uid()) or public.is_staff());

drop policy if exists wr_select on public.work_reactions;
create policy wr_select on public.work_reactions for select to authenticated using (true);
drop policy if exists wr_insert on public.work_reactions;
create policy wr_insert on public.work_reactions for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists wr_delete on public.work_reactions;
create policy wr_delete on public.work_reactions for delete to authenticated using (user_id = (select auth.uid()));

-- ── donations / payments / campaigns ────────────────────────────────────────
drop policy if exists camp_select on public.donation_campaigns;
create policy camp_select on public.donation_campaigns for select to authenticated using (is_active or public.is_staff());
drop policy if exists camp_staff_write on public.donation_campaigns;
create policy camp_staff_write on public.donation_campaigns for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists don_select on public.donations;
create policy don_select on public.donations for select to authenticated
  using (donor_user_id = (select auth.uid()) or public.is_staff());
drop policy if exists don_insert on public.donations;
create policy don_insert on public.donations for insert to authenticated
  with check (public.is_staff() or donor_user_id = (select auth.uid()));
drop policy if exists don_staff_update on public.donations;
create policy don_staff_update on public.donations for update to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists pi_staff on public.payment_intents;   -- حسّاس: للفريق فقط عبر الواجهة (الخادم يستخدم service_role)
create policy pi_staff on public.payment_intents for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- ── logs / notifications ────────────────────────────────────────────────────
drop policy if exists al_staff_select on public.activity_logs;
create policy al_staff_select on public.activity_logs for select to authenticated using (public.is_staff());
drop policy if exists al_staff_insert on public.activity_logs;
create policy al_staff_insert on public.activity_logs for insert to authenticated with check (public.is_staff());

drop policy if exists notif_select on public.notifications;
create policy notif_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()) or public.is_staff());
drop policy if exists notif_update_own on public.notifications;   -- تعليم كمقروء
create policy notif_update_own on public.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists notif_staff_insert on public.notifications;
create policy notif_staff_insert on public.notifications for insert to authenticated with check (public.is_staff());
