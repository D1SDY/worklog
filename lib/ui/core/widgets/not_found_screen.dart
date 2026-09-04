import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/shell_destination.dart';
import '../theme/app_tokens.dart';

/// Shown when a route cannot be resolved — a stale deep link, or a typed URL on
/// web.
///
/// Follows 📐 UI Component Rules → Empty States (centred muted icon + short
/// muted text) with the Text link button pattern to get back into the shell.
/// It renders outside the shell, so the link is the only way out.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.search_off_outlined,
                size: AppSizes.emptyStateIcon,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Сторінку не знайдено',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(ShellDestination.home.path),
                child: const Text('На головну'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
