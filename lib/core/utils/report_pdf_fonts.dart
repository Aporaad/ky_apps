import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper shared by all report PDF builders (account statement, group trial balance,
/// customer statement, worker statement).
///
/// `printing`'s [PdfGoogleFonts] already persists the downloaded TTF in its own
/// on-disk cache (`PdfBaseCache`), so "load once, reuse" only needs to avoid
/// re-issuing the same resolution Future on every print/export tap within the
/// same app run — hence the static cached Futures below rather than a
/// hand-rolled `Uint8List` cache. The `printing` bundle includes this exact
/// Cairo variant lookup (cairoRegular/cairoBold) that matches the app's on-screen
/// GoogleFonts Cairo theme, so the exported PDF shaping/ligatures match what the
/// user sees.
///
/// يُستخدم من كل مولّدات PDF — يحمّل خط Cairo مرة واحدة ويخزّنه.
class ReportPdfFonts {
  ReportPdfFonts._();

  static Future<pw.Font>? _regular;
  static Future<pw.Font>? _bold;

  static Future<pw.Font> get regular => _regular ??= PdfGoogleFonts.cairoRegular();

  static Future<pw.Font> get bold => _bold ??= PdfGoogleFonts.cairoBold();

  /// يبني `pw.ThemeData` مع خط Cairo عادي وعريض — يُستخدم كـ `Document(theme: ...)`
  /// لضمان تشكيل العربية بشكل صحيح في كل التقارير بدون fallback لـ Helvetica.
  static Future<pw.ThemeData> theme() async {
    return pw.ThemeData.withFont(
      base: await regular,
      bold: await bold,
      italic: await regular,
      boldItalic: await bold,
    );
  }
}
