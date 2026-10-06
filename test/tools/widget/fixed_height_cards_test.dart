import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement
// in this file.
import 'package:titan/generated/openapi.models.swagger.dart';

import 'package:titan/admin/ui/components/user_ui.dart';
import 'package:titan/amap/ui/pages/main_page/delivery_section.dart';
import 'package:titan/feed/ui/pages/association_events_page/association_event_card.dart';
import 'package:titan/loan/ui/pages/admin_page/loaners_bar.dart';
import 'package:titan/login/ui/components/sign_in_up_bar.dart';
import 'package:titan/mypayment/ui/components/invoice_card.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/product_card.dart';
import 'package:titan/mypayment/ui/components/paiment_delegate/wallet_balance_card.dart';
import 'package:titan/mypayment/ui/pages/main_page/account_card/device_dialog_box.dart';
import 'package:titan/mypayment/ui/pages/main_page/main_card_button.dart';
import 'package:titan/mypayment/ui/pages/main_page/main_card_template.dart';
import 'package:titan/mypayment/ui/pages/main_page/tos_dialog.dart';
import 'package:titan/mypayment/ui/pages/pay_page/info_card.dart';
import 'package:titan/ph/ui/components/year_bar.dart';
import 'package:titan/phonebook/ui/components/groupement_bar.dart';
import 'package:titan/seed-library/ui/components/types_bar.dart';
import 'package:titan/settings/ui/pages/log_page/log_card.dart';
import 'package:titan/tickets/ui/components/edit_ticket_event_helpers.dart';
import 'package:titan/tickets/ui/components/stat_tile.dart';
import 'package:titan/tickets/ui/components/ticket_event_card.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/vote/ui/components/member_card.dart';
import 'package:titan/vote/ui/pages/admin_page/list_card.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/card_fixtures.dart';
import '../../shared/fixed_size_card_fixtures.dart';
import '../../shared/fixed_width_card_detector.dart';

