# قاعدة بيانات Charity App على Supabase
### Database schema · Supabase (PostgreSQL)

قاعدة بيانات متكاملة لتطبيق الخير: تدير **المندوبين (delegates)** و**المشتركين (subscribers)**،
وتتحمّل **1000 مندوب** يعملون بالتوازي و**أكثر من 100,000 مستخدم** لأغراض المسابقات وطلبات المساعدة.

---

## 1) الفكرة العامة — فئتان من المستخدمين

| الفئة | من هم؟ | العدد المستهدف | أين يعملون؟ |
|------|--------|----------------|-------------|
| **الموظفون / المندوبون** (`user_type = 'staff'`) | مدير (admin) · مشرف (supervisor) · مندوب (delegate) | ~1000 مندوب | يديرون المشتركين والعائلات والمساعدات، ويراجعون الطلبات والمسابقات |
| **المستخدمون المجتمعيون** (`user_type = 'community'`) | الجمهور والمستفيدون | 100,000+ | يقدّمون طلبات المساعدة، يشاركون في المسابقات والختمات، يتبرّعون |

> **المفتاح في التوسّع:** المستخدمون المجتمعيون (100k) يتصلون **مباشرة بـ Supabase** عبر مكتبة العميل (Flutter `supabase_flutter`) محميّين بـ **Row-Level Security**، فلا يمرّون عبر خادم Dart — وهذا ما يجعل النظام يتحمّل الأعداد الكبيرة. أما خادم Dart فيتكفّل بالعمليات الإدارية للمندوبين باستخدام `service_role`.

---

## 2) العلاقة المحورية: مندوب ↔ مشترك

```
staff_profiles (delegate)  1 ───────< subscribers.assigned_delegate_id
                                       │
                                       └──< families.assigned_delegate_id
```

- كل **مشترك** مُسنَد إلى مندوب واحد عبر `subscribers.assigned_delegate_id`.
- كل **عائلة** كذلك عبر `families.assigned_delegate_id`.
- تاريخ إعادة الإسناد محفوظ للتدقيق في `subscriber_assignments` (من أسند، متى، ولماذا).
- المندوب له `assigned_areas[]` و`max_subscribers` (سعته القصوى) في `staff_profiles`.

---

## 3) الهوية والمصادقة (Supabase Auth)

الهوية مبنية على **Supabase Auth** (`auth.users`) + جدول عام `public.profiles` (علاقة 1:1):

- عند تسجيل أي مستخدم جديد، يُنشأ صف `profiles` تلقائياً عبر المُشغّل `handle_new_user()`.
- **كل الجداول تشير إلى `profiles(id)` وليس إلى `auth.users` مباشرة** → مصدر الهوية قابل للتبديل من مكان واحد.
- لترقية مستخدم إلى موظف/مندوب بعد تسجيله:

```sql
-- أنشئ المستخدم أولاً عبر Supabase Auth (Dashboard → Authentication → Add user)، ثم:
select public.make_staff('admin@charity.org', 'admin');
select public.make_staff('mandoub1@charity.org', 'delegate', 'بغداد', array['الكرخ','الرصافة']);
```

> **توصية أمنية مهمّة:** الباك-إند الحالي يستخدم دالة تجزئة بسيطة `_simpleHash` وتوكنات في الذاكرة — **غير آمنة**. مع Supabase صار بإمكانك الاستغناء عنها كلياً واستخدام Supabase Auth (بريد/هاتف/OTP/Google جاهزة)، وهذا أيضاً يحلّ معاناة إعدادات البريد وОТP السابقة.

---

## 4) الجداول (33 جدولاً) حسب المجال

| المجال | الجداول |
|--------|---------|
| مرجعي | `regions` |
| الهوية والصلاحيات | `profiles`, `staff_profiles`, `permissions`, `role_permissions` |
| المستفيدون | `families`, `family_members`, `subscribers`, `subscriber_assignments` |
| المساعدات | `aid_records` |
| طلبات المساعدة | `help_requests`, `help_request_attachments`, `help_request_status_history` |
| المسابقات والتفاعل | `competitions`, `competition_entries`, `participation_proofs`, `prizes`, `store_redemptions`, `claim_cards`, `points_ledger`, `user_engagement_stats` |
| الختمة | `khatmat`, `khatma_juz` |
| الأعمال (feed) | `work_posts`, `work_comments`, `work_reactions` |
| التبرعات والدفع | `donation_campaigns`, `donations`, `payment_intents` |
| السجلّ والإشعارات | `activity_logs` (مقسّم), `notifications` (مقسّم) |

