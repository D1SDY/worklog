import 'package:flutter/widgets.dart';

import '../../../domain/models/shell_destination.dart';
import '../theme/app_tokens.dart';
import 'lucide_svg.dart';

/// Icon for each [ShellDestination], per the design's Tab Item spec, which
/// overrides the story's original icon table. Головна and Профіль are Lucide
/// `house` and `user`; Тренування, Статистика and Досягнення use the design's
/// own barbell, bar chart and two-ring paths.
///
/// Lives in `lib/ui/` rather than on the domain enum so the domain layer stays
/// free of Flutter and rendering dependencies.
extension ShellDestinationIcons on ShellDestination {
  /// SVG source of this tab's icon, used unchanged in both states.
  String get lucideSvg {
    return switch (this) {
      ShellDestination.home => LucideSvg.house,
      ShellDestination.training => LucideSvg.barbell,
      ShellDestination.statistics => LucideSvg.barChart,
      ShellDestination.achievements => LucideSvg.rings,
      ShellDestination.profile => LucideSvg.user,
    };
  }
}

/// A tab's outline icon: one glyph and one 1.5px stroke for every state. The
/// active tab differs only in [color].
class TabIcon extends StatelessWidget {
  const TabIcon({
    required this.destination,
    required this.color,
    this.size = AppSizes.navIcon,
    super.key,
  });

  /// The tab whose glyph to draw.
  final ShellDestination destination;

  /// Stroke colour: [AppColors.accentBlue] when active, muted otherwise.
  final Color color;

  /// Width and height; the rules page fixes nav icons at 24px.
  final double size;

  @override
  Widget build(BuildContext context) {
    return LucideSvgIcon(svg: destination.lucideSvg, size: size, color: color);
  }
}
