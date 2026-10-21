import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tab and UI icons as SVG source, drawn as real strokes at the exact width the
/// design asks for (1.5px).
///
/// Icon fonts cannot do this: the Lucide font is 2px only, and font glyphs are
/// pre-outlined, so they render heavier than a stroked vector of the same
/// width. `house`, `user` and `search-x` are upstream Lucide with only
/// `stroke-width` changed; the barbell, bar chart and rings are the design's
/// own paths.
///
/// Lucide path data: (https://lucide.dev), ISC License, Copyright (c) Lucide
/// Contributors.
abstract final class LucideSvg {
  /// Stroke width for every icon, in the 24-unit viewBox (so px at 24px).
  static const String strokeWidth = '1.5';

  static const String _open =
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
      'viewBox="0 0 24 24" fill="none" stroke="#000000" '
      'stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">';
  static const String _close = '</svg>';

  /// Lucide `house` (formerly `home`).
  static const String house =
      '$_open'
      '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/>'
      '<path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 '
      '21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>'
      '$_close';

  /// Horizontal barbell, from the design (not Lucide): a bar, tall inner
  /// plates, short outer plates and bar ends. Never rotated.
  static const String barbell =
      '$_open'
      '<line x1="7" y1="12" x2="17" y2="12"/>'
      '<line x1="7" y1="8" x2="7" y2="16"/>'
      '<line x1="17" y1="8" x2="17" y2="16"/>'
      '<line x1="4.5" y1="9.5" x2="4.5" y2="14.5"/>'
      '<line x1="19.5" y1="9.5" x2="19.5" y2="14.5"/>'
      '<line x1="2" y1="12" x2="4.5" y2="12"/>'
      '<line x1="19.5" y1="12" x2="22" y2="12"/>'
      '$_close';

  /// Bar chart, from the design (not Lucide): three vertical bars standing on
  /// a baseline — middle tallest, left medium, right shortest.
  static const String barChart =
      '$_open'
      '<line x1="3" y1="20" x2="21" y2="20"/>'
      '<line x1="7" y1="20" x2="7" y2="12"/>'
      '<line x1="12" y1="20" x2="12" y2="5"/>'
      '<line x1="17" y1="20" x2="17" y2="14"/>'
      '$_close';

  /// Two concentric rings, from the design (not Lucide): no centre dot, no
  /// third ring.
  static const String rings =
      '$_open'
      '<circle cx="12" cy="12" r="9"/>'
      '<circle cx="12" cy="12" r="4"/>'
      '$_close';

  /// Lucide `user`: head circle and shoulder arc.
  static const String user =
      '$_open'
      '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>'
      '<circle cx="12" cy="7" r="4"/>'
      '$_close';

  /// Lucide `search-x`.
  static const String searchX =
      '$_open'
      '<path d="m13.5 8.5-5 5"/>'
      '<path d="m8.5 8.5 5 5"/>'
      '<circle cx="11" cy="11" r="8"/>'
      '<path d="m21 21-4.3-4.3"/>'
      '$_close';
}

/// Paints one [LucideSvg] icon at [size], tinted [color].
///
/// The SVG's own stroke colour is replaced wholesale via [BlendMode.srcIn], so
/// a single source serves every state — callers change only the colour.
class LucideSvgIcon extends StatelessWidget {
  const LucideSvgIcon({
    required this.svg,
    required this.size,
    required this.color,
    super.key,
  });

  /// SVG source, one of the [LucideSvg] constants.
  final String svg;

  /// Width and height in logical pixels.
  final double size;

  /// Stroke colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      // Decorative: the text next to an icon carries its meaning, so a
      // screen reader should not announce a separate image.
      excludeFromSemantics: true,
    );
  }
}
