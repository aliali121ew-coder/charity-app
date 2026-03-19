import 'package:flutter/material.dart';

// ── Translation Maps ─────────────────────────────────────────────────────────

const Map<String, String> _ar = {
  // General
  'app_name': 'منظمة الخير',
  'app_tagline': 'إدارة متكاملة للأعمال الخيرية',
  'save': 'حفظ',
  'cancel': 'إلغاء',
  'delete': 'حذف',
  'edit': 'تعديل',
  'add': 'إضافة',
  'view': 'عرض',
  'search': 'بحث',
  'filter': 'فلتر',
  'sort': 'ترتيب',
  'export': 'تصدير',
  'print': 'طباعة',
  'close': 'إغلاق',
  'confirm': 'تأكيد',
  'yes': 'نعم',
  'no': 'لا',
  'loading': 'جاري التحميل...',
  'no_data': 'لا توجد بيانات',
  'error_occurred': 'حدث خطأ',
  'retry': 'إعادة المحاولة',
  'all': 'الكل',
  'from': 'من',
  'to': 'إلى',
  'notes': 'ملاحظات',
  'status': 'الحالة',
  'date': 'التاريخ',
  'actions': 'الإجراءات',
  'name': 'الاسم',
  'phone': 'الهاتف',
  'email': 'البريد الإلكتروني',
  'address': 'العنوان',
  'total': 'الإجمالي',

  // Auth
  'login': 'تسجيل الدخول',
  'logout': 'تسجيل الخروج',
  'username_or_email': 'اسم المستخدم أو البريد الإلكتروني',
  'password': 'كلمة المرور',
  'remember_me': 'تذكرني',
  'login_button': 'دخول',
  'welcome_back': 'مرحباً بعودتك',
  'login_subtitle': 'سجّل دخولك للوصول إلى لوحة التحكم',
  'invalid_credentials': 'بيانات الدخول غير صحيحة',
  'field_required': 'هذا الحقل مطلوب',

  // Navigation
  'dashboard': 'لوحة التحكم',
  'reports': 'التقارير',
  'subscribers': 'المشتركون',
  'families': 'الأسر',
  'aid': 'المساعدات',
  'operations_log': 'سجل العمليات',
  'settings': 'الإعدادات',
  'works': 'أعمال المؤسسة',
  'help_requests': 'طلبات المساعدة',
  'main_menu': 'القائمة الرئيسية',

  // Dashboard
  'total_subscribers': 'إجمالي المشتركين',
  'total_families': 'إجمالي الأسر',
  'total_aid': 'إجمالي المساعدات',
  'active_cases': 'الحالات النشطة',
  'monthly_amount': 'المبلغ الشهري',
  'pending_reviews': 'قيد المراجعة',
  'aid_trend': 'اتجاه المساعدات',
  'aid_by_category': 'المساعدات حسب الفئة',
  'recent_activity': 'النشاط الأخير',
  'recent_subscribers': 'المشتركون الجدد',
  'recent_aid': 'المساعدات الأخيرة',
  'quick_actions': 'إجراءات سريعة',
  'this_month': 'هذا الشهر',
  'last_month': 'الشهر الماضي',
  'vs_last_month': 'مقارنةً بالشهر الماضي',
  'overview': 'نظرة عامة',
  'monthly_comparison': 'المقارنة الشهرية',

  // Subscribers
  'add_subscriber': 'إضافة مشترك',
  'subscriber_details': 'تفاصيل المشترك',
  'subscriber_name': 'اسم المشترك',
  'national_id': 'رقم الهوية',
  'area': 'المنطقة',
  'registration_date': 'تاريخ التسجيل',
  'subscriber_status': 'حالة المشترك',
  'contact_subscriber': 'التواصل',
  'add_note': 'إضافة ملاحظة',
  'search_subscribers': 'بحث في المشتركين...',
  'filter_by_status': 'فلتر حسب الحالة',
  'filter_by_area': 'فلتر حسب المنطقة',
  'total_subscribers_count': 'إجمالي المشتركين',

  // Families
  'add_family': 'إضافة أسرة',
  'family_details': 'تفاصيل الأسرة',
  'family_head': 'رب الأسرة',
  'members_count': 'عدد الأفراد',
  'marital_status': 'الحالة الاجتماعية',
  'income_level': 'مستوى الدخل',
  'eligibility_status': 'حالة الأهلية',
  'aid_received': 'المساعدات المستلمة',
  'search_families': 'بحث في الأسر...',
  'family_members': 'أفراد الأسرة',

  // Aid
  'add_aid': 'إضافة مساعدة',
  'aid_details': 'تفاصيل المساعدة',
  'aid_type': 'نوع المساعدة',
  'aid_amount': 'قيمة المساعدة',
  'beneficiary': 'المستفيد',
  'responsible_employee': 'الموظف المسؤول',
  'reference_number': 'الرقم المرجعي',
  'aid_financial': 'مالية',
  'aid_food': 'غذائية',
  'aid_medical': 'طبية',
  'aid_seasonal': 'موسمية',
  'aid_education': 'تعليمية',
  'aid_other': 'أخرى',
  'search_aid': 'بحث في المساعدات...',
  'filter_by_type': 'فلتر حسب النوع',
  'approve_aid': 'اعتماد المساعدة',
  'distribute_aid': 'صرف المساعدة',

  // Status
  'status_active': 'نشط',
  'status_inactive': 'غير نشط',
  'status_pending': 'قيد الانتظار',
  'status_suspended': 'موقوف',
  'status_approved': 'معتمد',
  'status_rejected': 'مرفوض',
  'status_distributed': 'تم الصرف',
  'status_eligible': 'مؤهل',
  'status_ineligible': 'غير مؤهل',

  // Operations Log
  'log_add': 'إضافة',
  'log_edit': 'تعديل',
  'log_delete': 'حذف',
  'log_approve': 'اعتماد',
  'log_reject': 'رفض',
  'log_distribute': 'صرف',
  'log_login': 'تسجيل دخول',
  'log_logout': 'تسجيل خروج',
  'log_report': 'تقرير',
  'log_settings': 'إعدادات',
  'performed_by': 'بواسطة',
  'search_logs': 'بحث في السجل...',
  'filter_by_action': 'فلتر حسب الإجراء',
  'filter_by_user': 'فلتر حسب المستخدم',
  'date_range': 'نطاق التاريخ',
  'total_operations': 'إجمالي العمليات',
  'operations_today': 'عمليات اليوم',

  // Reports
  'monthly_report': 'التقرير الشهري',
  'yearly_report': 'التقرير السنوي',
  'date_range_filter': 'فلتر نطاق التاريخ',
  'export_pdf': 'تصدير PDF',
  'export_excel': 'تصدير Excel',
  'aid_distribution': 'توزيع المساعدات',
  'subscriber_growth': 'نمو المشتركين',
  'families_overview': 'نظرة عامة على الأسر',
  'financial_summary': 'الملخص المالي',

  // Settings
  'language': 'اللغة',
  'theme': 'المظهر',
  'light_mode': 'الوضع الفاتح',
  'dark_mode': 'الوضع الداكن',
  'profile_settings': 'إعدادات الملف الشخصي',
  'users_management': 'إدارة المستخدمين',
  'permissions_management': 'إدارة الصلاحيات',
  'organization_settings': 'إعدادات المنظمة',
  'notifications': 'الإشعارات',
  'app_version': 'إصدار التطبيق',
  'arabic': 'العربية',
  'english': 'الإنجليزية',

  // Misc
  'iqd': 'د.ع',
  'members': 'أفراد',
  'confirm_delete': 'تأكيد الحذف',
  'confirm_delete_msg': 'هل أنت متأكد من حذف هذا العنصر؟ لا يمكن التراجع عن هذا الإجراء.',
  'no_permission': 'ليس لديك صلاحية للوصول إلى هذه الميزة',
  'search_hint': 'بحث هنا...',
};

