# Workout Logger (worklog)

Flutter app for logging workouts. Targets Android and iOS; until native builds
are set up, every change is tested on real phones as an installable web app
(PWA).

## Preview

| Build | URL | Updated |
|---|---|---|
| `develop` | https://d1sdy.github.io/worklog/ | every push to `develop`, after `flutter analyze` and `flutter test` pass |
| Pull request | `https://d1sdy.github.io/worklog/pr-<N>/` | every push to the PR; removed when it closes |

The deploy is `.github/workflows/develop.yml`: it formats, analyzes and tests
first, and a failing check blocks the deploy. The build is published to the
root of the `gh-pages` branch, next to the `pr-<N>/` previews.

### Install on iPhone

1. Open https://d1sdy.github.io/worklog/ in **Safari** (other iOS browsers
   cannot install web apps).
2. Tap **Share** → **Add to Home Screen** → **Add**.
3. Launch **Worklog** from the home screen. It opens fullscreen, without the
   Safari toolbar; content stays clear of the notch and the home indicator.

### Install on Android

1. Open https://d1sdy.github.io/worklog/ in **Chrome**.
2. Accept the **Install app** prompt, or use **⋮** → **Install app** /
   **Add to Home screen**.
3. Launch **Worklog** from the home screen or app drawer; it runs standalone,
   without the browser UI.

### Getting a new build onto the phone

Close the app and open it again. On launch, and whenever it returns to the
foreground, the app checks whether a newer build has been deployed and reloads
once if so. No service worker is registered, so nothing can pin an old build.

Deep links and refreshes on nested routes (`/worklog/training`) work: GitHub
Pages answers unknown paths with `404.html`, which hands the route back to the
app.

## Known PWA limitations

The preview is a testing vehicle, not a substitute for the native apps:

- **No background rest-timer notifications or vibration on iOS.** Safari does
  not let a web app run timers, vibrate or notify reliably while it is in the
  background or the screen is locked. Rest-timer behaviour must be verified on
  a native build.
- **Performance is not representative for NFR-1.1.** Flutter web runs on
  CanvasKit/WebAssembly in the browser; startup time and frame timings differ
  from a release build on Android/iOS. Measure NFR-1.1 on native builds only.
- **Offline storage must be web-compatible.** `sqflite` does not run on the
  web; local persistence has to use a package with a web backend (e.g. `drift`
  or `hive`) for the preview to keep working.
- Fonts and the CanvasKit renderer are fetched from Google's CDNs on first
  launch, so the first open needs a network connection.

## Development

See `CLAUDE.md` for the toolchain, commands, and the Definition of Done.

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

App icons are rendered from `web/icons/icon.svg`.
