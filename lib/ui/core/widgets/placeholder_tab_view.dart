import 'package:flutter/material.dart';

import '../../../domain/models/shell_destination.dart';
import '../theme/app_tokens.dart';

/// Stand-in body for a shell tab whose real content ships in a later story.
///
/// Deliberately scrollable: WORLOG-001 requires each tab to retain its scroll
/// offset across tab switches, which is only observable with a scrollable body.
class PlaceholderTabView extends StatelessWidget {
  const PlaceholderTabView({required this.destination, super.key});

  /// Enough rows to overflow every supported screen height.
  static const int itemCount = 40;

  final ShellDestination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: ListView.builder(
        key: PageStorageKey<String>(destination.name),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(destination.icon, color: AppColors.textMuted),
            title: Text(
              '${destination.label} $index',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}
