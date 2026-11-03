# Test layout

One folder per module, mirroring `lib/`; each module folder holds its test
levels:

```
test/<module>/unit/         # provider/notifier tests (no router, no widgets)
test/<module>/widget/       # ONE widget mounted in isolation (no router)
test/<module>/integration/  # full-app shells (this README's subject)
test/<module>/end_to_end/   # reserved: flows against a running backend
test/<module>/<module>_fixtures.dart  # that module's builders, stubs, doubles
test/shared/                # cross-module helpers (scaffold, fixtures,
                            #  *_stub.dart platform fakes)
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

Current state (2026-11-02, 96% round): **3080 tests
green, none skipped**, honest coverage **96.16%** (29640/30824 executable
lines, lib/generated and lib/l10n excluded); **mypayment 95.3%** (3912/4103),
tickets 95.9% (2196/2290), vote 94.5%, raffle 94.4%,
login 93.9%, loan 95.7%, admin 95.6%, phonebook 96.8%, super_admin 95.4%,
navigation 96.3%, tools 96.3%, booking 98.7%, cinema 97.2%,
**service 99.1%** (232/234), **recommendation 99.4%**,
**settings 99.4%**, **centralisation 99.2%**, and **user 100%**,
**home 99.6%**, **centralassociation 100%**, **version 100%**.
`auth` is **100%** (180/180). The web refresh grant used to be unreachable on
the VM — it is a compile-time `kIsWeb` branch — which is why its four tests
were skipped and its lines were only ever measured by a hand-run Chrome pass.
The `isWeb` seam puts the VM run on that branch, so those four tests now count
in the run above, and the popup `window` shim (`webWindowWithCallback`) is no
longer the uncovered remnant the previous state line recorded.

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
hiding, and both are fixed now, so their ledger entries are gone from the
open list: `buildPermissionToModuleRootMap` keyed its map by the permission
name with the module prefix **stripped** while `computeUserModuleRoots`
looked it up with the **full** name (a full name granted nothing, a bare name
collided on one key, plus a substring `access` filter and two catalog prefixes
that were not route roots), and `NoInternetPage`'s retry button read a stale
build-time `isConnected` without awaiting the re-ask, so
`QR.to(HomeRouter.root)` was unreachable from any state a user can reach. Both
are pinned end to end by `test/super_admin/unit/module_roots_test.dart`,
`test/settings/unit/module_gating_chain_test.dart` and
`test/tools/integration/no_internet_middleware_integration_test.dart`.

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

There are **no skipped tests**. Four used to be, in
`auth/unit/auth_repository_web_refresh_test.dart`, behind `skip: !kIsWeb`: the
web refresh-token grant is a compile-time branch on the browser, so the VM run
could only ever skip them, and only a hand-run Chrome pass executed them at
all. `AuthRepository` now takes an `isWeb` override that defaults to `kIsWeb`,
so the VM run constructs the repository on the browser branch. The four
assertions are unchanged — not weaker, just finally reached — and they run in
the default suite. The one branch still browser-only is
`getTokenFromRequest`'s popup shim (`webWindowWithCallback`), which needs a
real window and stays uncovered on the VM.

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
7. **Center/currency conventions found the hard way:** amap converts from
   CENTS (Hyperion stores `price`/`balance`/`amount` in cents: `2510` renders
   `25.10 €`, and the forms collect euros ×100 on save — ledger #5/#13),
   raffle still renders raw balances (`1250000` → `1250000.00 €`), and
   mypayment divides by 100 and appends `ʍ` (`25,10 ʍ` in fr). Look at the
   widget before writing the expectation.
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
    plus render-from-the-copy for a widget field or local.
    `findInplaceListMutations()` in `test/shared/inplace_list_mutation_detector.dart`
    classifies every mutating list/set call under lib/ as fresh / owned / api /
    control / nonlist / element / review, and
    `tools/unit/inplace_list_mutations_test.dart` fails when any `review` site
    exists — treat each one as guilty until its receiver is proven to be a
    local `= []` literal or a `.where(...).toList()` result. A `const <Type>[]` fixture is the cheapest
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
    `findFixedWidthCards()` in `test/shared/fixed_width_card_detector.dart`
    looks for a hardcoded width beside flex children *in the same file*, so `CardLayout(width: 140, height: 80)`
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
    **A "mounted" card may live in `test/tools/card_fixtures.dart`**, the
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
    `CustomButton` pair 236px over — and      `tools/unit/row_spacer_detector_test.dart` is its static rule: it scans
      `lib/` through `shared/row_spacer_detector.dart` and fails on ANY Row of
      that shape outside its `knownHazards` pin list — **which is empty today**.
      The fix is one shape: wrap the child in `Expanded` (with a one-line
      ellipsis when it is a title) so it takes the width that is left instead
      of taking the row past the edge. A pin carries the same burden as
      a `_notMounted` exemption — a reason, and removal the moment the row is
      fixed. All 18 pins are now gone with their fixes: `AdminPhCard` first
      (its field Column wrapped in `Expanded` with both values ellipsized —
      the row was the CAUSE of the 320px overflow the width sweep had pinned
      only by its symptom), then the eleven page headers (`Text` title +
      `Spacer` + action button), the five card rows whose unbounded child is
      data rather than a title (a date, a store name, a user name, a rights
      label, a search name), and the two whose roles were reversed
      (`RaffleWidget`'s stats columns → `Flexible` + a fixed gap +
      `mainAxisAlignment.center`, the species editor's month picker → two
      `Expanded` columns and no `Spacer`s). Because a clean `lib/` and a
      broken scan both report zero, the detector's liveness test points the
      scan at a temp-dir fixture (`tools/row_spacer_fixtures.dart`) holding
      one `Text` Row and one `Column` Row and requires both back — and, the
      other half of liveness, requires the three SAFE shapes (`Expanded`
      `Text`, `Flexible` `Column`, a Spacer-free row) to come back clean, so
      a detector that flagged the prescribed fix cannot pass. `shared/row_spacer_detector.dart`
      is the only implementation — there is no second language to drift
      against — and `tools/unit/row_spacer_detector_test.dart` holds it to
      both halves of liveness on the fixture and on `lib/`.

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

34. **One home per stub, one fixtures file per module.** Shared test code has
    exactly three homes, and a second copy in another file is the bug, not
    the shortcut:
    - **Platform stubs** — anything installed on a `…Platform.instance` seam —
      live in `test/shared/<thing>_stub.dart`: `file_picker_stub.dart`
      (`StubPlatformFile`, `StubFilePicker`, `stubPick`), `image_stub.dart`
      (`StubImagePicker`, `StubImageCropper`, `solidPng()`),
      `path_provider_stub.dart`, `route_mock_stub.dart`
      (`RecordingRouteMock`) and `url_launcher_stub.dart` (`FakeUrlLauncher`,
      `LaunchRecord`, `stubUrlLauncher`). They are cross-module by definition,
      so the install-and-restore (`addTearDown` back to the previous
      instance) lives in the stub file with them. Two exemptions, both
      deliberate: a seam only ONE file ever stubs keeps its fake in that file
      (auth's `_StalledAppAuth` on `FlutterAppAuthPlatform.instance`), and a
      seam that already HAS a shared stub must use it — feed's private
      image-picker fake was a second answer to the same
      `ImagePickerPlatform.instance` and was folded into `StubImagePicker`.
    - **Module fixtures** live in `test/<module>/<module>_fixtures.dart` (a big
      module may carry a second, purpose-named file — `tools/card_fixtures.dart`,
      `settings/settings_test_doubles.dart`):
      model builders (`raffleFixture`, `session`, `cash`, `variant`,
      `memberWithMemberships`), that module's endpoint stubs (`stubAdminLoads`,
      `stubStoreAdmin`, `stubDevices`, `stubMainPage`) and its notifier test
      doubles (`GroupListFake`, `MembersNotifier`, `ItemsNotifier`). The moment
      a SECOND file of the module needs one, it moves here — not copied, and
      not re-exported through a one-line alias (`member(x) =>
      fixtures.memberWithMemberships(x)`), which is how the same name ends up
      defined twice in a module.
    - **File-private helpers** — a builder, poller or finder exactly ONE test
      file uses — stay in that file, `_underscored`, and named for what IT
      builds so they cannot be mistaken for the module fixture: `cardSession`
      in the cinema card widget test (the module's `session`/`shortSession` in
      `cinema_fixtures.dart` build the integration records), `_settled` in the
      two admin provider tests (it polls two different providers, so it is
      deliberately not shared).
    Why: the 2026-10 sweep merged seven hand-copied `stubMyPayment` functions
    (one per mypayment file, five different bodies and no way to tell them
    apart at a call site), six `session()` builders, four image-picker
    platform fakes, three route mocks, three url_launcher fakes and two
    `solidPng()` copies. Same-named helpers with different bodies are worse
    than copies: the call site reads identically in two files that behave
    differently.
35. **Never read `QR.currentPath` in `lib/` — watch `renderedPathProvider`.**
    qlevar reports the path that was ASKED for while a redirect is still
    resolving, and notifies nobody when it finally changes, so a `build` that
    reads it once keeps that frame's value until something else rebuilds the
    widget (ledger #7: a template sitting behind another page kept showing
    the other module's state when its own route came back). Render decisions
    (`TopBar`'s chevron, the module templates' info icon, phonebook's admin
    branch, the tickets toast guard) `ref.watch` the provider; callbacks
    (`onBack`, `onPressed`, `useEffect` bodies) `ref.read` it. `QR.to` /
    `QR.back` are unaffected. The provider is fed by qlevar's global observer,
    registered from `lib/main.dart` and from `IntegrationScaffold.shellSetUp`
    — AFTER `QR.reset()`, which DROPS the observer lists, so registration has
    to stay idempotent (remove-then-add). A context that never registers (a
    unit test pumping a page straight into the tree)  falls back to `QR.currentPath` on first read, i.e. its old behaviour.

36. **A lookup may not assume the element is there.** `firstWhere` with no
    `orElse:` throws `Bad state: No element`; `where(...).first` throws it
    even when the SOURCE list is non-empty, because the filter may match
    nothing; `firstWhereOrNull(...)!` turns the safe lookup back into the
    unsafe one. All three have shipped here: a stale favourite name killed
    every section on centralisation's page, a deleted association threw out
    of the advert admin's Edit tap, and a member whose mandate rolled over
    took the phonebook reorder comparator down. `tools/unit/collection_guard_ratchet_test.dart`
    is the standing rule (convention 31's twin for lookups): it scans `lib/`
    through `shared/collection_guard_detector.dart` and fails on any of those
    three shapes outside its `knownGuards` pin list. A pin carries the same
    burden as every other exemption — a reason, and removal the moment the
    site is fixed — and the list is held to two entries, both provably
    guarded (an `any(hasError)` check, an enclosing `try`). A synthetic
    fixture proves each rule still flags its own shape while the
    safe shapes (`orElse`, a nullable lookup, an explicit loop) stay clean.
    The empty-input sweep that produced these fixes also hardened the date
    parsers: `processDateBackWithHourMaybe` no longer re-throws from its own
    fallback, `parseDuration` reads a blank field as 0 minutes, and booking's
    save guard refuses a blank date before `DateFormat.parse` sees it.
    `processDateBack` now also accepts the date PICKER's `yMMMd` shape: the
    picker wrote `Nov 15, 2026` while the parser read `yMd` only, so loan's
    end date came back blank for every locale and the initial-date write
    threw inside the picker callback.

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
  gate; the mypayment args pre-seed the admin-gate and invoice-list state (both
  load lazily, so a cold deep link sees nothing); also fakes `keyServiceProvider` (a real `getKeyId()`
  Future), `shouldSetupProvider`, `firebaseTokenProvider`; `groups:` pre-seeds
  the derived `allGroupList` provider — pages resolve group names from it with
  `firstWhere`, so the list should hold the wanted ids BEFORE the first
  build rather than arrive via a stubbed `groupsGet` mid-flight;
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
  must be pre-seeded (the same deep-link-time gate trap).
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
| `shared/*_stub.dart` | the platform seams (convention 34): `file_picker_stub.dart` (byte-backed `StubPlatformFile`, queue-driven `StubFilePicker`, `stubPick`), `image_stub.dart` (`StubImagePicker`, `StubImageCropper`, `solidPng()`), `path_provider_stub.dart`, `route_mock_stub.dart` (`RecordingRouteMock`) and `url_launcher_stub.dart` (`FakeUrlLauncher` / `LaunchRecord` / `stubUrlLauncher`). One copy each — these had 7, 4, 3, 3 and 2 hand-copied variants before the sweep |
| `<module>/<module>_fixtures.dart` | each module's own builders, endpoint stubs and notifier doubles (convention 34): `admin` (`GroupListFake`, `MembersNotifier`), `amap` (`cash`, `orderableDelivery`, `order`), `cinema` (`session`, `shortSession`, `fixedSessionStart`), `loan` (`ItemsNotifier`), `mypayment` (`stubMainPage`/`stubDevices`/`stubStoreAdmin`/… , `wallet`, `tos`, `userStoreFixture`), `purchases` (`variant`, `generator`, `myTicket`), `raffle` (`autoSizeText`, `raffleFixture`, `FixedRaffleList` — the pinned-list notifier both the unit and widget guard tests share), and the pre-existing `booking`, `ph`, `phonebook`, `seed-library`, `settings`, `tickets`, `tools`, `vote`. The other modules — `advert`, `auth`, `centralassociation`, `centralisation`, `event`, `feed`, `flappybird`, `home`, `login`, `navigation`, `others`, `recommendation`, `service`, `super_admin`, `user`, `version` — hold no fixture a second file needs, so they deliberately have NO fixtures file: their helpers stay private in the one test that uses them |
| `shared/page_module_guard.dart` | the page-ownership guard (convention 30, ledger #61): `pageModuleIndex()` maps every `class *Page` in `lib/` to the module that declares it, `moduleOfTestFileFrom()` / `currentTestModule()` read the module under test off the call stack, `foreignPagesMounted()` reports the pages on screen that no allowed module owns, and `assertNoForeignModulePages()` fails with the class, its owner, the file that declares it and the fix. Called at the end of every `pumpApp` |
| `tools/unit/page_module_guard_test.dart` | the guard's own test: the index finds the leak page and keeps both modules for a colliding name, the stack read skips harness frames, a foreign page really is reported, an allow-listed module really is not, and the failure text names the class, the owner and the remedy (ledger #61) |
| `purchases/integration/purchases_integration_test.dart` | purchases main page (canonical example) |
| `service/integration/local_notification_service_integration_test.dart` | local notifications through the mocked `dexterous` method channel (Android `registerWith()` first — no test env registers the platform impl): init/show/periodic/image/cancel wrappers, groupNotifications empty-vs-inbox branches, pending query hit+miss, decode handlers; one boot+QR.to journey proving the click listener navigates a mapped module (qlevar STRIPS the scheme from `test.titan:///advert?...`, so /advert mounts and the auth gate lands on /feed) |
| `amap/widget/amap_cards_widget_test.dart` | WIDGET level: `OrderUI` (long date + 3 products + `12500.00€`, plus its detail state, a text-scale sweep at 1.3/1.5/2.0x and the main page's 195px strip bound), `ProductCard` (long category/name, no-button 130px variant), `UserCashUi` (five-figure balance, long nickname) — each mounted alone at 360x640, so any overflow is fatal |
| `raffle/widget/raffle_cash_card_widget_test.dart` | WIDGET level: the raffle flip cash card's front face with a five-figure balance and a long nickname, plus the no-nickname full-name branch |
| `mypayment/widget/payment_delegate_widgets_test.dart` | WIDGET level: the whole payment-delegation family, which sat at **exactly zero** coverage (247 lines in `paiment_delegate/` + 91 in the two modals that host it) — `ProductCard`, `WalletBalanceCard` (data/loading/error), `CountdownTimer` (mm:ss, the 30s urgency threshold, `onFinished` once, and the `fullDurationSeconds` case where the ring must start nearly empty), `FeedbackOverlay` both marks, `ConfirmButton` (dispatch, the `totalSeconds: null` never-expire case, and the expiry that greys it out and kills the tap), `PaimentDelegateModal` (idle stack, already-expired drops the timer, loading→success→pops, cancel overlay, and the `onRefuse` delegate path that deliberately shows NO overlay), `RequestDetailModal` across all four statuses, and `showRequestModal` end to end including a real Ed25519 signature |
| `mypayment/integration/mypayment_pay_integration_test.dart` | the pay sheet (`pay_page.dart` + `confirm_button.dart` + `qr_code.dart`): the three gates to the sheet (TOS, no key, unknown device), keypad to cents, leading-comma seeding, backspace, the biometric + key-refused paths, and the QR sheet itself — which is where the round's 420px overflow fix lives. Extended by ledger #58 with the HAND-OFF rather than the sheet: the cents the buyer typed asserted as the envelope's `tot` through the real `BarcodeNotifier` parser, the code proven to have painted modules (an unscannable payload renders no `CustomPaint`), the wallet + history refetch that closing the sheet triggers, and the fail-closed sheet when the wallet will not load |
| `mypayment/widget/store_admin_cards_widget_test.dart` | WIDGET level: `SellerRightCard` (the module's biggest uncovered file, 87 lines, previously only reachable through the store-admin page) and `DeviceItem` (actual + revoked rows) |
| `mypayment/widget/pay_qr_code_widget_test.dart` | WIDGET level: `QrCode`, the far end of the pay flow's hand-off. Asserts the signed payload's fields (`tot` in whole cents, `key`, the hard-coded `store: true`, a fresh `iat`) by feeding `FakeKeyService.signedMessages` through the consumer's own parser; that the signature is a real 64-byte Ed25519 which **verifies** and which **fails** verification on a tampered `tot`; that the code painted modules rather than the error box; the viewport fallback when the box is unbounded (unreachable from the sheet, which wraps it in a `Flexible`); and that a rebuild re-signs under a fresh transaction id (regression for the
| `mypayment/widget/transaction_chart_test.dart` | WIDGET level: `TransactionChart`, the per-store pie under the monthly chart, which had no behavioural test — an empty month renders the `paiementNoTransaction` placeholder and no `PieChart`; two wallets produce two badges titled by wallet (the second going through `generateColorVariations`); and a touch in the donut hole answers -1, which hands EVERY transaction to `selectedTransactionsProvider` |
stateful `QrCode`) |
| `mypayment/unit/funding_url_provider_test.dart` | UNIT level for `fundingUrlProvider`: `build()` fetches nothing (a funding URL is a transaction, so a build-time fetch would mint a HelloAsso session nobody asked for), `getFundingUrl` posts the `TransferInfo` verbatim — the cents conversion and the redirect URL are the BUTTON's job, and a provider that quietly rescaled the amount would make the button's boundary tests lie — a refused POST and a 200-with-no-body both become `AsyncError` (`requireValue` then throws rather than handing back a stale URL), a thrown transport error does too, and a good URL is replaced by the next attempt (ledger #60) |
| `mypayment/integration/mypayment_fund_integration_test.dart` | the top-up sheet (`fund_page.dart` + `confirm_button.dart`, also zero coverage) and the HelloAsso hand-off (ledger #60): the TOS gate on the card, the cap printed from the wallet AND the TOS response, keypad to amount with leading-comma seeding and backspace-to-empty, the minimum guard, the cap boundary (950 accepted with 50 held, 951 refused with the amount intact), the `TransferInfo` POST (cents, and the exact `test.titan://mypayment` redirect), the `LaunchMode.externalApplication` hand-off asserted through the flags `launchUrl` decomposes it into, a failed TOS self-registering once and healing, and the two hand-off regressions — a refused launch now toasts the localized "cannot open" copy AND leaves the typed amount on the card, and a missing wallet fails the cap CLOSED instead of raising it |
| `mypayment/widget/fund_page_widget_test.dart` | WIDGET level: the cap-zeroing branch of `ConfirmFundButton` that the UI cannot reach (the card's `hasAcceptedTosProvider` gate closes the sheet first), the fail-open balance addend with a control showing the same amount refused when the wallet does load, and that the typed amount lives in `fundAmountProvider` rather than local state |
| `phonebook/widget/phonebook_cards_widget_test.dart` | WIDGET level, the module's first: `AssociationCard`, `EditableAssociationCard`, `MembershipCard` (its title is the "association - role" concatenation), `MemberCard` in both the nickname and no-nickname branches of `getName()`, and `AssociationGroupementBar` in its horizontal (40px strip) and vertical (`min(count * 52, 220)`) modes plus `AssociationResearchBar` with the filter affordance offered. No phonebook card is a fixed-width candidate — they all render through `ListItemTemplate`'s `Expanded`, so this file is what proves the family rather than assuming it |
| `purchases/widget/purchases_cards_widget_test.dart` | WIDGET level: both `TicketCard` classes (the main-page list row incl. its sold-out state, and the scan-page row with a five-figure use limit), and the main page's `CustomButton` header pair in the page's own `Padding(all: 30) > Row(spaceBetween)` shape with short and long labels, plus a lone button in a bare `Row`. Found the round's three defects — ledger #48 |
| `tickets/widget/tickets_rows_widget_test.dart` | WIDGET level: the sweep's four width-pinned tickets cards leave eight leaf widgets, all here — `TicketEventCard` mounted once per `TicketEventStatus` (reached by moving a date, since the status is a computed extension on `disabled`/`openDatetime`/`closeDatetime`, and each state is a different trailing chip width), `SectionCard`, `StatTile` at its real half-width with a five-figure value and total, `SwitchRow` editable and read-only, `SoldOutBadge`, `ReadOnlyBanner`, and all four status chips in one row. The value assertion needs `findRichText: true`: it is a `RichText` of two spans |
| `tickets/widget/user_ticket_card_transfer_test.dart` | WIDGET level: `UserTicketCard`'s transfer gate — the `transferBlockReason` arms the layout sweep never drove: a clean ticket offers the button (a non-null `onTap`), `scanned` reports the already-used message, a past session interpolates its `dd/MM/yyyy` date and `HH:mm` time, and the `session.id.isNotEmpty` guard keeps an unscheduled ticket transferable instead of looking expired |
| `feed/widget/feed_cards_widget_test.dart` | WIDGET level: `EventCard` (the 851x315 `AspectRatio` banner with its `Positioned(bottom: 53)` badge) in all three badge states, `EventCardTextContent` (a `size.width - 140` box holding a 30-char-truncated title and a location on ONE line) with and without a location, `EventAction` in all four button states including the waiting branch, `AssociationEventCard`, and `AdaptiveTextCard` with and without an image. The banner's image is fetched through an `AutoLoaderChild` on first build, so the 404 stub is what stops the card dying before it lays out |
| `loan/widget/loan_cards_widget_test.dart` | WIDGET level: `ItemCardInLoan` — a card the width-based detector MISSED, because it hands `CardLayout(width: 140, height: 80)` a number instead of hardcoding it, and the pinned 80px box holds a quantity `Text` with no line cap — in both quantity branches, `LoanersBar` (40px chip strip, long loaner names), the two `DateEntry` rows, `NumberSelectedText` folding 40 items x N into one count, and the borrower `SearchResult` row. A sync `NotifierProvider` has no `.future` in Riverpod 3, so the notifier's own `loadItemList` is what gets awaited |
| `loan/widget/start_date_entry_test.dart` | WIDGET level for `StartDateEntry`'s picker, which the sweep only mounted: `onTap` was fully uncovered. Driving it found a real defect — the picker writes `DateFormat.yMMMd` (`Nov 15, 2026`) while `processDateBack` parsed `yMd` only, so the end date was ALWAYS blank and the initial-date write threw; the tests pin both halves (start stored in the picker's shape, end derived from the shortest selected duration, initial date updated) and the empty-selection branch that clears the end instead of throwing |
| `cinema/widget/cinema_cards_widget_test.dart` | WIDGET level: the sweep mounts both cinema cards with a long name and every other field empty, so this file remounts them with a full TMDB record (tagline, genre, a 2h25min runtime, a multi-sentence synopsis) and adds the two widgets the sweep has no reason to know about — the `CinemaTemplate` shell and the `TmdbButton` pill in its icon and `Loader` states. `SessionCard` is mounted in BOTH `isWebFormatProvider` branches, each at a surface where the provider really returns true or false |
| `centralisation/widget/centralisation_cards_widget_test.dart` | WIDGET level for `ModuleCard`, which the width sweep had registered as mounted **and** exempted in the same file — the exemption suppressed the test while the ratchet counted it as covered, so `module_card.dart` sat at 37/37 uncovered behind a green sweep on a reason (`needs the modules map seeded`) that was simply false. The exemption is deleted, `_Card` grew a per-card `wrap` parent (the card's `Column` holds an `Expanded`, so it needs the bounded grid cell it actually lives in — `SliverGridDelegateWithMaxCrossAxisExtent(130)`), and the card is mounted here for real: favourite star state, a tap that toggles both ways, a 42-char name through `AutoSizeText`, and the `.svg` branch. That last one needed `stubNetworkImages` to answer `HttpClient.openUrl` and serve real SVG bytes — `flutter_svg` loads through `package:http`, not `NetworkImage`, so the branch had never been mountable. `LikedCard` is here too because the pair differ structurally: it pins 92px and has a rigid 36+8+30 column, which the 135px favourites strip in `main_page.dart` is built around and a 60px parent overflows |
| `super_admin/widget/super_admin_widgets_test.dart` | WIDGET level for the module's leaf widgets, none of which read the router (so the whole thing mounts without the `SuperAdminTemplate`→`TopBar`→`renderedPathProvider` trap — convention 35 — that keeps the pages themselves at integration level): `PermissionRow` in both states plus its one-line ellipsis, `PermissionTile`'s two counters, `SchoolUi` including the two reserved ids whose delete button is hidden, `SchoolButton`'s gradient, `SuperAdminButton`, `TextEditing`. The bulk is `PermissionDetailModal` (193 lines) pushed as a real bottom sheet: it renders both sections from l10n, finds the permission under its **module-prefixed** name (`core.admin` → `admin`, the lookup `permissions.dart` depends on), no-ops every callback when the permission is unknown, posts authorize/unauthorize with the right body, and surfaces a rejected write as a snackbar instead of a silently dropped tap |
| `service/integration/setup_notification_integration_test.dart` | `setUpNotification`'s authorized branch behind `runNotificationSetup: true`: the plugin initializes, the FCM token expiry is persisted under the signed-in id (~30 days), `getTopics` hits the endpoint twice (the notifier's build + the refresh), the gate flips to false, and a foreground push delivered through `FirebaseMessagingPlatform.onMessage` shows a notification whose payload carries the data map's routing fields |
| `service/integration/setup_notification_denied_integration_test.dart` | the denied half in its own file (one deep-link boot per file): the plugin still initializes, no token date is written, **zero** topic calls and `topicsProvider` is never instantiated (ledger #36 fixed — the counter used to sit at 1), the gate still flips |
| `service/unit/setup_notification_cache_test.dart` | drives `setUpNotification`'s 30-day token cache against the REAL expiration notifier (the shell's `FakeFirebaseTokenExpirationNotifier` short-circuits the condition for every test user, which is why the branch was dead): valid cache honoured (no saveDate, one topics call), expired date re-registers, a null expiration registers instead of throwing on `expiration!`, another user's date never reused, plus a COLD-BOOT case that never touches the provider first and so pins the `notifier.ready` await (ledgers #35/#43) and an INFO-LEVEL capture that the "registered" line really reaches the output (ledger #44). **Ledger #54** adds the poisoned-row recovery: the row is seeded with the literal string `"null"` (NOT the real JSON null the older case uses — that helper's `expiration?.toString()` is null-aware, so the older test exercised the guard and never the parser), and asserts no exception escapes, the token re-registers, and the bad row is overwritten with a real date |
| `tools/widget/fixed_width_cards_test.dart` | THE overflow sweep: every widget class in `lib/` that hardcodes a width AND puts flex children in that box (65 of them, found by `findFixedWidthCards()`), each mounted alone at 360x640, 320x640 AND 280x640 — one pass per width in `_sweepWidths`, narrowest last; 320 is the small end of real Android widths and 280 a stress floor narrower than any device the app ships to, so a label that merely barely fits at 320 is found by the assertion rather than by a user with a long translated string — with the app's real fonts out of the shared registry `tools/card_fixtures.dart`. all 65 mounted and `notMountedExemptions` empty — `OrderSection` was the last entry and left it in the bug #3 round, once `userOrderListProvider` started in `AsyncValue.loading()` instead of reading its own state from `build()` — and two ratchets: one that fails if a new candidate appears that is neither mounted nor exempted, and `tools/unit/mounted_but_exempted_ratchet_test.dart`, which fails if a fixture and an exemption ever name the same widget again. The 320 and 280 passes share one per-width pin map, `_overflowPins`: a pinned card is mounted anyway with its overflow RECORDED at the source (so the pass stays a real green rather than a silent skip), and the test then fails when the card fits — the drop IS the change the failure asks for. **Both sets are empty today.** `TimelineItem`, `AdminPhCard`, `SpeciesCard` and `UserTicketCard` were the four at 320; each overflow traced to the same fact (`flex.dart`'s `_constraintsForNonFlexChild` gives a non-flex Row child NO main-axis maximum, so it sizes to its intrinsic width and the row goes past the edge) and each is fixed in place: one `Text.rich` for the banner title+location, `Expanded` + ellipsized values for the ph card's field Column, `Expanded` columns in place of the species card's two fixed 100px boxes and their Spacers, and a `FittedBox.scaleDown` around the ticket date/time row so neither half is ellipsized. The 280 pass found three more when it was widened in: `RequestCard` and `TransactionCard` overran their fixed 70px height on the BOTTOM because the date under the title was left to wrap while the amount beside it sets its own width (the middle column collapses to 46-65px at 280) — fixed with `maxLines` + ellipsis on the date (3 on its own, 2 once the refund line below claims its share) and 2 on the refund, which caps the worst case at 18+28+21 = 67px inside the 70; and `PermissionTile`'s two `_SummaryChip`s overran on the RIGHT by 26px because `125000/125000` twice is wider than the box — fixed by wrapping each chip in a loose `Flexible` (intrinsic size whenever it fits, so 360 and 320 lay out identically) with the label ellipsized inside the chip. Adversarial data throughout (long French names, five-figure amounts). Ledger #47 |
| `tools/widget/fixed_height_cards_test.dart` | the HEIGHT half of the fixed-size sweep (ledger #62): every widget class in `lib/` that pins its own `height`/`minHeight`/`maxHeight` AND puts content that can outgrow that box inside it — 71 of them, of which **21 the width scan could not see at all** (mostly mypayment dialogs and templates: `TOSDialogBox`, `DeviceDialogBox`, `MainCardTemplate`, `WalletBalanceCard`, `SignInUpBar`). Each mounted alone in a 640-tall box at 360px with the app's real fonts, and every one asserts it actually mounted. It found two real overflows — `SignInUpBar`'s 24px label by 122px and `MainCardTemplate`'s card title by 56px, both unbounded in a `Row` inside a fixed-height box — and both are fixed. It found and FIXED `InfoCard`'s `Expanded`-outside-a-Flex trap by mounting it three-up as `confirm_button.dart` does, which is why its mount assertion is `findsWidgets` and not `findsOneWidget` |
| `tools/card_fixtures.dart` | the widget level's shared card-fixture registry: the `SweepCard` entries (source + class + `Type` + builder + optional bounded `wrap`) and the adversarial long strings both fixed-size sweeps mount. One registry rather than two copies, because a drifted copy fails as a phantom layout bug; the height sweep mounts the subset the height detector finds plus its own 21, and the `CardLayout` mount ratchet counts this file as a mounting site (ledger #62) |
| `tools/widget/fixed_size_card_layouts_test.dart` | the MOUNT RATCHET for the shape the width sweep cannot see (ledger #49): every widget class that calls `CardLayout` with a literal `width:`/`height:` (25 of them) must be BUILT or FOUND by a file under `test/**/widget/`, or listed in `notMounted` with a reason. Comments and string literals are stripped before the search so the sweep's `_notMounted` map cannot make a card look mounted; "mounted" means a constructor call or `find.byType`. Height-only pins count, unlike the width sweep. Five assertions — the ratchet has candidates, every candidate is mounted or exempted, every exemption has a reason, no exemption names a card the detector no longer finds, and no exemption names a widget a widget test really mounts (the scan-side twin of `tools/unit/mounted_but_exempted_ratchet_test.dart`, added when the five seed-library/vote exemptions were deleted under it). Verified non-vacuous: deleting the `DaysEvent` mount fails with the card named, an empty reason fails, a stale key fails |
| `home/widget/home_days_event_widget_test.dart` | WIDGET level, the home module's first: `DaysEvent` (a `CardLayout(height: 135, width: double.infinity)` day column) in its one-event, three-event, past/ongoing/future colour, multi-line-description and empty-day shapes. Found the 324px overflow in the card's `spaceBetween` location/association row — ledger #49 |
| `event/widget/event_cards_widget_test.dart` | WIDGET level, the event module's first: `EventUi` in its three variants — the list card (long name/location/association together, the description's two-line + `...` join, the 250px pin, the info-tap forwarding), the detail card (edit/delete row and info icon gone, tap suppressed), and the admin strip card in the 235px `SizedBox` `ListEvent` mounts it in (four `CardButton`s wired to test-owned callbacks, confirm/decline no-op once the decision is already made) — plus the three date-driven backgrounds (`white`/`gradient`/`grey` decorations and title colours), `EditDeleteButton`'s decoration, `CheckBoxEntry`'s notifier flip vs `onChanged` split, and `ListEvent`'s count/plural header, expand toggle, history filter and empty state. Found a 99px overflow in the card's location/association row — a plain `Text(association)` next to an `Expanded(location)`, the exact ledger #49 family one module over — fixed with the same two-`Expanded` ellipsis shape `DaysEvent` got. Nav taps (`QR.to` through the info icon, edit and `ListEvent`'s onEdit/onCopy) are deliberately never fired: qlevar's routes are not registered at widget level |
| `tools/unit/inplace_list_mutations_test.dart` | the ledger #51 RATCHET: fails when a mutating list/set call in `lib/` has a receiver the detector cannot resolve to a copy, a class field, a notifier's API or a platform object. Two assertions, each proven to fail when broken — an unresolved receiver (names `file:line` and the receiver, and says to copy it or teach the detector the shape: there is no allowlist to add to at all, not even a retired one — it was deleted along with its vacuous `const`-empty test), a total-and-bucket floor so a silently-dead regex is caught (`review` is asserted EMPTY as well as every other bucket being populated — that is what makes a dead regex and a clean sweep distinguishable), and a liveness floor that keeps a rule from silently reaching zero candidates. **The 28-entry exemption list this ratchet used to carry is gone**: every shape it held — a DateTime local, `useTextEditingController()`, a qlevar `QR.observer` registry, a fold accumulator with a `[]` seed, a ternary whose arms are both copies, `<MapEntry<String, List<String>>>[]`, `prefs.getStringList`, `keyService` from a provider — now has a rule in `test/shared/inplace_list_mutation_detector.dart` that proves the site is safe, and the diff of the dump before/after shows 28 rows moving out of `review` and **no other row changing bucket** |
| `tools/unit/row_spacer_detector_test.dart` | convention 31's ratchet: every `Row`-with-`Spacer`-and-unbounded-`Column`/`Text` in `lib/` must be listed in `knownHazards` — **empty today**, the 18 pins all fixed in place with the prescribed `Expanded` shape. Empty `lib/` output cannot pass vacuously: the liveness test scans a temp-dir fixture and requires the unsafe `Text` and `Column` rows back, and requires the safe shapes (`Expanded`/`Flexible` child, Spacer-free row) to be clean |
| `tools/row_spacer_fixtures.dart` | the synthetic fixture both row-spacer implementations read: `WithText`/`WithColumn` (genuinely unsafe) and `SafeExpandedText`/`SafeFlexibleColumn`/`SafeNoSpacer` (the prescribed fix), with the two class sets the tests assert against |
| `tools/unit/date_month_arithmetic_test.dart` | the DateTime month-boundary ratchet (category b): `sameDayYearsFrom` and `HistoryInterval.currentMonth` against Dec-31 / Jan-31 / Feb-28 fixtures, asserting the resulting MONTH (31 Dec + 1 month is November, not December; 29 Feb + 1 year is February, not March) plus the leap-year clamp. A normalization bug returns a valid DateTime, so "did not throw" is not the assertion |
| `raffle/unit/raffle_empty_guards_test.dart` | `raffleIdProvider` over an empty, populated and loading raffle list: an empty list yields `''` instead of `data.first`'s `Bad state: No element`, and a populated one still selects the first raffle |
| `raffle/widget/raffle_empty_ticket_card_test.dart` | the raffle cards' empty halves, mounted at 360px: `TicketWidget` with no ticket (`ticket[0]` used to throw a RangeError), a ticket whose raffle is absent from the list (the bare `firstWhere` threw `No element`), and `RaffleWidget` with an empty stats group (`stats.first` used to throw) |
| `vote/unit/section_provider_absent_id_test.dart` | `sectionProvider` when the selected id names no section (stale selection): it returns `SectionComplete.empty()` instead of `where(...).first`'s `Bad state: No element`, still resolves a present id, and handles an empty list |
| `advert/unit/advert_advertiser_lookup_test.dart` | the admin page's `advertiserOf` lookup: an advert whose association was deleted yields null (the bare `firstWhere` threw `No element` in the Edit tap) while a present advertiser still resolves, index and all |
| `vote/widget/list_logo_empty_test.dart` | `ListLogo` with an `AsyncData([])` logo group: it renders the same 40px circle with no image instead of reaching `logo.first` (`Bad state: No element` in a list row) |
| `vote/widget/vote_detail_logo_branches_widget_test.dart` | the detail page logo area in all three shapes: loaded avatar, EMPTY group (schedules the logo fetch exactly once, keeps the placeholder), and error group (renders the placeholder, fires no request); plus the program spacer |
| `purchases/widget/qr_code_scanner_empty_capture_test.dart` | `QRCodeScannerScreen.onDetect` on the frames the camera really emits: a capture with no barcode and a barcode with no raw value are both ignored (they used to throw `No element` / a null-check), while a real payload still reaches `onScan`. Driven through `MobileScanner`'s own callback on `FakeMobileScannerPlatform` |
| `shared/collection_guard_detector.dart` | the standing detector behind convention 36: three rules over `lib/` — `bareFirstWhere` (`firstWhere`/`singleWhere` with no `orElse:`), `whereChainFirst` (`where(...).first`/`.last`/`.single`, whose filtered list can be empty even when the source is not) and `unwrappedOptional` (`firstWhereOrNull(...)!`). Bracket-aware, with comments and string bodies blanked |
| `tools/unit/collection_guard_ratchet_test.dart` | convention 36's ratchet: every hit must be pinned in `knownGuards` with a reason, every pin must still be found (no stale keys), and a synthetic fixture proves each rule still flags its unsafe shape while the three safe shapes (`orElse`, nullable lookup, explicit loop) stay clean |
| `tools/collection_guard_fixtures.dart` | the collection-guard fixture, one file per shape (the detectors report the source file, so one file could not tell the three rules apart): `unsafe_bare`, `unsafe_chain`, `unsafe_unwrapped` and the safe `orElse` / nullable / loop files |
| `cinema/unit/parse_duration_test.dart` | `parseDuration` fed straight from its text field: blank, whitespace and malformed input yield 0 minutes instead of `int.parse`'s `FormatException`, while `1:45`/`0:30`/a missing minutes part still convert |
| `tools/unit/date_input_parsing_test.dart` | the shared date-input parsers on emptied fields: `processDateBackWithHourMaybe` answers `''` for blank and unparseable text (its fallback used to re-parse the same input and throw again) and still parses date+time and date-only strings; `processDateBack` still produces an ISO day |
| `booking/unit/booking_date_range_test.dart` | `hasInvalidBookingRange`, the save-guard helper: a blank field is invalid BEFORE `DateFormat.parse` (it used to throw from the Save `onTap`), a time-only field is left to the caller's combination with today, and ordered/reversed/unparseable ranges classify correctly |
| `tools/unit/mounted_but_exempted_ratchet_test.dart` | the REGISTRY-vs-EXEMPTION ratchet: fails when a widget is BOTH in `cardFixtures` (which every ratchet counts as mounted — the width and height sweeps, the localization round-trip, the CardLayout mount scan) AND in `notMountedExemptions` (which makes every one of those loops `continue` past it). That overlap is the `ModuleCard` shape — coverage claimed by the registry, measurement suppressed by the exemption — and the prose warnings in both files could not fail for it. Two sanctioned exits when it fires: delete the exemption and seed what the card reads, or remove the fixture entry so only the exemption accounts for the card. Liveness proven both ways on a synthetic overlap, and every exemption key must parse as a fixture id (`lib/…dart ClassName`) or the intersection could silently never fire |
| `shared/inplace_list_mutation_detector.dart` | the Dart port of the above detector, so the ratchet needs no Python at runtime. Buckets by receiver: a copy made on the spot, a class field, a notifier's API, a platform object, `DateTime`, an index expression. `state` is hard-wired to REVIEW — the one name a file can never have made for itself, and the one that silences the ratchet if the declaration scan gets it wrong |
| `tools/unit/logger_test.dart` | `Logger`'s level threshold and its pre-init queue: the default floor keeps info/warning/error/notification and drops debug (ledger #44), a raised floor still filters, hand-built `Log`s go through `writeLog`, a line queued while uninitialised is flushed exactly once, and `getLogs`/`clearLogs` delegate to the output. Plus the `kIsWeb` destination choice, split into `loggerDestinationFor` (console on the web, the file log everywhere else) because a VM run can never enter the console arm |
| `tools/unit/file_download_test.dart` | the download ROUTING, which `file_download.dart` sat at 4/17 without: `downloadChannelFor` over every value of `TargetPlatform`, so the browser wins over a mobile platform (a mobile browser is still a browser, and `saveAs` means nothing there) and iOS off the web gets the share sheet while every other native target keeps its own dialog. Plus `sanitizeFileName`, where an event or invoice name containing `/` used to point the shared file at a directory that does not exist. Splitting the branch out also proved the null check in the WEB arm was dead: `saveFile` answers a non-nullable `String`, only `saveAs` can say the user backed out (null), and the old single ternary's `String?` came from that arm and covered for both. The plugin hand-offs themselves stay untested on purpose: they are one call each, behind the channel this file pins |
| `tools/unit/plausible_event_test.dart` | the analytics call: the constructor's single trailing-slash strip, the POST lifecycle (the request completes against the binding's fake HttpClient and its status propagates back), and — through the `userAgentKindFor` seam — the User-Agent plausible's dashboard parses, which `event()` used to build inline behind `Platform.isAndroid`/`Platform.isIOS` and so could never be reached on a host. Both strings are pinned field by field (release, SDK int, model and build id for Android; system version and model for iOS), Android wins when both flags are set — the old two `if`s let the second overwrite the first — and a host that is neither sends no header at all. `getPlausible()` stays null without the `PLAUSIBLE_HOST`/`PLAUSIBLE_DOMAIN` defines, which is how CI boots |
| `tools/unit/coverage_lcov_test.dart` | the arithmetic the coverage GATE is made of, extracted from `tool/coverage_report.dart` into `tool/coverage_lcov.dart` so it can be asserted without spawning the CLI: `lib/generated/`, `lib/l10n/` and non-`lib/` records are dropped, `LF:`/`LH:` are ignored in favour of recounting the `DA:` lines (a record claiming 98/99 over three lines is not believed), the filtered lcov keeps only included records and carries the recount, a `DA` with a checksum counts once, a record with no `DA` is dropped instead of scoring 100% of nothing, an exact floor is met and a hundredth above it is not. The CLI itself was then re-run on the real lcov and still printed the same 29549/30811 — the extraction changed structure, not numbers |
| `tools/widget/loader_test.dart` | `Loader`'s size ceiling (ledger #46): a page-sized box caps at `defaultMaxSize` 64 instead of filling the viewport, a 1920x1080 desktop box caps too, an 80%-of-screen box (the idiom behind the pay page's QR placeholder and the raffle ticket's scan code) caps, a 40px box still shrinks to 40, unbounded constraints inside a scroll view fall back to `fallbackSize`, a caller-supplied `maxSize` is honoured, and a ceiling wider than the box still yields the box. Plus the real `QrCode` widget at 360x640 and 1920x1080 |
| `others/widget/loading_page_test.dart` | the boot screen's `Scaffold(body: Loader())` at 360x640 — its own isolate because `LoadingPage` navigates from `build` and qlevar_router's branch state is process-global (convention 19); needs `holdVersionVerifier: true` so the page stays on its spinner |
| `others/widget/others_version_pages_widget_test.dart` | ledger #55's F1. `UpdatePage` and `RollbackPage` were at **0/12 and 0/22** — unreachable from every test because the shell's two version fakes pinned `minimalTitanVersionCode <= titanVersion` to `1 <= 999`. Both mount at 360x640 with `titanVersion: 1, minimalTitanVersionCode: 1000, minimalHyperionVersion: '4.2.0'`: the localized copy, the client's version rendered from the provider (not a hardcoded string), the Hyperion minimum read back off `minimalHyperionVersionProvider`, the build flavor from the CI dart-define, and a 360px fit. Closes with the guard test asserting `minimal <= titanVersion` is `false` — the exact expression `lib/` branches on, which neither mounted page consults |
| `others/widget/no_internet_page_widget_test.dart` | ledger #55's F3. `NoInternetPage` was **0/31**: no fake could put `versionVerifierProvider` in its error state, and both of its `error:` arms route here. Mounted directly at 360x640 with `failVersionVerifier: true`: the server name resolved through the page's own element from the `BACKEND_HOST` dart-define, the "check your connection" and retry copy, the 360px fit, and the offline retry — which re-asks the backend and correctly leaves the user where they are. Closes with a guard asserting the provider really is an `AsyncError`, the state `lib/` branches on |
| `others/widget/no_module_page_widget_test.dart` | the `/no_module` page mounted directly with a seeded permission catalog and empty module roots (the middleware's redirect half lives in `tools/integration/no_module_redirect_integration_test.dart`, which owns its isolate's single deep-link): the granted-roots forward, the empty-roots stay, and the 360px fit |
| `super_admin/unit/module_roots_test.dart` | ledger #55's F2. `computeUserModuleRoots` decides which modules a user may open, and the shell's catalog fake returned `[]` in three of four containers — so it returned `[]` for every user in every test and the file sat at 7/20. Now **20/20**: the map builder (prefix split, no-dot entries skipped), `userHasPermission` by group and by account type, and root computation across the non-access filter, the permission filter and the lookup miss. Bug #56 is fixed and pinned here: a full-name grant resolves to its module, an ambiguous bare name is refused instead of resolving to the last module listed, `accessibility` no longer passes the access filter, and the two catalog prefixes that are not route roots (`raffle`, `seed-library`) map to `/tombola` and `/seed_library` |
| `mypayment/integration/mypayment_main_page_loading_test.dart` | the account card's `AsyncChild` spinner inside the main page's `SizedBox(height: 250)`: every mounted `Loader` on `/mypayment` must be `<= 64`. Stores resolve so the card mounts, the wallet call hangs so the loader stays up. Surface is 480px, not 360, because of the harness-font artifact in convention 20; its own isolate for the same reason as the boot screen |
| `service/unit/classes_test.dart` | the service value objects. Its `FirebaseTokenExpiration` group carries ledger #54's round-trip cases: `toJson` on a null expiration writes a real JSON null and **not** a String, `empty()` survives a full `jsonEncode`→`jsonDecode`→`fromJson` cycle, a real date survives the same cycle unchanged, and four unparseable stored values (the legacy string `"null"`, an empty string, nonsense, a missing key) each decode to null instead of throwing |
| `service/unit/setup_background_handler_test.dart` | `firebaseMessagingBackgroundHandler` called directly (it is registered from `main()`, which no test reaches): boots Firebase itself, refreshes the FCM token through the fake, initializes the plugin |
| `feed/integration/feed_home_integration_test.dart`, `home/integration/home_integration_test.dart`, `tools/integration/all_modules_integration_test.dart` | boot chain, feed, module catalog, navbar |
| `tools/integration/styleguide_page_integration_test.dart` | styleguide catalog render; button variants (danger/ondanger/secondary/disabled), all list rows + templates, search bars incl. the filter dialog, multi-select demos (tap + long press), text/date/image entries |
| `mypayment/integration/mypayment_integration_test.dart` | wallet/transactions, TOS accept flow, flip card, stats nav |
| `mypayment/integration/mypayment_store_admin_seller_rights_integration_test.dart` | the store-admin rights dialog: checked rights captured into `SellerCreation` (all five flags), a refused creation toasts and keeps the dialog, closing search clears the query, an emptied query calls `clear()` instead of `usersSearchGet(query: '')`, and the non-seller guard message |
| `mypayment/integration/mypayment_refund_integration_test.dart` | the refund sheet (`refund_page.dart` had ZERO coverage): confirmed+`requestTransaction`+`canCancel` gate, keypad to cents (12,5 → 1250), backspace, empty amount refused instead of `double.parse('')`'s FormatException, over-max amount refused (it POSTed 125.00 on a 50.00 refund before), a refused POST erroring and keeping the sheet, and the two negative gates. The sheet now hides the floating navbar while up — `NavigationTemplate` stacks the navbar over the whole Navigator, so its 82px band covered the sheet's bottom-anchored button and the tap never reached it (`hitTestable()` pins this) |
| `mypayment/widget/invoice_card_actions_widget_test.dart` | WIDGET level: `InvoiceCard`'s action sheet, the three ways an invoice's money status changes — admin mark paid / mark unpaid (the PATCH carries `paid` explicitly, and a success also fires the list refresher), the confirm-gated DELETE (nothing is sent before `Confirm`), and the payer's "mark as received". Plus the failure arm: a refused flip reports the error and does NOT refresh, because a list refresh on a failed write reads as "the backend changed it" |
| `mypayment/widget/mypayment_payment_return_widget_test.dart` | the page's payment-RETURN listener: `?code=succeeded` toasts once (a second forwarding change with the same code must stay quiet) and re-reads wallet + history + stores, not just the wallet |

| `mypayment/integration/mypayment_scan_integration_test.dart` | scan modal via `FakeMobileScannerPlatform`: scan→amount card→cancel dialog→refund, Next reset + 5s debounce, non-member gate dialog + bypass flag to backend, scan-error card, no-membership layout. Extended with the LIFECYCLE arm: backgrounding the app (`AppLifecycleState.inactive`) really stops the camera and drops the barcode subscription, and resuming re-arms it exactly ONCE — asserted by a single scan POST after resume, because a listener added without cancelling the old one would charge the customer twice |
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
| `amap/integration/amap_admin_add_product_integration_test.dart` | the CREATE half of the product form, which only the PATCH test ever exercised: no seeded product → the create-category field, a typed comma price (4,50 → 450 cents) carried in the real `amapProductsPost` body, the list-rebuild branch create mode runs and edit mode does not; plus the dropdown `onChanged` that swaps a free-text category for an existing one and drops the field |

| `amap/integration/amap_admin_edit_delivery_integration_test.dart` | delivery edit journey via creation-card pencil (own file: deferred-child rule), prefilled date + checkboxes, real PATCH |
| `seed-library/integration/seed_library_integration_test.dart` | menu grid incl. admin card, plants-page nav |
| `admin/integration/admin_integration_test.dart` | admin menu, groups nav, users-management modal, gating from feed |
| `admin/integration/admin_deeplink_integration_test.dart` | allowed admin deep link mounts (own file: init-path rule) |
| `tools/integration/middleware_gating_integration_test.dart` | non-admin deep link to `/tombola/detail` lands on feed (regression) |
| `tools/integration/rendered_path_integration_test.dart` | ledger #7: the same gated deep link, asserted through `renderedPathProvider` — the tracked path is the bounce TARGET (`/feed`, what the navigator rendered), not the path that was asked for, and `TopBar`'s chevron conditional (which watches it) agrees with the page on screen |
| `tools/integration/no_internet_middleware_integration_test.dart` | ledger #55's F3. One deep link (convention: qlevar only runs the init-path middleware chain on an isolate's first navigation) to `/` with `failVersionVerifier: true` — the log line `QR: redirect from [/] to [/no_internet]` is the assertion that `AuthenticatedMiddleware`'s `error:` arm ran, and the feed it would otherwise show is asserted **absent**. Second test pins the retry path: it re-asks the backend (verifier flips to `AsyncData`) and the user reaches the feed, because the handler awaits the re-ask and reads the fresh state instead of the build-time `isConnected` |
| `admin/integration/admin_groups_integration_test.dart` | `/admin/users_groups` deep link |
| `admin/integration/admin_notification_integration_test.dart` | `/admin/group_notification` deep link |
| `admin/integration/admin_structures_integration_test.dart` | `/admin/structures` deep link, structures + bank-holder state |
| `admin/integration/admin_association_integration_test.dart` | `/admin/association_memberships` deep link |
| `admin/integration/admin_associations_integration_test.dart` | `/admin/association` deep link |
| `admin/integration/admin_add_edit_structure_integration_test.dart` | `/admin/structures/add_edit_structure`: create form (membership chips), no-manager toast, full create capturing `mypaymentStructuresPost`, edit prefill (admin manager label) |
| `admin/integration/admin_groups_management_integration_test.dart` | `/admin/users_groups` write paths: sorted catalog, add-group modal → real `groupsPost` body captured, row action sheet (edit/manage/delete) |
| `admin/integration/admin_add_edit_member_integration_test.dart` | `/admin/association_memberships/detail_association_membership/add_edit_member`: create form, empty-user toast, picked user + dates → real `membershipsUsersUserIdPost`; pop-back lands on the seeded detail page (the manager group is seeded so the
  detail page resolves it) |
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
| `tickets/integration/tickets_edit_sections_integration_test.dart` | `/tickets/edit` item sections: locked rows (disabled fields, read-only banner, hidden add-question), add-category/add-session modals → real POST bodies (euros→cents, real picker dialogs), category DELETE via confirm modal, cancel-event unavailable toast, disabled vs allowed delete-event |
| `tickets/integration/tickets_edit_gating_integration_test.dart` | `/tickets/edit` bounce for sellers without `canManageEvents` (own file: convention 11) |
| `tickets/integration/tickets_book_integration_test.dart` | `/tickets/book`: not-found branch, category/session/question forms, checkout POST round-trip + success toast, sold-out badge blocks booking  Extended with the purchase GATE: a required question renders its `*` marker, leaves the Book button disabled until it is answered, and the typed answer then reaches the checkout body together with the category, session and the HelloAsso transfer request method. Then the THIRD checkout outcome: a non-zero price with no `paymentUrl` is the myempay case and must route to `/mypayment`, not to a browser or back to the module root — the free and HelloAsso arms were the only two ever driven. |
| `amap/integration/amap_list_products_integration_test.dart` | the customer `ListProductPage`: category pages built from the delivery's products, the overflow "See more" branch, the in-memory basket (+/- per row, the empty-basket refusal), and the real `amapOrdersPost` behind Confirm. Extended with the two branches the confirm bar decides between and nothing reached: an order ALREADY in the basket PATCHes that order (`amapOrdersOrderIdPatch`, and `verifyNever` a second POST — adding would leave the customer with two orders for one basket) and toasts "Order updated"; and the X on a non-empty basket asks first, leaving the basket intact behind the question, then really clears it on Confirm |
| `tickets/integration/tickets_book_payment_rails_integration_test.dart` | the myempay rail on `/tickets/book`, one test per reason the tile goes unselectable, each produced by seeding the backend answers the REAL `canPayProvider` chain branches on rather than by overriding the provider: unaccepted terms (accepted ≠ latest TOS), inactive device, revoked device, a device the wallet lookup does not know (404 → "not registered"), and a balance below the category price — the arm the provider deliberately leaves to the page because it depends on the amount. Plus the auto-switch: a wallet that covers the cheap category (myempay selectable, HelloAsso warning gone) but not the expensive one, so raising the price moves the selection OFF a method that can no longer pay |
| `tickets/integration/tickets_create_integration_test.dart` | `/tickets/create`: store chips, create round-trip capturing `ticketsAdminEventsPost` (euros→cents), extra-question editor, validation toast walk |
| `tickets/integration/tickets_book_integration_test.dart` | `/tickets/book` deep link: not-found branch + loaded event (needs `APP_ID_PREFIX=test`) |
| `tickets/integration/tickets_results_gating_integration_test.dart` | `/tickets/results` bounce for non sellers |
| `vote/integration/vote_detail_integration_test.dart` | `/vote/detail` deep link renders pre-seeded list state |
| `booking/integration/booking_detail_integration_test.dart` | `/booking/detail` deep link, non-admin branch |
| `booking/integration/booking_add_edit_integration_test.dart` | `/booking/add_edit` deep link, form pre-filled; plus the CREATE branch: room chips from the real endpoint, `bookingBookingsPost` round-trip asserting entity + note now ship (ledger #18 fixed, RRULE empty-string default), invalid-room toast |
| `booking/integration/booking_add_edit_recurrence_integration_test.dart` | edit-mode form: checkbox reshaping + prefill probe, no-day-selected guard (verifyNever PATCH/POST), RRULE edit round-trip asserting the PATCH ships note/entity/recurrenceRule (ledger #27, fixed), all-day toggle clears dates → validation toasts, and the interval ≥ 1 guard — `0` is refused by the field validator before syncfusion ever sees an `INTERVAL=0` rule (ledger #64) |
| `booking/integration/booking_admin_integration_test.dart` | `/booking/admin`: room + manager chip rows (gate via `user.groups` admin id). Extended with all four chip HANDLERS, each a `setRoom`/`setManager` plus a `QR.to`: each row's plus opens a blank form and each existing chip opens its own record — the selection is what the full-page form edits, so a missing one would silently pre-fill the previous room |
| `booking/integration/booking_admin_error_arms_integration_test.dart` | `/booking/admin`'s two failure arms, which only ever had their happy path driven: a room list that throws renders the error arm while the manager row keeps working, and vice versa — the real incident shape where one endpoint 500s and the admin loses the half that still works |
| `booking/integration/booking_admin_gating_integration_test.dart` | `/booking/admin` bounce for non admins |
| `booking/integration/booking_add_room_integration_test.dart` | `/booking/admin/room` form pre-filled (manager chips) |
| `booking/integration/booking_add_manager_integration_test.dart` | `/booking/admin/manager` form pre-filled (group chips) |
| `booking/integration/booking_manager_integration_test.dart` | `/booking/manager`: empty state + bookings grouped by decision (gate pre-seeded via `myManagerRoles:`) |
| `loan/widget/item_card_availability_widget_test.dart` | WIDGET level: `ItemCard`'s availability line, the number an admin reads before lending — `totalQuantity - loanedQuantity` (never the total, which would offer stock that is not on the shelf), the single-item boundary, `Unavailable` once it is fully out, and the edit/delete wiring that only renders when `showButtons` is on |
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
| `auth/integration/auth_session_lifecycle_integration_test.dart` | the session LIFECYCLE, which the sign-in and logout files each pin only one half of: both bypass `isLoggedInProvider`, so the derivation that guards every route was never watched flipping. Starts from a REAL valid session (`signedInToken` on `makeSignInFlowContainer`, no `isLoggedIn` override) → a protected foreign-module route renders; then the same `deleteToken()` + `pathForwardingProvider.reset()` sequence both logout sites run → `authTokenProvider` is an error, the stored refresh token is deleted from secure storage, `isLoggedInProvider` derives false, and a protected route is redirected to `/login`. The reset is load-bearing: the guard exempts `/login` only while forwarding still believes it is signed out, so deleting the token alone makes `/login` redirect to itself forever |
| `login/widget/login_web_panels_widget_test.dart` | WIDGET level, at a **1400x900** desktop surface (these panels are web-only; the 360x640 default would report overflows for a layout that only ever runs on a desktop): `RightPanel`'s carousel mount, a fling to the next screenshot, the dot-click→screenshot mapping (ledger #52), a real MOUSE hover that tilts the `Transform` and snaps back on exit, and the narrowest side-by-side width. `LeftPanel` mounts against the config getters' test fallbacks: under
`flutter test` the missing dart-defines no longer throw inside `build` —
`getBaseSchoolName()`/`getAppName()`/`getTitanLogo()` degrade to CI's values
(and the shipped `assets/emlyon` folder), so the school art and the app name
render, and the test pins those resolved asset names. |
| `phonebook/integration/phonebook_integration_test.dart` | `/phonebook` list + **live search filter** (types into the real TextField, one card survives) + an association whose groupement was deleted (its `groupementId` is in neither the grouping map nor the cards' lookup — both used to `!`-unwrap a missing key and take the page down) |
| `phonebook/integration/phonebook_detail_integration_test.dart` | `/phonebook/association_detail`: members by mandate ("Bolt - President"), empty state |
| `phonebook/integration/phonebook_member_detail_integration_test.dart` | `/phonebook/member_detail` pre-seeded member: nickname header, email, membership card |
| `phonebook/integration/phonebook_admin_integration_test.dart` | `/phonebook/admin` for the admin_phonebook group: header + editable card |
| `phonebook/integration/phonebook_association_edition_modal_integration_test.dart` | the edition bottom sheet's five actions from the real card journey: Edit → deferred add-edit form (prefilled fields + groupement bar), live-action inventory, term-year+1 confirm PATCH (mandateYear 2027), deactivate/delete confirm walk — toasts render via the root-navigator context + app-level wrapper (ledger #29 fixed), deactivate/delete wiring fixed (ledger #30); plus the two branches no test entered: a FULL admin who is NOT a phonebook admin gets only "Manage groups" (and routes to the groups editor), and "Manage members" is actually TAPPED rather than merely asserted present — its onPressed seeds the association and groupement, pops the sheet and routes to the membership editor. The file is at **104/104** lines |
| `phonebook/integration/phonebook_admin_gating_integration_test.dart` | `/phonebook/admin` bounce for plain users |
| `phonebook/integration/phonebook_groups_integration_test.dart` | `/phonebook/admin/edit_association_groups` toggle list (gates on the **plain admin** group) |
| `phonebook/integration/phonebook_add_edit_integration_test.dart` | `/phonebook/admin/add_edit_association` add + pre-filled edit modes (labels come from `InputDecoration`, canBeEmpty adds " (Optional)") |
| `phonebook/integration/phonebook_groupement_add_edit_integration_test.dart` | groupement edit form pre-filled from the selected groupement |
| `phonebook/integration/phonebook_member_flows_integration_test.dart` | REAL modal-driven member flows: add-member (editor → user-search sheet → real search endpoint → select → POST) and member-edition modal (edit-role → PATCH); the duplicated "card title == modal title" needs `.first` + `findsNWidgets(2)` |
| `vote/integration/vote_admin_integration_test.dart` | `/vote/admin` for the admin_vote group: section chips from the real sections endpoint (waiting-status state) |
| `vote/integration/vote_admin_gating_integration_test.dart` | `/vote/admin` bounce for plain users |
| `vote/integration/vote_add_section_integration_test.dart` | add-section form mounts + real `campaignSectionsPost` → back on admin with the new chip |
| `vote/integration/vote_open_votes_integration_test.dart` | waiting-status admin panel + Open votes through the real `campaignStatusOpenPost` → page flips to the open state (close button, counter) |
| `vote/integration/vote_admin_destructive_handlers_integration_test.dart` | `OpeningVote`'s last three branches: the **Fake** (pipo) delete dialog → `campaignListsDelete(listType: pipo)` + "Fake lists deleted", a rejected `campaignStatusOpenPost` → "Error opening votes" with the panel still waiting, and a rejected delete in BOTH dialogs → "Error deleting" (delete-all and pipo) |
| `vote/integration/vote_admin_status_handlers_integration_test.dart` | the admin page's status machine: delete-all dialog → real `campaignListsDelete`, open status (bare `7 Votes`, ledger #32 fixed) → Close votes POST, closed → Count votes POST, counting → Show-votes toggle + Publish dialog POST with real chart labels (ledger #33 fixed), Reset dialog → waiting again |
| `vote/integration/vote_main_page_integration_test.dart` | the `/vote` main surface (ListListCard + ListCard): open-status cards (name/type/logo-fallback/info buttons) + See-more FAB scroll, envelope select → `Selected` + provider state, already-voted section hides voting, published result bars with per-list percentages (75.0/25.0), non-voter cannot-vote surface, and a section with no lists leaves the page standing — its percent total is summed with `fold`; the `reduce` it replaced threw `Bad state: No element` inside `whenData`, which CATCHES a throwing callback and hands back an AsyncError this widget never reads, so the crash reached neither `FlutterError.onError` nor `takeException` (silent: no error widget, no framework report) |
| `vote/integration/vote_results_zero_integration_test.dart` | the PUBLISHED results chart (`VoteBars`) for the two result shapes no other fixture produces: every count 0 (the axis labels used to be `0/0` → `NaN%`) and a section with no lists (`.reduce` on an empty iterable threw `Bad state: No element` out of `build` — fixed: `VoteBars` folds its total now) |
| `vote/integration/vote_add_edit_list_integration_test.dart` | the waiting-status + button → add-list form, create round-trip capturing the real `campaignListsPost` body (all three TextEntry validators required) |
| `vote/integration/vote_add_list_type_error_integration_test.dart` | the type chips (a tap on "Pipo" must reach the POST, not stay in the widget) and a refused save (the form stays put and reports "Error editing" instead of popping like a success) |

| `vote/integration/vote_edit_list_integration_test.dart` | list-card edit sheet → prefilled edit form → real `campaignListsListIdPatch`; the card's onTap delays 150ms before the sheet shows |
| `loan/integration/loan_admin_integration_test.dart` | `/loan/admin` allowed case via `myLoaners:` gate pre-seed: item cards with quantities/caution |
| `loan/integration/loan_item_bar_integration_test.dart` | the add-edit-loan ItemBar: pre-populated per-loaner map via the admin parent mount (the search bar re-seeds it too), stepper round-trip (empty end before a start is picked — ledger #34 guard — caution 3000.00 €, selected count), computed end after a start pick, minus clears both, cap at total-loaned, both "No items" branches, edit mode pre-selects itemsQty |
| `loan/integration/loan_admin_gating_integration_test.dart` | `/loan/admin` bounce for non-loaner users |
| `loan/integration/loan_add_edit_item_integration_test.dart` | `/loan/admin/add_edit_item` edit form (own file: 3 stacked deferred libraries need a long frame budget) |
| `cinema/integration/cinema_integration_test.dart` | `/cinema` session cards (wide web layout: name/date/overview) + empty state |
| `cinema/integration/cinema_detail_integration_test.dart` | `/cinema/detail` pre-selected session renders |
| `cinema/integration/cinema_admin_detail_route_integration_test.dart` | the SECOND detail route, `/cinema/admin/detail`, nested under the admin page: nothing navigates to it (both callers build `/cinema/detail`), so only a typed URL can arrive there — which is how a bookmarked web URL does. Same file pins `CinemaRouter.module.getName`/`getDescription` against the real bundle (`getName` is the navbar label; `getDescription` has no caller in `lib/` at all, so a missing l10n key would only surface here) |
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
| `feed/integration/feed_event_create_failure_integration_test.dart` | bug report 28/09 (`plusieurs assos n'arrivent pas à créer d'event … "erreur lors de l'ajout"`): the CREATE-mode failure arm no other feed test takes — every one stubs a successful `calendarEventsPost`, and the suite's only `Error while adding` expectation belonged to the edit-mode poster upload. A refused create (500, no body) toasts the adding error, does not claim `Event added`, does not pop the form, and POSTs exactly once (no silent retry behind the user, which is how the reported 1–2 h retries became duplicates). **Writing it found the real defect**: the create branch returned `onSaved(...)` whenever `poster.value == null`, BEFORE ever looking at the created id, so a refused create with no poster was reported as a success and popped the page with nothing on the server. The id check now precedes the poster branch, and this test is what keeps it there. Two further arms pin the DUPLICATE-generating path: a created event whose poster upload throws, or whose upload is refused with a non-2xx, now names the **image** ("Error adding the image") and closes the form — it used to fall through to the generic "Error while adding" and stay open, so the next publish created a second event. Reaching that needed `EventImageNotifier.addEventImage` fixed as well: it discarded the response and always answered `true`, so a 4xx/5xx upload was reported to its caller as a success |
| `login/integration/login_failure_and_links_integration_test.dart` | the sign-in failure side and the two external links: a rejected code exchange lands `authTokenProvider` in its error state WITHOUT leaving `/login`, and register / recover open `/calypsso/register` and `/calypsso/recover` through `launchUrl` (a plugin the real run only answers on a device). Plus bug report 12/10: `/login` collects **no** password of its own — `find.byType(EditableText)` finds nothing and there is no wrong-password copy — because authentication happens on Calypso's page, so "l'app dit que le mot de passe est incorrect" cannot be attributed to this app. If a password field or such a claim ever appears on this screen, this fails |
| `feed/integration/feed_add_event_residual_integration_test.dart` | create-mode add_event_page residuals: the validation-chain toasts (title, dates, location, association), chip selection, the ticketing switch's permission subtitle, the date/link pairing through the real pickers, the existing-ticketing dropdown + captured `calendarEventsPost` body (ticketEventId `te-1`, null ticketUrl) |
| `feed/integration/feed_event_save_errors_integration_test.dart` | the save-failure arm reachable only with a poster attached: a THROWING image upload is caught by the page, toasts the adding error and does NOT pop. Also pins the finding that a non-2xx upload response is reported as success by the notifier (a 500 popped the page with "Event modified"), which is why a refused upload cannot reach the failure branch |
| `feed/unit/news_helper_dates_test.dart` | the seven date arms of the news subtitle, built relative to now so the suite cannot rot: today/yesterday/tomorrow, weekday inside the coming week, "last" inside the past week, month-day this year, explicit year otherwise, same-day from/to span (the day named once) and open-ended news |


| `feed/integration/feed_edit_event_residual_integration_test.dart` | edit-mode add_event_page residuals: prefilled all-day event, the all-day checkbox clearing both date controllers, save WITH a poster upload (platform-level `ImagePickerPlatform` fake → captured `EventEdit` body + `calendarEventsEventIdImagePost` + `Event modified`), refused update → `Error while modifying` |

The event module is deliberately **not registered in the central route
table** (`lib/router.dart`, commit "removing event from router"), so there
are no `/event/*` shells — deep links land on "Page Not Found" by design.

## Known app bugs surfaced by these tests

Only the bugs that are STILL OPEN are listed here. The fixed ones are gone
from this file: their `ledger #NN` identifiers still appear in the prose
elsewhere in this README and in test comments, numbers are never reused, and
a number whose entry is missing from this list is a ledger that has been
fixed. Nothing is open at the moment: the last three families closed from
code — amap's money units (#5 + #13: Hyperion stores cents, so lib divides on
render and multiplies what the forms collect, and the cash card's optimistic
update now shows previous + delta instead of the delta alone), qlevar's stale
`QR.currentPath`
(#7: lib watches `renderedPathProvider`, convention 35), and #37, which was
never an app bug but a measurement caveat (`getDominantColor`'s engine lane is
now awaited under `runAsync`, so its coverage is 32/33 on every run).

### Auth/session unit tests (`test/auth/`)

- `auth_repository_refresh_test.dart` — `AuthRepository.refreshToken`: the
  real repository over the mocked appauth/secure-storage channels (dedup,
  success, `invalid_grant`/`invalid_request` wipe, no-token fail-fast,
  non-OAuth failure); also covers PKCE helper boundary length 0.
- `auth_repository_web_refresh_test.dart` — the browser web refresh-token
  grant, driven on the VM through `AuthRepository(isWeb: true)`: request body,
  rotated-token persistence, invalid-token cleanup for HTTP 400 and 401, and
  retention of the token on a server error. No `--platform chrome` and no
  `skip:` — the seam is what made these four reachable in the default run.
- `auth_repository_web_login_test.dart` — the browser AUTHORIZATION-CODE grant,
  the other half of `AuthRepository(isWeb: true)`: the PKCE authorize URL and
  its `code_challenge_method=S256`, the code exchange body (grant type,
  client id, redirect, 128-char verifier), rotated-token persistence, a
  duplicate post from the same popup spending only one code, a popup closed
  with no code read as a cancellation, and — the invariant worth a test — a
  popup closed AFTER the code arriving not read as a cancellation. Plus the
  two failure paths: a blocked popup and a rejected or code-less exchange.
  Driven through the `openWindow` seam, because the shim is a conditional
  import whose off-browser arm is a bare `throw`.
- `openid_provider_test.dart` — auth token provider lifecycle: stored token
  load/refresh, empty storage/request/refresh responses to error states,
  request error, refresh error and successful refresh; real JWT subject
  decoding/cache and is-logged-in/loading derivatives.
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
- `findInplaceListMutations()` in
  `test/shared/inplace_list_mutation_detector.dart` — the **generalised**
  ledger #12/#51 sweep, Dart-only: 201 call sites across `lib/`, bucketed
  fresh/owned/api/control/nonlist/element/review. It has no allowlist: a site
  that is safe has to be *proved* safe by a rule in that file. Backed by
  `tools/unit/inplace_list_mutations_test.dart`, which fails on a new
  `review` site — see convention 24 for the mount ratchet's shape and
  convention 27 for the raw-string trap that briefly made the sweep report
  115 findings instead of 21.

## Roadmap to 80% (next rounds, biggest uncovered first)

> **Targets cleared:** 80% on 2026-10-18 (85.32%), 90% in the
> least-covered-module rounds, **95% on 2026-10-28 (95.02%,
> 29137/30664)** and **96% on 2026-11-02 (96.16%, 29640/30824)** — the
> source of the COVERAGE_MIN ratchet in CI, now 96. The
> list stays as the record of what each round did. Remaining headroom, by
> uncovered-line count: mypayment 191, amap 114, raffle 101, tickets 94,
> tools 90, admin 89, vote 85, feed 82, loan 62 (auth is fully covered).

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
   `DetailOrderUI` (exempt on layout grounds only — the `return state`
   crash that kept it out is fixed) and the fact that the two detector
   implementations are only cross-checked by count, so a richer
   cross-check — diffing the Python output from the test — is the obvious
   next tightening.

Per-round recipe: pick the top module, list its unmounted routes from the
router file, write one deep-link shell file per route (own file: init-path
rule), stub the endpoints its providers auto-load (grep `repository.` in
the page's watched providers), assert on rendered content (never vacuous),
run solo, then full suite + lcov.
