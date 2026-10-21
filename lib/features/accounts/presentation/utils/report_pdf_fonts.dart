import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper shared by both account report PDF builders.
///
/// `printing`'s [PdfGoogleFonts] already persists the downloaded TTF in its own
/// on-disk cache (`PdfBaseCache`), so "load once, reuse" only needs to avoid
/// re-issuing the same resolution Future on every print/export tap within the
/// same app run — hence the static cached Futures below rather than a
/// hand-rolled `Uint8List` cache, which the plan called for but turns out to be
/// unnecessary now that `printing` bundles this exact Cairo variant lookup
/// (cairoRegular/cairoBold) that matches the app's on-screen GoogleFonts Cairo
/// theme, so the exported PDF shaping/ligatures match what the user sees.
class ReportPdfFonts {
  ReportPdfFonts._();

  static Future<pw.Font>? _regular;
  static Future<pw.Font>? _bold;

  static Future<pw.Font> get regular => _regular ??= PdfGoogleFonts.cairoRegular();

  static Future<pw.Font> get bold => _bold ??= PdfGoogleFonts.cairoBold();

  /// Builds a `pw.ThemeData` with the Cairo regular/bold pair already loaded —
  /// used as `Document(theme: ...)` so every `pw.Text`/`pw.Table` in both report
  /// builders renders Arabic correctly (RTL glyph shaping) without Helvetica
  /// fallback (the known-hard point for client-side Arabic PDF generation).
  static Future<pw.ThemeData> theme() async {
    return pw.ThemeData.withFont(
      base: await regular,
      bold: await bold,
      italic: await regular,
      boldItalic: await bold,
    );
  }
}
