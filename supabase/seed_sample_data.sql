-- ════════════════════════════════════════════════════════════════════════════
-- seed_sample_data.sql — بيانات تجريبية واقعية لاختبار الشاشات
-- آمنة لإعادة التشغيل: جداول بلا مفتاح فريد محميّة بـ DO/IF، والبقية ON CONFLICT.
-- تُنفَّذ بصلاحية الخدمة (تتجاوز RLS). ملاحظة: قراءة العائلات/المشتركين من التطبيق
-- تتطلّب مستخدماً staff (سياسة is_staff)، أما الأعمال فمتاحة لأي مستخدم مسجّل.
-- ════════════════════════════════════════════════════════════════════════════

-- ── families ────────────────────────────────────────────────────────────────
do $$ begin if (select count(*) from public.families) = 0 then
  insert into public.families (head_name, members_count, marital_status, income_level, address, governorate, area, status, phone, aid_count, total_aid_amount, delegate_name, registration_date) values
  ('أبو علي الحسيني',6,'married','veryLow','حي الشعب','بغداد','الشعب','eligible','07701111111',8,450000,'أحمد محمد الكريمي','2026-01-10'),
  ('أم كرار العبودي',4,'widowed','veryLow','الزعفرانية','بغداد','الزعفرانية','eligible','07702222222',12,750000,'سارة علي الموسوي','2026-01-22'),
  ('محمد كاظم الخفاجي',8,'married','low','المدينة','بغداد','المدينة','eligible',null,5,300000,'حسين رضا الجبوري','2026-02-05'),
  ('سعاد رجب التكريتي',3,'divorced','low','الكاظمية','بغداد','الكاظمية','pending',null,2,120000,'نور محمد الهاشمي','2026-02-18'),
  ('حسين علوان الموسوي',5,'married','veryLow','الدورة','بغداد','الدورة','eligible',null,7,420000,'علاء الدين فارس','2026-03-01'),
  ('فارس قاسم العزاوي',4,'married','medium','اليرموك','بغداد','اليرموك','ineligible',null,0,0,'أحمد محمد الكريمي','2026-04-08');
end if; end $$;

-- ── subscribers ─────────────────────────────────────────────────────────────
do $$ begin if (select count(*) from public.subscribers) = 0 then
  insert into public.subscribers (name, phone, address, governorate, area, status, national_id, aid_count, delegate_name, subscription_amount, overdue_months, subscription_category, registration_date) values
  ('كريم طالب الصفار','07701234567','شارع الرشيد، الكرخ','بغداد','الكرخ','active','12345678901',3,'أحمد محمد الكريمي',25000,1,'آذار','2026-01-15'),
  ('محمد عبد الرضا','07709876543','حي الجامعة، الرصافة','بغداد','الرصافة','active','98765432109',2,'أحمد محمد الكريمي',25000,3,'كانون الثاني، شباط، آذار','2026-02-20'),
  ('رنا صبحي الرامي','07701111222','المنصور','بغداد','المنصور','active','11122233344',0,'سارة علي الموسوي',25000,2,'شباط، آذار','2026-03-05'),
  ('نور خليل العزاوي','07703333444','الزعفرانية','بغداد','الزعفرانية','active',null,5,'سارة علي الموسوي',25000,3,'كانون الثاني، شباط، آذار','2026-03-18'),
  ('غيث قاسم الشمري','07705555666','حي العدل','بغداد','العدل','active',null,1,'حسين رضا الجبوري',25000,0,null,'2026-04-02'),
  ('لمياء صلاح النجار','07704567890','الغزالية','بغداد','الغزالية','inactive',null,1,'سارة علي الموسوي',25000,0,null,'2026-08-05');
end if; end $$;

-- ── work_posts ──────────────────────────────────────────────────────────────
do $$ begin if (select count(*) from public.work_posts) = 0 then
  insert into public.work_posts (author_name, author_role, title, description, category, location, tags, beneficiary_count, view_count, like_count, is_featured, is_published, published_at) values
  ('مؤسسة النور الخيرية','إدارة المؤسسة','توزيع سلال غذائية في الشعب','وزّعنا 200 سلة غذائية على العائلات المتعففة في منطقة الشعب.','food','بغداد - الشعب',array['غذاء','رمضان'],200,1200,85,true,true,'2026-03-10'),
  ('مؤسسة النور الخيرية','إدارة المؤسسة','كفالة علاج طفل','تمت تغطية تكاليف عملية جراحية لطفل من عائلة متعففة.','medical','بغداد - المدينة',array['علاج','صحة'],1,900,140,true,true,'2026-04-02'),
  ('مؤسسة النور الخيرية','إدارة المؤسسة','دعم تعليمي للطلبة','قرطاسية وحقائب مدرسية لـ 120 طالباً.','educational','بغداد - الكرخ',array['تعليم'],120,640,60,false,true,'2026-05-15'),
  ('مؤسسة النور الخيرية','إدارة المؤسسة','كسوة العيد','وزّعنا ملابس العيد على 300 طفل.','seasonal','بغداد - الرصافة',array['عيد','كسوة'],300,1500,210,false,true,'2026-06-01'),
  ('مؤسسة النور الخيرية','إدارة المؤسسة','مساعدات مالية طارئة','صرف مساعدات مالية عاجلة لـ 40 أسرة.','financial','بغداد',array['مالية'],40,430,33,false,true,'2026-07-10');
