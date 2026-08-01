# Titan

Titan is a cross platform frontend written in Flutter for an open-source project launched by ÉCLAIR and maintained by ProximApp. This project aims to provide students of business and engineering schools a digital tool to simplify campus life and student association activities.

## Flavors

Titan supports [flavors](https://docs.flutter.dev/deployment/flavors), which allows the developer to easily switch between several versions of Titan for several use cases.

Titan includes 3 flavors: `dev`, `alpha`, `prod`. On VSCode, you can choose which flavor to use when launching the debugger

Each flavor is associated with a specific app package name (`*.titan.dev`, `*.titan.alpha`, `*.titan`) allowing the three app to be installed simultaneously on the same device.

## Base configuration

You need to create config json files with required variables:

- config/config-dev.json
- config/config-alpha.json
- config/config-prod.json

## Development

### Setup dev environment

Install Flutter:
https://docs.flutter.dev/get-started/install

Setup VS Code for Flutter development:
https://docs.flutter.dev/get-started/editor?tab=vscode

Titan is designed to be launched on Web, Android and iOS platforms.

### Run Titan

```bash
flutter run --flavor dev --dart-define-from-file=config/config-dev.json --web-port 3000
# flutter run --flavor alpha --dart-define-from-file=config/config-alpha.json --web-port 3000
# flutter run --flavor prod --dart-define-from-file=config/config-prod.json --web-port 3000
```

On the web, appending `--wasm --no-cross-origin-isolation` runs a version compiled to WebAssembly instead of JavaScript:

```bash
flutter run --flavor dev --dart-define-from-file=config/config-dev.json --web-port 3000 --wasm --no-cross-origin-isolation
```

`--no-cross-origin-isolation` is required: cross-origin isolation would otherwise be turned on along with WebAssembly, and it breaks popups — which is how both login and HelloAsso funding work. The same reasoning drives the `Cross-Origin-Embedder-Policy: credentialless` / `Cross-Origin-Opener-Policy: unsafe-none` headers in `web_dev_config.yaml` and `nginx.conf`.

Web release builds pass `--wasm` too, which emits both the WebAssembly and the JavaScript bundles; the loader in `web/index.html` picks whichever the browser supports. Note that `flutter build web` **rejects `--flavor`** — the flavor comes from the `flavor` key of the config file instead (see `getAppFlavor()` in `lib/tools/functions.dart`):

```bash
flutter build web --release --dart-define-from-file=config/config-alpha.json --wasm
```

Titan can be launched from VS Code _Run and Debug_ menu.

### Web performance

A few things in this repository exist only to keep the web build fast. They are
easy to undo by accident, so they are worth knowing about.

- **`web/index.html` owns the Core Web Vitals.** The splash screen is
  `position: fixed` and contains real text. Both matter: a splash that takes
  part in layout costs ~0.2 of Cumulative Layout Shift when Flutter attaches
  its view, and a splash made only of coloured `<div>`s is not "contentful",
  so First Contentful Paint does not fire until Flutter's first frame — several
  seconds later. The splash removes itself on the engine's `flutter-first-frame`
  event.
- **Brotli.** The `Dockerfile` builds `ngx_brotli` against the nginx it ships
  and precompresses every asset, and `nginx.conf` enables `brotli_static`. It is
  worth ~23% over gzip on the Dart bundle.
- **Fonts are bundled**, subset to Latin and stripped of hinting, in
  `assets/google_fonts/`. `google_fonts` finds them through the asset manifest
  and loads them lazily, so unused weights cost nothing. Adding a new
  `GoogleFonts.x()` call without adding the matching `X-Weight.ttf` silently
  brings back a runtime download from `fonts.gstatic.com`. Cut new subsets with
  `tool/subset_font.py`, which is the recipe the existing ones were made with.
- **`Roboto` is declared in `pubspec.yaml` under `fonts:`, not `assets:`.** The
  web engine lays text out in Roboto before anything else is registered, and
  fetches it from `fonts.gstatic.com` — 62 KB, cross-origin, awaited before the
  first frame — unless the font manifest already declares that family. Only
  `fonts:` entries reach `FontManifest.json`, so moving it would bring the
  download back.
- **The renderer is self-hosted.** The web build passes
  `--no-web-resources-cdn`, which serves CanvasKit/skwasm from our own origin
  rather than `www.gstatic.com`. It is 1.2 MB on the critical path, so dropping
  the third-party DNS lookup and TLS handshake — and serving it with our own
  brotli — is worth ~100 ms of first frame on a throttled mobile profile.
- **Routes are deferred.** Every module router imports its pages
  `deferred as …` and guards them with `DeferredLoadingMiddleware`. A plain
  import moves that page, and everything it references, into the bundle that
  every visitor downloads before the first frame.
- **`lib/tools/functions.dart` is imported by almost everything**, so anything
  heavy it imports lands in that same eager bundle. That is why
  `getDateInRecurrence` lives in `lib/tools/recurrence.dart` instead: it was
  dragging the whole Syncfusion calendar in with it.
- **Images** are WebP. School-supplied artwork is normalised by the
  `Normalize injected assets` step of `.github/workflows/release-web.yml`.
- **Icons are compiled in, not bundled as assets.** `lib/tools/ui/heroicons.dart`
  replaces the `heroicons` package, whose 1288 SVGs turned into 1288 entries in
  `AssetManifest.bin.json` — 193 KB that every visitor downloaded and parsed
  before the first frame — and one HTTP request per icon drawn. After adding a
  `HeroIcons.foo` that the app has not used before, run
  `dart run tool/gen_heroicons.dart`; styles other than outline additionally
  have to be declared in `tool/heroicons.yaml`.

### Formatting

To format code use `dart format .`

```
dart format .
```

### Linting

Titan support linting according to the official [Flutter static analysis options](https://dart.dev/guides/language/analysis-options).

The linter can be launched using:

```
dart analyze
```

Dart allows you to fix issues in your code with the dart command `dart fix`.

To preview proposed changes, use the `--dry-run` flag:

```
dart fix --dry-run
```

To apply the proposed changes, use the --apply flag:

```
dart fix --apply
```

### Testing

Titan's tests follow the official [Flutter documentation](https://docs.flutter.dev/testing).

Tests can be run using:

```bash
flutter test --flavor dev
```

To run a specific test file :

```bash
flutter test --flavor dev path/to/file.dart
```

## Advanced Configuration

### Notifications setup

Notifications are handled using the Firebase Cloud Messaging API. On mobile platforms, a valid notification configuration is required to debug Titan. Notifications are disabled on web builds.

Please refer to the [documentation](https://pub.dev/packages/firebase_messaging) of the corresponding Flutter's package to correctly setup notifications.

Please follow [Android](https://firebase.google.com/docs/cloud-messaging/android/client) or [iOS](https://firebase.google.com/docs/cloud-messaging/ios/client) Firebase documentation to setup notifications.

#### Android FCM config file

For Android, add your `google-services.json` in `android/app/src/<flavor>/`.

It has to be the file for *that* flavor. Each flavor builds a different
application id — `<APP_ID_PREFIX>.titan`, `.titan.alpha`, `.titan.dev`, from the
`APP_ID_PREFIX` in the matching `config/config-<flavor>.json` — and the Google
Services Gradle plugin fails the build outright when no client in the file
matches:

```
Execution failed for task ':app:processDevDebugGoogleServices'.
> No matching client found for package name 'com.myemapp.titan.dev'
```

Copying one flavor's file into another flavor's directory is the usual cause.
These files are gitignored, so the mistake only shows up on the machine that
made it.

#### iOS FCM config file

For iOS, add your `GoogleService-Info.plist` in `ios/config/<flavor>/`.

iOS is the more dangerous of the two: nothing checks that the plist's
`BUNDLE_ID` matches the flavor being built, so the wrong file builds cleanly and
silently registers the device against another Firebase project at runtime.
`plutil -extract BUNDLE_ID raw ios/config/<Flavor>/GoogleService-Info.plist` is
worth a look if notifications land in the wrong app.

## Advanced

### Allows non SSL connexion to use a custom local Hyperion backend

<details>
<summary>

On mobile, using plaintext HTTP connexions may raise issues.

</summary>

#### Android

Update [AndroidManifest.xml](./android/app/src/debug/AndroidManifest.xml):

```
<application
    ...
    android:usesCleartextTraffic="true"
    ...   >
```

#### iOS

Update [Info.plist](ios/Runner/Info.plist):

```
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
	<key>NSExceptionDomains</key>
	<dict>
		<key>yourdomain.com</key>
		<dict>
			<key>NSIncludesSubdomains</key>
			<true/>
			<key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
			<false/>
		</dict>
	</dict>
</dict>
```

</details>

### Update Titan's icon

First update the icon's file and update [pubspec.yaml](./pubspec.yaml).

Then run `flutter_launcher_icons` to generate all variants of the icon:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Upgrade Gradle version

[Guided upgrade using Android Studio](https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide#solution-1-guided-fix-using-android-studio)
[Java and Gradle compatibility](https://docs.gradle.org/current/userguide/compatibility.html)

## Building using Fastlane

### Fastlane configuration

For automated signature and upload, you need to provide the following keys:

- Google service account

```
android/fastlane-service-account.json
```

- Apple App Store Connect API key

```
ios/app-store-connect-api.p8
```

### Build and upload a version

```bash
cd ios # or android
bundle exec fastlane beta flavor:alpha # or prod or dev
```

### Update Fastlane

```bash
bundle update fastlane
cd ios
bundle update fastlane
cd android
bundle update fastlane
```