import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Loads brand SVGs from Simple Icons CDN (same source as the React prototype).
abstract final class BrandSvgCache {
  static final Map<String, String?> _mem = {};
  static final Map<String, Future<String?>> _inFlight = {};

  static Future<String?> svgBody(String slug) {
    final key = slug.toLowerCase();
    if (_mem.containsKey(key)) return Future.value(_mem[key]);
    return _inFlight.putIfAbsent(key, () async {
      final uri = Uri.parse('https://cdn.simpleicons.org/$key');
      try {
        final r = await http.get(uri).timeout(const Duration(seconds: 12));
        if (r.statusCode == 200) {
          final b = r.body;
          if (b.contains('<svg')) {
            _mem[key] = b;
            return b;
          }
        }
      } catch (_) {}
      _mem[key] = null;
      return null;
    }).whenComplete(() => _inFlight.remove(key));
  }
}

/// Marquee-sized brand glyph; shows a monogram while loading or if the CDN fails.
class BrandMarqueeIcon extends StatefulWidget {
  const BrandMarqueeIcon({
    super.key,
    required this.slug,
    required this.displayName,
    this.size = 22,
    this.accent,
  });

  final String slug;
  final String displayName;
  final double size;

  /// Optional brand hue (simple-icons paths are monochrome; this feels like full-color glyphs).
  final Color? accent;

  @override
  State<BrandMarqueeIcon> createState() => _BrandMarqueeIconState();
}

class _BrandMarqueeIconState extends State<BrandMarqueeIcon> {
  String? _svg;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BrandMarqueeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _svg = null;
      _done = false;
      _load();
    }
  }

  Future<void> _load() async {
    final data = await BrandSvgCache.svgBody(widget.slug);
    if (!mounted) return;
    setState(() {
      _svg = data;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monoBase = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final tintForSvg = widget.accent ?? monoBase.withValues(alpha: .88);
    final cf = ColorFilter.mode(tintForSvg, BlendMode.srcIn);

    if (_svg != null) {
      return SvgPicture.string(
        _svg!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        colorFilter: cf,
        allowDrawingOutsideViewBox: true,
      );
    }

    if (!_done) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: SizedBox(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: monoBase.withValues(alpha: .35),
            ),
          ),
        ),
      );
    }

    final letter = widget.displayName.trim().isNotEmpty
        ? widget.displayName.trim()[0].toUpperCase()
        : '?';
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: monoBase.withValues(alpha: .25)),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: widget.size * 0.52,
              fontWeight: FontWeight.w800,
              color: widget.accent ?? monoBase.withValues(alpha: .8),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
