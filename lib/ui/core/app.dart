import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget of the Workout Logger app.
///
/// Dark-only for now: the design is dark-first, and the system/light/dark
/// toggle is WORLOG-007's scope, not this story's.
class WorklogApp extends StatefulWidget {
  const WorklogApp({super.key, this.router});

  /// Router to run the app with. Defaults to [AppRouter.create]; tests inject
  /// one to start at a deep link instead of the Головна tab.
  final GoRouter? router;

  @override
  State<WorklogApp> createState() => _WorklogAppState();
}

class _WorklogAppState extends State<WorklogApp> {
  /// Built once: a [GoRouter] holds navigation state, so rebuilding one per
  /// frame would drop the user's place in every tab.
  late final GoRouter _router = widget.router ?? AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Workout Logger',
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
