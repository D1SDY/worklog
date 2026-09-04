import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worklog/ui/core/theme/app_theme.dart';
import 'package:worklog/ui/core/theme/app_tokens.dart';

void main() {
  setUpAll(() {
    // These are plain `test`s, not `testWidgets`, so nothing has initialised
    // the binding. google_fonts reaches for ServicesBinding.instance to look up
    // bundled fonts and logs a loud failure without it.
    TestWidgetsFlutterBinding.ensureInitialized();

    // Tests must not reach the network for fonts; the family name is still
    // applied, which is what these assertions check.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Design tokens match 📐 UI Component Rules', () {
    test('colour tokens are the exact published values', () {
      expect(AppColors.bgPrimary, const Color(0xFF0F1419));
      expect(AppColors.bgSecondary, const Color(0xFF1A2332));
      expect(AppColors.accentBlue, const Color(0xFF2563EB));
      expect(AppColors.accentGreen, const Color(0xFF10B981));
      expect(AppColors.accentOrange, const Color(0xFFF59E0B));
      expect(AppColors.accentRed, const Color(0xFFEF4444));
    });

    test('muted text really is ~60% opacity', () {
      expect(
        AppColors.textMuted.a,
        closeTo(AppColors.mutedOpacity, 0.01),
        reason: 'textMuted literal and mutedOpacity must not drift apart',
      );
    });

    test('spacing scale is the 4px steps and nothing else', () {
      expect(AppSpacing.scale, <double>[4, 8, 12, 16, 20, 24]);
    });

    test('radii match the published values', () {
      expect(AppRadius.input, 8);
      expect(AppRadius.card, 12);
      expect(AppRadius.modal, 16);
    });
  });

  group('AppTheme.dark', () {
    test('is dark and uses the primary background', () {
      final ThemeData theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.bgPrimary);
    });

    test('uses Inter for UI text', () {
      final String? family = AppTheme.dark().textTheme.bodyMedium?.fontFamily;

      expect(family, isNotNull);
      expect(family, contains('Inter'));
    });

    test('uses JetBrains Mono for numeric values', () {
      expect(AppTheme.numeric().fontFamily, contains('JetBrainsMono'));
    });

    group('bottom navigation bar', () {
      test('is 56px on the secondary surface', () {
        final NavigationBarThemeData nav = AppTheme.dark().navigationBarTheme;

        expect(nav.height, AppSizes.bottomNavHeight);
        expect(nav.height, 56);
        expect(nav.backgroundColor, AppColors.bgSecondary);
      });

      test('icons are the 24px size the rules page specifies', () {
        final NavigationBarThemeData nav = AppTheme.dark().navigationBarTheme;

        expect(nav.iconTheme?.resolve(<WidgetState>{})?.size, 24);
        expect(
          nav.iconTheme?.resolve(<WidgetState>{WidgetState.selected})?.size,
          AppSizes.navIcon,
        );
      });

      test('shows no Material indicator pill', () {
        expect(
          AppTheme.dark().navigationBarTheme.indicatorColor,
          Colors.transparent,
        );
      });

      test('active tab is accent blue, inactive is muted', () {
        final NavigationBarThemeData nav = AppTheme.dark().navigationBarTheme;
        const Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
        const Set<WidgetState> unselected = <WidgetState>{};

        expect(nav.iconTheme?.resolve(selected)?.color, AppColors.accentBlue);
        expect(nav.iconTheme?.resolve(unselected)?.color, AppColors.textMuted);
        expect(
          nav.labelTextStyle?.resolve(selected)?.color,
          AppColors.accentBlue,
        );
        expect(
          nav.labelTextStyle?.resolve(unselected)?.color,
          AppColors.textMuted,
        );
      });

      test('labels are always visible', () {
        expect(
          AppTheme.dark().navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
      });
    });
  });
}
