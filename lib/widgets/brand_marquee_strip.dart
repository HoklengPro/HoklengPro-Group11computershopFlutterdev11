import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/catalog_models.dart';
import 'brand_logo.dart';

/// Brand accent for Simple Icons monochrome SVG chips (closest official hues).
Color? marqueeAccentForSlug(String slug) {
  switch (slug.toLowerCase()) {
    case 'asus':
      return const Color(0xFFE2062F);
    case 'razer':
      return const Color(0xFF00FF00);
    case 'corsair':
      return const Color(0xFFFFEA00);
    case 'msi':
    case 'msibusiness':
      return const Color(0xFFFF0000);
    case 'alienware':
      return const Color(0xFF54D5F1);
    case 'logitechg':
      return const Color(0xFF00B8FC);
    case 'steelseries':
      return const Color(0xFFFF5200);
    case 'nvidia':
      return const Color(0xFF76B900);
    case 'amd':
      return const Color(0xFFED1C24);
    case 'intel':
      return const Color(0xFF0071C5);
    case 'hyperx':
      return const Color(0xFFE21836);
    case 'acer':
      return const Color(0xFF83B81A);
    case 'dell':
      return const Color(0xFF007DB8);
    case 'hp':
      return const Color(0xFF0096D6);
    case 'lenovo':
      return const Color(0xFFE2231A);
    default:
      return null;
  }
}

/// Infinite marquee without a nested horizontal [Scrollable].
///
/// A horizontal [ListView] nested in the home vertical [ListView] was winning
/// the gesture arena on Android emulators and blocked scrolling the page.
class InfiniteBrandMarquee extends StatefulWidget {
  const InfiniteBrandMarquee({
    super.key,
    required this.brands,
    required this.surface,
    required this.border,
    this.horizontalPadding = 18,
    this.velocityPixelsPerSecond = 42,
  });

  final List<BrandMarqueeSpec> brands;

  /// Kept for API compatibility with callers (strip background from parent).
  final Color surface;

  /// Divider / chip border tint context.
  final Color border;

  final double horizontalPadding;

  /// How fast logos scroll horizontally.
  final double velocityPixelsPerSecond;

  /// Repeated sequences stitched together for seamless looping.
  static const int copies = 7;

  @override
  State<InfiniteBrandMarquee> createState() => _InfiniteBrandMarqueeState();
}

class _InfiniteBrandMarqueeState extends State<InfiniteBrandMarquee>
    with SingleTickerProviderStateMixin {
  static const double _pillStride = 168;

  final GlobalKey _rowKey = GlobalKey();
  late final Ticker _ticker;
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0);

  Duration? _stamp;
  double _segmentPx = 0;
  double _accumulator = 0;
  int _layoutRetries = 0;

  @override
  void initState() {
    super.initState();
    for (final b in widget.brands) {
      unawaited(BrandSvgCache.svgBody(b.slug));
    }
    _ticker = createTicker(_handleTick);
    WidgetsBinding.instance.addPostFrameCallback(_tryArmTicker);
  }

  void _tryArmTicker(_) {
    _measureSegmentFromRow();
    if (_segmentPx > 0) {
      if (!_ticker.isActive && mounted) _ticker.start();
      _layoutRetries = 0;
      return;
    }
    if (_layoutRetries < 48 && mounted) {
      _layoutRetries++;
      WidgetsBinding.instance.addPostFrameCallback(_tryArmTicker);
    }
  }

  void _measureSegmentFromRow() {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return;
    _segmentPx = box.size.width / InfiniteBrandMarquee.copies;
  }

  void _handleTick(Duration now) {
    if (!mounted) return;

    _measureSegmentFromRow();
    final seg = _segmentPx;
    if (seg <= 0) return;

    final stamp = _stamp ?? now;
    final dtMicros = (now - stamp).inMicroseconds;
    _stamp = now;
    if (dtMicros <= 0) return;

    final dt = (dtMicros / 1000000.0).clamp(0.001, 0.05);
    _accumulator += widget.velocityPixelsPerSecond * dt;
    _accumulator %= seg;
    _offsetNotifier.value = _accumulator;
  }

  Widget _pill(
    BuildContext context,
    BrandMarqueeSpec b,
    TextStyle labelStyle,
    Color muted,
  ) {
    final accent = marqueeAccentForSlug(b.slug);
    return SizedBox(
      width: _pillStride,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: .45),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: muted.withValues(alpha: .85)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: BrandMarqueeIcon(
                    slug: b.slug,
                    displayName: b.name,
                    size: 28,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle.copyWith(
                      color:
                          accent?.withValues(alpha: .95) ?? labelStyle.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipRow(
    BuildContext context,
    TextStyle labelStyle,
    Color muted,
  ) {
    final n = widget.brands.length * InfiniteBrandMarquee.copies;
    return Row(
      key: _rowKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          _pill(
            context,
            widget.brands[i % widget.brands.length],
            labelStyle,
            muted,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _offsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).dividerColor.withValues(alpha: .75);

    final labelStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface,
            ) ??
        TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface,
        );

    final chipRow = _buildChipRow(context, labelStyle, muted);

    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 1),
            Colors.black.withValues(alpha: 1),
            Colors.black.withValues(alpha: 0),
          ],
          stops: const [0, 0.06, 0.94, 1],
        ).createShader(rect),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalPadding,
            16,
            widget.horizontalPadding,
            16,
          ),
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: AnimatedBuilder(
                  animation: _offsetNotifier,
                  builder: (_, __) {
                    final seg = _segmentPx;
                    if (seg <= 0) return chipRow;
                    return Transform.translate(
                      offset: Offset(-(_offsetNotifier.value % seg), 0),
                      child: chipRow,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