const Map<String, String> _en = {
  // General
  'app_name': 'Charity App',
  'app_tagline': 'Integrated Charity Management',
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'view': 'View',
  'search': 'Search',
  'filter': 'Filter',
  'sort': 'Sort',
  'export': 'Export',
  'print': 'Print',
  'close': 'Close',
  'confirm': 'Confirm',
  'yes': 'Yes',
  'no': 'No',
  'loading': 'Loading...',
  'no_data': 'No data available',
  'error_occurred': 'An error occurred',
  'retry': 'Retry',
  'all': 'All',
  'from': 'From',
  'to': 'To',
  'notes': 'Notes',
  'status': 'Status',
  'date': 'Date',
  'actions': 'Actions',
  'name': 'Name',
  'phone': 'Phone',
  'email': 'Email',
  'address': 'Address',
  'total': 'Total',

  // Auth
  'login': 'Login',
  'logout': 'Logout',
  'username_or_email': 'Username or Email',
  'password': 'Password',
  'remember_me': 'Remember me',
  'login_button': 'Sign In',
  'welcome_back': 'Welcome Back',
  'login_subtitle': 'Sign in to access the control panel',
  'invalid_credentials': 'Invalid credentials',
  'field_required': 'This field is required',

  // Navigation
  'dashboard': 'Dashboard',
  'reports': 'Reports',
  'subscribers': 'Subscribers',
  'families': 'Families',
  'aid': 'Aid',
  'operations_log': 'Operations Log',
  'settings': 'Settings',
  'works': 'Our Works',
  'help_requests': 'Help Requests',
  'main_menu': 'Main Menu',

  // Dashboard
  'total_subscribers': 'Total Subscribers',
  'total_families': 'Total Families',
  'total_aid': 'Total Aid',
  'active_cases': 'Active Cases',
  'monthly_amount': 'Monthly Amount',
  'pending_reviews': 'Pending Reviews',
  'aid_trend': 'Aid Trend',
  'aid_by_category': 'Aid by Category',
  'recent_activity': 'Recent Activity',
  'recent_subscribers': 'New Subscribers',
  'recent_aid': 'Recent Aid',
  'quick_actions': 'Quick Actions',
  'this_month': 'This Month',
  'last_month': 'Last Month',
  'vs_last_month': 'vs last month',
  'overview': 'Overview',
  'monthly_comparison': 'Monthly Comparison',

  // Subscribers
  'add_subscriber': 'Add Subscriber',
  'subscriber_details': 'Subscriber Details',
  'subscriber_name': 'Subscriber Name',
  'national_id': 'National ID',
  'area': 'Area',
  'registration_date': 'Registration Date',
  'subscriber_status': 'Subscriber Status',
  'contact_subscriber': 'Contact',
  'add_note': 'Add Note',
  'search_subscribers': 'Search subscribers...',
  'filter_by_status': 'Filter by Status',
  'filter_by_area': 'Filter by Area',
  'total_subscribers_count': 'Total Subscribers',

  // Families
  'add_family': 'Add Family',
  'family_details': 'Family Details',
  'family_head': 'Family Head',
  'members_count': 'Members Count',
  'marital_status': 'Marital Status',
  'income_level': 'Income Level',
  'eligibility_status': 'Eligibility Status',
  'aid_received': 'Aid Received',
  'search_families': 'Search families...',
  'family_members': 'Family Members',

  // Aid
  'add_aid': 'Add Aid',
  'aid_details': 'Aid Details',
  'aid_type': 'Aid Type',
  'aid_amount': 'Aid Amount',
  'beneficiary': 'Beneficiary',
  'responsible_employee': 'Responsible Employee',
  'reference_number': 'Reference Number',
  'aid_financial': 'Financial',
  'aid_food': 'Food',
  'aid_medical': 'Medical',
  'aid_seasonal': 'Seasonal',
  'aid_education': 'Education',
  'aid_other': 'Other',
  'search_aid': 'Search aid records...',
  'filter_by_type': 'Filter by Type',
  'approve_aid': 'Approve Aid',
  'distribute_aid': 'Distribute Aid',

  // Status
  'status_active': 'Active',
  'status_inactive': 'Inactive',
  'status_pending': 'Pending',
  'status_suspended': 'Suspended',
  'status_approved': 'Approved',
  'status_rejected': 'Rejected',
  'status_distributed': 'Distributed',
  'status_eligible': 'Eligible',
  'status_ineligible': 'Ineligible',

  // Operations Log
  'log_add': 'Add',
  'log_edit': 'Edit',
  'log_delete': 'Delete',
  'log_approve': 'Approve',
  'log_reject': 'Reject',
  'log_distribute': 'Distribute',
  'log_login': 'Login',
  'log_logout': 'Logout',
  'log_report': 'Report',
  'log_settings': 'Settings',
  'performed_by': 'By',
  'search_logs': 'Search logs...',
  'filter_by_action': 'Filter by Action',
  'filter_by_user': 'Filter by User',
  'date_range': 'Date Range',
  'total_operations': 'Total Operations',
  'operations_today': 'Today\'s Operations',

  // Reports
  'monthly_report': 'Monthly Report',
  'yearly_report': 'Yearly Report',
  'date_range_filter': 'Date Range Filter',
  'export_pdf': 'Export PDF',
  'export_excel': 'Export Excel',
  'aid_distribution': 'Aid Distribution',
  'subscriber_growth': 'Subscriber Growth',
  'families_overview': 'Families Overview',
  'financial_summary': 'Financial Summary',

  // Settings
  'language': 'Language',
  'theme': 'Theme',
  'light_mode': 'Light Mode',
  'dark_mode': 'Dark Mode',
  'profile_settings': 'Profile Settings',
  'users_management': 'Users Management',
  'permissions_management': 'Permissions Management',
  'organization_settings': 'Organization Settings',
  'notifications': 'Notifications',
  'app_version': 'App Version',
  'arabic': 'Arabic',
  'english': 'English',

  // Misc
  'iqd': 'IQD',
  'members': 'members',
  'confirm_delete': 'Confirm Delete',
  'confirm_delete_msg': 'Are you sure you want to delete this item? This action cannot be undone.',
  'no_permission': 'You do not have permission to access this feature',
  'search_hint': 'Search here...',
};

// ── Localizations Class ──────────────────────────────────────────────────────

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _strings =>
      locale.languageCode == 'ar' ? _ar : _en;

  String tr(String key) => _strings[key] ?? key;

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRtl => locale.languageCode == 'ar';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── BuildContext Extension ────────────────────────────────────────────────────
extension LocalizationExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).tr(key);
}
