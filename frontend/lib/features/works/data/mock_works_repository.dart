import 'package:charity_app/shared/models/work_post_model.dart';

class MockWorksRepository {
  static final List<WorkPost> _posts = [
    WorkPost(
      id: 'w1',
      title: 'توزيع السلال الغذائية الرمضانية على 300 أسرة',
      description:
          'في إطار مبادرة المؤسسة الخيرية لشهر رمضان المبارك، تم توزيع 300 سلة غذائية متكاملة تحتوي على التمر والأرز والزيت والمعلبات والمواد الأساسية على الأسر المحتاجة في مناطق مختلفة من المدينة. وقد شارك في هذه المبادرة أكثر من 50 متطوعاً من أبناء المجتمع.\n\nأُقيم الحفل بحضور عدد من الداعمين والمحسنين وممثلي الجهات الحكومية، وتضمن فعاليات متنوعة احتفالاً بهذه المناسبة الكريمة.',
      imageUrl:
          'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1488900128323-21503983a07e?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.food,
      date: DateTime(2025, 3, 15),
      location: 'الرياض - حي العزيزية',
      tags: ['رمضان', 'سلال غذائية', 'أسر محتاجة'],
      viewCount: 2840,
      likeCount: 412,
      beneficiaryCount: 300,
      isFeatured: true,
      authorName: 'أ. محمد العمري',
      authorRole: 'مدير البرامج',
      shareCount: 87,
      comments: [
        WorkComment(
          id: 'c1',
          authorName: 'أم عبدالله',
          authorRole: 'مستفيدة',
          text: 'جزاكم الله خيراً، لقد استفدت أنا وعائلتي من هذه المبادرة الكريمة. بارك الله في جهودكم.',
          date: DateTime(2025, 3, 16, 9, 30),
          likeCount: 24,
        ),
        WorkComment(
          id: 'c2',
          authorName: 'خالد الرشيدي',
          authorRole: 'متطوع',
          text: 'شرف لي المشاركة في هذا العمل الخيري الرائع. فريق العمل متميز ومنظم جداً.',
          date: DateTime(2025, 3, 15, 22, 15),
          likeCount: 18,
        ),
        WorkComment(
          id: 'c3',
          authorName: 'نورة السهلي',
          authorRole: 'داعمة',
          text: 'ما شاء الله، عمل رائع ومبارك. نتمنى لكم التوفيق والنجاح دائماً.',
          date: DateTime(2025, 3, 15, 20, 45),
          likeCount: 31,
        ),
      ],
    ),
    WorkPost(
      id: 'w2',
      title: 'قافلة طبية مجانية في المناطق النائية',
      description:
          'أطلقت المؤسسة قافلتها الطبية المجانية الشاملة التي تضم أطباء متخصصين في الباطنية والأطفال والأسنان والعيون، وقد استفاد منها أكثر من 500 مريض من سكان المناطق البعيدة عن المرافق الصحية.\n\nشارك في القافلة 18 طبيباً متخصصاً و30 ممرضاً وممرضة، وتم تقديم الفحوصات والعلاجات مجاناً مع توفير الأدوية اللازمة.',
      imageUrl:
          'https://images.unsplash.com/photo-1584515933487-779824d29309?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1584515933487-779824d29309?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.medical,
      date: DateTime(2025, 2, 20),
      location: 'منطقة عسير - قرى نائية',
      tags: ['صحة', 'أطباء', 'مجاني'],
      viewCount: 1920,
      likeCount: 356,
      beneficiaryCount: 500,
      isFeatured: true,
      authorName: 'د. سارة الحربي',
      authorRole: 'مشرفة الصحة',
      shareCount: 64,
      comments: [
        WorkComment(
          id: 'c4',
          authorName: 'سعد القحطاني',
          authorRole: 'مواطن',
          text: 'مبادرة إنسانية رائعة وضرورية لسكان المناطق النائية. الله يوفقكم.',
          date: DateTime(2025, 2, 21, 10, 0),
          likeCount: 45,
        ),
        WorkComment(
          id: 'c5',
          authorName: 'د. فاطمة العتيبي',
          authorRole: 'طبيبة متطوعة',
          text: 'كان تجربة إنسانية لا تُنسى. الرؤية في عيون المستفيدين تستحق كل شيء.',
          date: DateTime(2025, 2, 20, 18, 30),
          likeCount: 67,
        ),
      ],
    ),
    WorkPost(
      id: 'w3',
      title: 'منح الكسوة الشتوية للطلاب',
      description:
          'استقبل 200 طالب من أسر ذات دخل محدود حقائب الكسوة الشتوية التي تحتوي على ملابس دافئة عالية الجودة، بالتعاون مع عدد من الجهات الداعمة.\n\nاشتملت الكسوة على معطف دافئ وبدلة رياضية وأحذية ووسائل تدفئة متنوعة، لضمان راحة الطلاب خلال فصل الشتاء.',
      imageUrl:
          'https://images.unsplash.com/photo-1512909006721-3d6018887383?w=800&h=500&fit=crop',
      category: WorkCategory.seasonal,
      date: DateTime(2024, 12, 5),
      location: 'جدة - مدارس حكومية',
      tags: ['كسوة', 'طلاب', 'شتاء'],
      viewCount: 1450,
      likeCount: 289,
      beneficiaryCount: 200,
      authorName: 'أ. هدى المطيري',
      authorRole: 'مسؤولة التعليم',
      shareCount: 42,
      comments: [
        WorkComment(
          id: 'c6',
          authorName: 'ولي أمر',
          authorRole: 'مستفيد',
          text: 'الله يجزاكم الخير. أطفالنا سعداء جداً بهذه الكسوة الجميلة.',
          date: DateTime(2024, 12, 6, 8, 0),
          likeCount: 19,
        ),
      ],
    ),
    WorkPost(
      id: 'w4',
      title: 'منح دراسية للطلاب المتفوقين المحتاجين',
      description:
          'تكريماً للتميز وحرصاً على مسيرة الأجيال القادمة، أعلنت المؤسسة عن تخصيص 50 منحة دراسية كاملة لطلاب من الأسر ذات الإمكانيات المحدودة ممن حققوا معدلات مرتفعة في المرحلة الثانوية.\n\nتشمل المنح تكاليف الدراسة الجامعية كاملة بما فيها الرسوم والكتب والسكن وبدل المعيشة الشهري طوال مدة الدراسة.',
      imageUrl:
          'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.educational,
      date: DateTime(2025, 1, 10),
      location: 'المملكة العربية السعودية',
      tags: ['تعليم', 'منح', 'تفوق'],
      viewCount: 3200,
      likeCount: 621,
      beneficiaryCount: 50,
      isFeatured: true,
      authorName: 'أ. عبدالرحمن الدوسري',
      authorRole: 'مدير التعليم',
      shareCount: 156,
      comments: [
        WorkComment(
          id: 'c7',
          authorName: 'طالبة منتفعة',
          authorRole: 'طالبة جامعية',
          text: 'لولا هذه المنحة لما استطعت إكمال دراستي. الله يبارك في المؤسسة وداعميها الكرام.',
          date: DateTime(2025, 1, 11, 14, 20),
          likeCount: 89,
        ),
        WorkComment(
          id: 'c8',
          authorName: 'أستاذ جامعي',
          authorRole: 'أكاديمي',
          text: 'مبادرات كهذه هي التي تبني مستقبل الأمة. شكراً لكم على الاهتمام بالتعليم.',
          date: DateTime(2025, 1, 10, 20, 0),
          likeCount: 54,
        ),
        WorkComment(
          id: 'c9',
          authorName: 'ريم العنزي',
          authorRole: 'ولية أمر',
          text: 'ابنتي من المستفيدين وهي متفوقة بامتياز. جزاكم الله كل خير.',
          date: DateTime(2025, 1, 10, 16, 45),
          likeCount: 37,
        ),
      ],
    ),
    WorkPost(
      id: 'w5',
      title: 'إفطار الصائمين - 5000 وجبة يومياً',
      description:
          'أقامت المؤسسة مائدة إفطار رمضانية مفتوحة على مدار شهر رمضان الكريم، حيث وُزِّعت ما يزيد على 5000 وجبة يومياً لفئات متعددة من العمال والمسافرين والمحتاجين.\n\nشارك في تنظيم وتحضير الوجبات أكثر من 100 متطوع يومياً، وتم إعداد الوجبات في مطابخ مجهزة بالكامل لضمان الجودة والنظافة.',
      imageUrl:
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.events,
      date: DateTime(2025, 3, 1),
      location: 'مكة المكرمة',
      tags: ['رمضان', 'إفطار', 'خير'],
      viewCount: 5600,
      likeCount: 980,
      beneficiaryCount: 5000,
      isFeatured: true,
      authorName: 'أ. يوسف الشمري',
      authorRole: 'منسق الفعاليات',
      shareCount: 234,
      comments: [
        WorkComment(
          id: 'c10',
          authorName: 'عامل غير سعودي',
          authorRole: 'مستفيد',
          text: 'الله يجزاكم الجنة. في هذه البلاد الطيبة وجدنا الكرم الحقيقي.',
          date: DateTime(2025, 3, 2, 8, 30),
          likeCount: 142,
        ),
        WorkComment(
          id: 'c11',
          authorName: 'متطوع',
          authorRole: 'متطوع',
          text: 'تجربة روحية رائعة. العمل هنا يملأ القلب فرحاً وامتناناً.',
          date: DateTime(2025, 3, 1, 21, 0),
          likeCount: 76,
        ),
      ],
    ),
    WorkPost(
      id: 'w6',
      title: 'توزيع أضاحي عيد الأضحى المبارك',
      description:
          'وفاءً بسنة إبراهيم عليه السلام، نظّمت المؤسسة مشروع الأضاحي السنوي وتم توزيع أكثر من 400 أضحية على الأسر الفقيرة داخل المملكة وعدد من الدول الإسلامية المجاورة.\n\nتم تذبيح الأضاحي وتعبئتها وتبريدها وفق أعلى معايير الجودة والنظافة، ثم توزيعها على الأسر المسجلة في قاعدة بيانات المؤسسة.',
      imageUrl:
          'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=800&h=500&fit=crop',
      category: WorkCategory.seasonal,
      date: DateTime(2024, 6, 17),
      location: 'المملكة العربية السعودية وخارجها',
      tags: ['أضاحي', 'عيد الأضحى', 'لحوم'],
      viewCount: 4100,
      likeCount: 750,
      beneficiaryCount: 1600,
      isFeatured: true,
      authorName: 'أ. إبراهيم النجدي',
      authorRole: 'مشرف المشاريع',
      shareCount: 189,
      comments: [
        WorkComment(
          id: 'c12',
          authorName: 'أم فيصل',
          authorRole: 'مستفيدة',
          text: 'ما أجمل أن تتذكرونا في أيام الأعياد. بارك الله فيكم وفي داعميكم.',
          date: DateTime(2024, 6, 18, 9, 0),
          likeCount: 55,
        ),
      ],
    ),
    WorkPost(
      id: 'w7',
      title: 'مشروع بناء مسكن لأسرة بلا مأوى',
      description:
          'ضمن مبادرة "بيت لكل أسرة"، تم الانتهاء من بناء وتسليم وحدة سكنية متكاملة لأسرة كانت تعيش في ظروف قاسية، وذلك بفضل تبرعات المحسنين وجهود المتطوعين.\n\nتتضمن الوحدة السكنية غرفتين وصالة ومطبخاً ودورتي مياه، وتم تجهيزها بالكامل بالأثاث والمعدات اللازمة قبل التسليم.',
      imageUrl:
          'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800&h=500&fit=crop',
      category: WorkCategory.financial,
      date: DateTime(2024, 11, 20),
      location: 'الدمام - حي الفيصلية',
      tags: ['مسكن', 'بناء', 'مشاريع'],
      viewCount: 2700,
      likeCount: 543,
      beneficiaryCount: 6,
      authorName: 'م. أحمد الزهراني',
      authorRole: 'مشرف الإنشاءات',
      shareCount: 98,
      comments: [
        WorkComment(
          id: 'c13',
          authorName: 'رب الأسرة المستفيدة',
          authorRole: 'مستفيد',
          text: 'والله ما تقدر الكلمات تعبر عن شكري. ربنا يكرمكم ويجزاكم خير الجزاء.',
          date: DateTime(2024, 11, 21, 11, 0),
          likeCount: 201,
        ),
        WorkComment(
          id: 'c14',
          authorName: 'جار المستفيد',
          authorRole: 'مواطن',
          text: 'رأيت بأم عيني كيف تغير حال هذه الأسرة بعد هذا المشروع. الله يبارك.',
          date: DateTime(2024, 11, 20, 19, 30),
          likeCount: 87,
        ),
      ],
    ),
    WorkPost(
      id: 'w8',
      title: 'توزيع الحقيبة المدرسية على طلاب الصف الأول',
      description:
          'في مطلع العام الدراسي الجديد، وزّعت المؤسسة 350 حقيبة مدرسية متكاملة تحتوي على الكتب والأدوات والمستلزمات اللازمة لطلاب أسر ذات دخل محدود لضمان تعليم أبنائهم دون عبء مادي.',
      imageUrl:
          'https://images.unsplash.com/photo-1588072432836-e10032774350?w=800&h=500&fit=crop',
      category: WorkCategory.educational,
      date: DateTime(2024, 9, 1),
      location: 'الرياض - مدارس ابتدائية',
      tags: ['مدرسة', 'حقيبة', 'طلاب'],
      viewCount: 1850,
      likeCount: 317,
      beneficiaryCount: 350,
      authorName: 'أ. هدى المطيري',
      authorRole: 'مسؤولة التعليم',
      shareCount: 53,
      comments: [
        WorkComment(
          id: 'c15',
          authorName: 'مدير مدرسة',
          authorRole: 'تربوي',
          text: 'نشكر المؤسسة على هذا التعاون الرائع. طلابنا يستحقون كل الدعم.',
          date: DateTime(2024, 9, 2, 9, 0),
          likeCount: 28,
        ),
      ],
    ),
    WorkPost(
      id: 'w9',
      title: 'كفالة 120 يتيماً في عيد الفطر السعيد',
      description:
          'احتفاءً بعيد الفطر المبارك، نظّمت المؤسسة احتفالية خاصة للأيتام تضمنت توزيع ملابس العيد والهدايا وإقامة فعاليات ترفيهية تفاعلية وتوفير وجبات احتفالية لـ 120 طفلاً يتيماً.',
      imageUrl:
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1527525443983-6e60c75fff46?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.events,
      date: DateTime(2025, 3, 30),
      location: 'جدة - دور رعاية الأيتام',
      tags: ['أيتام', 'عيد الفطر', 'كفالة'],
      viewCount: 3400,
      likeCount: 689,
      beneficiaryCount: 120,
      isFeatured: true,
      authorName: 'أ. يوسف الشمري',
      authorRole: 'منسق الفعاليات',
      shareCount: 167,
      comments: [
        WorkComment(
          id: 'c16',
          authorName: 'مشرفة دار الأيتام',
          authorRole: 'إدارية',
          text: 'الأطفال لا يزالون يتحدثون عن هذا اليوم الجميل. شكراً من القلب.',
          date: DateTime(2025, 3, 31, 10, 0),
          likeCount: 134,
        ),
        WorkComment(
          id: 'c17',
          authorName: 'متطوعة',
          authorRole: 'متطوعة',
          text: 'ابتسامات الأطفال أغنى من أي شيء في الدنيا. شرف لنا الخدمة هنا.',
          date: DateTime(2025, 3, 30, 20, 0),
          likeCount: 98,
        ),
      ],
    ),
    WorkPost(
      id: 'w10',
      title: 'حملة التبرع بالدم "أنقذ حياة"',
      description:
          'بالتعاون مع المستشفيات وبنك الدم الوطني، أطلقت المؤسسة حملة تطوعية للتبرع بالدم شارك فيها 280 متبرعاً خلال يومين متتاليين، مما أسهم في تغطية احتياجات مرضى العمليات الجراحية.',
      imageUrl:
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=800&h=500&fit=crop',
      category: WorkCategory.medical,
      date: DateTime(2024, 10, 14),
      location: 'الرياض - مستشفى الملك فهد',
      tags: ['دم', 'تبرع', 'صحة'],
      viewCount: 1600,
      likeCount: 298,
      beneficiaryCount: 280,
      authorName: 'د. سارة الحربي',
      authorRole: 'مشرفة الصحة',
      shareCount: 76,
      comments: [
        WorkComment(
          id: 'c18',
          authorName: 'متبرع',
          authorRole: 'متطوع',
          text: 'تجربة إنسانية لا تعوض. أنصح الجميع بالتبرع بالدم، قد ينقذ حياة شخص.',
          date: DateTime(2024, 10, 15, 12, 0),
          likeCount: 43,
        ),
      ],
    ),
    WorkPost(
      id: 'w11',
      title: 'مشروع حفر بئر مياه في إثيوبيا',
      description:
          'امتداداً لمساعي المؤسسة في العمل الخيري خارج الحدود، تم الانتهاء من حفر وتجهيز بئر مياه صالحة للشرب في منطقة نائية بإثيوبيا، ستستفيد منها أكثر من 2000 نسمة من سكان القرية.\n\nالبئر مجهزة بمضخة كهربائية تعمل بالطاقة الشمسية وخزان للمياه وشبكة توزيع تصل إلى المنازل والحقول المجاورة.',
      imageUrl:
          'https://images.unsplash.com/photo-1504198458649-3128b932f49e?w=800&h=500&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1504198458649-3128b932f49e?w=800&h=500&fit=crop',
        'https://images.unsplash.com/photo-1541252260730-0412e8e2108e?w=800&h=500&fit=crop',
      ],
      category: WorkCategory.general,
      date: DateTime(2024, 8, 5),
      location: 'إثيوبيا - منطقة أوروميا',
      tags: ['مياه', 'بئر', 'إفريقيا'],
      viewCount: 4800,
      likeCount: 912,
      beneficiaryCount: 2000,
      isFeatured: true,
      authorName: 'أ. محمد العمري',
      authorRole: 'مدير البرامج',
      shareCount: 245,
      comments: [
        WorkComment(
          id: 'c19',
          authorName: 'متبرع كريم',
          authorRole: 'داعم',
          text: 'صدقة جارية تبقى بإذن الله. شكراً للمؤسسة على إيصال التبرعات لمن يستحق.',
          date: DateTime(2024, 8, 6, 8, 0),
          likeCount: 178,
        ),
        WorkComment(
          id: 'c20',
          authorName: 'ناشط إنساني',
          authorRole: 'منظمة دولية',
          text: 'رأينا هذا المشروع بأم أعيننا. الأثر على المجتمع المحلي عظيم جداً.',
          date: DateTime(2024, 8, 5, 16, 0),
          likeCount: 94,
        ),
      ],
    ),
    WorkPost(
      id: 'w12',
      title: 'دعم الأسر المتضررة من الفيضانات',
      description:
          'استجابةً السريعة لموجة الفيضانات التي ضربت عدداً من المناطق، سارعت المؤسسة إلى تقديم مساعدات عاجلة تشمل الغذاء والملبس وأدوات الإيواء المؤقت لأكثر من 80 أسرة منكوبة.',
      imageUrl:
          'https://images.unsplash.com/photo-1532629345422-7515f3d16bb6?w=800&h=500&fit=crop',
      category: WorkCategory.financial,
      date: DateTime(2024, 7, 22),
      location: 'المنطقة الغربية',
      tags: ['طوارئ', 'فيضانات', 'إغاثة'],
      viewCount: 3100,
      likeCount: 587,
      beneficiaryCount: 80,
      authorName: 'أ. عبدالرحمن الدوسري',
      authorRole: 'مدير التعليم',
      shareCount: 134,
      comments: [
        WorkComment(
          id: 'c21',
          authorName: 'متضرر من الفيضانات',
          authorRole: 'مستفيد',
          text: 'في أصعب اللحظات وجدنا أيديكم الكريمة. لن ننسى هذا أبداً.',
          date: DateTime(2024, 7, 23, 9, 30),
          likeCount: 167,
        ),
      ],
    ),
    WorkPost(
      id: 'w13',
      title: 'برنامج تحفيظ القرآن الكريم الصيفي',
      description:
          'في إطار دعم التعليم الديني، أطلقت المؤسسة برنامجاً صيفياً مكثفاً لتحفيظ القرآن الكريم في عدد من المساجد، استفاد منه 180 طالباً في مختلف الأعمار وأتمّ 30 منهم حفظ القرآن كاملاً.',
      imageUrl:
          'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=800&h=500&fit=crop',
      category: WorkCategory.educational,
      date: DateTime(2024, 7, 1),
      location: 'الرياض - مساجد الحي',
      tags: ['قرآن', 'حفظ', 'أطفال'],
      viewCount: 2200,
      likeCount: 445,
      beneficiaryCount: 180,
      authorName: 'أ. هدى المطيري',
      authorRole: 'مسؤولة التعليم',
      shareCount: 89,
      comments: [
        WorkComment(
          id: 'c22',
          authorName: 'والد حافظ',
          authorRole: 'مستفيد',
          text: 'ابني أتم حفظ القرآن هذا الصيف. أسعد لحظات حياتي. جزاكم الله خيراً.',
          date: DateTime(2024, 7, 2, 10, 0),
          likeCount: 212,
        ),
      ],
    ),
    WorkPost(
      id: 'w14',
      title: 'زيارة دار رعاية المسنين والترفيه عنهم',
      description:
          'في رحلة إنسانية مؤثرة، زار فريق من متطوعي المؤسسة دار رعاية المسنين، وأقاموا فعاليات ترفيهية وقدّموا الهدايا وأمضوا وقتاً طيباً برفقة ساكني الدار بهدف إدخال البهجة على قلوبهم.',
      imageUrl:
          'https://images.unsplash.com/photo-1586105449197-e36b5ac3e4b7?w=800&h=500&fit=crop',
      category: WorkCategory.events,
      date: DateTime(2024, 11, 3),
      location: 'المدينة المنورة',
      tags: ['مسنين', 'رعاية', 'تطوع'],
      viewCount: 1780,
      likeCount: 362,
      beneficiaryCount: 65,
      authorName: 'أ. يوسف الشمري',
      authorRole: 'منسق الفعاليات',
      shareCount: 67,
      comments: [
        WorkComment(
          id: 'c23',
          authorName: 'مسن مقيم',
          authorRole: 'مستفيد',
          text: 'يوم لا يُنسى. شعرت أن الجيل الجديد لم ينسَنا. شكراً لكم يا أبنائي.',
          date: DateTime(2024, 11, 4, 8, 0),
          likeCount: 145,
        ),
      ],
    ),
    WorkPost(
      id: 'w15',
      title: 'تمويل مشاريع صغيرة لرب الأسرة',
      description:
          'ضمن برنامج التمكين الاقتصادي، منحت المؤسسة قروضاً بدون فوائد وتمويلاً مباشراً لـ 25 شاباً من أرباب الأسر لمساعدتهم على إطلاق مشاريعهم الصغيرة والتحرر من الاعتماد على المساعدات.',
      imageUrl:
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&h=500&fit=crop',
      category: WorkCategory.financial,
      date: DateTime(2024, 5, 15),
      location: 'الرياض - جدة - الدمام',
      tags: ['مشاريع', 'تمكين', 'أسر'],
      viewCount: 2550,
      likeCount: 478,
      beneficiaryCount: 25,
      authorName: 'أ. إبراهيم النجدي',
      authorRole: 'مشرف المشاريع',
      shareCount: 112,
      comments: [
        WorkComment(
          id: 'c24',
          authorName: 'صاحب مشروع',
          authorRole: 'مستفيد',
          text: 'بفضل دعم المؤسسة فتحت مطعماً صغيراً وأرزقت منه عائلتي. لن أنسى هذا الجميل.',
          date: DateTime(2024, 5, 16, 11, 0),
          likeCount: 89,
        ),
        WorkComment(
          id: 'c25',
          authorName: 'اقتصادي',
          authorRole: 'خبير',
          text: 'هذا هو النهج الصحيح في العمل الخيري: تمكين المستفيد لا مجرد الإعانة.',
          date: DateTime(2024, 5, 15, 18, 0),
          likeCount: 67,
        ),
      ],
    ),
  ];

  List<WorkPost> getAll() => List.from(_posts);

  List<WorkPost> getByCategory(WorkCategory category) {
    if (category == WorkCategory.all) return getAll();
    return _posts.where((p) => p.category == category).toList();
  }

  List<WorkPost> search(String query) {
    if (query.isEmpty) return getAll();
    final q = query.toLowerCase();
    return _posts
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  List<WorkPost> getFeatured() => _posts.where((p) => p.isFeatured).toList();

  WorkPost? getById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<WorkCategory, int> getCategoryCounts() {
    final Map<WorkCategory, int> counts = {};
    for (final cat in WorkCategory.values) {
      if (cat == WorkCategory.all) continue;
      counts[cat] = _posts.where((p) => p.category == cat).length;
    }
    return counts;
  }

  int get totalBeneficiaries =>
      _posts.fold(0, (sum, p) => sum + p.beneficiaryCount);

  int get totalPosts => _posts.length;

  int get totalViews => _posts.fold(0, (sum, p) => sum + p.viewCount);

  int get monthlyPosts {
    final now = DateTime.now();
    return _posts
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .length;
  }

  // ── Mutable Actions ────────────────────────────────────────────────────────
  void toggleLike(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    post.isLiked = !post.isLiked;
    post.likeCount = post.isLiked ? post.likeCount + 1 : post.likeCount - 1;
  }

  void toggleSave(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].isSaved = !_posts[idx].isSaved;
  }

  void addComment(String postId, WorkComment comment) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].comments.insert(0, comment);
  }

  void addPost(WorkPost post) {
    _posts.insert(0, post);
  }
}
