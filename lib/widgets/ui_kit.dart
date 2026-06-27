import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/nexus_palette.dart';

class GradientTitle extends StatelessWidget {
  const GradientTitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final base = GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Colors.white,
        ).merge(style);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => NexusPalette.textGradientHorizontal.createShader(bounds),
          child: Text(
            text,
            style: base,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow:
                maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
          ),
        );
      },
    );
  }
}

class GlowDot extends StatelessWidget {
  const GlowDot({
    super.key,
    required this.color,
    this.radius = 4,
  });

  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
    );
  }
}

class GradientRgbButton extends StatelessWidget {
  const GradientRgbButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              colors: [NexusPalette.cyan, NexusPalette.magenta, NexusPalette.violet],
            ),
            boxShadow: [
              BoxShadow(
                color: NexusPalette.cyan.withValues(alpha: 0.22),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style:
                  GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white, size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outer gradient stroke + inner surface (CSS `border-gradient` feel).
class BorderGradientPanel extends StatelessWidget {
  const BorderGradientPanel({
    super.key,
    required this.radius,
    required this.child,
  });

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inner = Theme.of(context).brightness == Brightness.dark
        ? NexusPalette.darkSurface
        : NexusPalette.lightSurface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _BorderGradientPainter(
          radius,
          const LinearGradient(
            colors: [NexusPalette.cyan, NexusPalette.magenta, NexusPalette.violet],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: inner,
              borderRadius:
                  BorderRadius.circular(math.max(radius - 1, 0)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BorderGradientPainter extends CustomPainter {
  _BorderGradientPainter(this.radius, this.stroke);

  final double radius;
  final LinearGradient stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectXY(rect, radius, radius);
    final paint = Paint()
      ..shader = stroke.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect.deflate(.5), paint);
  }

  @override
  bool shouldRepaint(covariant _BorderGradientPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

void showNexusToast(BuildContext context, String msg) {
  final brightness = Theme.of(context).brightness;
  final elevated = brightness == Brightness.dark
      ? NexusPalette.darkSurface
      : const Color(0xFF0F172A);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      backgroundColor: elevated.withValues(alpha: 0.96),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: NexusPalette.cyan.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      content: Text(
        msg.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: const Color(0xFFF8FAFC),
        ),
      ),
    ),
  );
}

/// Dual progress bars (gaming / productivity) used on PDP and compact on cards.
class NexusBenchmarkStrip extends StatelessWidget {
  const NexusBenchmarkStrip({
    super.key,
    required this.gaming,
    required this.productivity,
    this.compact = false,
  });

  final int gaming;
  final int productivity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).dividerColor.withValues(alpha: .72);

    Widget bar(String label, int score, Color tone) {
      final v = (score.clamp(0, 100)) / 100.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: compact ? 8 : 9,
                  letterSpacing: 2,
                  color: muted,
                ),
              ),
              Text(
                '$score',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 10 : 12,
                  color: tone,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: v,
              minHeight: compact ? 3.5 : 6,
              backgroundColor: muted.withValues(alpha: .18),
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            'NEXUS SCORES',
            style: GoogleFonts.jetBrainsMono(letterSpacing: 2, fontSize: 11),
          ),
          const SizedBox(height: 14),
        ],
        bar('GAMING', gaming, NexusPalette.cyan),
        SizedBox(height: compact ? 8 : 14),
        bar('PRODUCTIVITY', productivity, NexusPalette.magenta),
      ],
    );
  }
}
