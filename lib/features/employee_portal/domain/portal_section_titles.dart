/// عناوين أقسام بوابة الموظف — المصدر الوحيد الذي يقرأه السجل والرئيسية معًا
/// Employee-portal section titles — the single source read by the registry and home alike.
///
/// كانت العناوين مكتوبة داخل `portalSections` وحدها. استخراجها إلى ثوابت يسمح للواجهة الرئيسية
/// (شرائح التصفية وسطر القسم داخل البطاقة) بأن تقرأ النص نفسه بدل نسخه — والنسخ كان سينحرف
/// صامتًا عند أول إعادة تسمية.
/// The titles used to live only inside `portalSections`. Hoisting them into constants lets the home
/// screen (filter chips and the section caption on a card) read the same text instead of copying
/// it — a copy would drift silently at the first rename.
class PortalSectionTitles {
  PortalSectionTitles._();

  static const String home = 'الرئيسية';
  static const String sales = 'المبيعات';
  static const String tailoring = 'التفصيل';
  static const String customers = 'العملاء';
  static const String workers = 'جاري العاملين';
  static const String accounts = 'الحسابات';
  static const String stores = 'المخازن';
  static const String management = 'الإدارة';
  static const String services = 'الخدمات والمزودين';
  static const String settings = 'الإعدادات';

  /// عنوان القسم بمعرّفه؛ والمعرّف المجهول يعود كما هو بدل أن يرمي
  /// The title for a section id; an unknown id comes back unchanged instead of throwing.
  static String of(String id) {
    switch (id) {
      case 'home':
        return home;
      case 'sales':
        return sales;
      case 'tailoring':
        return tailoring;
      case 'customers':
        return customers;
      case 'workers':
        return workers;
      case 'accounts':
        return accounts;
      case 'stores':
        return stores;
      case 'management':
        return management;
      case 'services':
        return services;
      case 'settings':
        return settings;
      default:
        return id;
    }
  }
}
