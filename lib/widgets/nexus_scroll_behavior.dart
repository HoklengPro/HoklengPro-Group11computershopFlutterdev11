import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Bouncing + overscroll so short lists and awkward nested layouts still drag
/// smoothly on Android; matches patterns already used on several screens.
class NexusScrollBehavior extends MaterialScrollBehavior {
  const NexusScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  /// Emulators often deliver drags as mouse/trackpad; include all common kinds
  /// so nested lists and the home feed still scroll reliably.
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      };
}
