# Test layout

One folder per module, mirroring `lib/`; each module folder holds its test
levels:

```
test/<module>/unit/         # provider/notifier tests (no router, no widgets)
test/<module>/widget/       # ONE widget mounted in isolation (no router)
test/<module>/integration/  # full-app shells (this README's subject)
test/<module>/end_to_end/   # reserved: flows against a running backend
test/shared/                # cross-module helpers (scaffold, fixtures)
```

`home`, `login` and `tools` have no `lib/<name>/` module — their tests live
under the closest match (`home/`, `login/`, `tools/`) with only the levels
they use.

## The four levels, cheapest first

Work down this list before writing anything slower. The right level for a
given bug is almost always the cheapest one that can see it.

1. **unit** — a provider/notifier in isolation. Fastest; cannot render.
2. **widget** — ONE widget (`OrderUI`, `SellerRightCard`, a chart) mounted
   through `pumpWidgetApp`: real `ProviderScope`, real l10n, real toast
   wrapper, NO router and no `AppTemplate`. Seconds per test, no navigation
   journey, and — because nothing filters overflows and the surface is a
   360x640 phone — it is the level that finds LAYOUT bugs. Cards, rows and
   chips all belong here.
3. **integration** — a real page through the real route table, middlewares
   and deferred loading. Costs a deep link and the one-boot-per-file rules
   (conventions 1/10/11); use it when the bug is about navigation, gating,
   a page's own provider fan-out, or a round-trip against the backend.
4. **end_to_end** — against a running backend. Reserved; nothing here yet,
   and nothing should move down to it while a widget test can see the bug.

Two things the widget level earned on its first run, both invisible to the
integration shells because they mount at 1920x1080: a 15px overflow in
amap's 130px product card, and unbounded name rows in mypayment's seller
card (350px) and device row (723px) — see ledger #39.

## Integration test shells

Full-app widget tests: real route table, real middlewares, real deferred page
loading, real l10n — only the network edge and the session bootstrap are
stubbed. These are the tests that move coverage on UI code, which provider
unit tests can never reach.

Current state (2026-10-18, mypayment flows round): **2468 tests
green**, honest coverage **85.32%** (26162/30664 executable lines,
lib/generated and lib/l10n excluded); **mypayment 90.2%** (3683/4085),
tickets 88.7% (2040/2300), tools 84.6%, recommendation 83.8%,
login 83.3%, phonebook 83.3%, navigation 81.8%, feed 80.4%, amap 79.3%,
vote 79.2%, loan 78.6%, auth 77.0%, admin 76.0%, booking 75.0%,
raffle 74.2%, **service 92.9%** (221/238), **super_admin 95.3%**,
**seed-library 96.6%**, **purchases 96.6%**, **advert 97.7%**,
**event 96.2%**, **settings 99.4%**, **centralisation 99.2%**, **user 100%**.

Two notes on reading that number. The pay flow
(`pay_page.dart`, `confirm_button.dart`, `qr_code.dart`, `keyboard.dart`,
`info_card.dart`) is at **100%** — which is exactly why ledger #58 exists:
those files were already at 48/49, 82/83 and 21/23 and every test stopped at
`find.byType(QrCode)`. Coverage measured the lines, never the payment. And
`others` is up 14 points on the `/no_module` work in ledger #55, which also
raised the denominator (`no_module.dart` grew a forward gate and an exit).

This round audited the 25 override fakes in `test/shared/app_scaffold.dart` —
the harness every shell test inherits — for ones that return a fixed
constant and thereby pin shut a branch in `lib/`. Three did, and two of them
were hiding whole files at **0%** behind a green suite:

- `FakeVersionVerifierNotifier` reported `minimalTitanVersionCode: 1` and
  `FakeTitanVersionNotifier` returned `999`, so `1 <= 999` was true in every
  test ever written and the `!value` arm of `minimalTitanVersionCode <=
  titanVersion` — the "your app is too old" decision, repeated verbatim in
  `AuthenticatedMiddleware`, `AppTemplate` and `LoadingPage` — was
  unreachable. `UpdatePage` sat at **0/12** and `RollbackPage` at **0/22**.
- `FakePermissionsNamesListNotifier` returned `[]` in three of four containers
  and `makeContainer` did not override it at all, so `computeUserModuleRoots`
  returned `[]` for **every user**: an empty catalog builds an empty map and
  every lookup hits its `continue`. `module_roots.dart` was 7/20 — the
  function that decides which modules a user may open.
- There was no fake that could put `versionVerifierProvider` in its **error**
  state at all. Both of its `error:` arms route to `/no_internet`
  (`AuthenticatedMiddleware`, `LoadingPage`), so `NoInternetPage` was
  **0/31** — 31 lines of real offline handling, including the only retry
  affordance a user has when the backend is down.

All three fakes are now parameterised (`makeContainer(titanVersion:,
minimalTitanVersionCode:, minimalHyperionVersion:, permissionCatalog:,
failVersionVerifier:, versionVerifierRecoversOnRetry:)`), and each new test
file carries a guard test asserting the *comparison or the AsyncValue state*
its page hangs on, so the fakes cannot silently go back to pinning the branch
shut. The state line moved +0.2 points, which is the honest measure of this
round: the coverage number is not what changed.

The round also surfaced **two real defects** the pinned branches had been
hiding, both pinned as `KNOWN BUG` rather than fixed because both are product
decisions: `buildPermissionToModuleRootMap` keys its map by the permission
name with the module prefix **stripped**, but `computeUserModuleRoots` looks
it up with the **full** name — so a full name grants nothing and a bare name
collides on one key; and `NoInternetPage`'s retry button reads a stale
build-time `isConnected` without awaiting the re-ask, so `QR.to(
HomeRouter.root)` is unreachable from any state a user can reach. See bugs
**#56** and **#57**.

