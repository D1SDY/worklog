/// A top-level destination in the app's bottom navigation shell.
///
/// Declaration order is the tab order in the bar, fixed by
/// 📐 UI Component Rules → Bottom Navigation Bar.
///
/// Labels are Ukrainian: that page defines the app's UI copy. The English names
/// in the WORLOG-001 description identify the tabs for the reader; they are not
/// the strings shown to users.
///
/// Pure Dart on purpose. Icons are presentation, so they live in
/// `lib/ui/core/icons/tab_icon.dart`, keeping this layer free of
/// Flutter and icon-font dependencies.
enum ShellDestination {
  home(path: '/home', label: 'Головна'),
  training(path: '/training', label: 'Тренування'),
  statistics(path: '/statistics', label: 'Статистика'),
  achievements(path: '/achievements', label: 'Досягнення'),
  profile(path: '/profile', label: 'Профіль');

  const ShellDestination({required this.path, required this.label});

  /// Route location of this tab's branch root.
  ///
  /// Later stories nest their screens under this path, so a tab's whole stack
  /// stays addressable — `/training/exercise/42` keeps the bar on Тренування.
  final String path;

  /// Text shown under the tab icon.
  final String label;
}
