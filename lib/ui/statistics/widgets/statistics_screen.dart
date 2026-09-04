import 'package:flutter/material.dart';

import '../../../domain/models/shell_destination.dart';
import '../../core/widgets/placeholder_tab_view.dart';

/// The Statistics tab. Placeholder content until its own story lands.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTabView(destination: ShellDestination.statistics);
  }
}