The previous round's finding was that the state line moved least, and that the
finding itself was the point: ledger #51 is about behaviour, not line count.
The `.sort(` sweep of ledger #12 was
generalised to every mutating list/set method, and the **12 sites it turned up
across 6 files included four that never notified a listener at all** — so the
data changed and the UI never rebuilt. Two of those had production callers on
the advert-poster and delivery-order delete paths. The new ratchet
(`tools/unit/inplace_list_mutations_test.dart`) fails on the next one. mypayment's three
biggest holes were the bottom-modal money flows — pay, fund and the
payment-delegation family — and all three are now at widget or near-widget
level (ledger #50). It also yielded the first two fixes this round: a 420px
overflow in the pay sheet's QR, and the discovery that toasts are invisible
to finders in this harness (convention 25). The widget level now
exists in every module (ledger #48), and the round after it added the MOUNT
RATCHET: a detector for `CardLayout` calls that pin a literal width or height
— the shape the width-based sweep structurally cannot see — plus a test that
fails when such a card is mounted by no widget test at all. It found and
fixed a 324px overflow in home's `DaysEvent` on the way, taking home
80.9→81.8% (ledger #49).

This round's headline is not the three modules that gained a widget
directory (centralisation 39.4→**53.9%**, super_admin 34.3→**49.7%**, login
47.5→**76.7%**); it is a **dead registration** in the sweep that was supposed
to prove they did. `centralisation`'s `ModuleCard` was listed in
`fixed_width_cards_test`
as mounted *and* in the same file's `_notMounted` exemption map — and the
exemption suppressed the test, so the ratchet's "every candidate is
accounted for" check counted it as covered while `module_card.dart` sat at
37/37 uncovered behind a green sweep. The exemption's stated reason ("needs
the modules map seeded") was false: `FavoritesNameProvider.build()` returns
`[]`. What the card actually needed was a bounded parent, since its `Column`
holds an `Expanded` and the sweep mounts every card in an unbounded
`SingleChildScrollView` — so `_Card` grew a per-card `wrap` override and the
card is now genuinely mounted, here and at widget level. The lesson is
written into the map's own doc comment: a reason in `_notMounted` is
unverified until some test mounts the card.

Two fixes came out of the same round, both proved by reverting with
`git show HEAD:` and re-running (ledger #52): `setUpNotification` was fetching
the topics list on **every** launch, including for users who had just denied
notifications, because it read a Riverpod notifier — which instantiates it —
before the permission answer arrived; and the web login's dot indicator
forwarded a dot index to `animateToPage`, which wants a page index, so
clicking dot 1 showed screenshot 2.

This round takes the NEXT module's uncovered integration paths after
booking's, chosen from the coverage table (raffle was second by uncovered
lines): the raffle add/edit cluster. Five files, **six defects — five of them
silent data loss**. Creating a raffle, editing its name and saving a pack
ticket all reported success without a byte reaching the wire:
`tombolaRafflesPost` and `tombolaRafflesRaffleIdPatch` had NO caller in
`lib/` at all, and the pack-ticket list sat in `loading`, which
`ListNotifierAPI.handleState` reads as a refusal — "Error during addition"
with no request behind it. Two layout defects came with them:
`TicketUI` and `ConfirmCreationDialog` had never been mounted by any test
and both overflow the boxes they pin. raffle **58.4→74.2%** (744→**466**
uncovered), total 61.0→**61.7%**, suite at **2221** green (bug **#63**).
The line-keyed ratchet in `test/tools/unit/` needed re-anchoring first: the
"fix: copying list before updating state" commit moved two allowlisted call
sites, so their keys went stale — precisely the staleness its own assertion
exists to catch.

This round: the tickets manage/results cluster, four files picked off the
uncovered table — `manage_ticket_event_page` (mount load + store/event
fan-out + refresh), its `ticket_event_card` action sheet (9→21 lines: the
sheet had never once been opened), `ticket_results_page` (stats card, CSV
gate, empty and populated lists) and the `offer_ticket_modal` transfer
sheet (48/49). Ten tests, **no new defects** — these paths were
stub-complete, they simply had never been mounted. Suite 2444→**2454**
green, tickets 80.8→**88.7%** (2040/2300), overall 84.09→**84.77%**;
the CI ratchet floor moves 75→**84** with the measurement.

Next round: mypayment's largest uncovered files, in one cluster —
`devices_page` (28→**94/97**), `invoices_admin_page` (38→**90/92**) and
`add_edit_store` (40→**75/76**). Fourteen tests, and **one real defect**:
`WaitingButton.restoreButtonSize` ran on its disposed animation controller
whenever a flow unmounted the button before the tap future completed —
DevicesPage hides the add-device row the moment the registration lands and
only then awaits the activation dialog, so the `.then` reverse() hit a dead
ticker (assert in debug, null ticker in release). Fixed with a
`context.mounted` guard, which also took `waiting_button.dart` to **100%**.
The round also taught two harness lessons: device_info_plus's `fromMap`
needs EVERY non-nullable field (a partial map is `Null is not a subtype of
String`, not a null-default), and a `Response<void>` endpoint must be
stubbed with `chopperResponseVoid()` — handing a typed body to `T=void`
is the `void_checks` lint, not a passing stub. Suite 2454→**2468** green,
mypayment 86.1→**90.2%** (devices_page 96.9%, invoices_admin 97.8%,
add_edit_store 98.7%), overall 84.77→**85.32%**; ratchet floor 84→**85**.

CI runs `dart run tool/coverage_report.dart`
(dependency-free): prints the per-module table into the job summary,
enforces the COVERAGE_MIN ratchet and writes the `lib/generated`-filtered
lcov that Codecov and the artifact receive.

## Running

```bash
# One file (always verify a new file solo before moving on)
flutter test --flavor prod --dart-define=flavor=prod --dart-define=APP_ID_PREFIX=test --dart-define=APP_NAME=MyEMApp --dart-define=BACKEND_HOST=https://myemapp.com/ --dart-define=TITAN_URL=https://myemapp.com/ --dart-define=SCHOOL_NAME= test/<module>/integration/<file>.dart

# Everything with coverage
flutter test --flavor prod --dart-define=flavor=prod --dart-define=APP_ID_PREFIX=test --dart-define=APP_NAME=MyEMApp --dart-define=BACKEND_HOST=https://myemapp.com/ --dart-define=TITAN_URL=https://myemapp.com/ --dart-define=SCHOOL_NAME= --coverage
```

The config defines (`APP_ID_PREFIX`, `APP_NAME`, `BACKEND_HOST`,
`TITAN_URL`) are compile-time constants the config functions throw without;
most are only needed by specific pages (redirect URLs, login, the sign-in
flow's real repository). The scaffold fakes the `KeyService` for everything
else.

A bare `flutter test` (no defines at all) also works: under the
`FLUTTER_TEST` env var the config getters fall back to those same values —
CI's, plus the shipped `assets/emlyon` folder for `SCHOOL_NAME` — instead
of throwing inside a `build`. Real builds keep the fail-fast StateError that
`tool/check_config.sh` guards at build time.

## Conventions (violating these produces inexplicable failures)

1. **One shell per file.** qlevar_router 1.12.4 only processes the
   init-path middleware chain on the FIRST navigation of an isolate. A file
   may contain exactly one test that boots with an `initialPath` (deep link)
   — put it first. Everything else must either already be mounted or be
   reached with the known workarounds.
2. **First mid-test `QR.to()` to an unmounted route is silently dropped**
   when an earlier test ran in the same isolate. Navigation tests go first    in their file (see the NOTE in `purchases/integration/
    purchases_integration_test.dart`,
   verified by bisect).
3. **`setUp` must stub the feed endpoints** (`scaffold.stubFeed()`), even
   when testing another module: the boot chain redirects `/` to `/feed`
   before reaching the page under test.
4. **`settle()`, not `pumpAndSettle`**, for pages with an active animation
   (feed's 1s timer, raffle's never-resolving ticket list). For the pump
   inside `pumpApp` itself, pass `pumpAndSettle: false`.
5. **Text finders vs `AutoSizeText`/`RichText`:** `find.text` does not
   match `AutoSizeText` content; use `find.byWidgetPredicate` with a
   widget-type check (`w is AutoSizeText && w.data == ...`) or
   `find.textContaining` where possible. A plain `RichText` (tickets'
   `StatTile` builds its "125000 / 125000" from two `TextSpan`s) is not an
   `AutoSizeText`, so neither of those matches it either — pass
   `findRichText: true` to `find.text`/`find.textContaining`, which makes
   the finder see the joined span text.
6. **Locale duality:** the app renders l10n **en** (MaterialApp resolution)
   but `localeProvider` defaults to **fr**, so number/date formatting uses
   `25,10` / `12/31/2100` style. Check the actual formatter used by the
   widget you assert on (mypayment cards use `localeProvider` = fr).
7. **Center/currency conventions found the hard way:** amap & raffle render
   raw balances (`2510.00`), mypayment divides by 100 and appends `ʍ`
   (`25,10 ʍ` in fr). Look at the widget before writing the expectation.
8. **Tap targets below the fold are silently dropped.** Long sheets and
   forms (EditProfile's Confirm, the add-event submit) sit off-viewport
   even at 1920×1080; `tester.tap` warns and misses, so the flow appears
   to "do nothing". `dragUntilVisible(target, find.byType(
   SingleChildScrollView).last, const Offset(0, -200))` before tapping —
   the modal body IS a SingleChildScrollView (`isScrollControlled: true`).
9. **Platform channels need mock handlers or the test hangs forever.**
   `Clipboard.setData/getData` without a handler never completes inside the
   FakeAsync zone (a pending future has no timeout): setData's `.then`
   never runs (no toast) and `await Clipboard.getData` freezes the body.
   `scaffold.stubClipboard(tester)` registers an in-memory handler; any
   new plugin call on a page under test needs the same treatment.
10. **One navigation journey per file — even for tap-driven flows** (the
    deferred-library variant of rules 1-2). A second test that navigates
    to a deferred route after a first deep link wedges the router stack in
    that process (route added, page never mounts); solo the same test
    passes. Split journeys into their own files — CI runs each file in a
    fresh process anyway (`feed_association_event_edit_integration_test
    .dart` exists for exactly this reason).
11. **A test that ends on /feed wedges the NEXT different-path deep link
    in the same file** — qlevar skips the middleware chain when the router
    is already on the target path, so a gate bounce followed by a
    same-path deep link mounts nothing (no redirect, no page). Order
    mount tests first, redirect/gate-bounce tests last, or give the bounce
    its own file (`tickets_edit_gating_integration_test.dart`).
12. **A page-level `GestureDetector(onTap: unfocus)` swallows the first
    tap on any button** after `enterText` (the field focus makes the tap
    hit the unfocus handler). Unfocus first:
    `tester.binding.focusManager.primaryFocus?.unfocus(); await
    tester.pump();` — then tap the button (`tickets_create_integration
    _test.dart`'s `tapSave`).
13. **scrollUntilVisible only guarantees BUILT, not VISIBLE** — a ListView
    builds into its cache extent ahead of the viewport. Follow it with
    `tester.ensureVisible(finder)` before tapping; and remember the
    FloatingNavbar overlays the bottom ~90px of the shell, so a
    bottom-aligned target is occluded (styleguide round).
14. **`thenAnswer` bodies need an explicit type argument on the response
    helper.** `chopperResponse(x)` infers `T` from the closure context; on
    the generated PATCH/POST stubs that inference collapses to `void` and
    the analyzer blames `x` (`void_checks`, "assignment to a variable of
    type 'void'"). Write `chopperResponse<EventEdit>(body)` — no
    `// ignore:` needed (the 5 remaining `void_checks` infos in the
    baseline are older files that never got the treatment).
15. **Firebase is testable, but only through the two platform fakes.**
    `FirebaseMessaging.instance` resolves `Firebase.app()`, so a test must
    install `FirebasePlatform.instance = FakeFirebaseCore()` and
    `await Firebase.initializeApp()` (the fake implements `apps`/`app`, not
    just `initializeApp`, or the very next line throws `[core/no-app]`);
    `FakeFirebaseMessaging` additionally needs `delegateFor` +
    `setInitialValues`, which `FirebaseMessaging`'s constructor calls via
    `instanceFor`. `requestPermission` returns a `NotificationSettings`
    (12 required fields — `showPreviews` takes `AppleShowPreviewSetting`,
    the rest `AppleNotificationSetting`). `FirebaseMessagingPlatform.onMessage`
    is a *static* broadcast controller: add a `RemoteMessage` to it to
    deliver a foreground push, no fake involved. The local-notifications
    plugin needs `AndroidFlutterLocalNotificationsPlugin.registerWith()` +
    `stubLocalNotificationsChannel()`. The shell's
    `setUpNotification` call is gated shut for every other test — pass
    `runNotificationSetup: true` to `makeContainer` to reopen it.
16. **`verifyNever` is unusable on the shared `MockRepository`.** It fails
    on ANY unrecorded call (the feed boot alone makes three), so "this
    endpoint was not called" has to be a counter in the stub's answer, not
    a mocktail verification.
17. **Never filter `A RenderFlex overflowed` in a test.** It hides real
    layout bugs for the whole module — the amap suite had one such filter
    and it was masking a 1-4px cash-card overflow, a 16px delivery-card
    overflow and the 73x73 `Loader` (ledgers #4/#38) for months. If a page
    overflows, fix the page: a `Text`/`AutoSizeText` in a `Row` wants
    `Expanded`/`Flexible`, and a flex child needs a FINITE width, which in
    a `Row` means the bound has to come from the enclosing card, not from
    the `Row` itself.
18. **Never sort a list the widget does not own.** `ListNotifierAPI` rebuilds
    its state list on every add/update/delete, so the list a page watches is
    unmodifiable and shared with every other watcher: sorting it in place
    during `build` is the one write of provider state that happens inside a
    build — `Cannot modify an unmodifiable list` on the first build that
    reaches the line. Sort a copy instead: `data = List.of(data)..sort(...)`
    for a closure/builder parameter, `final sorted = List.of(x)..sort(...)`
    plus render-from-the-copy for a widget field or local. `python3
    tool/detect_inplace_sorts.py` classifies every `.sort(` call under lib/ as
    cascade / copy-then-sort / review and exits 1 when a review site appears —
    run it before declaring a sort round finished, and treat each review site
    as guilty until its receiver is proven to be a local `= []` literal or a
    `.where(...).toList()` result. A `const <Type>[]` fixture is the cheapest
    possible guard: the mutation then throws in that test instead of in
    production.
19. **One router-driven page per test FILE, not per test.** qlevar_router
    keeps the active route branch in process-global state that survives a
    `ProviderContainer` swap, so the second router test in one isolate comes
    back rendering the first one's branch. Two leaks, both seen the hard
    way: `LoadingPage` navigates from `build` (`QR.to(LoginRouter.root)`),
    and simply having a page from another module mounted first left the next
    test's `/mypayment` rendering the **flappybird leaderboard**'s "Loading"
    text. `flutter test` gives each file a fresh isolate, so one page per
    file is the fix. Symptom: `find.byType(YourWidget)` is 0 while the router
    log still says `adding Route: .../your/path` — dump the rendered texts
    (`tester.widgetList<Text>(...).map((t) => t.data)`) to see whose page
    you are actually looking at.
20. **The test harness font overflows real layouts.** `flutter_test` draws
    every glyph as a square of the font size, so localized labels measure far
    wider than Roboto does: the mypayment account card's two `Row`s overflow
    by 32px and 83px at 360px wide under the harness font but have 92px and
    89px of headroom with the real Roboto TTFs (load them from
    `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts` with a `FontLoader`
    and a `TextPainter` to measure before believing an overflow). Before
    treating a harness-font overflow as a bug, measure the string with real
    Roboto; if it fits, widen the test surface instead of "fixing" the page.
21. **Unmount before the test ends when a provider stays loading.**
    Riverpod's `ProviderScheduler` defers autoDispose to a zero-duration
    `Timer`; a provider that loses its last listener during teardown arms it
    after the last pump, and flutter_test fails with "A Timer is still
    pending". Call `scaffold.unmountApp(tester)` (pump a `SizedBox` then
    pump) before the assertions' subject goes out of scope. It is also the
    only way to retire a widget's own `Timer.periodic`: feed's `EventAction`
    arms a 1s ticker (and `Timeago` a second one), and disposing the tree
    is what cancels them.
22. **A generated `copyWith(field: null)` KEEPS the old value.** Every model
    in `openapi.models.swagger.dart` is `field: field ?? this.field`, so
    passing `null` is indistinguishable from not passing the field. A
    `copyWith` fixture can therefore never reach a `field == null` branch:
    phonebook's `MemberCard` falls back to `getName()` only when `nickname`
    is null, and `.copyWith(nickname: null)` silently left "Turbo" in place.
    Build through the real constructor when the null branch is the thing
    under test. (Companion trap: `MemberComplete`'s required params are
    `name`, `firstname`, `id`, `accountType`, `schoolId`, `email`,
    `memberships` — omit `nickname` to get a genuine null.)
23. **A width-based detector cannot see a width passed as an argument.**
    `tool/detect_fixed_width_cards.py` looks for a hardcoded width beside
    flex children *in the same file*, so `CardLayout(width: 140, height: 80)`
    is invisible to it — the number is a constructor argument, not a
    `SizedBox`. loan's `ItemCardInLoan` is a real pinned 80px box that way
    and the sweep never saw it. Likewise, an *unconstrained* `Column` beside
    a `Spacer` in a `width: double.infinity` card has no hardcoded width at
    all, which is how the purchases scan row and the `CustomButton` pair
    (236px) both got past ledger #47. `CardLayout` is the one wrapper used
    widely enough to be worth a detector of its own, so
    `findFixedSizeCardLayouts()` in `shared/fixed_width_card_detector.dart`
    covers the argument form, and convention 24 says what it enforces. Both
    Python twins are gone as of ledger #62 — the Dart file is now the only
    implementation, which retires the "cross-checked only by count" debt this
    convention used to carry.
24. **A pinned `CardLayout` must be mounted by a widget test.** A card that
    fixes its own size is a card whose layout has never been measured, and the
    fix for an overflow is always "make the child elastic" — which is only
    verifiable by mounting the card at 360px with adversarial data.
    `tools/widget/fixed_size_card_layouts_test.dart` enforces it: every
    widget class that calls `CardLayout` with a literal `width:` or `height:`
    must be BUILT or FOUND (`find.byType`) by a file under
    `test/**/widget/`, or listed in its `notMounted` map with a reason.
    Three details make the check trustworthy rather than decorative:
    * **Comments and string literals are stripped** before the search. The
      fixed-width sweep's `_notMounted` map quotes class names in its keys and
      reasons (`'… OrderSection'`), and an import path is a string too — so a
      naive text search would eventually report a card as "mounted" purely
      because a hand-written exemption mentions it. "Mounted" means a
      constructor call or a `find.byType`, nothing weaker.
    * **Height counts.** The fixed-width detector deliberately skips
      height-only cards (clipping is a different question for a `RenderFlex`),
      but for a card a pinned height with an un-capped `Text` inside is the
      same hazard — that is exactly what `ItemCardInLoan` turned out to be.
    * **The ratchet is proven non-vacuous.** Deleting the `DaysEvent` mount
      fails with the card named; an exemption with an empty reason fails; an
      exemption naming a card the detector no longer finds fails. A guard
      nobody has watched fail is a guard nobody knows works.
    Pages and modals are exempt by design, not by debt: a page is measured by
    its module's integration test, and the boundary between the two levels is
    exactly what the exemption list records.
    **A "mounted" card may live in `test/shared/card_fixtures.dart`**, the
    widget level's shared fixture registry rather than a test of its own
    (ledger #62): both fixed-size sweeps mount every card in it at 360px with
    overflows fatal, so a card named there really has been measured. Scanning
    only `test/**/widget/` reported eight mounted cards as unmounted the day
    the registry was extracted, which is the kind of false alarm that teaches
    the next person to ignore a ratchet.
25. **A toast's text is not assertable in this harness, but its timer is
    real.** `displayToast` calls `toastification.show`, which renders into the
    package's own overlay. A probe test showed `find.textContaining(<message>)`
    matches **zero** widgets in a `pumpWidgetApp` tree even though the toast
    was raised — `ToastificationWrapper` is mounted, so this is the package's
    overlay, not a missing ancestor. Meanwhile `ToastificationItem` arms a
    2.5s `PausableTimer`, so any test that raises one MUST end with
    `drainToast` or it fails on "A Timer is still pending".
    The consequence is a whole class of tests that look written and assert
    nothing: `expect(find.text(<toast copy>), findsOneWidget)` fails loudly
    (good), but `expect(find.text(<string that also appears inline>),
    findsOneWidget)` **passes vacuously** — `paiementPleaseAcceptTOS` is both
    a toast and part of the TOS dialog's markdown body, so a test asserting it
    after tapping Top-up was really asserting the dialog was still up.
    So never assert a toast's copy. Assert the state the toast was reporting:
    * a guard refused → assert **no repository call happened** and the surface
      stayed put (`mypayment_fund_integration_test.dart` does this for both
      amount guards, which is also what makes them distinguish each other);
    * an action succeeded → assert the observable effect (the sheet popped,
      the list item changed status, the launch was recorded);
    * and if the message genuinely is the only signal, keep the test but say
      in a comment that it is asserting the surrounding state, not the copy.

26. **Assert that a provider mutation NOTIFIES, and that it does not mutate
    the object already in state.** Mutating a collection in place and asserting
    its *contents* is a test that cannot fail: `container.read` returns the very
    object you just mutated, so the contents look right while the app is
    frozen. Two dimensions are missing from that kind of assertion and both
    have to be asserted explicitly.
    * **Notification.** Riverpod's
      `ProviderElement.defaultUpdateShouldNotify` is `previous != next`, and for
      a `Map`/`List` `==` is *identity*. So the shape
      `state[t] = …; state = state;` — written to "poke" Riverpod after an
      in-place write — compares the map with itself, returns false, and
      notifies nobody. It looks like it works because the data really did
      change. Assert with `container.listen(provider, (prev, next) => …)` and
      count the calls.
    * **No aliasing.** Even a notifying provider is wrong if it mutated the
      previous snapshot, because a listener holding `previous` then sees a
      change it was never told about and `previous`/`next` both describe the new
      world. Assert `identical(before, notifier.state)` is **false** after a
      mutation, and that a list captured beforehand still has its old length.
    This is the whole reason ledger #51's six defects survived: every test
    touching them asserted contents, and contents are what in-place mutation
    changes.
27. **A Dart raw string does not interpolate.** `r'...$_fragment...'` compiles
    to a pattern containing the literal text `$fragment`. That is still a valid
    regex, it simply never matches, and nothing anywhere reports an error — the
    detector behind `tools/unit/inplace_list_mutations_test.dart` went from 21
    findings to 115 with no visible symptom. Spliced regex fragments are built
    by **concatenation** (`r'\b' + _typed + r'…'`) and never by interpolation
    inside `r'…'`. The generalisation of "it compiles" to "it works" is the
    trap; convention 26's "does it notify" is the same shape of mistake one
    level up.
28. **A fake that returns a constant DELETES the branches the other states
    would open.** `flutter_test` cannot tell a deleted branch from a covered
    one, so the suite stays green either way — the audit that finds these is
    asking a different question than the suite: *for each override fake, what
    is the full set of states the real notifier can return, and how many of
    them can this fake produce?* If `lib/` branches on more than one and the
    fake can only ever answer one, every other arm is dead code from the
    suite's point of view. Ledger #55 found three such fakes; two of them
    had put `UpdatePage` (0/12) and `NoInternetPage` (0/31) out of reach of
    any test ever written. Two habits fall out:
    - **When a fake is a branch point, make it parameterised.** `makeContainer`
      now takes `titanVersion`, `minimalTitanVersionCode`,
      `minimalHyperionVersion`, `permissionCatalog`, `failVersionVerifier`
      and `versionVerifierRecoversOnRetry`; each exists because a default
      could not express one state of the real provider.
    - **Every test that opens such a branch ends with a guard asserting the
      branch's own predicate**, not just the page it renders. Mounting
      `UpdatePage` passes whether or not `1 <= 999`; asserting
      `minimal <= titanVersion` is `false` is what makes the file mean
      something. Three such guards exist (one per finding) and each is
      proven against `git show HEAD:`.
29. **Assert the thing the OTHER side reads, not the thing your side renders.**
    A widget being present says nothing about what it carries, and the
    carrying is often unobservable from the widget tree. Three traps in one
    place, from ledger #58:
    - `QrImageView.data` is **private** and the `qr` package ships **no
      decoder**, so nothing can be asked what the code contains.
    - `QrPainter` is a `CustomPainter`, **not a widget** — `find.byType`
      cannot see it; it must be pulled off the `CustomPaint`.
    - `find.byType(QrImageView)` **passes on a failed code**: an invalid
      payload renders a bare `Container()` with no `CustomPaint` at all.

    The fix is to intercept one layer down, where the payload is still plain
    text, and assert the **consumer's** view of it. Here that is
    `FakeKeyService.signedMessages` (the bytes `getQRCodeContent` signs) fed
    through `BarcodeNotifier.updateBarcode` — the exact call a seller's
    scanner makes. Covering the other side of a hand-off is the whole point of
    an integration test; asserting that both halves rendered is not.
30. **A test that renders the WRONG page is not a failing test, it is a
    passing one.** Convention 19's leak has no symptom anyone would notice:
    qlevar_router keeps the active route branch in process-global state, so a
    page left mounted by an earlier test in the same isolate is what the next
    deep link really renders. The affected test finds **zero** of its own
    widgets, its `expect`s match nothing, and it passes — the router log even
    says `adding Route: …/mypayment` while the tree shows flappybird's
    leaderboard. That is the worst possible failure mode: the suite is green
    and the file asserts nothing.

    `pumpApp` now ends by asking the tree a question the test was implicitly
    asking anyway — *is the page I asked for the page on screen?*
    `test/shared/page_module_guard.dart` indexes every `class *Page` in `lib/`
    to the module that declares it, derives the module under test from the
    call stack (`test/<module>/`, skipping `test/shared/` frames), and fails
    the test naming the foreign class, the module that owns it and the file
    that declares it. Three details keep it honest rather than decorative:
    - **It runs AFTER the settle**, because deferred loading means the page
      under test is not in the tree until the route resolves; checked earlier
      it would read an empty tree as "nothing foreign".
    - **The index is `*Page`-suffixed on purpose.** Every routed page is a
      `*Page`; the wrappers that are legitimately shared across modules end
      in something else (`AppTemplate`, `PaymentTemplate`, `ModuleCard`), and
      indexing those would flag every module's shell as foreign to every
      other one.
    - **`allowedModules` names MODULES, not classes**, and is required to be
      deliberate: a gate-bounce file declares `allowedModules: {'feed'}` (the
      bounce IS its subject), and a *third* module appearing later still
      fails. All 16 files that cross module boundaries on purpose now say so
      with the reason beside the parameter — the same discipline as a
      `_notMounted` exemption, and the same rule applies: the reason is
      unverified until the guard is watched failing something.
    Generic names collide (`AdminPage` in eight modules, `DetailPage` in
    five) because a runtime type carries no library, so the index keeps every
    module that declares a name and treats a name as foreign only when NO
    allowed module declares it. That is the weaker but honest question, and
    `tools/unit/page_module_guard_test.dart` pins all four halves: the index
    finds the leak page, a genuinely foreign page is reported, the allow-list
    silences it, and the failure message names the class, the owner and the
    fix.

31. **A `Row` may not put a `Spacer` next to an unbounded `Column`/`Text`.**
    `Row` hands every non-flex child unbounded width, so the label sizes to
    its intrinsic width and never wraps to the row; once that width passes
    the row's, the `Spacer` has no slack left and the whole row paints past
    the right edge. This is ledger #47/#48's family — `AdminAdvertCard`
    shipped 37px over, purchases' scan `TicketCard` 149px over, the header
    `CustomButton` pair 236px over — and
    `tools/unit/row_spacer_detector_test.dart` is its static rule: it scans
    `lib/` through `shared/row_spacer_detector.dart` and fails on ANY Row of
    that shape outside its `knownHazards` pin list. The fix is one shape:
    wrap the child in `Expanded` (with a one-line ellipsis when it is a
    title) and drop the `Spacer`.    A pin carries the same burden as
    a `_notMounted` exemption — a reason, and removal the moment the row is
    fixed. The list includes `AdminPhCard`'s row: the CAUSE of the 320px
    overflow the width sweep pins only by its symptom.

32. **A provider build that throws is RETRIED, not failed — the error you
    are waiting for is ~31.6 fake seconds away.** Riverpod 3's container has
    a `defaultRetry` (10 attempts, 200ms doubling to a 6.4s cap ≈ 31.6s
    total) that applies to any build failure, and until it is exhausted the
    state reads `AsyncLoading(error: …)` — a *retrying* loading, not the
    terminal error. During that window `provider.future` PENDING: a
    `try { await provider.future } catch` in a tap handler never reaches its
    catch, `AsyncChild`/`when(loading:)` show the spinner, and the toast the
    catch was supposed to raise never appears. Symptoms are a missing error
    assertion with no exception anywhere, or a state printed as
    `AsyncLoading<Uint8List>(error: Exception: …)` after the test has long
    settled. Two facts make it tractable:
    - **One long `await tester.pump(const Duration(seconds: 40))` jumps the
      whole chain**: fake-async fires each chained backoff timer as the clock
      elapses, so every rebuild-and-fail in the sequence runs inside the
      single pump. Then `settle` and the catch lands on the next microtask.
    - **`defaultRetry` declines `Error` and `ProviderException`** (it only
      retries `Exception`s) — which is why an unstubbed mock
      (`MissingStubError`, an `Error`) fails instantly while a mocked
      `thenThrow(Exception(…))` stalls: both look like "the stub threw",
      only one of them comes back.
    The rule: any test whose subject is a provider's ERROR path owes one
    40s pump before it may expect an error widget, toast or text — and it
    earns its place by then asserting the terminal state (`AsyncError` /
    the toast), not the retrying one.

33. **Real file IO inside `testWidgets` never resumes.** An
    `await File.writeAsBytes(...)` (or `Directory.systemTemp.createTemp`)
    inside a `testWidgets` body hangs until the 30s timeout with no error
    and no output — the dart:io completion never comes back to the fake-async
    zone. The same code works in a plain `test()` and in `setUpAll`, so the
    failure looks like a bug in whatever the IO was feeding (a picker
    result, a fixture) rather than in the IO itself; a bare probe file that
    only writes one file is the two-line experiment that separates the two.
    Fixtures must therefore be **byte-backed**: `stubPick` in
    `test/shared/file_picker_stub.dart` builds a `PlatformFile` with
    in-memory `bytes`, which `readAsBytes()` returns before touching any
    path (`FilePicker.readAsBytes` checks `bytes` first), with `size` set to
    the length the app's size checks compare against. When a test needs a
    file "on disk", it needs the bytes; the disk is the thing that hangs.

## Scaffold API (`app_scaffold.dart`)

- `IntegrationScaffold.repository` — the `MockRepository` (mocktail).
- `FakeMobileScannerPlatform` — the mobile_scanner test double: replace
  `MobileScannerPlatform.instance` with it before pumping any camera
  surface (restore the previous instance in tearDown). `emitScan(payload)`
  feeds a scan onto the real barcode stream; the camera view is a blank
  box. The scan flow's 5s anti-double-scan gate compares wall-clock time,
  which fake-async pumps cannot advance — clear `lastTimeScannedProvider`
  to simulate the elapsed window (see the mypayment scan-modal tests).
- `makeContainer({user, userId, seedAsyncUser, myAssociations,
  myStructures, bankAccountHolder, selectedStructure, invoices,
  myManagerRoles, myLoaners, groups, runNotificationSetup,
  failVersionVerifier, versionVerifierRecoversOnRetry, titanVersion,
  minimalTitanVersionCode, minimalHyperionVersion, permissions,
  permissionCatalog})` — full session fakes; `runNotificationSetup` reopens
  the shell's FCM gate (ledger #35's file); `userId` overrides the
  JWT-derived `idProvider` (needed by raffle/amap pages); `seedAsyncUser` pins
  `asyncUserProvider` to `user` (opt-in: pages that SAVE through it, e.g.
  EditProfile, need it — `SingleNotifierAPI` silently refuses updates while
  loading; leaving it unseeded shifts nothing for older shells, amap's quirk
  filtering depends on that); `myAssociations` pre-seeds the advert/feed admin
  gate; the mypayment args pre-seed the admin-gate and invoice-list state (see
  known bugs 8-9); also fakes `keyServiceProvider` (a real `getKeyId()`
  Future), `shouldSetupProvider`, `firebaseTokenProvider`; `groups:` pre-seeds
  the derived `allGroupList` provider — pages resolve group names from it with
  bare `firstWhere` calls (known bugs 19-20), so the list must hold the wanted
  ids BEFORE the first build, not arrive via a stubbed `groupsGet` mid-flight;
  `purchasesSellers:` pre-seeds the purchases seller list (the scan-route admin
  gate and the scan page's seller chips derive from it).
- `makeContainerWithModules({user})` — adds the module catalog chain
  (asyncUser/permissions) for pages backed by `modulesProvider`.
- `makeLoggedOutContainer({authRepository})` — signed-out session for the
  login page; pass a real `AuthRepository` to exercise the sign-in flow.
- `makeSignInFlowContainer({authRepository})` — like the logged-out one but
  WITHOUT the isLoggedIn fake: the real session derivation flips from the
  token error state to the token the flow produces, so middlewares see the
  genuine transition and replay the pre-auth deep link.
- `pumpApp(tester, container, {initialPath, pumpAndSettle, allowedModules})` —
  real `QRouterDelegate` + `AppTemplate`; sets the navbar animation
  controller. Ends by running the page-ownership guard (convention 30), so a
  test that rendered another module's page fails HERE rather than passing
  vacuously. `allowedModules` names the modules this test expects to end up
  on beyond its own — a gate bounce, a redirect, a page that lives in
  `lib/navigation` or `lib/others` — and each one needs the reason in a
  comment; 16 files say so today (ledger #61).
- `pumpWidgetApp(tester, child, container, {surface, appFonts, locale})` — the WIDGET-level
  shell: `UncontrolledProviderScope` + `ToastificationWrapper` + a plain
  `MaterialApp` with the real l10n delegates and the widget as `home`. No
  router, no `AppTemplate`, no deep link, no navigation journey — so no
  convention 1/10/11 bookkeeping. `surface` defaults to a **360x640 phone**
  (pass `setWideSurface`-style sizes only when a card is genuinely desktop
  only); it is restored in tearDown. `appFonts` defaults to `true`, which
  loads the bundled Lato faces and stubs network images; pass `appFonts: false`
  explicitly only when a widget-level test does not render any text and must
  stay fast. `locale` pins the strings the widget resolves (prime BOTH arb
  libraries in `setUpAll` first — the deferred `loadLibrary()` behind
  `AppLocalizations` only ever completes for a file's first genuine load).
  Overflows are fatal here, which is the point (ledger #39).
- `pumpWidgetAt(tester, widget, {container, surface, appFonts, locale, frames})` —
  the top-level GENERAL mount: any widget, any size, under the same shell
  `pumpWidgetApp` builds, with `container` OPTIONAL — a widget that reads no
  providers mounts without a scope at all. `surface` defaults to the 360x640
  phone, `appFonts` to true (real glyphs + image stubs), `frames` to 4.
  Reach for it in one-off widget probes; suites that seed a container keep
  using `pumpWidgetApp`.
- `stubUrlLauncher(FakeUrlLauncher(launchSucceeds:))` + `launches` — url_launcher's
  platform side. `LaunchRecord` (url + `useSafariVC`, `useWebView`,
  `universalLinksOnly`, `enableJavaScript`, `enableDomStorage`) is what the fund
  flow's hand-off is asserted through, because `LaunchMode` itself never
  reaches the platform: `launchUrl` decomposes it into those booleans before
  delegating, and `useWebView` is the only observable difference between
  `externalApplication` and `platformDefault` for an http(s) URL (ledger #60).
- `stubInformation()`, `stubProfilePicture()`, `stubFeed()`.
- `stubClipboard(tester)` — in-memory Clipboard platform-channel handler
  (convention 9).
- `stubLoggerOutput(output)` — wires `loggerProvider` to a fake
  `LoggerOutput` so log-page shells render from in-memory lists instead of
  the on-disk log file. Call BEFORE `makeContainer()` (overrides apply at
  construction).
- `makeContainer` also takes `myStores:` (list of `UserStore`) and
  `storeSellers:` (map store-id → seller list) — the tickets admin gate
  (`canManageTicketEventsProvider`) chains those two repository-backed
  providers and the middleware evaluates them at deep-link time, so both
  must be pre-seeded (same trap as known bug 9).
- **`shellSetUp()`** — the standard preamble (binding init, `QR.reset`,
  shared-prefs mock, `stubInformation` + `stubFeed`); every shell file's
  `setUp` is now `scaffold = IntegrationScaffold(); scaffold.shellSetUp();`
  plus file-specific stubs. `stubAdminMainPage()` covers the admin main
  page's background loads that admin sub-page shells mount underneath.
  Never re-declare these lines by hand.
- `setWideSurface(tester)` — 1920×1080 logical viewport; the default
  800×600 overflows wide rows on card-list pages (call at test start).
- **Modal drivers** — bottom-sheet flows go through these instead of
  hand-rolled pump sequences: `openModal(tester, finder)` (tap + pump the
  slide-in), `tapInModal(tester, finder)` (tap inside + pump transitions),
  `closeModal(tester)` (pop + pump), `isModalOpen(tester)` (dismissible
  ModalBarrier probe). Modals render on the ROOT navigator, so plain
  finders reach into them. Flow tests must also drain the toast
  auto-close timer afterwards (`pump(Duration(seconds: 3)) + pump()`).

Router constants are **fragments** (`VoteRouter.detail` == `/detail`):
deep-link paths must be `'${XRouter.root}${XRouter.detail}'`.

- `makeContainer(holdVersionVerifier: true)` swaps the version verifier for
  `FakeHoldingVersionVerifierNotifier`, which never resolves. `LoadingPage`
  answers to it with a `when`, so a resolved verifier routes the boot screen
  to login/update on the first build and the thing under test is gone before
  it can be measured. Flags, not an `overrides` list — Riverpod 3 exports no
  `Override` type.
- The verifier has THREE states in `lib/` and the harness now reaches all
  three (convention 28, ledger #55):
  - `makeContainer(titanVersion: N, minimalTitanVersionCode: M)` — the
    comparison `minimalTitanVersionCode <= titanVersion`, repeated in
    `AuthenticatedMiddleware`, `AppTemplate` and `LoadingPage`. Defaults
    (`M: 1`, no `titanVersion` → `999`) leave it always true, which is what
    held `UpdatePage` at 0/12; pass `titanVersion: 1, minimalTitanVersionCode:
    1000` to open the update branch.
  - `makeContainer(minimalHyperionVersion: '4.2.0')` — `RollbackPage` prints
    it, and the real notifier reads `pubspec.yaml` through `rootBundle`, which
    a test asset bundle does not carry.
  - `makeContainer(failVersionVerifier: true)` — the `error:` state, which
    both of its `error:` arms route to `/no_internet`. Pair with
    `versionVerifierRecoversOnRetry: true` for the retry-button case.
    Without these two flags `NoInternetPage` was 0/31.
- `makeContainer(permissionCatalog: ['booking.access', …])` seeds the
  permission CATALOG (the module-prefixed names the backend knows). Left
  alone it is `[]`, and an empty catalog makes `computeUserModuleRoots`
  return `[]` for every user — so a test that needs the module list to be
  anything at all has to pass it (ledger #55).
- `makeContainer(permissionCatalog: ['booking.access', …])` seeds the
  permission CATALOG (the module-prefixed names the backend knows). Left
  alone it is `[]`, and an empty catalog makes `computeUserModuleRoots`
  return `[]` for every user — so a test that needs the module list to be
  anything at all has to pass it (ledger #55).
- `unmountApp(tester)` unmounts the tree inside the test body and pumps
  once, so Riverpod's zero-duration autoDispose timer has a frame to run in
  (convention 21).
- `makeContainer(deviceKeyId: ...)` decides what `KeyService.getKeyId()`
  answers, and `keyId` is a **mutable field** on `FakeKeyService` so a test can
  reach the branches that read the key a SECOND time after the first read
  passed. Null is the "no device registered" answer, which is what most tests
  want — it is the pay sheet's `showNotRegisteredDeviceDialog()` gate.
  `FakeKeyService` also does REAL in-memory Ed25519 (`getKeyPair` +
  `signMessage`), so a test can assert a real 64-byte signature over a
  request envelope rather than a stubbed string. Since ledger #58 it also
  **records** what it signs — `signedMessages` (the exact string handed to
  `signMessage`, oldest first) and `keyPairForTest` (the pair, once asked
  for, so a test can verify a signature with the device's PUBLIC key). That
  is the only way to see the pay flow's QR payload, since `QrImageView.data`
  is private and `qr` ships no decoder; see convention 29.
- `FakeUrlLauncher(launchSucceeds:)` + `stubUrlLauncher(fake)` — a
  `url_launcher_platform_interface` fake that records every launched URL in
  `fake.launched`, restoring the previous instance on teardown. It overrides
  `launch` (not `launchUrl`) because the base-class `launchUrl` is the
  non-virtual helper that decomposes `LaunchOptions` into the named flags, so
  that is the only place a launch can be observed however it was requested.
  This is how the fund test proves the top-up actually leaves the app for
  HelloAsso instead of merely clearing its own amount field.
- `loadAppFonts()` / `appTheme` / `pumpWidgetApp()` register the
  bundled Lato + Roboto + Silkscreen + ElMessiri faces from
  `assets/google_fonts/` and hand the app a Lato-themed `ThemeData`. Every
  widget-level `pumpWidgetApp()` now loads them by default, so no overflow
  assertion anywhere is still measured with the harness font.
- `stubNetworkImages()` (implied by loading fonts) serves a 1x1 PNG for
  every image request via `HttpOverrides`. A widget that builds an
  `Image.network` from a URL literal — `LinkCard` draws its module logo that
  way, with no provider to stub — otherwise dies with
  `NetworkImageLoadException` before it lays out.

Shared helpers live in `test/shared/app_scaffold.dart` — `chopperResponse(body)`,
`chopperListResponse(list)`, `chopperResponseVoid()`,
`settle(tester, {frames})`, the fixture builders `structure(id, name,
userId)`, `history(id, direction, total)`, `myPaymentStore`, plus the
scaffold methods above. Do **not** redeclare them locally; import
`app_scaffold.dart` and use them directly.

## Generated adapter & extension tests (module-agnostic codegen)

Two generators cover the file kinds whose shape repeats across modules. Both are
MODULE-AGNOSTIC: neither contains a module list; they walk `lib/<module>/adapters/`
and `lib/<module>/extensions/` (plus top-level module dart files for extensions),
and write each test into that module's OWN folder. Adding a new module needs no
generator change — create the sources, run the generator, its tests appear.

| Generator | Reads | Writes | Notes |
|---|---|---|---|
| `dart run tool/gen_adapter_tests.dart` | `lib/<m>/adapters/*.dart` | `test/<m>/adapter/<name>_adapter_test.dart` | Parses each `extension $X on T { ... }`, emits one test per extension member. Receivers and method parameters are built from `test/generated/openapi_mock_factories.dart` (`MockX.any`), so the members EXECUTE, not just compile. Methods with model parameters get `MockY.any` arguments. |
| `dart run tool/gen_extension_tests.dart` | `lib/<m>/extensions/*.dart` (and module-top-level files with `extension` decls) | `test/<m>/extension/<name>_extension_test.dart` | EXECUTION-level: one test per extension declaration that CALLS every parsed member. Receiver by type kind — generated model → `MockT.any`, plain enum → `T.values.first`, `chopper.Response` → a real 200 Response. Three receiver passes per declaration for branch coverage: `.any` (inert state), a populated pass (`copyWith` of the model's nullable String fields, from the `withFields` signature), `T.empty()` (all-null/empty arms) and `T.empty().copyWith(id:)` (populated-id arms). Measured coverage of `lib/*/extensions/*`: **100%.** |

Known limitation of the adapter generator: it builds receivers with inert
`MockT.any` defaults, so a time-dependent branch indexed on `DateTime.now()`
(`ticket_event.dart` line 12, `user_ticket.dart` line 17) can never be reached
by generated fixtures — those stay at 99.4%. Reaching them honestly needs clock
injection (a `now` parameter on the extension), not faked dates; if the branch
matters, hand-write the two lines into the module's handwritten file.

Behavior:

- Run with no flags: writes files whose content would change, reports `drift:`
  (and exits 1) for files whose on-disk content no longer matches what the
  generator would emit. CI/regen runs surface stale generated tests.
- `--overwrite`: rewrite all files.
- `lib/generated/` is always excluded from BOTH generators; `lib/<m>/adapters/`
  is excluded from the extension generator so one source never produces two
  overlapping test files.
- Deleting a module does NOT delete its generated tests automatically — remove
  the stale `test/<m>/` folder by hand (or the test suite fails compile).

Known fix history for these generators (do not re-break):
repo root resolves from the SCRIPT location (`tool/..`), never `Directory.current`
never `../..`; extension test names escape a leading `$` (an unescaped
`'$UserTicket on …'` inside a single-quoted string compiles as an interpolation
and fails with Undefined name); `existingTestFileFor` matches the generator's
own single-quoted import line; the extension output path is always
`test/<module>/extension/` regardless of the source's subdirectory.
Directed checks, counter-based stubs and the rest of the inventory continue
below.

## File inventory (module/integration/, shared helpers in test/shared/)

| File | Covers |
|---|---|
| `shared/app_scaffold.dart` | shared shell (see API above) |
| `shared/page_module_guard.dart` | the page-ownership guard (convention 30, ledger #61): `pageModuleIndex()` maps every `class *Page` in `lib/` to the module that declares it, `moduleOfTestFileFrom()` / `currentTestModule()` read the module under test off the call stack, `foreignPagesMounted()` reports the pages on screen that no allowed module owns, and `assertNoForeignModulePages()` fails with the class, its owner, the file that declares it and the fix. Called at the end of every `pumpApp` |
| `tools/unit/page_module_guard_test.dart` | the guard's own test: the index finds the leak page and keeps both modules for a colliding name, the stack read skips harness frames, a foreign page really is reported, an allow-listed module really is not, and the failure text names the class, the owner and the remedy (ledger #61) |
| `purchases/integration/purchases_integration_test.dart` | purchases main page (canonical example) |
| `service/integration/local_notification_service_integration_test.dart` | local notifications through the mocked `dexterous` method channel (Android `registerWith()` first — no test env registers the platform impl): init/show/periodic/image/cancel wrappers, groupNotifications empty-vs-inbox branches, pending query hit+miss, decode handlers; one boot+QR.to journey proving the click listener navigates a mapped module (qlevar STRIPS the scheme from `test.titan:///advert?...`, so /advert mounts and the auth gate lands on /feed) |
| `amap/widget/amap_cards_widget_test.dart` | WIDGET level: `OrderUI` (long date + 3 products + `12500.00€`, plus its detail state, a text-scale sweep at 1.3/1.5/2.0x and the main page's 195px strip bound), `ProductCard` (long category/name, no-button 130px variant), `UserCashUi` (five-figure balance, long nickname) — each mounted alone at 360x640, so any overflow is fatal |
| `raffle/widget/raffle_cash_card_widget_test.dart` | WIDGET level: the raffle flip cash card's front face with a five-figure balance and a long nickname, plus the no-nickname full-name branch |
| `mypayment/widget/payment_delegate_widgets_test.dart` | WIDGET level: the whole payment-delegation family, which sat at **exactly zero** coverage (247 lines in `paiment_delegate/` + 91 in the two modals that host it) — `ProductCard`, `WalletBalanceCard` (data/loading/error), `CountdownTimer` (mm:ss, the 30s urgency threshold, `onFinished` once, and the `fullDurationSeconds` case where the ring must start nearly empty), `FeedbackOverlay` both marks, `ConfirmButton` (dispatch, the `totalSeconds: null` never-expire case, and the expiry that greys it out and kills the tap), `PaimentDelegateModal` (idle stack, already-expired drops the timer, loading→success→pops, cancel overlay, and the `onRefuse` delegate path that deliberately shows NO overlay), `RequestDetailModal` across all four statuses, and `showRequestModal` end to end including a real Ed25519 signature |
| `mypayment/integration/mypayment_pay_integration_test.dart` | the pay sheet (`pay_page.dart` + `confirm_button.dart` + `qr_code.dart`): the three gates to the sheet (TOS, no key, unknown device), keypad to cents, leading-comma seeding, backspace, the biometric + key-refused paths, and the QR sheet itself — which is where the round's 420px overflow fix lives. Extended by ledger #58 with the HAND-OFF rather than the sheet: the cents the buyer typed asserted as the envelope's `tot` through the real `BarcodeNotifier` parser, the code proven to have painted modules (an unscannable payload renders no `CustomPaint`), the wallet + history refetch that closing the sheet triggers, and the fail-closed sheet when the wallet will not load |
| `mypayment/widget/store_admin_cards_widget_test.dart` | WIDGET level: `SellerRightCard` (the module's biggest uncovered file, 87 lines, previously only reachable through the store-admin page) and `DeviceItem` (actual + revoked rows) |
| `mypayment/widget/pay_qr_code_widget_test.dart` | WIDGET level: `QrCode`, the far end of the pay flow's hand-off. Asserts the signed payload's fields (`tot` in whole cents, `key`, the hard-coded `store: true`, a fresh `iat`) by feeding `FakeKeyService.signedMessages` through the consumer's own parser; that the signature is a real 64-byte Ed25519 which **verifies** and which **fails** verification on a tampered `tot`; that the code painted modules rather than the error box; the viewport fallback when the box is unbounded (unreachable from the sheet, which wraps it in a `Flexible`); and that a rebuild re-signs under a fresh transaction id (known bug #59) |
| `mypayment/unit/funding_url_provider_test.dart` | UNIT level for `fundingUrlProvider`: `build()` fetches nothing (a funding URL is a transaction, so a build-time fetch would mint a HelloAsso session nobody asked for), `getFundingUrl` posts the `TransferInfo` verbatim — the cents conversion and the redirect URL are the BUTTON's job, and a provider that quietly rescaled the amount would make the button's boundary tests lie — a refused POST and a 200-with-no-body both become `AsyncError` (`requireValue` then throws rather than handing back a stale URL), a thrown transport error does too, and a good URL is replaced by the next attempt (ledger #60) |
| `mypayment/integration/mypayment_fund_integration_test.dart` | the top-up sheet (`fund_page.dart` + `confirm_button.dart`, also zero coverage) and the HelloAsso hand-off (ledger #60): the TOS gate on the card, the cap printed from the wallet AND the TOS response, keypad to amount with leading-comma seeding and backspace-to-empty, the minimum guard, the cap boundary (950 accepted with 50 held, 951 refused with the amount intact), the `TransferInfo` POST (cents, and the exact `test.titan://mypayment` redirect), the `LaunchMode.externalApplication` hand-off asserted through the flags `launchUrl` decomposes it into, a failed TOS self-registering once and healing, and the two KNOWN BUG tests — a failed launch that reports nothing and has already discarded the amount, and a missing wallet that fails the cap OPEN |
| `mypayment/widget/fund_page_widget_test.dart` | WIDGET level: the cap-zeroing branch of `ConfirmFundButton` that the UI cannot reach (the card's `hasAcceptedTosProvider` gate closes the sheet first), the fail-open balance addend with a control showing the same amount refused when the wallet does load, and that the typed amount lives in `fundAmountProvider` rather than local state |
| `phonebook/widget/phonebook_cards_widget_test.dart` | WIDGET level, the module's first: `AssociationCard`, `EditableAssociationCard`, `MembershipCard` (its title is the "association - role" concatenation), `MemberCard` in both the nickname and no-nickname branches of `getName()`, and `AssociationGroupementBar` in its horizontal (40px strip) and vertical (`min(count * 52, 220)`) modes plus `AssociationResearchBar` with the filter affordance offered. No phonebook card is a fixed-width candidate — they all render through `ListItemTemplate`'s `Expanded`, so this file is what proves the family rather than assuming it |
| `purchases/widget/purchases_cards_widget_test.dart` | WIDGET level: both `TicketCard` classes (the main-page list row incl. its sold-out state, and the scan-page row with a five-figure use limit), and the main page's `CustomButton` header pair in the page's own `Padding(all: 30) > Row(spaceBetween)` shape with short and long labels, plus a lone button in a bare `Row`. Found the round's three defects — ledger #48 |
| `tickets/widget/tickets_rows_widget_test.dart` | WIDGET level: the sweep's four width-pinned tickets cards leave eight leaf widgets, all here — `TicketEventCard` mounted once per `TicketEventStatus` (reached by moving a date, since the status is a computed extension on `disabled`/`openDatetime`/`closeDatetime`, and each state is a different trailing chip width), `SectionCard`, `StatTile` at its real half-width with a five-figure value and total, `SwitchRow` editable and read-only, `SoldOutBadge`, `ReadOnlyBanner`, and all four status chips in one row. The value assertion needs `findRichText: true`: it is a `RichText` of two spans |
| `feed/widget/feed_cards_widget_test.dart` | WIDGET level: `EventCard` (the 851x315 `AspectRatio` banner with its `Positioned(bottom: 53)` badge) in all three badge states, `EventCardTextContent` (a `size.width - 140` box holding a 30-char-truncated title and a location on ONE line) with and without a location, `EventAction` in all four button states including the waiting branch, `AssociationEventCard`, and `AdaptiveTextCard` with and without an image. The banner's image is fetched through an `AutoLoaderChild` on first build, so the 404 stub is what stops the card dying before it lays out |
| `loan/widget/loan_cards_widget_test.dart` | WIDGET level: `ItemCardInLoan` — a card the width-based detector MISSED, because it hands `CardLayout(width: 140, height: 80)` a number instead of hardcoding it, and the pinned 80px box holds a quantity `Text` with no line cap — in both quantity branches, `LoanersBar` (40px chip strip, long loaner names), the two `DateEntry` rows, `NumberSelectedText` folding 40 items x N into one count, and the borrower `SearchResult` row. A sync `NotifierProvider` has no `.future` in Riverpod 3, so the notifier's own `loadItemList` is what gets awaited |
| `cinema/widget/cinema_cards_widget_test.dart` | WIDGET level: the sweep mounts both cinema cards with a long name and every other field empty, so this file remounts them with a full TMDB record (tagline, genre, a 2h25min runtime, a multi-sentence synopsis) and adds the two widgets the sweep has no reason to know about — the `CinemaTemplate` shell and the `TmdbButton` pill in its icon and `Loader` states. `SessionCard` is mounted in BOTH `isWebFormatProvider` branches, each at a surface where the provider really returns true or false |
| `centralisation/widget/centralisation_cards_widget_test.dart` | WIDGET level for `ModuleCard`, which the width sweep had registered as mounted **and** exempted in the same file — the exemption suppressed the test while the ratchet counted it as covered, so `module_card.dart` sat at 37/37 uncovered behind a green sweep on a reason (`needs the modules map seeded`) that was simply false. The exemption is deleted, `_Card` grew a per-card `wrap` parent (the card's `Column` holds an `Expanded`, so it needs the bounded grid cell it actually lives in — `SliverGridDelegateWithMaxCrossAxisExtent(130)`), and the card is mounted here for real: favourite star state, a tap that toggles both ways, a 42-char name through `AutoSizeText`, and the `.svg` branch. That last one needed `stubNetworkImages` to answer `HttpClient.openUrl` and serve real SVG bytes — `flutter_svg` loads through `package:http`, not `NetworkImage`, so the branch had never been mountable. `LikedCard` is here too because the pair differ structurally: it pins 92px and has a rigid 36+8+30 column, which the 135px favourites strip in `main_page.dart` is built around and a 60px parent overflows |
| `super_admin/widget/super_admin_widgets_test.dart` | WIDGET level for the module's leaf widgets, none of which read the router (so the whole thing mounts without the `SuperAdminTemplate`→`TopBar`→`QR.currentPath` trap that keeps the pages themselves at integration level): `PermissionRow` in both states plus its one-line ellipsis, `PermissionTile`'s two counters, `SchoolUi` including the two reserved ids whose delete button is hidden, `SchoolButton`'s gradient, `SuperAdminButton`, `TextEditing`. The bulk is `PermissionDetailModal` (193 lines) pushed as a real bottom sheet: it renders both sections from l10n, finds the permission under its **module-prefixed** name (`core.admin` → `admin`, the lookup `permissions.dart` depends on), no-ops every callback when the permission is unknown, posts authorize/unauthorize with the right body, and surfaces a rejected write as a snackbar instead of a silently dropped tap |
| `service/integration/setup_notification_integration_test.dart` | `setUpNotification`'s authorized branch behind `runNotificationSetup: true`: the plugin initializes, the FCM token expiry is persisted under the signed-in id (~30 days), `getTopics` hits the endpoint twice (the notifier's build + the refresh), the gate flips to false, and a foreground push delivered through `FirebaseMessagingPlatform.onMessage` shows a notification whose payload carries the data map's routing fields |
| `service/integration/setup_notification_denied_integration_test.dart` | the denied half in its own file (one deep-link boot per file): the plugin still initializes, no token date is written, **zero** topic calls and `topicsProvider` is never instantiated (ledger #36 fixed — the counter used to sit at 1), the gate still flips |
| `service/unit/setup_notification_cache_test.dart` | drives `setUpNotification`'s 30-day token cache against the REAL expiration notifier (the shell's `FakeFirebaseTokenExpirationNotifier` short-circuits the condition for every test user, which is why the branch was dead): valid cache honoured (no saveDate, one topics call), expired date re-registers, a null expiration registers instead of throwing on `expiration!`, another user's date never reused, plus a COLD-BOOT case that never touches the provider first and so pins the `notifier.ready` await (ledgers #35/#43) and an INFO-LEVEL capture that the "registered" line really reaches the output (ledger #44). **Ledger #54** adds the poisoned-row recovery: the row is seeded with the literal string `"null"` (NOT the real JSON null the older case uses — that helper's `expiration?.toString()` is null-aware, so the older test exercised the guard and never the parser), and asserts no exception escapes, the token re-registers, and the bad row is overwritten with a real date |
| `tools/widget/fixed_width_cards_test.dart` | THE overflow sweep: every widget class in `lib/` that hardcodes a width AND puts flex children in that box (65 of them, found by `findFixedWidthCards()`), each mounted alone at 360x640 with the app's real fonts out of the shared registry `shared/card_fixtures.dart`. 64 mounted, one — `OrderSection` — listed in `notMountedExemptions` with the reason it needs page-scoped provider state and deliberately absent from the registry, and two ratchets: one that fails if a new candidate appears that is neither mounted nor exempted, and `tools/unit/mounted_but_exempted_ratchet_test.dart`, which fails if a fixture and an exemption ever name the same widget again. Adversarial data throughout (long French names, five-figure amounts). Ledger #47 |
| `tools/widget/fixed_height_cards_test.dart` | the HEIGHT half of the fixed-size sweep (ledger #62): every widget class in `lib/` that pins its own `height`/`minHeight`/`maxHeight` AND puts content that can outgrow that box inside it — 71 of them, of which **21 the width scan could not see at all** (mostly mypayment dialogs and templates: `TOSDialogBox`, `DeviceDialogBox`, `MainCardTemplate`, `WalletBalanceCard`, `SignInUpBar`). Each mounted alone in a 640-tall box at 360px with the app's real fonts, and every one asserts it actually mounted. It found two real overflows — `SignInUpBar`'s 24px label by 122px and `MainCardTemplate`'s card title by 56px, both unbounded in a `Row` inside a fixed-height box — and both are fixed. It found and FIXED `InfoCard`'s `Expanded`-outside-a-Flex trap by mounting it three-up as `confirm_button.dart` does, which is why its mount assertion is `findsWidgets` and not `findsOneWidget` |
| `shared/card_fixtures.dart` | the widget level's shared card-fixture registry: the `SweepCard` entries (source + class + `Type` + builder + optional bounded `wrap`) and the adversarial long strings both fixed-size sweeps mount. One registry rather than two copies, because a drifted copy fails as a phantom layout bug; the height sweep mounts the subset the height detector finds plus its own 21, and the `CardLayout` mount ratchet counts this file as a mounting site (ledger #62) |
| `tools/widget/fixed_size_card_layouts_test.dart` | the MOUNT RATCHET for the shape the width sweep cannot see (ledger #49): every widget class that calls `CardLayout` with a literal `width:`/`height:` (25 of them) must be BUILT or FOUND by a file under `test/**/widget/`, or listed in `notMounted` with a reason. Comments and string literals are stripped before the search so the sweep's `_notMounted` map cannot make a card look mounted; "mounted" means a constructor call or `find.byType`. Height-only pins count, unlike the width sweep. Five assertions — the ratchet has candidates, every candidate is mounted or exempted, every exemption has a reason, no exemption names a card the detector no longer finds, and no exemption names a widget a widget test really mounts (the scan-side twin of `tools/unit/mounted_but_exempted_ratchet_test.dart`, added when the five seed-library/vote exemptions were deleted under it). Verified non-vacuous: deleting the `DaysEvent` mount fails with the card named, an empty reason fails, a stale key fails |
| `home/widget/home_days_event_widget_test.dart` | WIDGET level, the home module's first: `DaysEvent` (a `CardLayout(height: 135, width: double.infinity)` day column) in its one-event, three-event, past/ongoing/future colour, multi-line-description and empty-day shapes. Found the 324px overflow in the card's `spaceBetween` location/association row — ledger #49 |
| `event/widget/event_cards_widget_test.dart` | WIDGET level, the event module's first: `EventUi` in its three variants — the list card (long name/location/association together, the description's two-line + `...` join, the 250px pin, the info-tap forwarding), the detail card (edit/delete row and info icon gone, tap suppressed), and the admin strip card in the 235px `SizedBox` `ListEvent` mounts it in (four `CardButton`s wired to test-owned callbacks, confirm/decline no-op once the decision is already made) — plus the three date-driven backgrounds (`white`/`gradient`/`grey` decorations and title colours), `EditDeleteButton`'s decoration, `CheckBoxEntry`'s notifier flip vs `onChanged` split, and `ListEvent`'s count/plural header, expand toggle, history filter and empty state. Found a 99px overflow in the card's location/association row — a plain `Text(association)` next to an `Expanded(location)`, the exact ledger #49 family one module over — fixed with the same two-`Expanded` ellipsis shape `DaysEvent` got. Nav taps (`QR.to` through the info icon, edit and `ListEvent`'s onEdit/onCopy) are deliberately never fired: qlevar's routes are not registered at widget level |
| `tools/unit/inplace_list_mutations_test.dart` | the ledger #51 RATCHET: fails when a mutating list/set call in `lib/` has a receiver the detector cannot resolve to a copy, a class field, a notifier's API or a platform object. Five assertions, each proven to fail when broken — a new site (names `file:line` and the receiver), an exemption with no reason, a stale exemption naming a site the detector no longer finds, a total-and-bucket-count floor so a silently-dead regex is caught, and a row-for-row cross-check against the Python tool (190 rows, identical; this is the stronger check the fixed-size detector's count-only comparison lacks) |
| `tools/unit/mounted_but_exempted_ratchet_test.dart` | the REGISTRY-vs-EXEMPTION ratchet: fails when a widget is BOTH in `cardFixtures` (which every ratchet counts as mounted — the width and height sweeps, the localization round-trip, the CardLayout mount scan) AND in `notMountedExemptions` (which makes every one of those loops `continue` past it). That overlap is the `ModuleCard` shape — coverage claimed by the registry, measurement suppressed by the exemption — and the prose warnings in both files could not fail for it. Two sanctioned exits when it fires: delete the exemption and seed what the card reads, or remove the fixture entry so only the exemption accounts for the card. Liveness proven both ways on a synthetic overlap, and every exemption key must parse as a fixture id (`lib/…dart ClassName`) or the intersection could silently never fire |
| `shared/inplace_list_mutation_detector.dart` | the Dart port of the above detector, so the ratchet needs no Python at runtime. Buckets by receiver: a copy made on the spot, a class field, a notifier's API, a platform object, `DateTime`, an index expression. `state` is hard-wired to REVIEW — the one name a file can never have made for itself, and the one that silences the ratchet if the declaration scan gets it wrong |
| `tools/unit/logger_test.dart` | `Logger`'s level threshold and its pre-init queue: the default floor keeps info/warning/error/notification and drops debug (ledger #44), a raised floor still filters, hand-built `Log`s go through `writeLog`, a line queued while uninitialised is flushed exactly once, and `getLogs`/`clearLogs` delegate to the output |
| `tools/widget/loader_test.dart` | `Loader`'s size ceiling (ledger #46): a page-sized box caps at `defaultMaxSize` 64 instead of filling the viewport, a 1920x1080 desktop box caps too, an 80%-of-screen box (the idiom behind the pay page's QR placeholder and the raffle ticket's scan code) caps, a 40px box still shrinks to 40, unbounded constraints inside a scroll view fall back to `fallbackSize`, a caller-supplied `maxSize` is honoured, and a ceiling wider than the box still yields the box. Plus the real `QrCode` widget at 360x640 and 1920x1080 |
| `others/widget/loading_page_test.dart` | the boot screen's `Scaffold(body: Loader())` at 360x640 — its own isolate because `LoadingPage` navigates from `build` and qlevar_router's branch state is process-global (convention 19); needs `holdVersionVerifier: true` so the page stays on its spinner |
| `others/widget/others_version_pages_widget_test.dart` | ledger #55's F1. `UpdatePage` and `RollbackPage` were at **0/12 and 0/22** — unreachable from every test because the shell's two version fakes pinned `minimalTitanVersionCode <= titanVersion` to `1 <= 999`. Both mount at 360x640 with `titanVersion: 1, minimalTitanVersionCode: 1000, minimalHyperionVersion: '4.2.0'`: the localized copy, the client's version rendered from the provider (not a hardcoded string), the Hyperion minimum read back off `minimalHyperionVersionProvider`, the build flavor from the CI dart-define, and a 360px fit. Closes with the guard test asserting `minimal <= titanVersion` is `false` — the exact expression `lib/` branches on, which neither mounted page consults |
| `others/widget/no_internet_page_widget_test.dart` | ledger #55's F3. `NoInternetPage` was **0/31**: no fake could put `versionVerifierProvider` in its error state, and both of its `error:` arms route here. Mounted directly at 360x640 with `failVersionVerifier: true`: the server name resolved through the page's own element from the `BACKEND_HOST` dart-define, the "check your connection" and retry copy, the 360px fit, and the offline retry — which re-asks the backend and correctly leaves the user where they are. Closes with a guard asserting the provider really is an `AsyncError`, the state `lib/` branches on |
| `others/widget/no_module_page_widget_test.dart` | the `/no_module` page mounted directly with a seeded permission catalog and empty module roots (the middleware's redirect half lives in `tools/integration/no_module_redirect_integration_test.dart`, which owns its isolate's single deep-link): the granted-roots forward, the empty-roots stay, and the 360px fit |
| `super_admin/unit/module_roots_test.dart` | ledger #55's F2. `computeUserModuleRoots` decides which modules a user may open, and the shell's catalog fake returned `[]` in three of four containers — so it returned `[]` for every user in every test and the file sat at 7/20. Now **20/20**: the map builder (prefix split, no-dot entries skipped), `userHasPermission` by group and by account type, and root computation across the non-access filter, the permission filter and the lookup miss. Carries three `KNOWN BUG` cases pinning the key mismatch in bug #56 — the map is keyed by the **stripped** name and read with the **full** name |
| `mypayment/integration/mypayment_main_page_loading_test.dart` | the account card's `AsyncChild` spinner inside the main page's `SizedBox(height: 250)`: every mounted `Loader` on `/mypayment` must be `<= 64`. Stores resolve so the card mounts, the wallet call hangs so the loader stays up. Surface is 480px, not 360, because of the harness-font artifact in convention 20; its own isolate for the same reason as the boot screen |
| `service/unit/classes_test.dart` | the service value objects. Its `FirebaseTokenExpiration` group carries ledger #54's round-trip cases: `toJson` on a null expiration writes a real JSON null and **not** a String, `empty()` survives a full `jsonEncode`→`jsonDecode`→`fromJson` cycle, a real date survives the same cycle unchanged, and four unparseable stored values (the legacy string `"null"`, an empty string, nonsense, a missing key) each decode to null instead of throwing |
| `service/unit/setup_background_handler_test.dart` | `firebaseMessagingBackgroundHandler` called directly (it is registered from `main()`, which no test reaches): boots Firebase itself, refreshes the FCM token through the fake, initializes the plugin |
| `feed/integration/feed_home_integration_test.dart`, `home/integration/home_integration_test.dart`, `tools/integration/all_modules_integration_test.dart` | boot chain, feed, module catalog, navbar |
| `tools/integration/styleguide_page_integration_test.dart` | styleguide catalog render; button variants (danger/ondanger/secondary/disabled), all list rows + templates, search bars incl. the filter dialog, multi-select demos (tap + long press), text/date/image entries |
| `mypayment/integration/mypayment_integration_test.dart` | wallet/transactions, TOS accept flow, flip card, stats nav |
| `mypayment/integration/mypayment_store_admin_seller_rights_integration_test.dart` | the store-admin rights dialog: checked rights captured into `SellerCreation` (all five flags), a refused creation toasts and keeps the dialog, closing search clears the query, an emptied query calls `clear()` instead of `usersSearchGet(query: '')`, and the non-seller guard message |
| `mypayment/integration/mypayment_refund_integration_test.dart` | the refund sheet (`refund_page.dart` had ZERO coverage): confirmed+`requestTransaction`+`canCancel` gate, keypad to cents (12,5 → 1250), backspace, empty amount refused instead of `double.parse('')`'s FormatException, over-max amount refused (it POSTed 125.00 on a 50.00 refund before), a refused POST erroring and keeping the sheet, and the two negative gates. The sheet now hides the floating navbar while up — `NavigationTemplate` stacks the navbar over the whole Navigator, so its 82px band covered the sheet's bottom-anchored button and the tap never reached it (`hitTestable()` pins this) |
| `mypayment/integration/mypayment_scan_integration_test.dart` | scan modal via `FakeMobileScannerPlatform`: scan→amount card→cancel dialog→refund, Next reset + 5s debounce, non-member gate dialog + bypass flag to backend, scan-error card, no-membership layout |
| `purchases/integration/purchases_scan_integration_test.dart` | `/purchases/scan` deep link, seller chips → ticket cards, ScanDialog tag→scan→confirm walk (GET scan check + PATCH consume with the typed tag), stale-secret probe (ledger #25), rejected-scan error branch, Annuler reset |
| `seed-library/integration/plant_detail_integration_test.dart` | editable plant detail render branches (difficulty stars, raw enum type), plant-now PATCH, save nickname/note PATCH + toast, death dialog → consommée PATCH + death-date label, failed-save error toast |
| `seed-library/integration/plant_deposit_integration_test.dart` | `/seed_library/seed_deposit` deep link: ancestor/species cards (admin Espèce row), species → hint → `plantsPost` round-trip (body: speciesId, null ancestor, envelope, method) + reference dialog showing the NEW reference (ledger #28 fixed) + OK dismiss, empty-field inline validator blocks the POST, empty my-plants → not-available message |
| `tickets/integration/tickets_edit_residual_integration_test.dart` | edit page residuals: save validations (title/quota toasts), stats-card RichText (sold/quota, in-checkout), staged per-section PATCHes (category/session/question — each verifies its own endpoint and that untouched sections skip theirs) |
| `tickets/integration/tickets_edit_questions_integration_test.dart` | questions-section internals + unlocked-row staging: add-question modal (required, cents price, text-type default) + refused-create error toast, row staging (text, price, answer-type dropdown, required/activated switches), delete-question round-trip + answers-guard refusal, unlocked category/session TextEntry edits, the session row's own date+time picker round-trip, and locked-row inertness (null onChanged/onTap: no delete buttons, disabled fields, dead switches, no picker) |
| `mypayment/integration/mypayment_request_history_integration_test.dart` | `/mypayment/requestHistory` deep link, request cards, empty state |
| `mypayment/integration/mypayment_devices_integration_test.dart` | `/mypayment/devices` deep link, device cards + status tags, add-device button |
| `mypayment/integration/mypayment_structure_stores_integration_test.dart` | `/mypayment/structureStores` deep link, store list, add-store nav (gated) |
| `mypayment/integration/mypayment_invoices_structure_integration_test.dart` | `/mypayment/invoicesStructure` deep link, invoice cards (gated) |
| `mypayment/integration/mypayment_invoices_admin_integration_test.dart` | `/mypayment/invoicesAdmin` deep link, bank-holder-allowed case (gated) |
| `mypayment/integration/mypayment_invoices_admin_gating_integration_test.dart` | `/mypayment/invoicesAdmin` bounce for non bank holders (own file) |
| `mypayment/integration/mypayment_store_admin_integration_test.dart` | `/mypayment/storeAdmin` deep link, seller cards (own-seller rule) |
| `mypayment/integration/mypayment_store_stats_integration_test.dart` | `/mypayment/storeStats` deep link, interval selector + summary |
| `mypayment/integration/mypayment_transfer_structure_integration_test.dart` | `/mypayment/transferStructure` deep link, user search + results |
| `raffle/integration/raffle_integration_test.dart` | main page empty/admin states, detail page (standalone), ticket cards (standalone) |
| `amap/integration/amap_integration_test.dart` | balance, delivery filtering, order card, empty state, admin nav |
| `amap/integration/amap_admin_accounts_integration_test.dart` | admin AccountHandler: cash cards, client-side filter, users-mode search → real cash POST, flip-card → real cash PATCH |
| `amap/integration/amap_admin_deliveries_integration_test.dart` | admin DeliveryHandler: + card → add-delivery form, card counts (orders/products), trash dialog → real DELETE, Open dialog → real openordering POST |
| `amap/integration/amap_admin_products_integration_test.dart` | admin ProductHandler: + card → add-product form, category-grouped cards, trash dialog → real DELETE |
| `amap/integration/amap_admin_edit_forms_integration_test.dart` | deep-linked product edit form (pre-seeded `productProvider`), real PATCH body captured |
| `amap/integration/amap_admin_edit_delivery_integration_test.dart` | delivery edit journey via creation-card pencil (own file: deferred-child rule), prefilled date + checkboxes, real PATCH |
| `seed-library/integration/seed_library_integration_test.dart` | menu grid incl. admin card, plants-page nav |
| `admin/integration/admin_integration_test.dart` | admin menu, groups nav, users-management modal, gating from feed |
| `admin/integration/admin_deeplink_integration_test.dart` | allowed admin deep link mounts (own file: init-path rule) |
| `tools/integration/middleware_gating_integration_test.dart` | non-admin deep link to `/tombola/detail` lands on feed (regression) |
| `tools/integration/no_internet_middleware_integration_test.dart` | ledger #55's F3. One deep link (convention: qlevar only runs the init-path middleware chain on an isolate's first navigation) to `/` with `failVersionVerifier: true` — the log line `QR: redirect from [/] to [/no_internet]` is the assertion that `AuthenticatedMiddleware`'s `error:` arm ran, and the feed it would otherwise show is asserted **absent**. Second test is bug #57's `KNOWN BUG`: the retry re-asks the backend (verifier flips to `AsyncData`, `isConnectedProvider` becomes true) and the user is **still on the page**, because `QR.to(HomeRouter.root)` reads a stale build-time `isConnected` |
| `admin/integration/admin_groups_integration_test.dart` | `/admin/users_groups` deep link |
| `admin/integration/admin_notification_integration_test.dart` | `/admin/group_notification` deep link |
| `admin/integration/admin_structures_integration_test.dart` | `/admin/structures` deep link, structures + bank-holder state |
| `admin/integration/admin_association_integration_test.dart` | `/admin/association_memberships` deep link |
| `admin/integration/admin_associations_integration_test.dart` | `/admin/association` deep link |
| `admin/integration/admin_add_edit_structure_integration_test.dart` | `/admin/structures/add_edit_structure`: create form (membership chips), no-manager toast, full create capturing `mypaymentStructuresPost`, edit prefill (admin manager label) |
| `admin/integration/admin_groups_management_integration_test.dart` | `/admin/users_groups` write paths: sorted catalog, add-group modal → real `groupsPost` body captured, row action sheet (edit/manage/delete) |
| `admin/integration/admin_add_edit_member_integration_test.dart` | `/admin/association_memberships/detail_association_membership/add_edit_member`: create form, empty-user toast, picked user + dates → real `membershipsUsersUserIdPost`; pop-back lands on the seeded detail page (known bug 19) |
| `admin/integration/admin_association_write_integration_test.dart` | `/admin/association` populated rows (manager-group subtitle, logo-404 fallback), add modal → `associationsPost` body, edit modal → `associationsAssociationIdPatch` (confirm disabled until changed) |
| `raffle/integration/raffle_creation_integration_test.dart` | `/tombola/detail/creation`: creation mode (ticket/prize strips, add cards), Open dialog → real `openPatch`, locked mode (stats + Tirer), prize delete dialog → real `tombolaPrizesPrizeIdDelete` |
| `raffle/integration/raffle_add_prize_integration_test.dart` | `/tombola/detail/creation/add_edit_prize` deep link: quantity/name/description form → real `tombolaPrizesPost` body (own file: nested-route deep-link rule) |
| `raffle/integration/raffle_confirm_payment_integration_test.dart` | `/tombola/detail` (admin, pre-loaded pack list — the page only fetches on refresh): buy card → ConfirmPaymentDialog render, x-cancel (no call), insufficient-balance guard toast + verifyNever, purchase POST `tombolaTicketsBuyPackIdPost` + local balance drop + pop, failure toast + pop, non-open status guard (label taps now hittable in-card, ledger #31 fixed) |
| `raffle/integration/raffle_pack_ticket_add_edit_integration_test.dart` | `/tombola/detail/creation/add_edit_pack_ticket` deep link — the page's FIRST test (61 lines at 0%): add mode → real `tombolaPackTicketsPost` body (pack size, price, raffle id) incl. the comma price "7,50" → 8 €, both guards (pack size 0 inline, price 0 toast, `verifyNever`), and edit mode prefilled from `packTicketProvider` → real `tombolaPackTicketsPackticketIdPatch` + `PackTicketEdit` body (own file: nested-route deep-link rule). Colds the page with NOTHING pre-seeded, which is what surfaced defect (c) of ledger #63 |
| `raffle/integration/raffle_creation_edit_flows_integration_test.dart` | `/tombola/detail/creation`, no route navigation: the raffle NAME save → real `tombolaRafflesRaffleIdPatch` + `RaffleEdit` body (was a local-only write, ledger #63b), the empty-name guard, the ticket strip's delete dialog → real `tombolaPackTicketsPackticketIdDelete`, and the locked status's winning-ticket strip (`Tickets gagnants` + its empty state) |
| `raffle/integration/raffle_creation_ticket_edit_journey_integration_test.dart` | the ticket strip's pencil journey → deferred `/tombola/detail/creation/add_edit_pack_ticket`, both fields prefilled from the provider the pencil seeded, PATCH round-trip and the pop back to the strip (own file: convention 10) |
| `raffle/integration/raffle_edit_prize_integration_test.dart` | the prize strip's pencil journey → deferred `/tombola/detail/creation/add_edit_prize` in EDIT mode — quantity/name/description prefilled, then a real `tombolaPrizesPrizeIdPatch` + `PrizeEdit` body (own file: convention 10; the add-prize file covers CREATE only) |
| `raffle/integration/raffle_admin_create_integration_test.dart` | `/tombola/admin`: the strip's plus → "Pour quel groupe ?" picker → ConfirmCreationDialog → real `tombolaRafflesPost` + `RaffleBase` body, then the REFETCHED strip still showing the new raffle — that refetch is exactly what erased the old local-only create (ledger #63a). Fixed pumps only: the dialog's `repeat()` animation never settles |
| `seed-library/integration/species_add_edit_integration_test.dart` | `/seed_library/species/add_edit_species`: form render (Optional label suffixes, raw enum-name type chips), empty-name/malformed-prefix validation, create → real `seedLibrarySpeciesPost` body |
| `tools/integration/styleguide_page_integration_test.dart` | `/styleguide` catalog render + tap demos (buttons, list items, icon buttons, toggle rows, search bar); FloatingNavbar empty-items layout storm absorbed |
| `tickets/integration/tickets_edit_integration_test.dart` | `/tickets/edit`: gate-passed mount, full form render, save round-trip through the real `ticketsAdminEventsEventIdPatch`, missing-id unmount (own file ordering: redirects last) |
| `tickets/integration/tickets_edit_sections_integration_test.dart` | `/tickets/edit` item sections: locked rows (disabled fields, read-only banner, hidden add-question), add-category/add-session modals → real POST bodies (euros→cents, real picker dialogs), category DELETE via confirm modal, cancel-event unavailable toast, disabled vs allowed delete-event (known bug 21) |
| `tickets/integration/tickets_edit_gating_integration_test.dart` | `/tickets/edit` bounce for sellers without `canManageEvents` (own file: convention 11) |
| `tickets/integration/tickets_book_integration_test.dart` | `/tickets/book`: not-found branch, category/session/question forms, checkout POST round-trip + success toast, sold-out badge blocks booking |
| `tickets/integration/tickets_create_integration_test.dart` | `/tickets/create`: store chips, create round-trip capturing `ticketsAdminEventsPost` (euros→cents), extra-question editor, validation toast walk |
| `tickets/integration/tickets_book_integration_test.dart` | `/tickets/book` deep link: not-found branch + loaded event (needs `APP_ID_PREFIX=test`) |
| `tickets/integration/tickets_results_gating_integration_test.dart` | `/tickets/results` bounce for non sellers |
| `vote/integration/vote_detail_integration_test.dart` | `/vote/detail` deep link renders pre-seeded list state |
| `booking/integration/booking_detail_integration_test.dart` | `/booking/detail` deep link, non-admin branch |
| `booking/integration/booking_add_edit_integration_test.dart` | `/booking/add_edit` deep link, form pre-filled; plus the CREATE branch: room chips from the real endpoint, `bookingBookingsPost` round-trip asserting entity + note now ship (ledger #18 fixed, RRULE empty-string default), invalid-room toast |
| `booking/integration/booking_add_edit_recurrence_integration_test.dart` | edit-mode form: checkbox reshaping + prefill probe, no-day-selected guard (verifyNever PATCH/POST), RRULE edit round-trip asserting the PATCH ships note/entity/recurrenceRule (ledger #27, fixed), all-day toggle clears dates → validation toasts, and the interval ≥ 1 guard — `0` is refused by the field validator before syncfusion ever sees an `INTERVAL=0` rule (ledger #64) |
| `booking/integration/booking_admin_integration_test.dart` | `/booking/admin`: room + manager chip rows (gate via `user.groups` admin id) |
| `booking/integration/booking_admin_gating_integration_test.dart` | `/booking/admin` bounce for non admins |
| `booking/integration/booking_add_room_integration_test.dart` | `/booking/admin/room` form pre-filled (manager chips) |
| `booking/integration/booking_add_manager_integration_test.dart` | `/booking/admin/manager` form pre-filled (group chips) |
| `booking/integration/booking_manager_integration_test.dart` | `/booking/manager`: empty state + bookings grouped by decision (gate pre-seeded via `myManagerRoles:`) |
| `loan/integration/loan_detail_integration_test.dart` | `/loan/detail` deep link renders pre-seeded loan state |
| `advert/integration/advert_integration_test.dart` | `/advert` deep link: cards (RichText titles), association bar, plain-user sees no admin button |
| `advert/integration/advert_admin_integration_test.dart` | `/advert/admin` allowed case: member-owned cards, Post button (gate pre-seeded via `myAssociations:`) |
| `advert/integration/advert_admin_gating_integration_test.dart` | `/advert/admin` bounce for non members |
| `advert/integration/advert_add_edit_integration_test.dart` | `/advert/admin/add_edit_advert` edit form pre-filled from client state |
| `ph/integration/ph_integration_test.dart` | `/ph` deep link: empty-database message, nav buttons, no admin button |
| `ph/integration/ph_admin_integration_test.dart` | `/ph/admin` allowed case: journal cards + add button (gate via `user.groups` = admin_ph id) |
| `ph/integration/ph_admin_gating_integration_test.dart` | `/ph/admin` bounce for plain users |
| `ph/integration/ph_past_selection_integration_test.dart` | `/ph/past_ph_selection` grid: year chip, past-only filter (covers are 1x1 PNGs — the codec crashes on invalid bytes) |
| `login/integration/login_integration_test.dart` | signed-out boot on `/login`: sign-in form renders (needs `APP_NAME`) |
| `login/integration/login_sign_in_flow_integration_test.dart` | REAL sign-in flow: appauth channel → code exchange → real storeToken → secure storage write → session derives → deep-link replay renders the wanted page |
| `login/widget/login_web_panels_widget_test.dart` | WIDGET level, at a **1400x900** desktop surface (these panels are web-only; the 360x640 default would report overflows for a layout that only ever runs on a desktop): `RightPanel`'s carousel mount, a fling to the next screenshot, the dot-click→screenshot mapping (ledger #52), a real MOUSE hover that tilts the `Transform` and snaps back on exit, and the narrowest side-by-side width. `LeftPanel` mounts against the config getters' test fallbacks: under
`flutter test` the missing dart-defines no longer throw inside `build` —
`getBaseSchoolName()`/`getAppName()`/`getTitanLogo()` degrade to CI's values
(and the shipped `assets/emlyon` folder), so the school art and the app name
render, and the test pins those resolved asset names. |
| `phonebook/integration/phonebook_integration_test.dart` | `/phonebook` list + **live search filter** (types into the real TextField, one card survives) |
| `phonebook/integration/phonebook_detail_integration_test.dart` | `/phonebook/association_detail`: members by mandate ("Bolt - President"), empty state |
| `phonebook/integration/phonebook_member_detail_integration_test.dart` | `/phonebook/member_detail` pre-seeded member: nickname header, email, membership card |
| `phonebook/integration/phonebook_admin_integration_test.dart` | `/phonebook/admin` for the admin_phonebook group: header + editable card |
| `phonebook/integration/phonebook_association_edition_modal_integration_test.dart` | the edition bottom sheet's five actions from the real card journey: Edit → deferred add-edit form (prefilled fields + groupement bar), live-action inventory, term-year+1 confirm PATCH (mandateYear 2027), deactivate/delete confirm walk — toasts render via the root-navigator context + app-level wrapper (ledger #29 fixed), deactivate/delete wiring fixed (ledger #30) |
| `phonebook/integration/phonebook_admin_gating_integration_test.dart` | `/phonebook/admin` bounce for plain users |
| `phonebook/integration/phonebook_groups_integration_test.dart` | `/phonebook/admin/edit_association_groups` toggle list (gates on the **plain admin** group) |
| `phonebook/integration/phonebook_add_edit_integration_test.dart` | `/phonebook/admin/add_edit_association` add + pre-filled edit modes (labels come from `InputDecoration`, canBeEmpty adds " (Optional)") |
| `phonebook/integration/phonebook_groupement_add_edit_integration_test.dart` | groupement edit form pre-filled from the selected groupement |
| `phonebook/integration/phonebook_member_flows_integration_test.dart` | REAL modal-driven member flows: add-member (editor → user-search sheet → real search endpoint → select → POST) and member-edition modal (edit-role → PATCH); the duplicated "card title == modal title" needs `.first` + `findsNWidgets(2)` |
| `vote/integration/vote_admin_integration_test.dart` | `/vote/admin` for the admin_vote group: section chips from the real sections endpoint (waiting-status state) |
| `vote/integration/vote_admin_gating_integration_test.dart` | `/vote/admin` bounce for plain users |
| `vote/integration/vote_add_section_integration_test.dart` | add-section form mounts + real `campaignSectionsPost` → back on admin with the new chip |
| `vote/integration/vote_open_votes_integration_test.dart` | waiting-status admin panel + Open votes through the real `campaignStatusOpenPost` → page flips to the open state (close button, counter) |
| `vote/integration/vote_admin_status_handlers_integration_test.dart` | the admin page's status machine: delete-all dialog → real `campaignListsDelete`, open status (bare `7 Votes`, ledger #32 fixed) → Close votes POST, closed → Count votes POST, counting → Show-votes toggle + Publish dialog POST with real chart labels (ledger #33 fixed), Reset dialog → waiting again |
| `vote/integration/vote_main_page_integration_test.dart` | the `/vote` main surface (ListListCard + ListCard): open-status cards (name/type/logo-fallback/info buttons) + See-more FAB scroll, envelope select → `Selected` + provider state, already-voted section hides voting, published result bars with per-list percentages (75.0/25.0), non-voter cannot-vote surface |
| `vote/integration/vote_add_edit_list_integration_test.dart` | the waiting-status + button → add-list form, create round-trip capturing the real `campaignListsPost` body (all three TextEntry validators required) |
| `vote/integration/vote_edit_list_integration_test.dart` | list-card edit sheet → prefilled edit form → real `campaignListsListIdPatch`; the card's onTap delays 150ms before the sheet shows |
| `loan/integration/loan_admin_integration_test.dart` | `/loan/admin` allowed case via `myLoaners:` gate pre-seed: item cards with quantities/caution |
| `loan/integration/loan_item_bar_integration_test.dart` | the add-edit-loan ItemBar: pre-populated per-loaner map via the admin parent mount (the search bar re-seeds it too), stepper round-trip (empty end before a start is picked — ledger #34 guard — caution 3000.00 €, selected count), computed end after a start pick, minus clears both, cap at total-loaned, both "No items" branches, edit mode pre-selects itemsQty |
| `loan/integration/loan_admin_gating_integration_test.dart` | `/loan/admin` bounce for non-loaner users |
| `loan/integration/loan_add_edit_item_integration_test.dart` | `/loan/admin/add_edit_item` edit form (own file: 3 stacked deferred libraries need a long frame budget) |
| `cinema/integration/cinema_integration_test.dart` | `/cinema` session cards (wide web layout: name/date/overview) + empty state |
| `cinema/integration/cinema_detail_integration_test.dart` | `/cinema/detail` pre-selected session renders |
| `cinema/integration/cinema_add_session_integration_test.dart` | admin + card → add-session form, create round-trip through the real `cinemaSessionsPost` (poster gate pre-seeded via `sessionPosterMapProvider`, AdminSessionCard's 1px overflow absorbed) |
| `cinema/integration/cinema_edit_session_integration_test.dart` | admin card pencil → prefilled edit form → real `cinemaSessionsSessionIdPatch` (duration is minutes: 120 renders "02:00") |
| `recommendation/integration/recommendation_integration_test.dart` | `/recommendation` recommendation cards from the real endpoint |
| `recommendation/integration/recommendation_information_integration_test.dart` | `/recommendation/information` pre-selected recommendation card + description |
| `recommendation/integration/recommendation_add_edit_integration_test.dart` | admin + card → add-deal form, create round-trip through the real POST; the mandatory logo comes from the REAL ImagePicker path with a fake `ImagePickerPlatform` (pick → read → compress → preview) |
| `recommendation/integration/recommendation_edit_integration_test.dart` | information-page pencil → prefilled edit form → real PATCH (own file: deferred-route rule 10; the edited deal must exist in the GET list or the in-place update reports failure) |
| `settings/integration/settings_integration_test.dart` | `/settings` main page: profile rows, ICU-plural notification counter, language sheet → SharedPreferences `locale`, ical Clipboard copy + toast |
| `settings/integration/settings_logs_integration_test.dart` | `/settings/logs` log/notification tabs from a fake `LoggerOutput`; Edit account sheet saves through the real `usersMePatch` (scroll + tap below the fold, `seedAsyncUser`) |
| `settings/integration/settings_logout_integration_test.dart` | the REAL logout path, and now the app's ONLY one (ledger #53): seeds a `firebaseTokenExpiration` prefs row for `user-1`, waits on the notifier's `ready` so the row is provably in state first, then drives the real "Log out" row → confirm modal → `Confirm`. `flutter_secure_storage`'s channel is stubbed so `deleteToken` is real but hermetic. Asserts the pref key is gone AND the in-memory state is empty — `reset()` assigns state directly instead of re-reading prefs, so a prefs-only check would still pass if that assignment were deleted. Writing it is what surfaced that the *other* `reset()` caller, `QuitDialog`, was unreachable in the shipped app and has since been deleted |
| `feed/integration/feed_event_handling_integration_test.dart` | `/feed/event_handling`: pending filter default, Approve through the real endpoint (notifier replaces the item in place), filter chips + empty states |
| `feed/integration/feed_association_events_integration_test.dart` | `/feed/association_events`: association chips, event cards (name/location), chip switch reloads per association |
| `feed/integration/feed_association_event_edit_integration_test.dart` | card Edit sheet → `/feed/add_edit_event` in edit mode, form prefilled (own file: deferred-route rule 10) |
| `feed/integration/feed_add_edit_event_integration_test.dart` | create round-trip: real `calendarEventsPost` body captured, `Event added` toast, back on feed |
| `feed/integration/feed_add_event_residual_integration_test.dart` | create-mode add_event_page residuals: the validation-chain toasts (title, dates, location, association), chip selection, the ticketing switch's permission subtitle, the date/link pairing through the real pickers, the existing-ticketing dropdown + captured `calendarEventsPost` body (ticketEventId `te-1`, null ticketUrl) |
| `feed/integration/feed_edit_event_residual_integration_test.dart` | edit-mode add_event_page residuals: prefilled all-day event, the all-day checkbox clearing both date controllers, save WITH a poster upload (platform-level `ImagePickerPlatform` fake → captured `EventEdit` body + `calendarEventsEventIdImagePost` + `Event modified`), refused update → `Error while modifying` |

The event module is deliberately **not registered in the central route
table** (`lib/router.dart`, commit "removing event from router"), so there
are no `/event/*` shells — deep links land on "Page Not Found" by design.

## Known app bugs surfaced by these tests

Also fixed along the way: the dead `WidgetRef ref` parameter on
`MapNotifier`/`SingleMapNotifier.autoLoad(List)` (removed — `WidgetRef` is
sealed and unfakeable), `VotedSectionProvider.addVote` mutating the
previous state list in place (crashed on unmodifiable lists), and
`Module.copyWith` returning `this.name` for `description`. All have
regression tests.

1. ~~**Infinite redirect loop on gated deep links** — FIXED.~~
   `AdminMiddleware` bounced to `/`, and `AuthenticatedMiddleware`'s replay
   branch returned the forwarded path again, forever. Fix:
   `admin_middleware.dart` now bounces non-admins to `/feed` (a real,
   always-granted route); the replay branch in
   `authenticated_middleware.dart` drops a non-matching pending deep link
   to `/feed` instead of returning it (defensive: stale forward after
   login). Regression tests: `middleware_gating_integration_test.dart`
   (bounce) and `admin_deeplink_integration_test.dart` (allowed).
2. ~~**Raffle card embeds a full `Scaffold`** (`RaffleTemplate`) inside the
   main page's scroll view → unbounded-height crash in debug mode (~6000
   exception storm); release builds silently tolerate it.~~ FIXED (2026-09
   layout pass): `RaffleWidget` no longer wraps itself in `RaffleTemplate`
   — list cards render their box directly; only pages use the template.
3. **Amap `UserCashNotifier`/`UserOrderListNotifier` `return state` from
   `build()`** — Riverpod 3 throws once on the first build (uninitialized
   state) before the scheduled load heals it. Tests filter that one
   exception; the real fix is returning `AsyncValue.loading()`.
4. ~~**Amap order card rows overflow horizontally** ~125px with real-world
   dates (shipped visual bug, debug-visible only)~~ FIXED (2026-10 card
   sweep). The overflow filter is gone and the whole `lib/` tree swept for
   the family (fixed-width card + `Text`/`AutoSizeText` as a `Row` child):
   158 files carry a fixed-width container, 15 had the defect, 7 were real
   and are fixed — `OrderUI` (195px: date row → `Expanded`+ellipsis,
   count/amount row → `Expanded` + `Flexible(FittedBox(scaleDown,
   centerRight))`), `DeliveryUi` (280px), `OrderDetailUi` (250px),
   `UserCashUi` (150px, amap + raffle), the "See more" pill (150px), and
   phonebook's association header. Two traps worth remembering, both hit
   here: **`AutoSizeText` in a `Row` never scales** (a Row hands its
   children unbounded width, so the widget renders at its natural size —
   it only works in a bounded `Column`), and **a flex child inside a
   `Row`'s slot is illegal**: the delivery status pill lives in a
   spaceBetween `Row`, so its subtree is unbounded and `Flexible` on the
   label threw `RenderFlex children have non-zero flex but incoming width
   constraints are unbounded`; the pill itself is now a loose `Flexible`
   (still shrink-wrapped, still centred) so the label can ellipsize.
   `ignoreAmapKnownQuirks()` no longer swallows `A RenderFlex
   overflowed` — it was the suite's only overflow filter, so all 94 amap
   tests now render with overflows fatal (0 remaining).
   Re-audited 2026-10 (ledger **#42**): the horizontal fix was complete, but
   the card's HEIGHT was still pinned, and pinning a height cannot answer an
   accessibility setting. The detail state (`isDetail`, 100px — the order
   detail page mounts it) overflowed its own content by **4px at the default
   text scale**, and all three states overflowed at 1.3x (17px / 9px / 27px).
   `height` is now `(isDetail ? 105 : 150) * MediaQuery.textScalerOf(context).scale(1)`.
   A `ConstrainedBox(minHeight)` + `IntrinsicHeight` pair was tried first and
   rejected: the button subtree reports a pessimistic intrinsic height, so the
   card measured **172px instead of 150px** and the whole design moved. The
   scale-aware height keeps the card at exactly 150px at the default scale (the
   `Spacer` still pins the button row to the bottom edge) and stays clean to
   2.0x. Three guards in `amap_cards_widget_test.dart` cover the detail state,
   the 1.3/1.5/2.0x sweep and the main page's 195px `HorizontalListView`
   bound; all three fail against the pinned height, so none is vacuous.
   Lesson for the rest of the fixed-height family: a fixed-height card needs
   the text scale, and its states (`isDetail`, locked-without-buttons) have to
   be mounted separately — the button state alone hid the detail bug.
5. **Amap cash balance rendered raw** (`2510.00` — looks like cents but is
   treated as euros); mypayment divides by 100. Probably one of them is
   wrong; needs a product decision.
6. **mypayment `hasAcceptedTosProvider` is autoDispose** with no listener
   during the TOS branch; the accept flow updates a disposed notifier
   (caught by tests via a container listener). Real fix: listen somewhere
   permanent or drop autoDispose.
7. **qlevar `QR.currentPath` can disagree with the rendered page** after a
   mid-chain redirect (parent URL update fires last). Tests assert rendered
   content where this showed up. Cosmetic but confusing when debugging.
8. **mypayment invoices pages never fetch on mount** —
   `InvoiceListNotifier.build()` returns loading and both invoices pages
   only call the repository from pull-to-refresh/pagination callbacks, so
   a freshly-opened page shows its loading branch forever until the user
   pulls. Tests pre-seed `invoiceListProvider` (`invoices:` on
   `makeContainer`); the real fix is loading in `build()`.
9. **`AdminMiddleware` gates on async providers** (`isStructureAdmin`/
   `isBankAccountHolder` watch repository-backed notifiers): at deep-link
   time the data has not landed and the redirect evaluates before the
   state resolves, bouncing legitimate admins. Tests pre-seed the state
   (`myStructures:`/`bankAccountHolder:`/`selectedStructure:` on
   `makeContainer`); the real fix is awaiting the providers' first value
   in the middleware.
10. ~~**`LoanCard` overflows its fixed 250px width by ~200px** with ordinary
    names (AutoSizeText in an unbounded row inside the card).~~ FIXED
    (2026-09 layout pass): every text row in the card family is now
    Expanded/Flexible — LoanCard (name + status/date rows), BookingCard
    (room + decision/keys rows), ItemCard and CheckItemCard (availability
    + duration lines), AdminSessionCard (name block). The whole family's
    tests dropped `absorbLayoutOverflows`.
11. ~~**`BookingCard` (detail mode) decision/keys row overflows ~138px** —
    same fixed-width card pattern as #10.~~ FIXED (2026-09, with #10).
12. ~~**`DeliveryHandler` sorts the provider's list in place**~~ FIXED
    (2026-10): the builder sorts a copy (`List.of(data)..sort(...)`), and
    `ListNotifierAPI` rebuilds the list on every mutation path, so the
    widget had been the only writer of provider state during build. The
    four amap admin stubs now hand out `const` lists — an unmodifiable
    fixture is what proves the fix (the file is 26/26 covered).
13. **amap money fields are int-typed and rendered raw** — the cash PATCH
    parses `7,50` → `7.5` then `.round()`s into the int balance (8), and
    product prices/balances render `350` as `350.00 €`. Consistent, but
    any decimal price silently rounds on save; needs a product decision
    (same family as #5).
14. **Deep links into an amap deferred child die on the parent shell's
    quirks in later isolate tests** — `/amap/admin/add_edit_delivery`
    mounts `AmapMainPage` underneath, whose `UserCashNotifier` self-read
    (#3) turns fatal when another test already ran in the isolate (the
    healing load never lands). The delivery edit journey therefore lives
    in its own tap-navigated file
    (`amap_admin_edit_delivery_integration_test.dart`); the product edit
    form deep-links fine because its parent shell has no such read.
    Same design space as convention 10 — pick per-page, not per-module.
15. ~~**The styleguide's FloatingNavbar demo ships an EMPTY items list** —
    `itemWidth = availableWidth / items.length` is infinite, so every
    frame throws the Stack's `BoxConstraints forces an infinite width`
    assertion, which cascades into debug scheduler-callback semantics
    assertions (`parentDataDirty`, `_needsLayout`, `_needsPaint`).~~
    FIXED (2026-09 layout pass): the demo ships four real Module items
    (Home/Search/Favorites/Profile with snack-bar taps); the test's
    in-body `FlutterError.onError` filter is gone.
16. **`CustomSearchBar`'s clear (x-mark) button can never appear on a
    static page** — it mounts only when the HookWidget rebuilds while its
    controller has text, and `useTextEditingController` does not subscribe
    to text changes; `onChanged` fires but nothing rebuilds. Same family
    as the EditProfile Confirm bug (already fixed there). Real fix: wrap
    the x-mark in a `ValueListenableBuilder` on the controller.
17. **`EventCompleteTicketUrl.fromJson({})` throws** (`Null is not a
    subtype of String` in `dateTimeFromJson`) — `EventNotifier.build()`
    and `AddEditEventPage`'s `isEdit` check both call it, so the event
    add-edit page can never mount, and the event module is ALSO not
    registered in `lib/router.dart` (commit "removing event from router").
    Double-blocked: no test can deep-link it, and a standalone pump
    crashes on the provider. Real fix: use `empty()` + register the
    router. Blocking the event add-edit coverage (274 lines).
18. ~~**`BookingReturnApplicant.toBookingBase()` drops `entity`, `note`
    and `recurrenceRule`** — FIXED.~~ The create-path adapter now carries
    all three (BookingBase supports them), so a created booking keeps
    the typed entity and note. The create test asserts the POST body
    (`booking_add_edit_integration_test.dart`) — note the shipped wire
    format: a non-recurring booking sends the RRULE as an EMPTY STRING,
    not null. Edit-path sibling: #27 (also fixed).
19. **`AssociationMembershipInformationEditor` does a bare
    `groups.firstWhere((g) => g.id == managerGroupId)`** — any membership
    whose manager group is missing from the loaded list (empty group
    list, or the default empty membership with `managerGroupId: ''`)
    crashes the detail page with `Bad state: No element`. Surfaced when
    the add-member page pops back to the detail page underneath. Tests
    seed the parent membership (`associationMembershipProvider`) with a
    manager group that exists; real fix is `orElse:` a placeholder.
20. **`AssociationItem` has the same bare `firstWhere` on the
    association's `groupId`** — the associations page crashes on mount
    whenever an association's group is not in the group list (e.g. the
    list still resolving). Tests pre-seed `allGroupList` via the
    scaffold's `groups:` arg (same family as bug 19; real fix is
    `orElse:`).
21. ~~**A successful ticket-event delete crashes on its own toast** —
    `deleteEvent` displays the success toast with the NAVIGATOR's context
    (captured before unmount), from where `Overlay.maybeOf` cannot
    resolve and toastification has no global wrapper, so
    `Toastification.show` hits its `not initialized` assertion. The
    failure branch toasts through the form context and works; only the
    success path crashes.~~ FIXED (2026-09, same two-layer remedy as #29):
    the app-level `ToastificationWrapper` in `main.dart` gives the
    captured navigator context an overlay to resolve, so the success
    branch survives its own unmount — no lib change needed, the capture
    was already correct. The success test is unblocked:
    `tickets_edit_sections_integration_test.dart` drives the full DELETE
    round-trip and asserts the 'Ticketing deleted successfully' toast +
    `navigator.pop()`.
22. ~~**`PrizeCard`'s fixed 125px column overflows by 8px** with its normal
    content (name + quantity + action row).~~ FIXED (2026-09, with #10):
    the quantity line is Flexible, and the lock branch was rebuilt — the
    'Tirer' draw button became a full-width label button (its icon+label
    row overflowed the old 40px square by ~84px) and 'En Attente' lost its
    inner Spacer.
23. **The species `TypesBar` renders raw Dart enum names**
    (`plantesAromatiques` instead of the JSON label "Plantes
    aromatiques") — `RadioChip` prints `item.name` from the generated
    enum, and no French label mapping exists. Cosmetic; tests assert the
    rendered (raw) strings.
24. **The scan modal's membership row overflows at desktop widths** —
    `ScanPage` sizes the row `MediaQuery.width - 40` while the bottom
    sheet caps at 640px, so the close X lands ~200px off-screen at 800px
    width (unbugged at phone widths, where the sheet is full-bleed).
    Scan-modal tests needing the X use a 500px viewport; the row needs
    `MediaQuery`-independent constraints (LayoutBuilder) instead.
    Discovered by the scan-modal geometry probe in
    `mypayment_scan_integration_test.dart`.
25. **The purchases ScanDialog never sends the scanned secret** —
    `onScan` captures the build-time `scanner` snapshot; `setSecret` runs
    only in the data branch of that stale (loading) snapshot, so the
    GET's secret path param stays `""` and the confirm PATCH consumes
    `""` too. Blast radius: the error branch's 2s auto-reset and error
    toast are also dead code (same stale snapshot), so a rejected scan
    leaves the dialog stuck on the error card. Fix: resolve the current
    state with `ref.read(scannerProvider)` inside `onScan`. Proven by
    the secret-capture probe in `purchases_scan_integration_test.dart`.
26. **Deep-linking `/seed_library/plants/plant_detail` crashes** —
    `EditablePlantDetail` runs a bare `species.firstWhere` on the synced
    species list; with the plant state set before the species list
    resolves (the shipped deep-link state) it throws `Bad state: No
    element`, and nothing on the route calls `loadPlant` anyway (the page
    hangs on the AsyncChild loader first). Only reachable    from the my
    plants list in-app. Fix: handle the missing species + load the plant
    from route params.
27. ~~**The booking EDIT path drops `note`, `entity` and `recurrenceRule`**
    — FIXED.~~ `toBookingReturn()`
    (adapters/booking_return_applicant.dart) now carries the three fields
    into the `BookingReturn` the edit path builds, so the PATCH body
    (`toBookingEdit()`, which always supported them) ships the freshly
    generated RRULE plus any note/entity — syncfusion serializes the end
    date in UTC, so the test pins the RRULE on
    BYDAY/INTERVAL/UNTIL-year. Proven by the PATCH-body capture in
    `booking_add_edit_recurrence_integration_test.dart`; the CREATE path
    still drops the fields via `toBookingBase` (ledger #18).
28. ~~**The plant-deposit success dialog shows a STALE reference and
    crashes on an empty waiting list** — FIXED.~~ The dialog builder now
    reads the added plant from the CURRENT `plantListProvider` state
    (`ref.read(...).maybeWhen(data: ..., orElse: () => null)` — the
    established cinema/vote create-success idiom) instead of the
    widget's build-time snapshot: it shows the freshly assigned
    reference and a first-plant deposit on an empty list renders an
    empty reference instead of crashing. The test stubs the POST with a
    distinct `BAS-0300` and asserts the dialog shows it and NOT the
    stale pre-add `BAS-0200`.
29. ~~**The association edition modal's confirm toasts display through a
    popped context** — FIXED.~~ Two-layer fix: the modal captures the
    ROOT navigator's context at build time and toasts through it (the
    sheet's own context dies on pop, so the l10n lookup inside
    displayToast threw), and the app now wraps MaterialApp in the
    toastification package's `ToastificationWrapper`
    (lib/main.dart, mirrored in the test scaffold) so `show()`'s
    Overlay.maybeOf fall-back resolves even from a context whose overlay
    is gone. The confirm tests use completing stubs and assert the toast
    text (`Association updated` / `deactivated` / `deleted`). A 2026-09
    sweep audited all 166 `displayToast` sites for the same shape (toast
    after an await/pop that unmounts the widget) and fixed 7 more files
    with the same root-navigator capture-before-the-async-gap pattern:
    settings logout (toast after `QR.to(login)`), the tickets offer-modal
    pop, the loan add-edit + add-edit-item saves and the raffle
    pack-ticket/prize saves (toast after `QR.back()`), and the mypayment
    request modal's confirm/refuse (pop-then-toast ×3). The other
    post-await sites were verified safe (toast-before-navigate order,
    error branches with no navigation, or root/main contexts).
30. ~~**The association edition modal's deactivate/delete ternaries are
    CROSSED** — FIXED.~~ The `onYes` branches
    (association_admin_edition_modal.dart) now match the danger button's
    label: a LIVE association's "Deactivate association" runs the
    deactivate PATCH and a DEACTIVATED one's "Delete association" runs
    the DELETE (which requires `deactivated == true`, finally
    reachable). The tests flip with the fix and assert the intended
    endpoint with `verifyNever` on the other
    (`phonebook_association_edition_modal_integration_test.dart`).
31. ~~**`BuyPackTicket`'s column overflows its fixed 160px card, painting
    the status label BELOW the card's boundary and outside its hit area**
    — FIXED.~~ Two-part fix in buy_type_ticket_card.dart: the logo+price
    row's price text is wrapped in `Flexible(FittedBox(scaleDown,
    centerRight))` (a bare FittedBox in an unconstrained row slot still
    paints at natural size — that was the 25px horizontal overflow), and
    the label container's vertical padding is trimmed 10→4 so the
    column's fixed contents fit the 160px card again, with the label
    text scale-down fitted. The tests now tap the status label directly
    and no longer absorb any overflow
    (`raffle_confirm_payment_integration_test.dart`).
32. ~~**`VoteCount` interpolates a `List<int>` into its label** — FIXED.~~
    The `sectionsStatsProvider` map stores `AsyncValue<List<int>>` (a
    `MapNotifier<int>`), so interpolating the whole list rendered
    `[7] Votes` with brackets on every open-status campaign.
    VoteCount now renders `data.first` (empty-guarded); the test asserts
    the bare `7 Votes`
    (`vote_admin_status_handlers_integration_test.dart`).
33. ~~**`VoteBars` puts an `Expanded` inside the admin page's scrollable
    column** — FIXED.~~ VoteBars' root is now `SizedBox.expand` (fills
    whatever bounded height the caller gives, no Flex ancestor needed)
    and the admin embeds wrap it in `SizedBox(height: 280)` — the
    unbounded-flex crash is gone and the chart paints: the tests assert
    the real bottom-axis labels (`BDE` ×2, `100.00%`, `12 Votes`) from
    the results endpoint. Note a bare `SizedBox(height)` wrapper alone
    still fails — an Expanded directly inside a SizedBox is a
    ParentDataWidget error, hence the widget-side `SizedBox.expand`.
34. ~~**The loan steppers crash before any start date is picked** —
    FIXED.~~ The +/- steppers call `setEndFromSelected(start, ...)` with
    startProvider's empty-string default, and `DateFormat.yMd.parse('')`
    threw on every first tap of a fresh loan form. end_provider.dart now
    no-ops on an empty start (the end field simply stays empty), and the
    item-bar tests exercise both paths: the no-op on a fresh page and
    the computed `start + shortest suggested duration` after a legit
    date pick.
35. ~~**`setUpNotification`'s 30-day token cache is inverted, and its expiry
    check is dead code**~~ FIXED 2026-10 (ledgers #35/#43). The condition was
    `userId != user.id || expiration != null || expiration!.isBefore(now)`,
    so after the first `saveDate` the middle clause was true forever: the FCM
    token was re-registered and `getTopics()` re-fetched on EVERY launch, and
    `isBefore` could never decide anything. Measured against the real
    notifier (`setup_notification_cache_test.dart`): a cache with 10 days left
    was rewritten to now+30d, and a cached `expiration: null` under the
    signed-in id threw **"Null check operator used on a null value"** out of a
    launch — the one combination that reaches the third operand is the one
    that dereferences the field it just tested. Now `expiration == null ||
    expiration!.isBefore(now)`, so the cache is "register when there is no
    date yet, or when the 30 days are up": a valid cache is left alone (one
    topics refresh, from the provider's own build), an expired one
    re-registers, a null one registers without throwing, and another user's
    date is never reused. The product decision the old entry left open — does
    a launch re-register the token? — is answered by the code's own
    `Duration(days: 30)`: no, not inside 30 days. `setup.dart` is now **40/40**
    and the service module 89.8→**91.1%**.
36. **FIXED (`setUpNotification` fetched the topics list even for users who
    denied notifications)** — it watched `topicsProvider.notifier` before the
    permission answer arrived, and that notifier's `build()` calls
    `getTopics()` itself, so every launch of the app hit
    `notificationTopicsGet` regardless of authorization (denied: 1 call,
    authorized: 2) — and it fired on the first frame, while the permission
    dialog was still open. Reading a notifier *is* instantiating it, so the
    fix is to `ref.read` it inside the authorized branch instead:
    `setup.dart` no longer touches `topicsProvider` until the answer says it
    may. Denied is now **0 calls**; authorized is still 2 (the notifier's own
    build plus the explicit refresh after the token is saved), which is what
    the authorized file asserts. The regression is pinned twice in
    `service/integration/setup_notification_denied_integration_test.dart`:
    the topic-call counter must be 0, AND `container.exists(topicsProvider)`
    must be false — the second assertion is what makes the first honest rather
    than a race that happened to resolve. Proven by reverting `setup.dart`
    with `git show HEAD:` and re-running: `Expected: <0> Actual: <1>`.
    Not fixed, same file: the background handler still calls
    `LocalNotificationService().init()` twice, and `setUpNotification` still
    never awaits `init()`. (Verified while writing the tests: the
    `ref.watch` inside the `requestPermission().then` callback does NOT trip
    a riverpod assert.)
37. **`feed/tools/image_color_utils.dart` coverage is not deterministic**
    (+/-18 lines, i.e. the whole feed module's number). `getDominantColor`
    awaits `Image.toByteData()` — real engine work no `FakeAsync` pump can
    drive — so its tail is covered only when the callback lands before the
    test tears down: `test/feed` alone measures 26/33, the same files inside
    the full suite measured 8/33 twice. Do not chase the difference; re-run
    `--coverage test` and quote the number it prints.
38. **`Loader` sizes itself to `shortestSide`** — inside any bounded box
    taller than it is wide it renders *that* size, so in the amap delivery
    card's 230x73 slot it drew a 73x73 spinner that pushed the other two
    rows 16px off the bottom on every mount. Found only once the overflow
    filter came off (ledger #4); the card now wraps its `AutoLoaderChild`
    in a 20px `SizedBox`, and the fixed 100px cash cards in amap and
    raffle lost 6px of dead tail spacing for the same reason (they
    overflowed by 1-4px). The conclusion drawn here — "any future card
    that hosts a loader must bound it, changing `Loader` itself would
    resize every page that uses it" — was superseded by ledger #46, which
    put the ceiling in `Loader` itself.
39. **Three phone-width overflows the 1920px shells could not see** (found
    by the new widget level, ledger: `test/*/widget/`). Every integration
    shell renders at 1920x1080, so a card that only fits a desktop passes
    the suite and breaks on a phone: amap's `ProductCard` cannot fit a
    TWO-line name in its 130px no-button variant (15px overflow — the name
    is now `maxLines: showButton ? 2 : 1`), mypayment's `SellerRightCard`
    put an unbounded `Center`+`Text` next to a `Spacer` (350px; now
    `Expanded`+`Align(centerLeft)`+ellipsis, Spacer dropped) and
    `DeviceItem` did the same with its name `Column` (723px; now
    `Expanded` with both labels ellipsized). Mount leaf widgets at
    360x640, not at the shell's desktop size — that is the whole point of
    the level.

43. **The cache was also unreachable on a cold boot** (the reason #35's
    clause could not decide anything even after the operator flip).
    `FirebaseTokenExpirationNotifier.build()` cannot await its own prefs read,
    so it returned `FirebaseTokenExpiration.empty()` and fired
    `getSavedDate()` — and `setUpNotification` read that state inside
    `requestPermission().then`, a tick or two later, seeing the empty default
    (`userId: ''`) for *every* launch. The 30-day cache never consulted the
    saved date at all. The notifier now exposes `late Future<void> ready`
    (`getSavedDate` returns its future instead of being `async void`) and
    setup awaits it before the check. The guard that pins this is the
    cold-boot case in `setup_notification_cache_test.dart`: it mounts
    `setUpNotification` *without* touching the provider first, exactly like
    `NavigationTemplate`'s first build; dropping the `await` makes that one
    test fail while the warm-start cases still pass.
    The mechanical reason nothing ran this at all: the shell overrides
    `firebaseTokenExpirationProvider` with `FakeFirebaseTokenExpirationNotifier`,
    which returns the fixed userId `'me'` and a date 30 days out — so
    `userId != user.id` was true for *every* test user and the `||` chain
    short-circuited before lines 33-34. The condition was never untestable,
    only unreachable through the shell.
44. **`logger.info` was accepted and then thrown away — the whole app's
    info-level diagnostics were mute.** `Logger.minimalLogLevel` defaulted to
    `LogLevel.warning` and `writeLog` drops
    `log.level.index < minimalLogLevel.index`, so both `info` and `debug` were
    filtered out at the last step, with no trace: no file line, no settings log
    card, no console line. The audit counted exactly **one** `logger.info`
    call in `lib/` — `setUpNotification`'s "Firebase messaging token
    registered" — so the app's single informational diagnostic never reached
    any output, on any launch, ever. `minimalLogLevel` now defaults to
    `LogLevel.info`; `debug` stays out (nothing writes it) and the field is
    still a plain mutable knob for a caller that wants its floor back at
    `warning`. Pinned by `logger_test.dart` (default floor keeps
    info/warning/error/notification, drops debug; raising the floor still
    works; `writeLog` honours the floor for hand-built `Log`s) and, end to
    end, by a new case in `setup_notification_cache_test.dart` that captures
    the logger output through the shell's `stubLoggerOutput` and asserts the
    registration line arrives at `LogLevel.info` — put the `warning` default
    back and that line never reaches the capture and four tests fail.
45. **The logger's pre-init path could spin the microtask queue forever.**
    `writeLog` re-queued by calling back into itself from `_initFuture`, so a
    logger that never sets its private `_initialized` re-queued forever: the
    shipped harness `_StubLogger` does exactly that (it overrides `init()`
    with a no-op), and so does any real logger whose output init *throws*
    (a failed `FileLoggerOutput.init()` → a path_provider error left the flag
    false, and every later line re-armed the callback instead of writing).
    Writes before init settles now go into a pending list that is flushed
    **once** when it settles, and a flush that finds the logger still unready
    hands the lines to the output anyway — which drops them itself if it is
    not ready, instead of looping. `logger_test.dart`'s
    `UninitialisedLogger` (a logger whose `init()` never flags ready) asserts
    a queued line is delivered exactly once; this defect is reasoned from the
    old code path rather than reverted-verified, because re-introducing it
    hangs the test run instead of failing an assertion.
Also fixed along the way (with regression tests): `BookTicketPage`'s
`useEffect` cleanup called `ref.read` during unmount (Riverpod throws on
every real navigation away from the page — notifier now captured at build
time), `AddEditBookingPage`/`AddEditEventPage` crashed with a `Null`
cast for **new** bookings/events (`recurrenceRule != ""` guard passed for
null; now `recurrenceRule?.contains(...) ?? false`), ph's
`YearListNotifier.addYear` mutated the previous state list in place (same
class as the old addVote bug), `OpenIdTokenProvider`'s async token
methods wrote `state` after async gaps without `ref.mounted` checks
(crashed whenever the session bootstrap disposed the provider mid-flight,
exposed by the mock-OIDC flow test), and `AdminScrollChips` dereferenced
`dataKey.currentContext!` in its edit-mode scroll effect — a guaranteed
crash whenever the pre-selected room/manager/group was not in the chip
list (deep link, state restore), now null-checked with `context.mounted`,
and `IsLoggedInProvider._isValid` crashed with a `FormatException` on a
corrupt stored token (`JwtDecoder.isExpired` *throws* on non-JWT input
instead of answering "expired") — any storage corruption booted the app
into a provider exception; it now reads as signed out. Found by the
session-expiry unit test. The phonebook round then surfaced two more:
`MemberPicturesNotifier.build()` returned `state` (uninitialized at build
time — Riverpod throws "Tried to read the state of an uninitialized
provider" on every member-detail open; now returns a fresh map), and
`AssociationGroupementBar`'s scroll effect dereferenced
`dataKey.currentContext!` when the selected groupement was not in the chip
list (deep link; same class as the AdminScrollChips crash, guarded now).
`SectionList.build` returned `{}` AFTER `loadTList`/`setTData` had written
state (build results overwrite state — the section chips never rendered on
a fresh vote admin page; now builds and returns the real map),
`SectionsStatsNotifier.build` read `state` uninitialized (same class as
#3), `loanerProvider.firstWhere` had no `orElse` (a stale/absent loaner id
threw "Bad state: No element" through LoanMainPage — now returns
`Loaner.empty()`), and the loan admin map providers read `state`
uninitialized with the same build-overwrites-state trap (fixed together).
The settings/feed round surfaced four more, all fixed with tests:
`EditProfile`'s placeholder pointed at `assets/images/profile.png`, which
does not exist in pubspec or on disk — opening Edit account without a
profile picture was a guaranteed asset crash (now `getTitanLogo()`, the
flavor-aware placeholder every other screen uses); the same Confirm button
computed `disabled:` from controller text at build time with no
subscription to controller changes, so on desktop/web (no keyboard inset
to trigger a rebuild) it could never be enabled (now nested
`ValueListenableBuilder`s); `ManageAssociationEventPage` only loaded its
event list from chip taps/pull-to-refresh while `useState` had already
frozen the first association — a cold open sat on the loading branch
forever (now a mount-time `useEffect` fires the initial load); and
`AddEditEventPage` wrapped its Form in a second `Expanded` inside
`FeedTemplate`'s own `Expanded` — competing ParentDataWidgets,a debug-mode exception that silently tears down the page (removed; every
other feed page passes a plain child). The cinema round surfaced one more
of the same family: the session create-success branch read
`sessionList.last` from the widget's build-time snapshot — "Bad state: No
element" on every first-session creation and a stale poster id otherwise
(now `ref.read(sessionListProvider)`). Also ledgered while writing the
shells: `AdminSessionCard` ships a 1px vertical overflow in its fixed-
height button row (viewport-independent, same class as LoanCard/
BookingCard, tests absorb it); the recommendation create form's mandatory
logo can only enter through the real ImagePicker, which tests fake at the
platform-interface level; and `ListNotifierAPI.update` replaces by id in
the loaded list, so an edit of a record absent from the GET answer reports
failure despite a 2xx — the shells keep the edited record in the list. Also `AssociationEventCard`'s Edit
button ran `QR.to(...)` BEFORE `Navigator.pop()`, which pops the topmost
route: with the feed library warm the push is synchronous and the pop
closed the freshly pushed edit page instead of the sheet (reordered;
matches every other modal in the app). The vote round then surfaced four
more, all fixed with tests: the admin page's + (add-list) button called
`ListReturn.fromJson({})` and the generated parser casts a missing nested
key (`json['section'] as Map<String, dynamic>`) — the add-list entry
point crashed 100% of the time, release included (runtime TypeError, not
a debug assert; now `ListReturn.empty()`); the create-success branch read
`listList.last` from the widget's build-time snapshot, which predates the
add — "Bad state: No element" on every first-list creation and a stale id
for the logo upload otherwise (now `ref.read(listListProvider)`); the
create adapter dropped `program` entirely, so the admin's program text
never reached the backend (added to `toListBase()`); and
`SectionList.build`'s `lists.when(data: (list) { list = list; })`
assigned its own shadowing parameter — a no-op that kept the per-section
map empty on mount, so list cards only appeared after a manual
pull-to-refresh (now `maybeWhen` on the outer variable).

46. **`Loader` sized itself to `constraints.biggest.shortestSide`, so every
    page-level spinner grew to fill the box it landed in.** The hardcoded
    `24.0` fallback only ever applied to unbounded constraints, which is the
    minority of call sites. Sweeping all 14 `Loader(` call sites in `lib/`:
    the boot screen (`others/ui/loading_page.dart`, literally
    `Scaffold(body: Loader())`) drew a 360px spinner on a phone and 1080px
    on the desktop web build; the pay page's QR placeholder and the raffle
    ticket's scan code wrap their `Loader` in
    `SizedBox(screenWidth * 0.8)`, i.e. **288px on a 360 phone and 1536px on
    desktop** — a spinner wider than the window it sits in; `AccountCard`'s
    `AsyncChild` sat in the main page's own `SizedBox(height: 250)`. `Loader`
    now takes `maxSize` (default `Loader.defaultMaxSize` = 64) and clamps:
    `math.min(available, maxSize)`, with the unbounded fallback named
    `Loader.fallbackSize` (still 24). Small boxes keep the size-derived
    behaviour, and a caller that genuinely wants a bigger spinner passes
    `maxSize`. Verified non-vacuous by reverting the clamp: 7 of the 10 new
    guards fail (boot screen 288, QR placeholder 99, the phone/desktop/80%
    box cases 360-1080).

    Two test-harness facts came out of it and are now conventions 19-21:
    **a page that navigates from `build` poisons every later router test in
    the same isolate** (`LoadingPage`; and a `/mypayment` test that ran after
    another module's page rendered the *flappybird leaderboard*, because
    qlevar_router keeps the active branch in process-global state that
    survives a `ProviderContainer` swap), and **the mypayment account card
    overflows under the test harness font at 360 and 412 but not at 480**.
    The overflows are a harness artifact, not a bug: `flutter_test` draws
    every glyph as a square of the font size, where "Personal balance" at
    18px measures 288px against a 260px budget and the five 12px bold button
    labels measure 383px against 300px; loaded with the real Roboto TTFs from
    the Flutter SDK they measure 137.9px and 211.3px, i.e. 92px and 89px of
    headroom on a 360 phone. `MainCardTemplate` was deliberately left alone.
    The first version of the mypayment guard was also vacuous — it held the
    *stores* call open, whose `AsyncChild` sits in a `Column` and so took the
    24px fallback even before the fix; it had to be retargeted at the wallet
    call to reach the bounded account-card loader.
47. **Four cards fixed a width and then let their content exceed it.** The
    standing sweep (`fixed_width_cards_test.dart`) mounts every widget class
    in `lib/` that hardcodes a width and puts flex children inside it — 65 of
    them, which is more than the 87 card-ish classes in the codebase had
    between them — at 360x640 with the app's real fonts, and it found four
    real overflows that no page-level test could see because every page
    shell runs at 1920x1080:

    * `AdminAdvertCard`'s header `Row` put the title `Column` in an
      **unconstrained** flex slot next to a `Spacer` and two icon buttons, so
      a 52-character advert title pushed the edit and delete buttons 37px
      off the right edge of a 300px card. Now `Expanded` + `maxLines: 2` +
      ellipsis (convention 17's rule: a flex child in a `Row` needs its
      finite width from the enclosing card).
    * `SumUpCard` is a fixed 90x50 box holding a two-line `Column`; the title
      had no line cap, so it wrapped and overflowed the bottom by 60px. Both
      lines are now `maxLines: 1` + ellipsis.
    * `LinkCard` is a fixed 70px tall and its name `Text` had no line cap
      either — 12px out of the bottom. Now `maxLines: 2` + ellipsis.
    * `ProductDetailCard`'s content column ended in a decorative 10px
      `SizedBox`, and the card is a fixed 100px tall — exactly the "dead
      tail spacing" that ledger #38 removed from the amap and raffle cash
      cards. Removed, which clears a 1px overflow.

    Two harness facts made the sweep possible at all, both of which would
    have produced a wall of phantom failures otherwise. **The harness font is
    not a device** (convention 20): the mypayment account card overflows by
    32px and 83px under it at 360 and is clean under the bundled Lato, so
    `loadAppFonts()` registers `assets/google_fonts/*.ttf` and every
    measurement in the sweep is real typography. And **a card that crashes
    during build satisfies "no overflow" for the wrong reason** — fourteen of
    the first run's nineteen failures were exactly that, an unstubbed
    `MapNotifier.autoLoad` logo fetch or a `firstWhere` over an empty species
    list, leaving an empty tree. Each entry now asserts
    `find.byType(card.type)` first, so a card that does not mount is a
    failure rather than a pass.

    The ratchet is what makes it a check rather than a snapshot: the first
    test re-runs the detector (ported to Dart in
    `test/shared/fixed_width_card_detector.dart`, cross-checked against the
    Python one) and fails if a candidate is neither mounted nor listed in
    `_notMounted` with a reason. Six were exempted when this ran —
    `OrderSection`, `ModuleCard`, `FiltersBar`, `PersonalPlantCard`,
    `PlantCard`, `ListListCard` — each because its content comes from a
    page-level provider map the shared container does not seed; they are
    covered at page level by their module's integration tests instead.
    Only `OrderSection` still is: the other five were mounted for real once
    the fixtures grew their own inline stubs (and the sweeps the seeds that
    fire on the providers' own fetches), and
    `tools/unit/mounted_but_exempted_ratchet_test.dart` now fails any
    widget registered as mounted and exempted at the same time — the
    `ModuleCard` shape that let this list rot in the first place.
48. **Three phone-width defects in purchases, none of them a hardcoded
    width.** The fixed-width sweep (#47) had already taken the four
    `width:`-then-overflow cards, so this round mounted the rest of the card
    layer in the six modules that had no widget level at all — cinema,
    tickets, loan, feed, phonebook, purchases — and the remaining bugs are
    the shapes a width-based detector cannot see:

    * The scan page's `TicketCard` put its label `Column` in an
      **unconstrained** flex slot of a `Row`, next to a `Spacer` and a
      trailing icon — ledger #47's `AdminAdvertCard` defect, the same family,
      one module over. A 12500-use ticket pushed the row 149px past the
      right edge. The `Column` is now the `Expanded` child and the `Spacer`
      is gone (a `Spacer` beside an `Expanded` can only steal half the slack
      and would have pushed the icon to the middle of the card).
    * The purchases main page's header `CustomButton` pair overflowed by
      236px. Two causes that had to be fixed together: the button's own
      `Row` had a 20pt bold `Text` with no flex and no line cap, and the
      page's header `Row` handed both buttons unbounded width. The label is
      now `Flexible` + `maxLines: 1` + ellipsis and the page wraps each
      button in `Flexible`, which caps it at half of the 300px the padding
      leaves. The French labels are already at the limit — "Historique" and
      "Scanner" measured 319px against 300px — so this overflows for a real
      user, in a real locale, today.
    * `CustomButton` then **asserted** instead of overflowing once the label
      went flexible: a `Flexible` under an unbounded width throws
      "RenderFlex children have non-zero flex but incoming width constraints
      are unbounded", so any caller that put it in a plain `Row` hit a
      layout assertion. Fixed with `mainAxisSize: MainAxisSize.min`, which
      shrink-wraps when the width is unbounded and still ellipsizes when it
      is not. A component that is only safe under one particular parent is a
      landmine for the next caller, so `purchases_cards_widget_test.dart`
      keeps a test that mounts a lone button in a bare `Row`.

    Twenty-five of the twenty-eight widgets mounted this round were already
    correct, and the reason is worth recording: they render through
    `ListItemTemplate`, which wraps its title in an `Expanded` `Column` and
    lets the text wrap. Phonebook's four rows all go through it, which is
    also why the width-based detector found no phonebook candidate at all.
    Mounting them proves the family rather than assuming it. Two more
    detector blind spots turned up while writing the fixtures, both of them
    generated-model traps worth remembering: `MemberComplete`'s
    `copyWith` is `nickname ?? this.nickname`, so passing `null` KEEPS the
    old nickname and a copyWith fixture can never reach the `nickname ==
    null` branch of `getName()`; and `StatTile` renders its value in a
    `RichText`, which `find.text` does not match without `findRichText:
    true`.

    One finding is a gap in the sweep rather than a bug: cinema's
    `SessionCard` has two completely different layouts behind
    `isWebFormatProvider` (a 500px safe-width threshold), and mounting it at
    360 only ever measures the phone branch. `cinema_cards_widget_test.dart`
    mounts both, each at a surface where the provider genuinely returns true
    or false rather than by forcing the flag against the width it derives
    from.
49. **`DaysEvent`'s location/association row overflowed by 324px** — the
    home module's day card had a `spaceBetween` `Row` holding a
    `Text(event.location)` and a `Text(event.association.name)` with NOT ONE
    `Expanded` between them, inside a `CardLayout(height: 135, width:
    double.infinity)` on a card that is 300px wide at a phone. A long venue
    plus a long association name is the ordinary case for a real association,
    so this is a shipped visual bug, debug-visible only. Both lines are now
    `Expanded` + `maxLines: 1` + ellipsis with an 8px gap, the same fix as
    ledger #47's `AdminAdvertCard`. Found by mounting the card for the first
    time, four of five shapes in the new file failing on the same `Row`.

    The round that found it is the ratchet. Convention 23 recorded that the
    width-based detector cannot see a width passed as an ARGUMENT, and
    `CardLayout` is the one wrapper used widely enough to be worth a detector
    of its own, so
    `findFixedSizeCardLayouts()` in
    `test/shared/fixed_width_card_detector.dart` (first written beside a
    Python twin, since deleted — see the tools section below) finds the 25
    classes that
    hand it a literal dimension, and
    `tools/widget/fixed_size_card_layouts_test.dart` fails if any of them is
    mounted by no file under `test/**/widget/`. Thirteen are mounted (twelve
    already, by the sweep; `DaysEvent` and amap's `UserCashUiLayout` by this
    round) and twelve are exempt with reasons: four pages, one modal, three
    admin edit dialogs, two admin list sections, `OrderSection`, and
    `DetailOrderUI`.

    `DetailOrderUI` is the interesting exemption, because it is real debt and
    it is one line away from not being. Its build watches
    `userOrderListProvider`, whose notifier `return state` from `build()` —
    bug #3 — and under Riverpod 3 that throws "Tried to read the state of an
    uninitialized provider" through the provider's own error channel, not
    through `FlutterError.onError`. The `ignoreAmapKnownQuirks()` filter
    absorbs the message in the integration tests but cannot here, so the card
    never lays out. The fix is `return const AsyncValue.loading()`, which is
    what every other `ListNotifierAPI` subclass in the codebase already does;
    it was left out of this round because it changes main-page provider
    behaviour and belongs to whoever owns bug #3.

50. **The pay sheet's QR overflowed its own container by 420px, and toasts
    cannot be asserted at all in this harness.** Two findings, one round.

    `QrCode` sized its square from `MediaQuery.size.width` while the sheet
    that hosts it is bounded by the screen HEIGHT, and the `Column` in
    `pay_page/confirm_button.dart` handed it an unbounded height so it never
    saw the budget it was being given. On a short or landscape surface the
    square came out 420px taller than the space available — a user on a small
    phone or in landscape sees a clipped, un-scannable QR on the one screen
    that has to work. Fixed at both ends, the same way `Loader` was fixed in
    ledger #46: the sheet slot is `Flexible` so the remaining height really is
    the QR's budget, and `QrCode` derives its side from its incoming
    `LayoutBuilder` constraints (falling back to the media query only when a
    dimension is infinite) rather than from the viewport.

    The second finding is a testing constraint, not an app bug, and it is the
    more valuable of the two because it was silently producing false passes.
    A probe proved `toastification`'s overlay is unreachable from `find`ers in
    a pumped tree: `find.textContaining(<message>)` matches **zero** widgets
    for a toast that was demonstrably raised. So every test that asserted a
    toast's copy was asserting nothing. The dangerous case is not the obvious
    one (a copy that appears nowhere else simply FAILS, which is fine) but
    the string that appears in two places — `paiementPleaseAcceptTOS` is both
    the toast AND part of the TOS dialog's markdown body, so a fund test
    asserting it after tapping Top-up was really asserting the dialog was
    still mounted. That is now convention 25, with the rule: assert the state
    a toast reports (no repository call, the sheet stayed, the list item
    changed), never its copy. The fund tests do exactly that, and it makes
    them stronger than the toast version would have been — the two amount
    guards are now told apart by what they PREVENT, with the cap boundary
    straddled exactly (950,00 against 50,00 held goes through, 951,00 does
    not) so the arithmetic is pinned rather than implied.

    The round's coverage: `mypayment` **59.2% → 76.2%** (2419 → 3116 of 4090,
    1666 → 974 uncovered) from 57 tests in three files. The payment-
    delegation family is the find of it — `paiment_delegate/` plus the two
    modals that host it was **338 lines at exactly 0%**, and it is the rare
    part of this app that is pure widget logic, so it needed no router at all.
    Two behaviours there are only visible as a pair and are now asserted as
    one: the countdown decides whether the confirm button is still live, and
    the button's own expiry animation is separate from the countdown's, so
    they can disagree. `ConfirmButton` with `totalSeconds: null` is the case
    that matters — a zero-duration controller would grey the button out on the
    first frame without its `> 0` guard, which is the whole reason that guard
    is there.

    Also landed for the fund test: `FakeUrlLauncher` (a
    `url_launcher_platform_interface` fake, following the pattern the project
    already uses for platform interfaces) and `makeContainer(deviceKeyId:)`,
    which is what makes the pay sheet's no-key gate reachable at all.

51. **Six in-place mutations of provider state across the whole of `lib/`, two
    of which never notified a listener at all.** Ledger #12 swept
    `.sort(`. The same sweep generalised to every mutating list/set method —
    `add`, `addAll`, `clear`, `insert`, `remove`, `removeAt`, `removeLast`,
    `removeWhere`, `shuffle`, … — finds 190 call sites, of which **12 were
    defects in 7 files** and 21 remain unresolved for a human to read.
    `tool/detect_inplace_list_mutations.py` +
    `findInplaceListMutations()` in
    `test/shared/inplace_list_mutation_detector.dart` now do it, and
    `tools/unit/inplace_list_mutations_test.dart` fails on any new one.

    Four of the twelve never notified at all, which is why this is worth a
    ledger rather than a lint. `MapNotifier.addE` (its `data:` arm) and
    `deleteE` did
    `state[t] = …; state = state;` — the "poke Riverpod" idiom — and since
    `defaultUpdateShouldNotify` is `previous != next` with identity equality on
    a `Map`, that assignment compared the map to itself and notified nobody.
    `deleteE` additionally called `removeAt` on `eList`, the list *already
    inside* `state[t]`. Both have production callers:
    `advertPostersNotifier.deleteE(advert.id, 0)` and
    `deliveryOrdersNotifier.deleteE(deliveryId, index)` — so deleting an
    advert's poster, or a line of a delivery order, left the row on screen
    until something unrelated rebuilt it. `ListNotifier.add`/`addAll` had the
    same shape — `state = AsyncValue.data(d)` wrapping the *same* list, so
    `previous != next` was false and they never notified either, which is a
    stronger failure than the aliasing bug they also had. (`addE`'s
    `orElse:` arm and `deleteT`/`setTData`/`resetTData` all allocate a new map
    and did notify; they were only ever aliasing.)

    The other four are aliasing without a notification gap:
    `advert`'s `addAssociation` (`state.add(i); state = state.sublist(0);` — an
    in-place write plus a copy of itself, which is just a slower
    `[...state, i]`); seed-library's `deletePlantFromList`/`addPlantToList` in
    two files, each sitting directly beside a sibling method that already did it
    correctly; phonebook's `addMember`, which pushed the new membership into
    the *caller's own* `MemberComplete` — the same instance already in state;
    and `admin`'s group-member picker, where `value.remove(e)` deleted from the
    list inside `userList` without notifying, leaving the "+" row tappable so
    the same user could be added twice.

    Phonebook's `reorderMember` was the worst of the set and had no test at
    all. It aliased `members[i].memberships`, mutated it in place, and then
    **threw away the result of `members[i].copyWith(memberships: …)`** — so the
    renumbering only ever worked by accident, through the in-place mutation it
    was not supposed to depend on. It now builds a new list and uses the
    `copyWith` it was already calling.

    Every fix has a test that fails against the old code, and that was the
    instructive part: my first attempt at the notification tests **passed
    against the reverted source**, because the revert patch had silently
    no-op'd against text `dart format` had already reflowed. A non-vacuity
    proof that is not checked is worth nothing, so every fix was reverted with
    `git show HEAD:<file>` and re-run — 4 of 7, 4 of 5, 3 of 5, 1 and 1 failed
    respectively, each with the diagnostic that proves it saw the real bug.

    The detector's own lesson is convention 27: two of its regexes were
    originally spliced as `r'…$_fragment…'`, and Dart raw strings do not
    interpolate, so both compiled to patterns containing the literal text
    `$fragment` and matched nothing. Findings went 21 → 115 with no error
    anywhere. That is now a test.

    Two harness notes from the same round. `CardLayout` wraps its child in a
    `Hero`, so it cannot be nested inside another `CardLayout` — a test that
    tries asserts "A Hero widget cannot be the descendant of another Hero
    widget", which is a confusing way to learn that a layout wrapper takes
    plain content (amap's `UserCashUiLayout` is handed a `Column` of
    `AutoSizeText`s, not a `UserCashUi`). And `ignoreAmapKnownQuirks()` now
    lives in `shared/app_scaffold.dart` rather than being defined in
    `amap_integration_test.dart` and imported by five sibling files;
    `amap_integration_test.dart` re-exports it, so none of those imports
    changed.

52. **Ledger #36 fixed, and a second off-by-offset found beside it while
    proving it.** `setUpNotification` read `topicsProvider.notifier` before
    `requestPermission()` had answered; reading a notifier instantiates it,
    and `TopicsProvider.build()` fetches the list itself, so **every** launch
    hit `notificationTopicsGet` — including for users who had just denied
    notifications and can never subscribe to one, and it fired on the first
    frame with the dialog still open. `setup.dart` now `ref.read`s the
    notifier inside the authorized branch: denied is **0 calls** (was 1),
    authorized stays 2, which is what the authorized file asserts. The
    regression is pinned twice in
    `service/integration/setup_notification_denied_integration_test.dart` —
    the topic counter must be 0, **and** `container.exists(topicsProvider)`
    must be false, because that second assertion is what makes the first
    honest rather than a race that happened to resolve. Proven by reverting
    `setup.dart` with `git show HEAD:` — `Expected: <0> Actual: <1>`.

    The neighbouring file had the same shape of bug in its dot indicator.
    `SmoothPageIndicator`'s `onDotClicked` hands back a **dot** index (0-based
    over the screenshots) while `PageController.animateToPage` takes a
    **page** index, and the page showing screenshot N is `initialPage + N`
    because the carousel is parked at 1000 for infinite scroll. The raw index
    was forwarded, so clicking dot 1 showed screenshot **2**. Fixed by
    translating (`initialPage + index`), pinned in
    `login/widget/login_web_panels_widget_test.dart`, and proven the same way:
    against the reverted file the tap shows `Upcoming screenings`.

    The instructive part is the assertion I threw away. The carousel's offset
    is also not a multiple of the screenshot count (1000 % 7 = 6), and
    `SmoothPageIndicator` derives its active dot from `page % count`, which
    looked like the indicator highlighting the wrong dot at rest — so I
    "fixed" `initialPage` to a multiple of the screenshot length and wrote a
    test for it. The test failed with `offset: 1001.0`, and reading
    `WormPainter` showed why: it has an explicit `offset > count - 1` branch
    that wraps the travel for an infinite pager, so dot 0 was painted
    correctly all along. Both the "fix" and the test were reverted. A wrong
    premise caught in one grep is cheaper than a wrong premise that reaches
    `lib/`, and the only reason it was cheap is that the assertion was read
    against the library instead of against my own expectation of it.

53. **`FirebaseTokenExpirationNotifier.reset()` had no test, and one of its two
    callers is unreachable.** The method clears the per-user FCM token cache —
    the 30-day row `setUpNotification` reads to decide whether to re-register
    a push token. Both call sites are UI callbacks that run *after*
    `await auth.deleteToken()` behind an `if (!kIsWeb)` guard (false in tests,
    so it does run), which puts it out of reach of any provider unit test.
    Driving the two real logout paths takes
    `firebase_token_expiration_provider.dart` to **21/21**.

    Each path asserts the same two things, because `reset()` does two things:
    the prefs row is **removed**, and the in-memory state is **emptied**.
    Checking only prefs would pass even if the `state = ...` assignment were
    deleted, since `reset` assigns state directly rather than re-reading; the
    pair is what makes each half load-bearing.

    The settings path (`settings/integration/settings_logout_integration_test
    .dart`) is a real journey: seed the row, `await notifier.ready` so the
    row is provably in state before the test means anything, scroll to the
    "Log out" row, confirm the modal, and land on `/login` with the success
    toast. `flutter_secure_storage`'s channel is stubbed so `deleteToken` is
    real but hermetic.

    The quit-dialog path turned up something worth more than the coverage:
    **`setDisplay(true)` is called nowhere in `lib/`.** `NavigationTemplate`
    read `displayQuitProvider` to decide whether to mount `QuitDialog`, but
    the only writes anywhere were the dialog's own two `setDisplay(false)`
    calls. The dialog was unreachable in the shipped app — dead code kept
    alive by a flag nobody flips. A test that flips the flag by hand covers
    that dead code perfectly and proves nothing about the product, so the
    honest move was to ask rather than to bank the coverage. **Decision: it
    is deleted.** `navigation/ui/quit_dialog.dart` (60 lines) and
    `navigation/providers/display_quit_popup.dart` (16) are gone, along with
    the template's branch, its `displayQuitProvider` watch and two imports
    (-4), the provider's own unit test (-11) and the integration test that
    existed only to reach it. **This is the first round to delete `lib/`
    files**, so the lib-preservation check is deliberately inverted here:
    `git status lib/` must show exactly those two paths as `D` and nothing
    untracked. Settings' logout is now the app's single logout path, which
    is also the one the earlier ledger #21/#29 toast fix was written for.
    Deleting code that the quit-dialog test had covered moved the navigation
    module 89.2→**89.8%** — covered dead code is still dead code, and removing
    it is the only way the percentage can tell you so. The test that
    motivated the question still earned its keep: it is what surfaced that the
    second `reset()` caller was already unreachable.

    Two harness corrections this round. `deleteToken` touches
    `flutter_secure_storage`'s method channel, which does not exist in a test
    env, so the test stubs it — the same channel the login flow's test
    already fakes. The deleted quit-dialog test had also taught the harness
    something: its toast fired on a `context` its own `QR.to` was about to
    invalidate, so the text was unfindable while `displayToast` still armed a
    real 2.5s `PausableTimer` that failed the test if left running. I had
    written in that test's doc comment that the toast would not fire at all;
    the pending-timer failure corrected me (convention 25).

54. **`FirebaseTokenExpiration.toJson` wrote the string "null" for a null
    expiration, and its own reader could not parse it back.** `expiration` is
    `DateTime?` and `FirebaseTokenExpiration.empty()` sets it null, but
    `toJson` called `expiration.toString()` — and `toString()` on a null is the
    four characters `null`. `json.encode` faithfully wrote that as a JSON
    **string**, which `fromJson`'s `json['expiration'] != null` guard sailed
    straight past (the string is not null), so `DateTime.parse("null")` threw
    a `FormatException` out of `getSavedDate`. That runs inside
    `notifier.ready`, which `setUpNotification` awaits inside
    `requestPermission().then` — so the failure took the whole authorized
    branch down, before it registered anything.

    Fixed at both ends, because fixing only the writer leaves anyone who
    already has a poisoned row crashing:
    - `toJson` uses `expiration?.toString()`. The on-disk format for a real
      date is **unchanged** (`DateTime.toString()`), so no existing row needs
      rewriting — deliberately kept rather than switching to
      `toIso8601String()`, which would have been tidier but would have
      changed a format an existing test pins.
    - `fromJson` parses through a `_parseExpiration` helper built on
      `DateTime.tryParse`, so an absent, empty, malformed or legacy-`"null"`
      value all mean "no date" — which is exactly the branch `setup.dart`
      already handles by re-registering the token.

    **The poison path was latent, not live.** Nothing in `lib/` can currently
    write a null expiration: the only writer is `saveDate`, whose parameter is
    a non-nullable `DateTime`, and `copyWith` cannot null an existing date
    either. So this was a serializer that could produce a document its own
    parser rejected — a landmine for the next caller, not a crash users were
    hitting. That is worth saying plainly, because it is the difference
    between "urgent" and "fix before someone uses it", and it is exactly what
    the tolerant reader is for: it makes the landmine harmless rather than
    load-bearing.

    The tests note a trap worth remembering. The existing "a null expiration
    re-registers instead of crashing" case seeded its row with
    `expiration?.toString()`, which is null-aware and therefore encodes to a
    real JSON `null` — so it exercised the *guard* and never the *parser*.
    Reading it as coverage of the null path would have been wrong. The new
    notifier test seeds the literal four characters instead, and asserts the
    full recovery: no exception escapes, the token re-registers
    (`topicsCalls == 2`), **and** the poisoned row is overwritten with a real
    date, so this is a one-time recovery rather than a crash every launch.
    Against the old model it fails exactly as the bug reads —
    `FormatException`, then `Expected: <2> Actual: <1>`.

55. **Three shell fakes returned constants that pinned shut real `lib/`
    branches — two of them hiding whole files at 0%.** This round audited all
    25 override fakes in `test/shared/app_scaffold.dart` for the shape that
    matters: a fake that can only say ONE thing, used by a `lib/` site that
    branches on more than one. Three matched, and the pattern generalises —
    **a fake that returns a constant does not neutralise a branch, it deletes
    it.** A test suite that is green over a deleted branch looks identical to
    one that is green over a covered one.

    **F1 — the version fakes pinned the update branch shut.**
    `FakeVersionVerifierNotifier` hardcoded `minimalTitanVersionCode: 1` and
    `FakeTitanVersionNotifier` returned `999`, so the comparison `lib/` makes
    in three places (`AuthenticatedMiddleware`, `AppTemplate`, `LoadingPage`)
    was `1 <= 999` — always true, forever. The "your app is too old" decision
    is the `!value` arm of that, and no test could reach it. `UpdatePage` was
    **0/12** and `RollbackPage` **0/22**: not untested but *unreachable from
    any test*, which is rarer and stronger. Both fakes are parameterised now,
    and `test/others/widget/others_version_pages_widget_test.dart` (7 tests)
    mounts the two pages with `titanVersion: 1, minimalTitanVersionCode:
    1000`. `RollbackPage` additionally needs `minimalHyperionVersionProvider`
    faked: the real notifier reads `pubspec.yaml` through `rootBundle`, which
    a test asset bundle does not carry. Result: 11/12 and 21/22, and the one
    miss in each is a static field, not a branch.

    **F2 — the permission-catalog fake short-circuited module gating
    entirely.** `FakePermissionsNamesListNotifier` returned `[]` in three of
    the four containers and `makeContainer` did not override it at all. An
    empty catalog means `buildPermissionToModuleRootMap` yields `{}` and
    every lookup in `computeUserModuleRoots` hits its `continue`, so **every
    user in every test had zero modules** — and that is the function that
    decides which modules a user may open. `module_roots.dart` was 7/20.
    `makeContainer(permissionCatalog:)` and a parameterised
    `FakePermissionsNamesListNotifier(names)` open it;
    `test/super_admin/unit/module_roots_test.dart` (16 tests) now takes the
    file to **20/20**, and the shell's navbar — whose module items come from
    this chain — renders real items for the first time.

    **F3 — one state of `versionVerifierProvider` had no fake at all.** The
    two existing fakes answer `data` and `loading`; nothing could answer
    `error`. Both `error:` arms route to `/no_internet`
    (`authenticated_middleware.dart:59`, `loading_page.dart:46`), and no test
    in the suite had ever mentioned `NoInternetPage`, so it was **0/31**.
    `FakeErroringVersionVerifierNotifier` plus
    `makeContainer(failVersionVerifier:, versionVerifierRecoversOnRetry:)`
    brings it to **30/31** — and the single remaining line is
    `QR.to(HomeRouter.root)`, which bug **#57** shows is unreachable.

    Three guard tests keep this from silently reverting, one per finding,
    because each page mounts directly and never consults the thing the fake
    was pinning: the version file asserts `minimal <= titanVersion` is
    `false`; the module-roots file asserts a non-empty catalog produces
    non-empty roots; the no-internet file asserts
    `versionVerifierProvider` is an `AsyncError`. All are proven against
    `git show HEAD:`.

56. **`buildPermissionToModuleRootMap` keys its map by the name with the
    module prefix STRIPPED; `computeUserModuleRoots` reads it with the FULL
    name.** `KNOWN BUG`, pinned by three cases in
    `test/super_admin/unit/module_roots_test.dart`.

    ```dart
    map[permissionName] = moduleRoot;                      // 'booking.access' -> 'access'
    ...
    final backendRoot = permissionToModule[permission.permissionName];
    ```

    `permissionName` is the catalog entry minus its prefix, but
    `CorePermission.permissionName` is whatever the backend sent for that
    user. Both shapes are in circulation, so one of the two lookups always
    misses and the user gets fewer modules than their permissions say:

    - **full name** (`booking.access`): `continue`s. The user sees only the
      Settings fallback, even holding a valid module grant.
    - **bare name** (`access`): hits, but every module collapses onto the
      single key `access`, so the map's last writer wins and the user is
      routed to whichever module the catalog happened to list last.

    `lib/super_admin/providers/permissions_list_provider.dart:172` already
    hedges over exactly this — `mappedPermissions[fullName] ??
    mappedPermissions[shortName]` — which is evidence the codebase knows the
    two shapes exist and does not know which one arrives.

    Left unfixed deliberately: each candidate answers "which modules may a
    user open", and the three answers differ for users who hold both
    `booking.access` and `raffle.access` today. That is a product decision,
    not a refactor.

57. **`NoInternetPage`'s retry button needs TWO taps — the first is a silent
    no-op.** `KNOWN BUG`, pinned by
    `test/tools/integration/no_internet_middleware_integration_test.dart`.
    (An earlier reading of this file called the button *unreachable*; that was
    wrong, and the correction matters more than the original claim.)

    ```dart
    onTap: () async {
      isConnectedNotifier.isInternet();   // not awaited
      if (isConnected) {                  // the value `build` captured
        QR.to(HomeRouter.root);
      }
    },
    ```

    Two independent mistakes. `isConnected` is a `final` captured when the
    widget was built, and the user is on this page **precisely because** it
    was false — so the guard cannot pass on the tap that would make it true.
    And `isInternet()` is not awaited, so even reading a fresh value would
    race the re-ask. The `async` on the closure hides the second one: it reads
    as though the closure waits.

    **It is not a dead end, and the distinction is the whole point.** Tap 1:
    the stale `isConnected` is still false so no navigation runs — but the
    re-ask *does* succeed, flipping the verifier to `AsyncData` and
    `isConnectedProvider` to true, which rebuilds the page with a closure that
    now captures `true`. Tap 2 therefore navigates to `/home`. The first tap
    is a wasted gesture with no feedback whatsoever, and
    `isConnectedNotifier.isInternet()` has exactly one caller in `lib/` — this
    closure — so tap 1 is *always* a no-op. On a genuinely offline connection
    every tap is a no-op and the page is a true dead end.

    The test asserts both halves separately, because they behave differently
    and only the broken one is interesting. `QR.currentPath` is the assertion
    signal rather than `find.byType(NoInternetPage)`: qlevar **pushes** `/home`
    on top, so the old page lingers in the widget tree and a
    by-type assertion would report the stale page as still present.
    `QR.to(HomeRouter.root)` is the one uncovered line in a file that is
    otherwise 30/31, and it cannot be covered without changing the code.

    The consequence is worth stating plainly: the only way out of the
    no-internet screen does not work. Today the user recovers by killing the
    app and relaunching, which re-runs the whole boot chain and re-reads
    `versionVerifierProvider` — so the page is self-healing in practice and
    this is a real-but-circumventable defect, not a bricked app. Left
    unfixed because the fix changes behaviour (does retry *navigate*, or only
    re-check and let the user navigate themselves?).

    A third finding from the same sweep was the opposite shape: `NoModulePage`
    (`/no_module`, **0/15**) was a **dead route** — nothing in `lib/` ever
    navigated to it, by constant or literal, while the place that computes the
    emptiness it exists to report (`moduleRootListProvider` → `loadModules([])`)
    quietly left the user on the feed with an empty navbar. Same shape as the
    unreachable `QuitDialog` deleted in ledger #53: a page that exists,
    compiles, ships — and can never be seen.

    **Since wired.** `AuthenticatedMiddleware` now forwards to
    `AppRouter.noModule` when the path is `/` AND `moduleRootListProvider` has
    *resolved* to an empty list AND the user is neither admin nor super-admin;
    the check sits immediately after the signed-in gate and BEFORE the
    `return FeedRouter.root` forwarding branches. Scoping it to `path == '/'`
    was the correction: a first version that ran for every guarded path broke
    five tests and turned out to be redirecting *away from* the Others page
    the user had just opened. `NoModulePage` also had no exit at all, so the
    same round added an "Others" `TextButton` → `QR.to(AppRouter.allModules)`
    — the redirect was otherwise a trap. Its forward is now gated on a
    non-empty root list, which closes an infinite redirect loop that the route's
    own unreachability had been hiding.

    Making that state testable required one harness change worth recording:
    `makeContainer`'s `permissionsProvider` override used to be
    `isNotEmpty`-gated, so "this user holds no permissions" — the exact state
    `/no_module` exists for — could not be expressed. It is now
    **unconditional**, and an empty list means empty. `permissionCatalog`
    stays conditional on purpose: leaving the real notifier loading is what
    keeps ordinary shells *off* `/no_module`. Covered by
    `others/widget/no_module_page_widget_test.dart` (3) and
    `tools/integration/no_module_redirect_integration_test.dart` (4).

58. **The mypayment pay flow was 100% line-covered and still proved nothing
    about the payment.** `pay_page.dart`, `confirm_button.dart` and
    `qr_code.dart` already sat at 48/49, 82/83 and 21/23 — and every one of
    those tests stopped at `expect(find.byType(QrCode), findsOneWidget)`. The
    sheet is a payment instrument; what a seller's phone reads is the *string*
    inside the code, and no test had ever looked at it. Two reasons it was
    invisible, both structural rather than accidental:

    - **`QrImageView.data` is private**, and the `qr` package ships no
      decoder, so nothing in the widget tree can be asked what the code
      carries. `find.byType(QrImageView)` is weaker than it looks anyway: on
      an invalid or over-long payload `QrImageView` renders a bare
      `Container()` and **no `CustomPaint` at all**, so the existing assertion
      passed for a code the seller could not scan.
    - **`QrPainter` is a `CustomPainter`, not a widget**, so
      `find.byType(QrPainter)` finds nothing — it has to be pulled off the
      `CustomPaint` that carries it.

    **The interception point is one layer down, where the payload is still
    plain text.** `getQRCodeContent` signs `data.codeUnits` and base64s the
    result into the envelope, so `FakeKeyService` now records every
    `signMessage` call (`signedMessages`, plus `keyPairForTest` for verifying
    against the public key). That is the whole hand-off, end to end:
    `AccountCard.showPayModal` → the three gates → `PayPage`'s keypad →
    `ConfirmButton`'s `local_auth` → `QrCode`'s signing → the consumer's
    `BarcodeNotifier.updateBarcode` (`ScanInfo.fromJson(jsonDecode(barcode))`).

    Result: the flow is **310/314**, with `pay_page.dart`, `confirm_button.dart`
    and `qr_code.dart` all at **100%** and `keyboard.dart`, `info_card.dart`
    and `barcode_provider.dart` at 100%. The four lines still missed in
    `functions.dart` are the brightness-correction branch of
    `generateColorVariations`, a store-card colour helper unrelated to paying.

    **What the round actually added, beyond the numbers:**
    - The **cents** the buyer typed are asserted as the envelope's `tot`,
      reached through the real consumer parser — `12,50` → `1250`, which pins
      the `(12.50 * 100).round()` float round against drift.
    - The signature is a **real 64-byte Ed25519** that **verifies against the
      device's public key**, and a payload claiming one more cent does **not**
      verify. Without that second half a signature over some unrelated string
      would still pass the first.
    - **Closing the QR sheet refetches the wallet and the history** (counted
      with `clearInteractions` first, so the assertions are about the pop and
      not the page load).
    - **A wallet that fails to load leaves the sheet fail-closed.** Both
      `PayPage` and `ConfirmButton` read the balance through
      `maybeWhen(orElse: () => 0)`, so an error presents as a *zero* balance
      rather than an error — the safe direction, and the only reason that
      branch is worth a test. Neither site checks `isLoading`, so if the
      default ever became "unlimited" the sheet would cheerfully hand out a
      payment larger than the wallet.

    Five probe patches, each reverted from a `/tmp` backup rather than
    `git show HEAD:` — `confirm_button.dart` and `qr_code.dart` are **modified
    vs HEAD** from earlier rounds, so `git show HEAD:` would have destroyed
    those fixes. `* 100` → `* 10` killed 2 tests; `store: true` → `false` killed
    2; dropping the balance check killed the fail-closed guard and the
    pre-existing over-balance guard; dropping `getMyWallet()` killed the
    refetch count; pinning the uuid killed the rebuild test.

    Two of this round's own assumptions were wrong and the tests said so:
    `FutureBuilder` **keeps the previous snapshot** when its `future` changes
    (`didUpdateWidget` calls `_snapshot.inState(...)`, which preserves `data`),
    so a re-sign does *not* flash a loader — the transaction id changes
    silently; and `QrPainter` being a painter, not a widget (above).

59. **`QrCode` mints a fresh transaction id on every rebuild, so a payment
    code can change while a seller is scanning it — with no visible sign.**
    Pinned by `test/mypayment/widget/pay_qr_code_widget_test.dart`.

    ```dart
    final id = const Uuid().v4();                       // inside build()
    return FutureBuilder(future: getQRCodeContent(id, …), …)
    ```

    Both halves re-run on every rebuild: the uuid, and the whole async signing
    pass (`future:` is a fresh `Future` object each build, not a memoised
    one). Nothing in the flow pins `id`, so two rebuilds of the same sheet
    produce two different transactions for the same payment. What makes it
    easy to miss is that **the swap is invisible** — `FutureBuilder`
    preserves the previous snapshot when its `future` changes, so there is no
    loader flash and no error; the image just swaps. A seller who scanned the
    first code and then had it replaced has a payload the seller never
    captured.

    Reachability is ordinary rather than exotic: the sheet hosts `QrCode`
    under a `FutureBuilder`/`LayoutBuilder` that reads `MediaQuery`, so a
    keyboard, a rotation or any ancestor rebuild re-enters `build`. **Left
    unfixed** — the fix is to hoist the id (and the signed payload) into a
    provider or a `State` so the code is minted once per displayed payment,
    but that changes what the backend sees on a re-scan and so is a product
    decision, not a test's. The probe (`final id = 'fixed-id';`) kills exactly
    this one test, which is what keeps it honest.

60. **The fund flow hands the app over to HelloAsso, and no test had ever
    checked what it handed over.** `fund_page.dart` and `confirm_button.dart`
    were at 50/54 and 58/80 with the whole hand-off uncovered: the POST that
    asks HelloAsso for a payment page (`fundingUrlProvider`), and the
    `launchUrl` that leaves the app. Unlike the pay flow there is nothing to
    intercept — the provider's page is a browser, not a device — so the
    assertion has to come from the platform side, and `FakeUrlLauncher` now
    records a `LaunchRecord` (url + `useSafariVC`, `useWebView`,
    `universalLinksOnly`, `enableJavaScript`, `enableDomStorage`) rather than
    just the URL string.

    `fund_page.dart` is now **54/54**, `funding_url_provider.dart` and
    `fund_amount_provider.dart` **100%**, and `confirm_button.dart` 61/80 —
    the fund flow as a whole **126/154** (81.8%), from 119/154. The residue is
    `web_view_modal.dart` (0/9, routed at `/mypayment/fund` and unreachable
    without a `webview_flutter` platform fake) and the `kIsWeb`-only
    `helloAssoCallback` branch, which no VM test can take.

    **What the round added, beyond the numbers:**
    - The **launch mode**, which is the whole premise: `LaunchMode
      .externalApplication` is the only mode that actually LEAVES the app, and
      `platformDefault` would open an in-app web view for an `http(s)` URL, so
      the provider's `titan://mypayment` return could never fire. `useWebView`
      is the only observable difference between the two modes — `LaunchMode`
      itself never reaches the platform, `launchUrl` decomposes it into these
      booleans. `enableJavaScript` is `true` even for
      `externalApplication` (`WebViewConfiguration`'s default) and inert here;
      the test asserts it anyway, with that comment, because my own first
      assumption was the opposite.
    - The **redirect URL**, exactly: `test.titan://mypayment` under the CI
      `--dart-define`s. `endsWith('://mypayment')` would have passed for a web
      URL too, which is precisely the shape that cannot come back into the app.
    - **The cents and the boundary**: 950,00 typed against a 1 000,00 cap with
      50,00 held goes through (`<=`, and the balance is an *addend*), 951,00
      does not, and 960,00 is where the balance stops being load-bearing.
    - **`fundingUrlProvider` does not fetch at build**, unlike its two
      siblings: a funding URL is a transaction, so pre-fetching it would mint
      a HelloAsso session for a top-up the user may never start. Pinned with
      `verifyNever`.

    Eight probe patches, each reverted from a `/tmp` backup (this file is
    modified vs HEAD from earlier rounds, so `git show HEAD:` would have
    destroyed them). `externalApplication` → `platformDefault` kills 2,
    redirect scheme → web URL kills 1, `* 100` → `* 10` kills 2, the balance
    default `0` → `999` kills 1, `<=` → `<` kills 1, dropping the minimum
    check kills 1, and turning `tryLaunchUrl`'s `throw` into a `return` kills
    both KNOWN BUG tests.

    **Two of this round's findings are defects in `lib/`, pinned not fixed.**
    - **The cap check fails OPEN on a missing wallet.** `ConfirmFundButton`
      reads the balance through `maybeWhen(orElse: () => 0)` and then ADDS it:
      `amountToAdd + currentAmount <= maxBalanceAmount`. A wallet that never
      arrives therefore presents as a balance of *zero*, which raises the
      ceiling instead of lowering it — 500,00 is accepted against a 1 000,00
      cap by a user whose balance the app could not read at all. The pay
      sheet's identical default is fail-CLOSED because there the balance is an
      upper bound; same `orElse`, opposite safety, which is exactly why the
      default needs a test at each site rather than a convention.
    - **The failed-launch path has already thrown the amount away.** The
      `data:` arm clears the amount and pops the sheet BEFORE it launches,
      because the POST succeeded — so when the launch then fails the user is
      back on the card having lost what they typed, though nothing was
      charged. The refused-POST path keeps the amount for exactly this reason,
      and the failed-LAUNCH path, which is one step further along and arguably
      worse, does not.

    And one more, found while writing the TOS test: **`MainPage`'s TOS retry
    is unbounded, and a TOS outage wedges the page rather than disabling it.**
    `tos.maybeWhen(error: …)` sits inside `build` with no "already retried"
    flag, so every rebuild on an errored TOS calls `register()` and re-fetches
    the TOS; with an outage that does not heal, that is an await loop inside
    the frame. Measured rather than guessed: this test file hung for **nine
    minutes** with a permanently failing TOS and the runner killed it with
    `Shell subprocess crashed with SIGTERM` before a single assertion ran.
    So the outage in the test has to be made transient (`tosFailsOnce`), and
    what the test pins is the retry itself — exactly one `register`, two TOS
    fetches, and a card that healed. The defect is left unfixed: the fix is a
    retry flag or a backoff, and a test cannot decide whether the second
    register should also be throttled.

61. **A test that renders the wrong page passes — so the suite could not be
    trusted to notice when it happened.** Convention 19 has said for two
    rounds that qlevar_router's active route branch is process-global and that
    one router-driven page belongs per *file*. It was a rule everyone had to
    remember, and the consequence of forgetting was invisible: the affected
    test finds zero of its own widgets, its `expect`s match nothing, and it
    goes green. Nothing in `flutter_test` can see that. The rule is now
    enforced by `test/shared/page_module_guard.dart` from inside `pumpApp`
    (convention 30): index every `class *Page` in `lib/` to its declaring
    module, take the module under test from the call stack, and fail the test
    when the mounted tree holds a page no allowed module declares.

    Installing it found **16 files that cross module boundaries on purpose**
    and had never said so — every one a gate bounce onto `/feed` (admin,
    advert, booking, loan, mypayment invoices, ph, phonebook, tickets ×2,
    vote), `/no_internet` and `/no_module` (which live in `lib/others`, not in
    the module the test is about), `/all_modules` (`lib/navigation`), and the
    notification-setup files that boot `/feed` merely to host the shell. Each
    now passes `allowedModules:` with the reason beside it, which is the same
    discipline as a `_notMounted` exemption — and the same caveat: **a reason
    in an exemption is unverified until the guard is watched failing
    something**, so `tools/unit/page_module_guard_test.dart` mounts
    flappybird's leaderboard inside a mypayment-shaped tree and asserts the
    failure text names the class, its owner and the fix.

    What the guard cost and what it bought, stated plainly: +8 tests, no
    change to coverage (67.2 → 67.4 is ledger #60's fund work), and one
    permanent 20-line scan of `lib/` per integration file's first `pumpApp`.
    In exchange a class of vacuous test can no longer reach CI silently.

62. **The fixed-width detector deliberately excluded fixed HEIGHTS, and that
    exclusion was the same wrong call it had already made once.** The reason
    on record was "clipping is a different question from overflow" — true of a
    `RenderFlex`, where a pinned height compresses, and false of a card, where
    a pinned height with an un-capped `Text` in it overflows *vertically* by
    exactly the same kind of amount. Convention 24 already said this about
    `ItemCardInLoan`; the width half of the scan never caught up.

    `findFixedHeightCards()` is the same scan with the height predicates, and
    the one predicate that had to change is the interesting part:

    - **width** needs **flex children** beside the literal width, because a
      row is exactly as wide as the hardcoded box;
    - **height** needs **content that can outgrow the box** (`Text`, `Column`,
      `ListView`, …), because flex children *compress* inside a fixed height
      — `Expanded` shrinks to fit and the box silently clips. Asking the
      height scan for "is there a flex child" would have found the wrong
      family, and asking it for `Expanded` specifically would have found only
      cards that cannot overflow.

    **71 candidates, 21 of which the width scan structurally could not see**,
    and the shape of those 21 is the finding: eleven are mypayment, and they
    are mostly dialogs and templates rather than cards — `TOSDialogBox`,
    `DeviceDialogBox`, `MainCardTemplate`, `WalletBalanceCard`, `SignInUpBar`.
    A family the width scan never looked at, with no card-level test for
    several of them.

    **Two real defects, both the same shape, both fixed:**

    - `SignInUpBar` — a 24px bold label and a 35px icon in a `Row` inside a
      `height: 50` bar, with nothing bounding the label: a 37-character label
      **overflowed by 122px**. `Flexible` alone would have *wrapped* it, and a
      wrapped 24px line does not fit 50px of height either, so it is one line
      that ellipsises — the only elastic shape that box has room for. Worth
      stating plainly: no current copy overflows (the strings are "Log in",
      "Sign up"), so this is a robustness fix for the next translation, not a
      visible bug today. It was found because the sweep feeds the family
      adversarial strings, which is the only way to see the shape at all.
    - `MainCardTemplate` — the card title sits in a `Row` beside a `Spacer`
      and a 30px toggle icon, and a `Spacer` takes the slack but bounds
      nothing: 37 characters **overflowed by 56px**. This is the account card
      that convention 20 already flags as the tightest layout in the app, and
      the fix is the documented one from convention 17 — `Flexible` around the
      `Text`.

    Both were proved non-vacuous by putting the `/tmp` backups back and
    re-running: the sweep reported exactly those two overflows at exactly
    those sizes, then the fixed files were restored md5-identical. The
    ratchet was proved separately — deleting one fixture from the registry
    fails with the card named.

    **The structural change is the shared fixture registry.** Two sweeps over
    the same cards is two copies of every builder unless they share one, and a
    drifted copy fails as a phantom layout bug — the most expensive kind of
    wrong answer this suite gives. `test/shared/card_fixtures.dart` now owns
    the `SweepCard` entries and the long strings; the height sweep mounts the
    subset the height detector finds (a card that pins no height is the width
    sweep's business, and sweeping it here would make the ratchet's
    "mounted ⊆ found" half a lie about what the file covers) plus its own 21.
    That extraction immediately broke the `CardLayout` mount ratchet, which
    only scanned `test/**/widget/` and reported eight real cards as unmounted;
    convention 24 now says the shared registry counts, because both sweeps
    really do mount every card in it at 360px.

    One honest note on the mount: `InfoCard` returns an `Expanded`, so it only
    lays out inside a `Flex`, and the sweep mounts it three-up in a `Row`
    exactly as `confirm_button.dart` does — which is why the mount assertion
    is `findsWidgets` and not `findsOneWidget`. The failure it still guards
    against is `findsNothing`: a card that threw during build satisfies "no
    overflow" for the wrong reason.

    Net: 69 tests, both lib defects fixed, coverage 67.4 → **67.5%** with
    `sign_in_up_bar.dart` and `main_card_template.dart` now at **100%**
    (17/17 and 33/33) — two more files measured that were not before, plus
    the whole 71-card family now checked at 360px instead of 50 of them.

### The in-place sort family (2026-10, ledgers #12/#40)

Ledger #12 was one instance of a family, so the whole family got swept with
`tool/detect_inplace_sorts.py`: 35 `.sort(` sites in 24 files, of which **21
were genuine defects in 19 files** — amap `orders_section`, the
booking/cinema/feed/ph/recommendation/event main pages, five admin pages
(group notification, groups, association membership + its information editor,
structure), super_admin `school_page`, loan `loaners_items` and
`on_going_loan`, mypayment's two transaction-detail pages, phonebook
`tools/function.dart`, cinema `main_page_index_provider` and settings
`module_list_provider`. Every one of them threw `Cannot modify an unmodifiable
list` the first time a build reached it, because the list came straight from a
`ListNotifierAPI` watcher. All now sort a copy (`List.of(x)..sort(...)` for
builder parameters, `final sorted = List.of(x)..sort(...)` for widget fields
and locals). The remaining 14 sites were each verified individually: their
receiver is a locally declared `= []` literal or a `.where(...).toList()`
result, so the detector's `review` bucket is empty of real defects. The five
amap/cinema/booking fixtures that feed those pages became `const <Type>[]`, so
a regression now fails as a loud `Cannot modify an unmodifiable list` in a test
instead of in production (convention 18).

The settings member of that family exposed a worse bug underneath
(ledger **#40**).
`ModulesNotifier.loadModules` sorted the notifier's own `allModules` catalog,
deleted every ungranted module from it, appended `/settings` (+ `/admin`,
`/super_admin`) to it, and then assigned that very list object to `state`:
provider state and catalog were the same object, and every later mutation was
a mutation of state riverpod could not see. Worse, the destructive prune was
load-bearing. The user's selection was read back out of the *already pruned*
catalog (`working[allSavedModulesName.indexOf(name)]` over a catalog that had
just lost its ungranted entries), so after an app restart the reload walked
only the four saved names, found every ungranted module still present in the
whole catalog and re-exposed the entire module list to any user — permissions
decorative from the second launch onwards. The persisted catalog order also
never matched the shipped catalog, so the "catalog changed" branch discarded
the user's module order on every launch. `loadModules` now selects over the
whole catalog (`enabled ∩ granted`, ordered by the catalog), `allModules`
stays whole, `reorderModules` applies the drag to the visible list and mirrors
the move into the catalog so it survives a restart, `sortModules`/
`toggleModule` keep working on copies, and `getModuleByRoot`'s unknown-root
fallback answers with a module the user can actually see rather than
`allModules.first` (which, with a whole catalog, is a module they may not have
been granted). `reorderModules` has no caller in lib/ — only the test drives
it — so it was the cheapest place in the app to have been wrong.
`settings_state_providers_test.dart` now pins all of it: a reload keeps the
drag, the catalog stays whole (and never contains `/settings`), and a second
`ProviderContainer` over the same `SharedPreferences` stands in for the
restart, proving the hidden modules stay hidden.

63. ~~**The whole raffle add/edit cluster wrote nothing to the backend** —
   FIXED (2026-10), six defects found by the five new raffle integration
   files.~~ (a) **"create a raffle" created nothing**: `ConfirmCreationDialog`
   built exactly the `RaffleBase` `tombolaRafflesPost` expects and handed it
   to `createRaffle`, which was `localAdd` — and then called
   `loadRaffleList()`, so the optimistic entry was erased a frame later.
   `tombolaRafflesPost` had NO caller in `lib/`; it is the save path now.
   (b) **"Edit raffle" never persisted**: `updateRaffle` was `localUpdate`
   only, so a rename reverted on the next fetch — and
   `tombolaRafflesRaffleIdPatch` ("Edit Raffle", `RaffleEdit{name,
   description}`) was also uncalled. (c) **The pack-ticket strip never
   loaded**: `PackTicketsListNotifier.build()` returned `loading` forever
   unless something pulled to refresh (its sibling `LotListNotifier`
   already auto-loads from `raffleIdProvider` — the asymmetry WAS the bug),
   and `ListNotifierAPI.handleState` refuses mutations while loading, so
   saving a pack ticket from that state reported "Error during addition"
   WITHOUT EVER CALLING THE API. (d) **A comma price crashed the tap**:
   `TextEntry(isDouble: true)` accepts "7,50" (it rewrites the comma before
   parsing) and the handler then re-parsed the raw text with
   `double.parse(price.text)` → FormatException: no save, no message.
   (e) **`TicketUI` overflowed its own rigid 130x125 box by 25px** — it had
   never been mounted by any test; two text lines + the 40px button row
   leave 11px of slack inside 101px, less than one wrapped line, so the
   FIRST wrap (any narrow font, any five-figure pack size) overflows. Both
   texts are single-line with an ellipsis now. (f) **`ConfirmCreationDialog`
   pinned 350px around a title that outgrew it by 104px**, and the overflow
   pushed the check button to a point nothing could hit — the title now owns
   the leftover space in a scroll view, with the button row pinned below it.
   Every one of these is asserted by a test that fails against the old code.

64. **The booking recurrence form accepted an interval of 0, and syncfusion
   spins forever on `INTERVAL=0`** — the save handler parses the interval
   field into `RecurrenceProperties.interval`, calls
   `SfCalendar.generateRRule` and expands the rule with
   `getRecurrenceDateTimeCollection` BEFORE any request goes out, so a typed
   `0` froze the tap handler permanently: no toast, no POST/PATCH, no way
   back. `TextEntry(isInt: true)` only rejects what `int.tryParse` refuses
   or what is negative, and 0 is neither — while the
   `bookingInvalidIntervalError` key had been sitting in BOTH arbs with NO
   caller. The interval field now carries a `validator` refusing anything
   below 1, so `Form.validate()` — which gates the whole handler — stops it
   at the form: the field error renders and the usual "Incorrect or missing
   fields" toast follows. Verified at the source before fixing: a bare
   round trip of `interval = 0` through generateRRule + expansion never
   returns (the repro was killed by a 30-second alarm, exit 142). Pinned by
   `booking_add_edit_recurrence_integration_test.dart`, which fills every
   other save condition (room, both hours, end date, a weekday) so the
   interval is the only thing left to fail — against the old code that test
   hangs instead of failing.

### Auth/session unit tests (`test/auth/`)

- `auth_repository_refresh_test.dart` — `AuthRepository.refreshToken`: the
  real repository over the mocked appauth/secure-storage channels (dedup,
  success, `invalid_grant` wipe, no-token fail-fast, non-OAuth failure).
- `session_expiry_test.dart` — session validity derives from the real JWT
  expiry (valid/expired/unparseable), `loadingProvider` for dead sessions,
  and provider-side `refreshAccessToken` (state update + rethrow).
- `expired_token_handling_test.dart` — `AppAuthenticator` (401 → refresh →
  single retry, Retry-Count loop breaker, single-flight dedup, refresh
  failure → null) and the `ListNotifier` tokenExpire contract (error state
  AND rethrow; other errors stay swallowed).

Unit-test containers that touch the session chain must override
`isConnectedProvider` (a static true/false fake): the real one watches the
version verifier, which pulls the repository/logger bootstrap chain and
its path_provider plugin calls. And remember Riverpod 3 does not export
the `Override` type — helpers cannot take `List<Override>`; take the
concrete values instead.

## Debug toolkit

- `debugPrint('DIAG texts: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}')`
  dumps rendered texts (needs `flutter/material.dart` import).
- Log grep: `grep -E "Finding Match|redirect from" log` shows the router
  chain; a healthy bounce is `/x → /feed` followed by `/feed` route add.
- Exception storms counted in the log (`Multiple exceptions (N)`) point at
  layout loops — usually a nested Scaffold or unbounded width/height.
- `findFixedWidthCards()` in `test/shared/fixed_width_card_detector.dart` — the
  candidate list behind `fixed_width_cards_test.dart`: class + source +
  hardcoded-width count + required constructor params, so a new card's
  registry entry is a copy away. It used to be mirrored by
  `tool/detect_fixed_width_cards.py` "so the test can assert its own coverage
  without shelling out"; that twin is **deleted as of ledger #62** and the Dart
  file is the only implementation. Its known blind spots (convention 23): a
  width passed as a constructor argument (`CardLayout(width: 140)`) and an
  unconstrained `Column` beside a `Spacer` in a `double.infinity` card both
  have no hardcoded width in the file, and both shipped real overflows — plus,
  until this round, every fixed HEIGHT. Per-module `test/<module>/widget/` files are
  the complement, not a duplicate.
- `findFixedSizeCardLayouts()` in `test/shared/fixed_width_card_detector.dart`
  — the argument-form sibling of the above: class + source + the pinned
  dimensions (`width 250 x height 145`), 25 candidates. It had a Python twin
  (`tool/detect_fixed_size_card_layouts.py`, whose only job was the "the two
  agree on the count" check); that is **deleted as of ledger #62**, so the Dart
  file is the single implementation and the count invariant went with it.
- `findFixedHeightCards()` in the same file — the HEIGHT sibling of the width
  scan (71 candidates, ledger #62). Its predicate is not "is there a flex
  child" but "is there content that can outgrow the box": `Expanded` and
  `Spacer` compress inside a fixed height, so they are the one shape that
  cannot produce the vertical overflow this scan hunts. Use it to list what
  pins a height; `tools/widget/fixed_height_cards_test.dart` is what mounts
  them.
- `python3 tool/detect_inplace_sorts.py` — the ledger #12 family's original
  regression guard: cascade and copy-then-sort sites are safe by construction,
  every `review` site is a `.sort(` on a list the caller may not own (exit 1).
  It also prints `--all` buckets when you need to see what it skipped.
  **Superseded** by the next entry, which sweeps every mutating list/set method
  rather than only `.sort(`; kept because its 21 fixes are what ledger #12
  records and its `review` bucket is where that work was triaged.
- `python3 tool/detect_inplace_list_mutations.py` — the **generalised**
  ledger #12/#51 sweep: 191 call sites across `lib/`, bucketed
  fresh/owned/api/control/nonlist/element/review. `--count` prints just the
  `review` number, `--dump` emits one machine-readable row per call and
  always exits 0 (machine mode for the Dart port's cross-check), `--all`
  shows every bucket; the human modes exit 1 when any `review` site exists.
  Backed by
  `tools/unit/inplace_list_mutations_test.dart`, which fails on a new one —
  see convention 24 for the mount ratchet's shape and convention 27 for the
  raw-string trap that briefly made this tool report 115 findings instead of 21.

## Roadmap to 80% (next rounds, biggest uncovered first)

> **Target cleared 2026-10-18:** honest coverage is **85.32%**, so the 80%
> goal below is passed; the list stays as the record of what each round
> did. Next target **90%**, still ranked by uncovered-line count:
> admin 479, raffle 465, amap 403, mypayment 402, booking 368, tools 364,
> vote 320, loan 311, feed 271, tickets 260.

The honest number is 43.4%; ~37 points are missing. Page shells alone will
not close that — each module's sub-pages and their widgets must render too.
Suggested order by uncovered-line count:

1. ~~mypayment sub-pages~~ (DONE 2026-09: request history, devices,
   structure stores, invoices admin+structure, store admin, store stats,
   transfer structure — module then 38%): remaining: scan page, stats chart
   internals, store admin interactions (add/revoke seller).
   ~~pay/fund/refund/delegation~~ (DONE 2026-10, ledger #50: module
   59.2→**76.2%**, 974 uncovered — next: `seller_right_card` 80,
   `invoice_card` 77, `devices_page` 69, the `sum_up_chart` /
   `transaction_chart` internals, `interval_selector` 54, and
   `key_service.dart` 37, which is real Ed25519 against a platform channel
   and needs its own fake rather than a stub).
3. ~~**tickets UI beyond main page**~~ (DONE 2026-09: `/book` shell +
   forms/checkout/sold-out, `/create` round-trip + question editor,
   `/edit` round-trip + gate, `/results` gating; module 24.7→**64.1%**):
   remaining: manage page internals, QR scan page (mock the scanner),
   booked-tickets list interactions.
0. ~~Shame rows~~ (DONE 2026-09: advert 8.6→**67.8%**, login
   2.0→47.5%, ph 5.8→**55.2%**): remaining: ph add-edit page, advert
   poster upload flow, login web variant.
4. ~~**amap sub-pages**~~ (partially DONE 2026-09: admin handlers
   account/delivery/product + both edit forms, module 32→**58.4%**, admin
   block 32→**84.3%**, ledger #12 fixed 2026-10, card sweep 2026-10:
   7 fixed-width cards made flexible and the suite's only RenderFlex
   filter removed, so every amap page renders overflow-strict under its
   94 tests — ledgers #4/#38): remaining: detail order
   page (0%), list products
   page (0%), presentation page, order panel interactions, delivery
   status chain beyond Open (lock/deliver/archive dialogs).
5. **raffle admin + creation flows** (26.9→**54.6%** 2026-09: creation
   page, open dialog, prize add/delete round-trips, confirm-payment
   dialog buy journey incl. the balance guard and failure branch;
   **58.4→74.2%** 2026-10, ledger #63 — the whole ADD/EDIT cluster like
   booking's: pack-ticket add/edit page 61→**1** uncovered (create + edit
   round-trips, both guards, the comma price), prize edit branch 9→2,
   ticket strip delete + pencil journey, the locked winning strip, and the
   admin create dialog 46→2 — five files, six defects, module 744→**466**
   uncovered and total 61.0→**61.7%**):
   remaining: `raffle_card` 57, `main_page` 51, `user_cash_ui` 43,
   the admin page's `account_handler` 30 + `winning_ticket_card` 25, and
   the detail page's `prize_dialog`/`confirm_payment` remainder.
6. ~~**feed & settings**~~ (DONE 2026-09: settings 68.3% incl. logs page
   + Edit account save flow, feed 63.7% incl. event management,
   association events, create/edit event): remaining: news detail page,
   club pages, event poster upload path.
7. **phonebook, booking, cinema, vote, loan, recommendation** (mostly DONE
   2026-09: booking 48.9→**55.5%** incl. add-edit create round-trip,
   phonebook 63.2% incl. modal member flows, vote
   48.8% incl. open-votes + list create/edit round-trips, **78.1%** incl.
   the admin page's full status machine with the counting graph painting
   (ledger #32/#33 fixed) and the main voting surface (ListCard/ListList
   Card: selection, voted gating, published result bars), loan admin +
   item add-edit (47.6%), **63.1%** incl. the add-edit-loan ItemBar
   (steppers with the #34 empty-start guard, end/caution wiring, empty
   branches, edit preselect),
   cinema **76.0%** incl. session create/edit
   round-trips, recommendation **83.4%** incl. add/edit form round-trips):
   remaining: vote detail/results internals, loan admin booking flows.
8. **per-module coverage push** (2026-09: total 43.4→**56.3%**, tickets
   24.7→**80.1%** incl. edit-page item sections, the residual, the
   delete-success toast (ledger #21 fixed) and the questions internals
   + locked-row inertness (edit_ticket_event_page 141→54 uncovered),
   delete-success toast (ledger #21 fixed)
   validations/save fan-out, tools 67.9→**73.2%** incl. the full
   styleguide catalog, booking 48.9→**63.1%** incl. the edit-mode
   recurrence round-trip and the create-path entity/note round-trip
   (ledgers #27/#18 fixed), admin 20.8→**46.8%** incl.
   structure add-edit, groups management write paths,add-member round-trip, associations add/edit round-trips, phonebook
   63.2→**69.2%** incl. the association edition modal (toasts #29,
   crossed wiring #30), seed-library
   23.6→**57.1%** incl. species form, plant-detail edit flows and the
   plant-deposit POST round-trip (stale-reference dialog fixed, ledger
   #28),
   mypayment 40.4→**49.3%** incl. the scan modal end-to-end via a
   platform fake, purchases 38.5→**68.0%** incl. the scan dialog, plus
   the fixed-width card family laid out (ledgers #2/#10/#11/#15/#22:
   LoanCard, BookingCard, ItemCard, CheckItemCard, AdminSessionCard,
   PrizeCard's lock branch, the FloatingNavbar demo and the raffle
    card's nested Scaffold — every test dropped its overflow absorbs):
   next by uncovered lines: mypayment remainder (~2017), raffle remainder
   (966), admin remainder (938); next single files: add_edit_event_page 274
   (BLOCKED by ledger #17 until the router + fromJson bugs are fixed),
   event_ui 155 (BLOCKED), feed add_event_page 87 residual COVERED
   2026-10: 87→37
   uncovered, feed 69.0→**70.3%** (the module prints 69.0–70.3% run to
   run, ledger #37), via a create-mode residual file and an
   edit-mode one (the platform-level image-picker fake drives the poster
   upload; the ticketing switch needed a `Material(type:
   MaterialType.transparency)` wrapper for its ink splash)
   **in-place sort sweep 2026-10**: 21 defects in 19 lib files fixed (the
   #12 family), `tool/detect_inplace_sorts.py` landed as the guard, five
   fixtures turned `const`, and the settings catalog fix behind them closed
   ledger #40 (after a restart the whole module list came back regardless of
   permissions); total **60.4%**, 1233 tests
   **service 67.2→89.8%** incl. `service/tools/setup.dart` 0/40 → 38/40:
   the harness had pinned the shell's notification gate shut on purpose,
   so a `runNotificationSetup: true` opt-in plus the two Firebase platform
   fakes opened the file (conventions 15/16); ledgers #35/#36 came out of
   it
   (local_notification_service
   covered 2026-09: 89→8 uncovered via the mocked dexterous channel + a
   scheme-URL navigation journey; edit_ticket_event_page residual covered
   2026-09: 141→54 uncovered, module 75.4→**80.1%**, via the
   questions-internals file).
   **widget level, last six modules 2026-10** (ledger #48): cinema, tickets,
   loan, feed, phonebook and purchases had NO `test/<module>/widget/` folder
   at all, so this was 28 widgets over 6 files, 41 tests, total
   **63.0→63.4%**. The wins are uneven and that is the finding: feed
   70.7→**74.9%** and cinema 74.4→**79.6%** (both had whole widgets nothing
   mounted, incl. cinema's `CinemaTemplate` shell and its TMDB pill),
   tickets 79.9→**80.8%**, purchases 67.9→**70.4%**, phonebook
   70.0→70.2%, loan 60.2→**65.2%**. Three real defects, all purchases
   (149px scan `TicketCard` row, 236px `CustomButton` pair, and a
   `Flexible`-under-unbounded-width assertion in the same button). Twenty-five
   of the twenty-eight widgets were already correct, all of them through
   `ListItemTemplate`'s `Expanded` — which is also why the width-based
   detector found no phonebook candidate at all, so a per-module file is the
   only thing that can tell "already safe" from "never mounted". Next by
   uncovered lines: mypayment remainder (~1666), raffle remainder (~742),
   admin remainder (~1026), seed-library remainder (~521); next single
   files: `event_ui` 155 and `add_edit_event_page` 274 (both BLOCKED by
   ledger #17 until the router + `fromJson` bugs are fixed), and the six
   `_notMounted` sweep exemptions (`OrderSection`/`ModuleCard`/`FiltersBar`/
   `PersonalPlantCard`/`PlantCard`/`ListListCard`) now have a precedent for
   being reached at page level instead.
   **mount ratchet 2026-10** (ledger #49): `CardLayout` is the one wrapper
   used widely enough to deserve its own detector, so a new one now finds the
   25 classes that hand it a literal dimension — the argument form the
   width-based sweep cannot see — and
   `tools/widget/fixed_size_card_layouts_test.dart` fails when one of them is
   mounted by no `test/**/widget/` file. Worth 0.4 points of coverage and one
   real 324px overflow in home. Two debts it now tracks instead of hiding:
   `DetailOrderUI` (exempt until bug #3's `return state` becomes
   `AsyncValue.loading()`) and the fact that the two detector
   implementations are only cross-checked by count, so a richer
   cross-check — diffing the Python output from the test — is the obvious
   next tightening.

Per-round recipe: pick the top module, list its unmounted routes from the
router file, write one deep-link shell file per route (own file: init-path
rule), stub the endpoints its providers auto-load (grep `repository.` in
the page's watched providers), assert on rendered content (never vacuous),
run solo, then full suite + lcov.
