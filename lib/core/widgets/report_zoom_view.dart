import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// غلاف موحَّد لكل شاشات التقارير يضيف التكبير والتصغير.
/// Shared zoom shell for every report screen.
///
/// كان كل تقرير يلفّ محتواه بـ `InteractiveViewer` مجرّد: يعمل بالقرص/الإصبعين
/// فقط، بلا نسبة ظاهرة وبلا أزرار — فيتعذّر التكبير على الحاسب أو عند تعطّل
/// اللمس المتعدد. هنا مصفوفة تحويل واحدة تقودها الأزرار والإيماءات معاً، فتبقى
/// النسبة المعروضة مطابقة للواقع دائماً.
///
/// Previously each report wrapped its body in a bare `InteractiveViewer`:
/// pinch only, no percentage, no buttons — unusable on desktop. One transform
/// matrix now serves both the buttons and the gestures, so the label never lies.
///
/// [child] is the fully built report sheet (letterhead + table + footer). The
/// shell never rebuilds it on zoom — only the transform changes, so the tables
/// do not re-layout while the user zooms.
class ReportZoomView extends StatefulWidget {
  /// محتوى التقرير كاملاً (الورقة + الجدول + التذييل) داخل تمرير عمودي.
  /// The whole report content; must include its own vertical scrolling.
  final Widget child;

  /// حدود التكبير — نفس الحدود في كل التقارير حتى لا يختلف سلوكها.
  /// Zoom bounds, identical across reports so behaviour never differs.
  final double minScale;
  final double maxScale;

  /// مقدار الخطوة لكل ضغطة زر.
  /// Step applied by each button press.
  final double step;

  const ReportZoomView({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 2.5,
    this.step = 0.15,
  });

  @override
  State<ReportZoomView> createState() => _ReportZoomViewState();
}

class _ReportZoomViewState extends State<ReportZoomView> {
  final TransformationController _controller = TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScale);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncScale);
    _controller.dispose();
    super.dispose();
  }

  /// مزامنة النسبة مع أي تكبير بالإصبع أو القرص.
  /// Keep the percentage label in step with pinch/scroll gestures.
  void _syncScale() {
    if (!mounted) return;
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _scale).abs() < 0.01) return;
    setState(() => _scale = scale.clamp(widget.minScale, widget.maxScale));
  }

  /// تطبيق نسبة تكبير محددة (مع تثبيت الحدود).
  /// Apply a specific zoom factor, clamped to the allowed range.
  void _applyZoom(double scale) {
    final clamped = scale.clamp(widget.minScale, widget.maxScale);
    _controller.value = Matrix4.identity()..scale(clamped);
    setState(() => _scale = clamped);
  }

  /// العودة إلى 100%.
  void _resetZoom() => _applyZoom(1.0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            // التمرير العمودي يبقى للمحتوى نفسه — التكبير لا يعطّل القراءة.
            // Vertical scrolling stays with the content; zoom never blocks reading.
            child: widget.child,
          ),
        ),
        // شريط الأدوات عائم أسفل اليسار — لا يحجب أرقام العمود الأول (يمين RTL).
        // The toolbar floats bottom-left so it never covers the first column (RTL).
        Positioned(
          left: 12,
          bottom: 12,
          child: _buildControls(),
        ),
      ],
    );
  }

  /// شريط الأدوات العائم: تصغير + النسبة الحيّة + تكبير + إعادة الضبط.
  /// Floating toolbar: zoom out, live percentage, zoom in, reset.
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'تصغير',
            onTap: _scale <= widget.minScale + 0.001
                ? null
                : () => _applyZoom(_scale - widget.step),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${(_scale * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _zoomButton(
            icon: Icons.add_rounded,
            tooltip: 'تكبير',
            onTap: _scale >= widget.maxScale - 0.001
                ? null
                : () => _applyZoom(_scale + widget.step),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: AppColors.border,
          ),
          _zoomButton(
            icon: Icons.fit_screen_rounded,
            tooltip: 'الحجم الطبيعي',
            onTap: (_scale - 1.0).abs() < 0.001 ? null : _resetZoom,
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      color: const Color(0xFF6B2D1B),
      disabledColor: AppColors.textMuted.withValues(alpha: 0.45),
    );
  }
}