/// The height half of the fixed-size sweep (ledger #62).
///
/// The width detector excluded a card that only pins a HEIGHT, on the grounds
/// that "clipping is a different question from overflow". That was the same
/// wrong call convention 24 records for `ItemCardInLoan`: inside a
/// `RenderFlex` a pinned height compresses, but a card whose own box is
/// `SizedBox(height: 40)` with an un-capped `Text` in it overflows
/// **vertically** by exactly the same kind of amount, and
/// `flutter_test` treats that as fatal too. So the exclusion is gone and the
/// two families live in separate FILES — separate, because mixing them buries
/// the width bugs, which is what the original objection was actually about.
///
/// The mount is the width sweep's, unchanged and for the same reasons: alone
/// at 360x640, `appFonts: true` so the harness measures in real Lato rather
/// than in squares (convention 20), no router and no `AppTemplate`, and a
/// `find.byType` assertion per card so "no overflow" cannot be true because
/// the card failed to build.
///
/// The one difference is in the parent. A fixed HEIGHT is only reachable
/// inside a bounded parent, so `wrap` is not an override here but the default:
/// every card goes into a `SizedBox(height: 640)` so a card that wants to
/// grow past the box overflows instead of sitting in an unbounded scroll view
/// where nothing can.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The endpoints the height candidates fetch on mount. Same reason as the
  /// width sweep's list: an unstubbed mocktail method returns null where a
  /// `Future` is expected, so the card dies before it lays out and "no
  /// overflow" becomes true for the wrong reason.
  void stubCardImages() {
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.advertAdvertsAdvertIdPictureGet(
        advertId: any(named: 'advertId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.cinemaSessionsSessionIdPosterGet(
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository
          .recommendationRecommendationsRecommendationIdPictureGet(
            recommendationId: any(named: 'recommendationId'),
          ),
    ).thenAnswer((_) async => _missingImage);
    when(
      () => scaffold.repository.campaignListsListIdLogoGet(
        listId: any(named: 'listId'),
      ),
    ).thenAnswer((_) async => _missingImage);
    // The two endpoints the seed-library/vote cards fetch on build: their
    // providers' build() calls them and OVERWRITE a state seed once the
    // future lands, so the data has to come from the repository.
    when(() => scaffold.repository.seedLibrarySpeciesGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), speciesMap),
    );
    when(() => scaffold.repository.campaignSectionsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        SectionComplete.empty().copyWith(id: 'section-1', name: 'Section 1'),
      ]),
    );
  }

  /// The height candidates the width detector ALSO finds — cards that pin both
  /// a width and a height. The width sweep already proved these builders mount
  /// (they are in [cardFixtures]), so the height sweep reuses them rather than
  /// rebuilding them. These are deliberately NOT in [_heightOnly]: a card that
  /// pins a width but no height would make the "mounted ⊆ found" ratchet a lie
  /// about what the height sweep covers.
  /// Cards that pin BOTH a width and a height: they are in the width sweep's
  /// [cardFixtures] AND the height detector finds them. The height sweep reuses
  /// these builders rather than rebuilding them.
  final _both = cardFixtures.where((c) {
    final candidate = '${c.source} ${c.className}';
    return findFixedHeightCards().map((h) => h.toString()).contains(candidate);
  }).toList();

  /// The height candidates the width detector does not find, so they belong to
  /// this sweep alone. Twenty-one of them, and the shape of the list is the
  /// finding: eleven are mypayment, and they are mostly DIALOGS and templates
  /// rather than cards — `TOSDialogBox`, `DeviceDialogBox`,
  /// `MainCardTemplate`, `WalletBalanceCard` — which is what "height-only"
  /// buys: a family the width scan structurally never looked at.
  final _heightOnly = <SweepCard>[
    SweepCard(
      'lib/admin/ui/components/user_ui.dart',
      'UserUi',
      UserUi,
      (c, _) => UserUi(
        user: CoreUserSimple.empty().copyWith(firstname: longName),
        onDelete: () {},
      ),
    ),
    SweepCard(
      'lib/amap/ui/pages/main_page/delivery_section.dart',
      'DeliverySection',
      DeliverySection,
      (c, _) => const DeliverySection(),
    ),
    SweepCard(
      'lib/feed/ui/pages/association_events_page/association_event_card.dart',
      'AssociationEventCard',
      AssociationEventCard,
      (c, _) => AssociationEventCard(
        event: EventCompleteTicketUrl.empty().copyWith(
          name: longTitle,
          description: longName,
          start: DateTime(2026, 10, 2),
          end: DateTime(2026, 10, 3),
          location: longName,
          association: Association.empty().copyWith(name: longName),
        ),
      ),
    ),
    SweepCard(
      'lib/loan/ui/pages/admin_page/loaners_bar.dart',
      'LoanersBar',
      LoanersBar,
      (c, _) => LoanersBar(onTap: (_) {}),
    ),
    SweepCard(
      'lib/login/ui/components/sign_in_up_bar.dart',
      'SignInUpBar',
      SignInUpBar,
      (c, _) => SignInUpBar(
        label: longTitle,
        onPressed: () async {},
        isLoading: false,
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/components/invoice_card.dart',
      'InvoiceCard',
      InvoiceCard,
      (c, _) => InvoiceCard(
        invoice: Invoice.empty().copyWith(
          reference: longTitle,
          creation: DateTime(2026, 10, 2),
          startDate: DateTime(2026, 10, 2),
          endDate: DateTime(2026, 11, 2),
          total: 1250000,
          structure: structure('store-1', longName, 'user-1'),
        ),
        isAdmin: true,
        invoicesRefresher: () {},
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/components/paiment_delegate/product_card.dart',
      'ProductCard',
      ProductCard,
      (c, _) => ProductCard(
        title: longTitle,
        description: longName,
        priceInCents: 1250000,
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/components/paiment_delegate/wallet_balance_card.dart',
      'WalletBalanceCard',
      WalletBalanceCard,
      (c, _) => const WalletBalanceCard(),
    ),
    SweepCard(
      'lib/mypayment/ui/pages/main_page/account_card/device_dialog_box.dart',
      'DeviceDialogBox',
      DeviceDialogBox,
      (c, _) => DeviceDialogBox(
        title: longTitle,
        descriptions: longName,
        buttonText: 'OK',
        onClick: () {},
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/pages/main_page/main_card_template.dart',
      'MainCardTemplate',
      MainCardTemplate,
      (c, _) => MainCardTemplate(
        actionButtons: [
          MainCardButton(
            icon: HeroIcons.wallet,
            onPressed: () async {},
            title: longTitle,
            colors: const [Colors.white, Colors.black],
          ),
        ],
        colors: const [Colors.white, Colors.black],
        title: longTitle,
        toggle: null,
        child: const SizedBox.shrink(),
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/pages/main_page/tos_dialog.dart',
      'TOSDialogBox',
      TOSDialogBox,
      (c, _) => TOSDialogBox(
        title: longTitle,
        descriptions: longName,
        onYes: () {},
        onNo: () {},
      ),
    ),
    SweepCard(
      'lib/mypayment/ui/pages/pay_page/info_card.dart',
      'InfoCard',
      InfoCard,
      // `InfoCard` returns an `Expanded`, so it only lays out inside a Flex: in
      // the pay sheet it is one of three cards side by side under the QR. A
      // bare `SizedBox` parent is "Incorrect use of ParentDataWidget", which is
      // a fixture problem, not a card problem — hence `wrap`.
      (c, _) => InfoCard(
        icons: HeroIcons.wallet,
        title: longTitle,
        value: '1 250,00 ʍ',
      ),
      wrap: (child) => SizedBox(
        height: 640,
        // Three of them, exactly as `confirm_button.dart` builds them: each is
        // an `Expanded`, so each gets a third of the 360px. An `Expanded` here
        // too would be a second `FlexParentData` on the same RenderObject.
        child: Row(children: [child, child, child]),
      ),
    ),
    SweepCard(
      'lib/ph/ui/components/year_bar.dart',
      'YearBar',
      YearBar,
      (c, _) => const YearBar(),
    ),
    SweepCard(
      'lib/phonebook/ui/components/groupement_bar.dart',
      'AssociationGroupementBar',
      AssociationGroupementBar,
      (c, _) => AssociationGroupementBar(),
    ),
    SweepCard(
      'lib/seed-library/ui/components/types_bar.dart',
      'TypesBar',
      TypesBar,
      (c, _) => TypesBar(),
    ),
    SweepCard(
      'lib/settings/ui/pages/log_page/log_card.dart',
      'LogCard',
      LogCard,
      (c, _) => LogCard(
        log: Log(
          message: longName,
          level: LogLevel.notification,
          time: DateTime(2026, 10, 2, 12, 30),
        ),
      ),
    ),
    SweepCard(
      'lib/tickets/ui/components/edit_ticket_event_helpers.dart',
      'SectionCard',
      SectionCard,
      (c, _) => SectionCard(title: longTitle, child: Text(longName)),
    ),
    SweepCard(
      'lib/tickets/ui/components/stat_tile.dart',
      'StatTile',
      StatTile,
      // Two RichText spans built from "125000 / 125000" in the real tile: the
      // value and the total are separate spans, so neither `find.text` nor a
      // widget-type check can see the tile's text (convention 5).
      (c, _) => const StatTile(
        label: 'Billets',
        value: 125000,
        total: 125000,
        color: Colors.black,
      ),
    ),
    SweepCard(
      'lib/tickets/ui/components/ticket_event_card.dart',
      'TicketEventCard',
      TicketEventCard,
      (c, _) => TicketEventCard(
        ticketEvent: EventSimple.empty().copyWith(
          name: longTitle,
          openDatetime: DateTime(2026, 10, 2),
          closeDatetime: DateTime(2026, 10, 3),
          storeId: 'store-1',
        ),
      ),
    ),
    SweepCard(
      'lib/vote/ui/components/member_card.dart',
      'MemberCard',
      MemberCard,
      (c, _) => MemberCard(
        // `ListMemberComplete` wraps a `CoreUserSimple`, which has no lastname:
        // the card prints firstname + nickname, so both are long here.
        member: ListMemberComplete.empty().copyWith(
          user: CoreUserSimple.empty().copyWith(
            firstname: longName,
            nickname: longTitle,
          ),
        ),
        onEdit: () {},
        onDelete: () {},
        isAdmin: true,
      ),
    ),
    SweepCard(
      'lib/vote/ui/pages/admin_page/list_card.dart',
      'ListCard',
      ListCard,
      (c, _) => ListCard(
        list: ListReturn.empty().copyWith(
          name: longTitle,
          description: longName,
        ),
        onEdit: () {},
        onDelete: () async {},
        isAdmin: true,
      ),
    ),
  ];

  /// The cards this sweep mounts: the width sweep's cards that ALSO pin a
  /// height, plus the height-only ones this round added.
  final cards = [..._both, ..._heightOnly];

  test('the sweep covers every fixed-height card under lib/', () {
    final found = findFixedHeightCards().map((c) => '$c').toList();
    final covered = {...cards.map((c) => '$c'), ...notMountedExemptions.keys};
    final uncovered = found.where((c) => !covered.contains(c)).toList();

    expect(
      uncovered,
      isEmpty,
      reason:
          'these fixed-height cards are not mounted by this sweep. Add an '
          'entry to _heightOnly or _both in '
          'test/tools/widget/fixed_height_cards_test.dart (a card the width '
          'sweep already mounts goes in _both), or list it in '
          'notMountedExemptions with the reason it cannot be mounted.',
    );
    // An exemption with no reason is a silent hole; make it a failure.
    expect(
      notMountedExemptions.values.where((r) => r.trim().isEmpty),
      isEmpty,
      reason:
          'every entry in notMountedExemptions must say why the card cannot '
          'be mounted here',
    );
    // The mirror image: a card this file mounts must be one the height
    // detector really finds. Without this, a card that stopped pinning a
    // height would keep being swept forever under a name that no longer
    // describes it.
    final mounted = cards.map((c) => '$c').toSet();
    expect(
      mounted.where((c) => !found.contains(c)),
      isEmpty,
      reason:
          'the sweep mounts a card the height detector no longer finds; drop '
          'the entry from this file (_heightOnly or _both) or teach the '
          'detector about the new shape.',
    );
  });

  for (final card in cards) {
    if (notMountedExemptions.containsKey('${card.source} ${card.className}'))
      continue;
    testWidgets('${card.source} ${card.className} fits a 640px-tall box', (
      tester,
    ) async {
      final container = scaffold.makeContainer(
        myStructures: [structure('structure-1', longName, 'user-1')],
      );
      stubCardImages();
      // Seed AFTER the stubs: reading a provider's notifier fires its
      // build()'s repository fetch on the spot, so a stub registered
      // afterwards would miss that call — the provider would settle on an
      // AsyncError and the card would mount against an empty list. The
      // seed covers the shared maps (species, section); the one exemption
      // left (OrderSection) reads page-scoped maps this seed does not touch.
      seedSharedMaps(container);
      addTearDown(container.dispose);

      final anim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 200),
        value: 1,
      );
      addTearDown(anim.dispose);

      final cardWidget = card.build(container, anim);
      await scaffold.pumpWidgetApp(
        tester,
        // The bounded parent. `wrap` still wins when a card brings its own
        // (`ModuleCard` is a `GridView` child, `InfoCard` is a three-up flex),
        // and for everything else this is what gives the pinned height something
        // to overflow against.
        card.wrap?.call(cardWidget) ?? SizedBox(height: 640, child: cardWidget),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      // `findsWidgets`, not `findsOneWidget`: the point is that the card is
      // ON SCREEN, and one entry (`InfoCard`, which is itself an `Expanded`)
      // is deliberately mounted three-up to mirror the pay sheet. `findsNothing`
      // is the failure this guards against — a card that threw during build
      // satisfies "no overflow" for the wrong reason.
      expect(
        find.byType(card.type),
        findsWidgets,
        reason:
            '${card.source} ${card.className} did not mount: either it threw '
            'during build, or the fixture it needs is missing.',
      );

      await scaffold.unmountApp(tester);
    });
  }
}

/// Cards the height sweep deliberately does NOT mount, and why.
///
/// A 404 for every logo/picture the cards request: the image widgets render
/// their error state, which is what a device shows for a missing asset.
final _missingImage = chopper.Response(http.Response('', 404), <int>[]);
