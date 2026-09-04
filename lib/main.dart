import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'ui/core/app.dart';

void main() {
  // Clean deep-link URLs (`/training`, not `/#/training`) when the shell runs
  // in a browser. A no-op on Android and iOS — the import resolves to a stub
  // off the web.
  usePathUrlStrategy();
  runApp(const WorklogApp());
}