> قيم الـ enum مطابقة تماماً لـ `.name` في Dart (مثل `veryLow`, `foodBasket`, `underReview`, `zainCash`) حتى لا يتغيّر كود التطبيق ولا الصفوف المخزّنة.

---

## 5) كيف تطبّق المخطّط؟

### الخيار أ — Supabase CLI (موصى به)
```bash
# اربط مشروعك
supabase link --project-ref <your-project-ref>
# طبّق كل الهجرات بالترتيب
supabase db push
```

### الخيار ب — SQL Editor في لوحة Supabase
افتح **SQL Editor** ونفّذ الملفات بالترتيب من `0001` إلى `0013`.

الملفات مكتوبة **idempotent** (تستخدم `if not exists` وحُرّاس للـ enum والسياسات) فيمكن إعادة تشغيلها بأمان.

---

## 6) التوسّع إلى 1000 مندوب و100,000+ مستخدم

الحجم بحدّ ذاته سهل على Postgres (101 ألف صف مستخدم = لا شيء). التحدّي هو **التزامن** و**الجداول كثيفة الكتابة**. المعالجات المبنية في هذا المخطّط:

1. **تجميع الاتصالات (Connection Pooling):** آلاف العملاء لا يمكنهم فتح اتصال Postgres لكلٍّ منهم. استخدم **Supavisor** المدمج في Supabase:
   - المنفذ **6543** (Transaction mode) لتطبيقات الجوال/Serverless — يتحمّل آلاف الاتصالات.
   - المنفذ **5432** (Session mode) للباك-إند طويل العمر.

2. **الفهرسة:** فهارس مركّبة على مسارات الاستعلام الساخنة (المندوب+الحالة، الطلبات حسب الحالة+الوقت، لوحة الصدارة على `total_points DESC`) + فهارس `pg_trgm` للبحث بالأسماء/الهواتف العربية.

3. **التقسيم الشهري (Partitioning):** الجداول كثيفة النمو `activity_logs` و`notifications` مقسّمة شهرياً — تبقى الفهارس صغيرة وسريعة، وأرشفة القديم = حذف قسم. جدوِل إنشاء الأقسام مستقبلاً عبر **pg_cron**:
   ```sql
   select cron.schedule('mk-partitions','0 0 25 * *', $$
     select public.ensure_month_partition('activity_logs', (date_trunc('month', now())+interval '1 month')::date);
     select public.ensure_month_partition('notifications', (date_trunc('month', now())+interval '1 month')::date);
   $$);
   ```

4. **لوحة الصدارة الفورية:** بدل حساب `SUM(points)` على ملايين الصفوف، يحافظ مُشغّل على `user_engagement_stats.total_points` مجمّعاً لحظياً من `points_ledger` (مصدر الحقيقة، append-only). الاستعلام = `order by total_points desc limit N` على فهرس.

5. **التزامن والنزاهة:**
   - `UNIQUE(competition_id, user_id)` يمنع الانضمام المزدوج.
   - خصم المخزون ذرّياً: `update prizes set stock = stock-1 where id=? and stock>0`.
   - النقاط دفتر إضافة-فقط + خصم داخل معاملة (transaction) لمنع الصرف المزدوج.

6. **الوسائط في Storage وليس في القاعدة:** الصور والتسجيلات في **Supabase Storage** (buckets مع سياسات)؛ الجداول تحفظ المسار فقط — ضروري عند 100k مستخدم.

7. **قراءات ثقيلة:** استخدم **Read Replicas** (خطط Supabase الأعلى) للتقارير ولوحة الصدارة، و**Realtime** للإشعارات الحيّة، وتخزين مؤقت (cache) لأعلى المتصدّرين.

8. **RLS بأداء عالٍ:** كل السياسات تستخدم النمط `(select auth.uid())` ليُحسب مرّة واحدة لكل استعلام (initplan caching) بدل كل صف.

---

## 7) الربط مع خادم Dart الحالي

- اضبط `DATABASE_URL` على سلسلة اتصال Supabase (منفذ **5432** Session، أو **6543** Transaction لبيئات Serverless) — `db.dart` يستخدم `sslMode.require` وهو المطلوب.
- استخدم **Service Role Key** في الخادم فقط (يتجاوز RLS للعمليات الإدارية). **لا تضعه أبداً في تطبيق الجوال.**
- جداول `donations` و`payment_intents` مطابقة لما ينشئه `ensureSchema()` حالياً، فلا تعارض.

---

## 8) الخطوة التالية (اختياري)
- توليد كود Dart/الـ repositories التي تقرأ/تكتب في هذه الجداول (استبدال المستودعات الوهمية Mock).
- تفعيل RLS الأدقّ ليرى المندوب مشتركي مناطقه فقط (`assigned_areas`).
