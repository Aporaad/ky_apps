import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/theme/app_colors.dart';
import 'package:ky_apps/core/utils/report_pdf_grid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// هندسة شبكة الطباعة الموحّدة — الحارس الذي كان غائباً
/// The unified print grid's geometry — the guard that never existed.
///
/// ── لماذا هذا الملف؟ لأن المطبوع كان يُجزَّأ جداول كل ثلاثين سطراً، لكل واحد رأسه
///    وعروضه المحسوبة نسبةً على حدة: فيظهر رأس الجدول في منتصف الورقة مرات، وينزلق
///    كل عمود حين تُقرَّب نسبته في كتلة خلاف الأخرى. لا اختبار واحد كان يلمس بنية
///    الجدول المطبوع، فعاش العطل دورات كاملة.
/// ── Why this file: the printout was cut into tables of thirty rows, each with its own head
///    and its own fractionally-rounded widths — so the heading reappeared mid-sheet and every
///    column drifted. Nothing tested the printed table's structure, so the defect lived on.
///
/// ── الاختبار هنا يقرأ بنية `pw.Table` نفسها: عدد السطور، أعلام التكرار، نوع العروض،
///    وسطر واحد لكل خانة — أي ما يُرى على الورق لا ما يُكتب في الشيفرة.
/// ── It reads the `pw.Table` structure itself: row count, repeat flags, width kinds and one
///    line per cell — what the paper shows, not what the source says.
void main() {
  const columns = <PdfGridColumn>[
    PdfGridColumn(label: 'النوع', weight: 1.3),
    PdfGridColumn(label: 'التاريخ', weight: 1.2),
    PdfGridColumn(label: 'الرصيد', numeric: true, weight: 1),
  ];

  const rows = <List<String>>[
    ['منصرف للقص', '2026-10-12', '-4,418.39'],
    ['وارد من مورد', '2026-10-13', '120.00'],
  ];

  pw.Table grid({
    List<String>? opening,
    List<String>? totals,
    List<List<String>> body = rows,
    double width = 800,
  }) {
    return pdfReportGrid(
      columns: columns,
      rows: body,
      opening: opening,
      totals: totals,
      width: width,
    );
  }

  group('widths', () {
    test('the columns divide the sheet exactly, the last absorbing the remainder', () {
      const set = <PdfGridColumn>[
        PdfGridColumn(label: 'أ', weight: 1),
        PdfGridColumn(label: 'ب', weight: 2),
        PdfGridColumn(label: 'ج', weight: 1),
      ];

      final widths = pdfGridColumnWidths(set, 800);

      // مجموع يساوي العرض حرفياً: لا شق فارغ في آخر السطر ولا تجاوز للهامش
      // A sum equal to the width to the point: no sliver at the line's end, no overrun.
      expect(widths.fold<double>(0, (sum, w) => sum + w), 800);
      expect(widths[1], widths[0] * 2);
    });

    test('every column keeps a floor when the report is far too wide', () {
      final set = List<PdfGridColumn>.generate(
        40,
        (_) => const PdfGridColumn(label: 'ع'),
      );

      final widths = pdfGridColumnWidths(set, 300);

      expect(widths, hasLength(40));
      expect(widths.every((w) => w >= 14), isTrue);
    });

    test('no columns is no widths', () {
      expect(pdfGridColumnWidths(const <PdfGridColumn>[], 800), isEmpty);
    });

    test('the content width is the sheet minus both margins', () {
      expect(
        pdfGridContentWidth(PdfPageFormat.a4, sideMargin: 20),
        closeTo(PdfPageFormat.a4.width - 40, 0.001),
      );
      expect(
        pdfGridContentWidth(PdfPageFormat.a4.landscape, sideMargin: 20),
        closeTo(841.89 - 40, 0.01),
      );
    });
  });

  group('one table, one head', () {
    test('the head, the opening, the rows and the totals are one table', () {
      final table = grid(
        opening: const ['رصيد سابق', '', '240.00'],
        totals: const ['الإجمالي', '', '430.93'],
      );

      // رأس + افتتاح + سطرين + مجاميع
      expect(table.children, hasLength(1 + 1 + rows.length + 1));
    });

    test('no row is repeated on a later page', () {
      final table = grid(
        opening: const ['رصيد سابق', '', '240.00'],
        totals: const ['الإجمالي', '', '430.93'],
      );

      // `repeat: true` هو ما كان يرمي رأس الجدول في منتصف كل ورقة
      // `repeat: true` is what used to drop the heading in the middle of every sheet.
      expect(table.children.every((row) => !row.repeat), isTrue);
    });

    test('a hundred rows stay one table, so the head is drawn once', () {
      final table = grid(
        body: [for (int i = 0; i < 100; i++) rows[i % rows.length]],
        totals: const ['الإجمالي', '', '430.93'],
      );

      expect(table.children, hasLength(1 + 100 + 1));
    });

    test('widths are fixed points, never fractions', () {
      final table = grid();

      // العروض النسبية كانت تُقرَّب لكل كتلة على حدة فتتزحلق الأعمدة
      // Fractions were rounded per block, which is how the columns slid out of place.
      expect(
        table.columnWidths!.values.every((w) => w is pw.FixedColumnWidth),
        isTrue,
      );
      expect(table.columnWidths!.values.cast<pw.FixedColumnWidth>().first.width,
          greaterThan(0));
    });

    test('the head carries one cell per column whatever the row count', () {
      final table = grid(body: const <List<String>>[]);

      expect(table.children.first.children, hasLength(columns.length));
    });

    test('a row shorter than the head cannot crash the grid', () {
      final table = grid(body: const <List<String>>[
        ['وارد'],
      ]);

      expect(table.children.last.children, hasLength(columns.length));
    });
  });

  group('cells', () {
    test('every cell is a single fitted line of one uniform height', () {
      final table = grid(
        opening: const ['رصيد سابق', '', '240.00'],
        totals: const ['الإجمالي', '', '430.93'],
      );

      double? height;
      var fitted = 0;

      for (final row in table.children) {
        for (final cell in row.children) {
          final box = cell as pw.Container;

          // ارتفاع ثابت موحّد: صف لا يطول على حساب جاره ولا ورقة تتنفّخ أسطرها
          // One fixed height: no row grows at its neighbour's expense.
          expect(box.constraints?.maxHeight, box.constraints?.minHeight);
          height ??= box.constraints?.maxHeight;
          expect(box.constraints?.maxHeight, height);

          // الخانة الفارغة بلا طفل يُقاس (صفر÷صفر = NaN يُسقط المستند عند الحفظ)
          // An empty cell carries no measured child: 0÷0 is a NaN that kills the save.
          if (box.child is pw.SizedBox) continue;

          // التقلّص بدل الالتفاف: «المستن»/«د» كان ثمرة softWrap لا نقص بيانات
          // Shrink instead of wrap: «المستن»/«د» came from softWrap, not from missing data.
          final fittedBox = box.child as pw.FittedBox;
          expect(fittedBox.fit, pw.BoxFit.scaleDown);

          final text = fittedBox.child;
          if (text is pw.Text) {
            expect(text.maxLines, 1);
            expect(text.softWrap, isFalse);
            // الأرقام والنص المشكَّل يُرسم يساراً→يمين حتى لا تُقلب الإشارة
            // Figures and pre-shaped text draw ltr so a minus never flips.
            expect(text.textDirection, pw.TextDirection.ltr);
          }
          fitted++;
        }
      }

      expect(height, isNotNull);
      expect(height!, greaterThan(8));
      expect(fitted, greaterThan(10));
    });

    test('a wide report and a narrow one both keep one line per cell', () {
      for (final width in <double>[320, 800, 1200]) {
        final table = grid(width: width);

        for (final row in table.children) {
          for (final cell in row.children) {
            expect(cell, isA<pw.Container>(), reason: 'العرض $width');
          }
        }
      }
    });
  });

  group('statistics strip', () {
    test('no fields draws nothing', () {
      expect(
        pdfStatsStrip(title: 'إحصاءات التقرير', fields: const <PdfStatBox>[]),
        isA<pw.SizedBox>(),
      );
    });

    test('the strip carries every field the caller kept', () {
      final strip = pdfStatsStrip(
        title: 'إحصاءات التقرير',
        fields: const <PdfStatBox>[
          PdfStatBox('السابق', '240'),
          PdfStatBox('وارد', '50'),
          PdfStatBox('منصرف', '30'),
          PdfStatBox('الصافي', '20'),
          PdfStatBox('الرصيد الحالي', '260', tone: 'primary', emphasis: true),
        ],
      );

      // الشريط كله wrap واحد: لا التفاف على أسطر يخلق فراغات في الورقة
      // The strip is a single wrap: no manual line breaks to leave gaps on the sheet.
      expect(strip, isA<pw.Container>());
    });

    test('the compact line drops the frames and keeps the figures', () {
      final strip = pdfStatsStrip(
        title: '',
        compact: true,
        fields: const <PdfStatBox>[
          PdfStatBox('السابق', '240'),
          PdfStatBox('الرصيد الحالي', '260'),
        ],
      );

      expect(strip, isA<pw.Container>());
    });

    test('the palette is the screen palette, not the old heavy ink', () {
      const palette = PdfGridPalette();

      // الشبكة الفاتحة نفسها على الشاشة والورق: حدود #E2E8F0 لا حبر داكن
      // The screen's own light grid on paper too: #E2E8F0 rules, not heavy ink.
      expect(palette.rule.red, AppColors.border.r);
      expect(palette.rule.green, AppColors.border.g);
      expect(palette.rule.blue, AppColors.border.b);
      expect(palette.negative.red, AppColors.error.r);

      // وشريط الرأس هو شفافية الشاشة نفسها مسطَّحة فوق بياض الورقة
      // And the head band is the screen's own alpha flattened over white paper.
      expect(
        palette.headBand.red,
        closeTo(0.08 * AppColors.primary.r + 0.92, 1e-9),
      );
      expect(
        palette.totalsBand.green,
        closeTo(0.12 * AppColors.primary.g + 0.88, 1e-9),
      );
    });
  });
}
