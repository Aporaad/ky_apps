/// تفقيط المبلغ بالعربية — كتابة الرقم بالحروف كما يطبعه المستند المالي
/// Arabic amount in words (tafqeet) — writing a figure in letters, as financial documents do.
///
/// ── لماذا وحدة مشتركة في `core/utils`؟ لأن كل مستندات المخازن والفواتير والكشوف تحتاج
///    السطر نفسه («ثلاثمائة وثلاثة ألف ومائة ﷼ يمني») تحت خانة الصافي، ولو كُتب في كل
///    شاشة لصارت الصيغ مختلفة بين شاشة وأخرى ولما أمضى المستخدم مراجعته مع الطبعة.
/// ── Why one shared unit in core/utils: every stock document, invoice and statement prints the
///    same line under the net figure. Written per screen, the wording would drift between
///    screens and the user could never match a printout against another document.
///
/// ── القاعدة المستعملة هنا هي ما يطبعه النظام المكتبي فعلاً: تجزئة الرقم إلى مئات ثم
///    «ألف» ثم «مليون»، والوصل بـ«و» بين القطع. لا يدّعي هذا الملف أنه المرجع الشرعي
///    للتفقيط، بل يطابق ما تخرج الطبعة الحالية.
/// ── The rule used here is what the desktop document actually prints: split into hundreds,
///    then "thousand", then "million", joined with "و". This does not claim to be the legal
///    authority on tafqeet — it matches the printout in front of the user.
class ArabicNumberWords {
  ArabicNumberWords._();

  static const List<String> _ones = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
  ];

  static const List<String> _teens = [
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const List<String> _tens = [
    '',
    '',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  static const List<String> _hundreds = [
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// تفقيط مبلغ كامل مع العملة: 303100 → «ثلاثمائة وثلاثة ألف ومائة ﷼ يمني»
  /// Spell a whole amount with its currency: 303100 → "ثلاثمائة وثلاثة ألف ومائة ﷼ يمني".
  ///
  /// الكسور تُدار بوحدة فرعية (هللة/فلس) إن وُجدت، وتُحذف عند الانعدام — لأن طباعة
  /// «وصفر» بعد المبلغ توهم القارئ أن هناك كسراً لم يُلحظ.
  /// A fraction is appended as a minor unit when present; "and zero" is never printed, since it
  /// would make the reader look for a fraction that is not there.
  static String amount(
    double value, {
    String currency = '﷼ يمني',
    String minorUnit = 'هللة',
  }) {
    if (value.isNaN || value.isInfinite) return '—';

    if (value < 0) {
      return '${amount(-value, currency: currency, minorUnit: minorUnit)} فقط لا غير (سالب)';
    }

    // الكسر يُؤخذ من الأصل لا من قيمة مُقرَّبة: تقريب 100.5 إلى 101 كان يترك «مائة و واحد
    // و خمسون هللة» — أي مبلغ أطول من نفسه بمئة هللة.
    // The fraction comes from the original, not a rounded copy: rounding 100.5 up to 101 spelled
    // "one hundred and one, and fifty fils" — an amount larger than itself.
    final whole = value.truncateToDouble().toInt();
    final fraction = ((value - whole).abs() * 100).round();

    final parts = <String>[];

    if (whole == 0) {
      parts.add('صفر');
    } else {
      parts.add(_spellWhole(whole));
    }

    final words = parts.join(' ');

    final withCurrency = currency.isEmpty ? words : '$words $currency';

    return fraction > 0
        ? '$withCurrency و ${_spellBelow1000(fraction)} $minorUnit'
        : withCurrency;
  }

  /// تفقيط رقم صحيح بلا عملة
  /// Spell a whole number without the currency label.
  static String number(int value) => value == 0 ? 'صفر' : _spellWhole(value);

  // ── التفكيك إلى مجموعات: ملايين → آلاف → بقايا / splitting into groups ────────
  static String _spellWhole(int value) {
    final groups = <(int, String)>[
      (1000000, 'مليون'),
      (1000, 'ألف'),
      (1, ''),
    ];

    final pieces = <String>[];
    var rest = value;

    for (final (unit, label) in groups) {
      if (unit == 1) {
        final tail = _spellBelow1000(rest);
        if (tail.isNotEmpty) pieces.add(tail);
        break;
      }

      final count = rest ~/ unit;
      rest = rest % unit;

      if (count == 0) continue;

      pieces.add(_groupWord(count, label));
    }

    return pieces.where((piece) => piece.isNotEmpty).join(' و ');
  }

  /// صياغة مجموعة: 1 ألف · 2 ألفان · 3-10 آلاف · 11+ ألف
  /// Group wording: dual and plural forms, which is where a naive spelling reads wrong.
  static String _groupWord(int count, String label) {
    if (count == 1) return label;
    if (count == 2) return label == 'مليون' ? 'مليونان' : 'ألفان';

    if (count >= 3 && count <= 10) {
      // 3-10 تطلب الجمع: «ثلاثة آلاف» لا «ثلاثة ألف»
      // Three to ten take the plural: "three thousands", not "three thousand".
      final plural = label == 'مليون' ? 'ملايين' : 'آلاف';

      return '${_spellBelow1000(count)} $plural';
    }

    return '${_spellBelow1000(count)} $label';
  }

  /// تفقيط ما دون الألف (0..999) بترتيب: المئات ثم العشرات ثم الآحاد
  /// Spell below one thousand: hundreds, then tens, then ones.
  static String _spellBelow1000(int value) {
    if (value <= 0 || value > 999) return '';

    final hundreds = value ~/ 100;
    final remainder = value % 100;

    final parts = <String>[];

    if (hundreds > 0) parts.add(_hundreds[hundreds]);

    if (remainder > 0) {
      if (remainder < 10) {
        parts.add(_ones[remainder]);
      } else if (remainder < 20) {
        parts.add(_teens[remainder - 10]);
      } else {
        final unit = remainder % 10;
        final ten = remainder ~/ 10;

        // النظام المكتبي يُقدّم الآحاد على العشرات: «أحد وعشرون» لا «عشرون وأحد»
        // The desktop puts the unit before the ten: "one and twenty", not "twenty and one".
        parts.add(unit > 0 ? '${_ones[unit]} و ${_tens[ten]}' : _tens[ten]);
      }
    }

    return parts.join(' و ');
  }
}