end if; end $$;

-- ── aid_records (reference_number فريد) ─────────────────────────────────────
insert into public.aid_records (reference_number, beneficiary_name, type, amount, currency, status, responsible_employee, aid_date, notes) values
  ('AID-2026-001','أبو علي الحسيني','financial',150000,'IQD','distributed','أحمد محمد','2026-01-20','مساعدة شهرية'),
  ('AID-2026-002','أم كرار العبودي','food',75000,'IQD','distributed','سارة خالد','2026-02-05',null),
  ('AID-2026-003','محمد كاظم الخفاجي','medical',200000,'IQD','approved','أحمد محمد','2026-02-18','علاج طبي عاجل'),
  ('AID-2026-004','حسين علوان الموسوي','seasonal',120000,'IQD','distributed','علي كريم','2026-03-10','مساعدة رمضان'),
  ('AID-2026-005','فاطمة علي الزهراء','financial',100000,'IQD','pending','أحمد محمد','2026-04-08',null)
on conflict (reference_number) do nothing;

-- ── help_requests (request_number فريد) ─────────────────────────────────────
insert into public.help_requests (request_number, type, status, urgency, title, description, full_name, phone, governorate, area, full_address, family_size, submitted_at, type_data) values
  ('HR-2026-001','foodBasket','pending','high','طلب سلة غذائية','أسرة من 6 أفراد بحاجة لسلة غذائية شهرية.','خالد عبد الله','07701000001','بغداد','الدورة','حي الدورة، قرب الجامع',6,'2026-07-20','{}'),
  ('HR-2026-002','treatment','underReview','critical','طلب علاج عاجل','مريض بحاجة لدواء مزمن شهري.','سميرة حسن','07701000002','بغداد','الكاظمية','الكاظمية، شارع 20',4,'2026-07-21','{}'),
  ('HR-2026-003','financial','approved','medium','طلب دعم مالي','تأخّر إيجار المنزل لشهرين.','عمار ياسر','07701000003','البصرة','المعقل','المعقل، محلة 5',5,'2026-07-22','{}'),
  ('HR-2026-004','doctorBooking','pending','low','حجز موعد طبيب','حجز موعد مع طبيب أطفال.','هدى كامل','07701000004','النجف','مركز النجف','حي السعد',3,'2026-07-24','{}')
on conflict (request_number) do nothing;

-- ── competitions (تُضاف إن لم توجد بنفس العنوان) ────────────────────────────
do $$ begin
  if not exists (select 1 from public.competitions where title = 'حفظ سورة الملك') then
    insert into public.competitions (title, description, category, reward_points, target, winner_count, starts_at, ends_at, prize_type, prize_title, is_published) values
    ('حفظ سورة الملك','احفظ سورة الملك خلال أسبوع','quran',150,7,5,now(),now()+interval '7 days','digital','شهادة حفظ',true),
    ('تحدي الصدقة اليومية','تصدّق يومياً لمدة 30 يوماً','charity',300,30,3,now(),now()+interval '30 days','physical','سلة هدايا',true);
  end if;
end $$;

-- ── donations (id فريد) ─────────────────────────────────────────────────────
insert into public.donations (id, donor, amount, currency, method, status, reference, date, notes) values
  ('TRF-000001','متبرّع كريم',250000,'IQD','zainCash','completed','ZC-000001','2026-07-01',null),
  ('TRF-000002','فاعل خير',500000,'IQD','bankTransfer','completed','BNK-000002','2026-07-05',null),
  ('TRF-000003','أم محمد',100000,'IQD','visaCard','processing','VS-000003','2026-07-18',null),
  ('TRF-000004','عبد الله',75000,'IQD','cash','completed','CSH-000004','2026-07-22',null)
on conflict (id) do nothing;
