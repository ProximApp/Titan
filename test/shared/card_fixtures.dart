import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/admin/ui/pages/membership/association_membership_detail_page/association_membership_member_editable_card.dart';
import 'package:titan/advert/ui/components/association_item.dart';
import 'package:titan/advert/ui/pages/admin_page/admin_advert_card.dart';
import 'package:titan/advert/ui/pages/main_page/advert_card.dart';
import 'package:titan/amap/ui/components/product_ui.dart';
import 'package:titan/amap/ui/pages/admin_page/adding_user_card.dart'
    as amap_add;
import 'package:titan/amap/ui/pages/admin_page/delivery_ui.dart'
    as amap_admin_delivery;
import 'package:titan/amap/ui/pages/admin_page/user_cash_ui.dart' as amap_cash;
import 'package:titan/amap/ui/pages/delivery_pages/product_ui_check.dart';
import 'package:titan/amap/ui/pages/detail_delivery_page/product_detail_ui.dart';
import 'package:titan/amap/ui/pages/main_page/delivery_ui.dart'
    as amap_main_delivery;
import 'package:titan/booking/ui/components/booking_card.dart';
import 'package:titan/centralassociation/class/link.dart';
import 'package:titan/centralassociation/ui/pages/link_card.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralisation/ui/pages/liked_card.dart';
import 'package:titan/centralisation/ui/pages/module_card.dart';
import 'package:titan/cinema/ui/pages/admin_page/admin_session_card.dart';
import 'package:titan/cinema/ui/pages/main_page/session_card.dart'
    as cinema_session;
import 'package:titan/event/ui/components/event_ui.dart';
import 'package:titan/feed/ui/pages/event_handling_page/admin_event_card.dart';
import 'package:titan/feed/ui/pages/main_page/time_line_item.dart';
import 'package:titan/home/ui/day_card.dart';
import 'package:titan/home/ui/month_bar.dart';
import 'package:titan/loan/ui/pages/admin_page/item_card.dart';
import 'package:titan/loan/ui/pages/admin_page/loan_card.dart';
import 'package:titan/loan/ui/pages/loan_group_page/check_item_card.dart';
import 'package:titan/loan/ui/pages/loan_group_page/item_bar.dart';
import 'package:titan/mypayment/ui/components/request_card.dart';
import 'package:titan/mypayment/ui/components/transaction_card.dart';
import 'package:titan/mypayment/ui/pages/devices_page/device_item.dart';
import 'package:titan/mypayment/ui/pages/main_page/seller_card/admin_invoice_card.dart';
import 'package:titan/mypayment/ui/pages/main_page/seller_card/store_seller_card.dart';
import 'package:titan/mypayment/ui/pages/main_page/seller_card/structure_admin_card.dart';
import 'package:titan/mypayment/ui/pages/stats_page/sum_up_card.dart';
import 'package:titan/mypayment/ui/pages/store_admin_page/seller_right_card.dart';
import 'package:titan/mypayment/ui/pages/store_stats_page/summary_card.dart';
import 'package:titan/mypayment/ui/pages/structure_admin_page/admin_store_card.dart';
import 'package:titan/ph/ui/pages/admin_page/admin_ph_card.dart';
import 'package:titan/purchases/ui/pages/history_page/purchase_card.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/adding_user_card.dart'
    as raffle_add;
import 'package:titan/raffle/ui/pages/admin_module_page/tombola_card.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/prize_card.dart'
    as raffle_edit_prize;
import 'package:titan/raffle/ui/pages/creation_edit_page/user_cash_ui.dart'
    as raffle_cash;
import 'package:titan/raffle/ui/pages/raffle_page/prize_card.dart'
    as raffle_page_prize;
import 'package:titan/recommendation/ui/components/recommendation_card.dart';
import 'package:titan/seed-library/ui/components/filters_bar.dart';
import 'package:titan/seed-library/ui/pages/main_page/menu_card_ui.dart'
    as seed_menu;
import 'package:titan/seed-library/ui/pages/plants_page/personal_plant_card.dart';
import 'package:titan/seed-library/providers/species_type_list_provider.dart';
import 'package:titan/vote/providers/status_provider.dart';
import 'package:titan/vote/providers/sections_stats_provider.dart';
import 'package:titan/seed-library/ui/pages/species_page/species_card.dart';
import 'package:titan/seed-library/ui/pages/stock_page/plant_card.dart';
import 'package:titan/super_admin/ui/pages/main_page/menu_card_ui.dart'
    as super_menu;
import 'package:titan/super_admin/ui/pages/permissions/permission_tile.dart';
import 'package:titan/super_admin/ui/pages/schools/school_page/school_ui.dart';
import 'package:titan/tickets/ui/components/session_card.dart'
    as tickets_session;
import 'package:titan/tickets/ui/components/stats_card.dart';
import 'package:titan/tickets/ui/components/tarif_card.dart';
import 'package:titan/tickets/ui/components/user_ticket_card.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/ui/styleguide/list_item_template.dart';
import 'package:titan/tools/ui/styleguide/searchbar.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';
import 'package:titan/tools/ui/widgets/top_bar.dart';
import 'package:titan/vote/ui/pages/main_page/list_card.dart';
import 'package:titan/vote/ui/pages/main_page/list_list_card.dart';
import 'package:titan/vote/ui/pages/main_page/side_item.dart';
import 'app_scaffold.dart';

/// The card fixtures the fixed-SIZE sweeps share.
///
/// Both sweeps mount the same cards with the same adversarial data; the only
/// difference is which detector produced the list — the width family
/// (`fixed_width_cards_test.dart`) and the height family
/// (`fixed_height_cards_test.dart`, ledger #62). A second copy of these
/// builders would be a second source of truth that drifts the moment one
/// card's constructor changes, and a drifted fixture fails as a phantom
/// layout bug — the most expensive kind of wrong answer this suite gives.
///
/// Each entry names the widget's own [SweepCard.type] so the sweep can assert
/// the card actually MOUNTED. That is not ceremony: half of these cards used
/// to satisfy "no overflow" for the wrong reason, because an unstubbed
/// repository call threw during build and left the tree empty (see the
/// `_notMounted` map in the sweep).
///
/// The strings are long on purpose: the sweep measures them in real Lato, and
/// it is the length that decides whether a hardcoded box is too small.

class SweepCard {
  const SweepCard(
    this.source,
    this.className,
    this.type,
    this.build, {
    this.wrap,
  });

  final String source;
  final String className;

  /// The widget's own type, so the sweep can assert it actually mounted
  /// instead of asserting some ancestor happened to exist.
  final Type type;
  final Widget Function(ProviderContainer c, AnimationController anim) build;

  /// Overrides the sweep's default parent. It exists for cards that cannot
  /// live inside a vertically unbounded `SingleChildScrollView`: a card
  /// holding an `Expanded` needs a finite height, and in the app it gets one
  /// from the grid cell it is built in. `ModuleCard` is the case in point -
  /// it is only ever a `GridView.builder` child.
  final Widget Function(Widget child)? wrap;

  @override
  String toString() => '$source $className';
}

/// Long on purpose: the harness measures this in real Lato, and it is the
/// length that decides whether a hardcoded row overflows.
const longName =
    'Association des étudiants en medecine de l universite de bordeaux';
const longTitle = 'Reservation pour la conference annuelle';

/// `Request$` has no `empty()` — every field is required.
/// A pending top-up request, the shape the request card and its modal read.
final proposedRequest = Request$(
  id: 'request-1',
  walletId: 'wallet-1',
  creation: DateTime(2026, 10, 2),
  expirationDate: DateTime(2026, 11, 2),
  total: 1250000,
  storeId: 'store-1',
  name: longTitle,
  module: 'module-1',
  objectId: 'object-1',
  status: enums.RequestStatus.proposed,
);

final cardFixtures = <SweepCard>[
  SweepCard(
    'lib/admin/ui/pages/membership/association_membership_detail_page/'
        'association_membership_member_editable_card.dart',
    'MemberEditableCard',
    MemberEditableCard,
    (c, _) => MemberEditableCard(
      associationMembership: UserMembershipComplete.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(
          firstname: longName,
          nickname: 'Durand',
        ),
      ),
    ),
  ),
  SweepCard(
    'lib/advert/ui/components/association_item.dart',
    'AssociationItem',
    AssociationItem,
    (c, _) => AssociationItem(
      name: longName,
      onTap: () {},
      selected: true,
      avatarName: 'AB',
      associationId: 'assoc-1',
    ),
  ),
  SweepCard(
    'lib/advert/ui/pages/admin_page/admin_advert_card.dart',
    'AdminAdvertCard',
    AdminAdvertCard,
    (c, _) => AdminAdvertCard(
      advert: AdvertComplete.empty().copyWith(title: longTitle),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/advert/ui/pages/main_page/advert_card.dart',
    'AdvertCard',
    AdvertCard,
    (c, _) =>
        AdvertCard(advert: AdvertComplete.empty().copyWith(title: longTitle)),
  ),
  SweepCard(
    'lib/amap/ui/components/product_ui.dart',
    'ProductCard',
    ProductCard,
    (c, _) => ProductCard(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: longName,
      ),
      quantity: 12500,
      showButton: true,
    ),
  ),
  SweepCard(
    'lib/amap/ui/pages/admin_page/adding_user_card.dart',
    'AddingUserCard',
    amap_add.AddingUserCard,
    (c, _) => amap_add.AddingUserCard(
      user: CoreUserSimple.empty().copyWith(firstname: longName),
      onAdd: () {},
    ),
  ),
  SweepCard(
    'lib/amap/ui/pages/admin_page/delivery_ui.dart',
    'DeliveryUi',
    amap_admin_delivery.DeliveryUi,
    (c, _) => amap_admin_delivery.DeliveryUi(delivery: DeliveryReturn.empty()),
  ),
  SweepCard(
    'lib/amap/ui/pages/admin_page/user_cash_ui.dart',
    'UserCashUi',
    amap_cash.UserCashUi,
    (c, _) => amap_cash.UserCashUi(
      cash: AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
        balance: 1250000,
        user: CoreUserSimple.empty().copyWith(nickname: longName),
      ),
    ),
  ),
  SweepCard(
    'lib/amap/ui/pages/delivery_pages/product_ui_check.dart',
    'ProductUi',
    ProductUi,
    (c, _) => ProductUi(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: longName,
      ),
      onclick: () {},
      isModification: true,
    ),
  ),
  SweepCard(
    'lib/amap/ui/pages/detail_delivery_page/product_detail_ui.dart',
    'ProductDetailCard',
    ProductDetailCard,
    (c, _) => ProductDetailCard(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: longName,
      ),
      quantity: 12500,
    ),
  ),
  SweepCard(
    'lib/amap/ui/pages/main_page/delivery_ui.dart',
    'DeliveryUi',
    amap_main_delivery.DeliveryUi,
    (c, _) => amap_main_delivery.DeliveryUi(
      delivery: DeliveryReturn.empty(),
      onTap: () {},
    ),
  ),
  SweepCard(
    'lib/booking/ui/components/booking_card.dart',
    'BookingCard',
    BookingCard,
    (c, _) => BookingCard(
      booking: BookingReturn.empty().copyWith(note: longTitle),
      isAdmin: true,
    ),
  ),
  SweepCard(
    'lib/centralassociation/ui/pages/link_card.dart',
    'LinkCard',
    LinkCard,
    (c, _) => LinkCard(
      link: Link(name: longName, url: 'https://example.test', icon: 'home'),
    ),
  ),
  SweepCard(
    'lib/centralisation/ui/pages/liked_card.dart',
    'LikedCard',
    LikedCard,
    (c, _) => LikedCard(
      module: Module(
        name: longName,
        description: longTitle,
        icon: 'home',
        url: '/feed',
        liked: true,
      ),
    ),
  ),
  SweepCard(
    'lib/centralisation/ui/pages/module_card.dart',
    'ModuleCard',
    ModuleCard,
    (c, _) => ModuleCard(
      module: Module(
        name: longName,
        description: longTitle,
        icon: 'home',
        url: '/feed',
      ),
    ),
    // `section_list.dart` builds this card in a grid of
    // `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 130,
    // childAspectRatio: 1)`, so the cell is square and at most 130px. The
    // card's `Column` holds an `Expanded`, which asserts outright under the
    // sweep's unbounded scroll view, so the parent is reproduced here rather
    // than loosened - a bounded parent is the only shape this card has.
    wrap: (child) => SizedBox(width: 130, height: 130, child: child),
  ),
  SweepCard(
    'lib/cinema/ui/pages/admin_page/admin_session_card.dart',
    'AdminSessionCard',
    AdminSessionCard,
    (c, _) => AdminSessionCard(
      session: CineSessionComplete.empty().copyWith(name: longTitle),
      onTap: () {},
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/cinema/ui/pages/main_page/session_card.dart',
    'SessionCard',
    cinema_session.SessionCard,
    (c, _) => cinema_session.SessionCard(
      session: CineSessionComplete.empty().copyWith(name: longTitle),
      index: 0,
    ),
  ),
  SweepCard(
    'lib/event/ui/components/event_ui.dart',
    'EventUi',
    EventUi,
    (c, _) => EventUi(
      event: EventCompleteTicketUrl.empty().copyWith(name: longTitle),
      isDetailPage: true,
    ),
  ),
  SweepCard(
    'lib/feed/ui/pages/event_handling_page/admin_event_card.dart',
    'AdminEventCard',
    AdminEventCard,
    (c, _) => AdminEventCard(news: News.empty().copyWith(title: longTitle)),
  ),
  SweepCard(
    'lib/feed/ui/pages/main_page/time_line_item.dart',
    'TimelineItem',
    TimelineItem,
    (c, _) => TimelineItem(item: News.empty().copyWith(title: longTitle)),
  ),
  SweepCard(
    'lib/home/ui/day_card.dart',
    'DayCard',
    DayCard,
    (c, _) => DayCard(
      day: DateTime(2026, 10, 2),
      isToday: true,
      numberOfEvent: 12500,
      index: 0,
      onTap: () {},
    ),
  ),
  SweepCard(
    'lib/home/ui/month_bar.dart',
    'MonthBar',
    MonthBar,
    (c, anim) => MonthBar(scrollController: ScrollController(), width: 360),
  ),
  SweepCard(
    'lib/loan/ui/pages/admin_page/item_card.dart',
    'ItemCard',
    ItemCard,
    (c, _) => ItemCard(
      item: Item.empty().copyWith(name: longName),
      showButtons: true,
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/loan/ui/pages/admin_page/loan_card.dart',
    'LoanCard',
    LoanCard,
    (c, _) => LoanCard(loan: Loan.empty().copyWith(notes: longTitle)),
  ),
  SweepCard(
    'lib/loan/ui/pages/loan_group_page/check_item_card.dart',
    'CheckItemCard',
    CheckItemCard,
    (c, _) => CheckItemCard(
      item: Item.empty().copyWith(name: longName),
      isSelected: true,
    ),
  ),
  SweepCard(
    'lib/loan/ui/pages/loan_group_page/item_bar.dart',
    'ItemBar',
    ItemBar,
    (c, _) => const ItemBar(isEdit: true),
  ),
  SweepCard(
    'lib/mypayment/ui/components/request_card.dart',
    'RequestCard',
    RequestCard,
    (c, _) => RequestCard(request: proposedRequest),
  ),
  SweepCard(
    'lib/mypayment/ui/components/transaction_card.dart',
    'TransactionCard',
    TransactionCard,
    (c, _) =>
        TransactionCard(transaction: History.empty().copyWith(total: 1250000)),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/devices_page/device_item.dart',
    'DeviceItem',
    DeviceItem,
    (c, _) => DeviceItem(
      device: WalletDevice.empty().copyWith(name: longName),
      isActual: true,
      onRevoke: () async {},
    ),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/main_page/seller_card/admin_invoice_card.dart',
    'InvoiceAdminCard',
    InvoiceAdminCard,
    (c, _) => const InvoiceAdminCard(),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/main_page/seller_card/store_seller_card.dart',
    'StoreSellerCard',
    StoreSellerCard,
    (c, _) => StoreSellerCard(store: myPaymentStore),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/main_page/seller_card/structure_admin_card.dart',
    'StructureAdminCard',
    StructureAdminCard,
    (c, _) => const StructureAdminCard(),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/stats_page/sum_up_card.dart',
    'SumUpCard',
    SumUpCard,
    (c, _) => SumUpCard(
      title: longTitle,
      amount: '1250000.00',
      color: Colors.teal,
      darkColor: Colors.black,
      shadowColor: Colors.grey,
    ),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/store_admin_page/seller_right_card.dart',
    'SellerRightCard',
    SellerRightCard,
    (c, _) => SellerRightCard(
      me: Seller.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(nickname: longName),
      ),
      storeSeller: Seller.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(nickname: 'Boutique'),
      ),
    ),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/store_stats_page/summary_card.dart',
    'SummaryCard',
    SummaryCard,
    (c, _) => SummaryCard(
      history: [
        History.empty().copyWith(total: 1250000),
        History.empty().copyWith(total: 1250000),
      ],
    ),
  ),
  SweepCard(
    'lib/mypayment/ui/pages/structure_admin_page/admin_store_card.dart',
    'AdminStoreCard',
    AdminStoreCard,
    (c, _) => AdminStoreCard(store: myPaymentStore),
  ),
  SweepCard(
    'lib/ph/ui/pages/admin_page/admin_ph_card.dart',
    'AdminPhCard',
    AdminPhCard,
    (c, _) => AdminPhCard(
      ph: PaperComplete.empty().copyWith(name: longTitle),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/purchases/ui/pages/history_page/purchase_card.dart',
    'PurchaseCard',
    PurchaseCard,
    (c, _) => PurchaseCard(
      purchase: PurchaseReturn.empty().copyWith(
        product: AppModulesCdrSchemasCdrProductComplete.empty(),
      ),
      onClicked: () {},
    ),
  ),
  SweepCard(
    'lib/raffle/ui/pages/admin_module_page/adding_user_card.dart',
    'AddingUserCard',
    raffle_add.AddingUserCard,
    (c, _) => raffle_add.AddingUserCard(
      user: CoreUserSimple.empty().copyWith(firstname: longName),
      onAdd: () {},
    ),
  ),
  SweepCard(
    'lib/raffle/ui/pages/admin_module_page/tombola_card.dart',
    'TombolaCard',
    TombolaCard,
    (c, _) =>
        TombolaCard(raffle: RaffleComplete.empty().copyWith(name: longTitle)),
  ),
  SweepCard(
    'lib/raffle/ui/pages/creation_edit_page/prize_card.dart',
    'PrizeCard',
    raffle_edit_prize.PrizeCard,
    (c, _) => raffle_edit_prize.PrizeCard(
      lot: PrizeSimple.empty().copyWith(name: longTitle),
      onEdit: () {},
      onDelete: () async {},
      status: enums.RaffleStatusType.open,
      onDraw: () async {},
    ),
  ),
  SweepCard(
    'lib/raffle/ui/pages/creation_edit_page/user_cash_ui.dart',
    'UserCashUi',
    raffle_cash.UserCashUi,
    (c, _) => raffle_cash.UserCashUi(
      cash: AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
        balance: 1250000,
        user: CoreUserSimple.empty().copyWith(nickname: longName),
      ),
    ),
  ),
  SweepCard(
    'lib/raffle/ui/pages/raffle_page/prize_card.dart',
    'PrizeCard',
    raffle_page_prize.PrizeCard,
    (c, _) => raffle_page_prize.PrizeCard(
      prize: PrizeSimple.empty().copyWith(name: longTitle),
    ),
  ),
  SweepCard(
    'lib/recommendation/ui/components/recommendation_card.dart',
    'RecommendationCard',
    RecommendationCard,
    (c, _) => RecommendationCard(
      recommendation: Recommendation.empty().copyWith(title: longTitle),
      isMainPage: true,
    ),
  ),
  SweepCard(
    'lib/seed-library/ui/components/filters_bar.dart',
    'FiltersBar',
    FiltersBar,
    (c, _) {
      // FiltersBar reads syncSpeciesListProvider (seeded by seedSharedMaps) AND
      // syncSpeciesTypeListProvider (a List<SpeciesType>, card's own stub).
      // Both must contain the dropdown's current value or Flutter asserts "exactly
      // one item with DropdownButton's value". Seed the species type list so the
      // species type dropdown at least does not assert; the difficulty/season
      // dropdowns still need their own stubs (their value lists are page-level too).
      c.read(speciesTypeListProvider.notifier).state = AsyncValue.data(
        SpeciesTypesReturn(
          speciesType: [
            enums.SpeciesType.plantesAromatiques,
            enums.SpeciesType.plantesFruitiRes,
            // The species-type FILTER defaults to `autre`, so the dropdown's
            // value must be in its item list or Flutter asserts "exactly one
            // item with DropdownButton's value".
            enums.SpeciesType.autre,
          ],
        ),
      );
      // `syncSpeciesTypeListProvider` is a plain `Provider` derived from the
      // notifier above, so writing the source is enough: it recomputes and
      // FiltersBar's species type dropdown reads a non-empty list instead of
      // asserting "exactly one item with DropdownButton's value".
      return const FiltersBar();
    },
  ),
  SweepCard(
    'lib/seed-library/ui/pages/main_page/menu_card_ui.dart',
    'MenuCardUi',
    seed_menu.MenuCardUi,
    (c, _) => const seed_menu.MenuCardUi(text: longTitle, icon: HeroIcons.user),
  ),
  SweepCard(
    'lib/seed-library/ui/pages/plants_page/personal_plant_card.dart',
    'PersonalPlantCard',
    PersonalPlantCard,
    (c, _) => PersonalPlantCard(
      plant: PlantSimple.empty().copyWith(
        nickname: longName,
        speciesId: 'species-1',
      ),
      onClicked: () {},
    ),
  ),
  SweepCard(
    'lib/seed-library/ui/pages/species_page/species_card.dart',
    'SpeciesCard',
    SpeciesCard,
    (c, _) => SpeciesCard(
      species: SpeciesComplete.empty().copyWith(
        name: longName,
        speciesType: enums.SpeciesType.plantesAromatiques,
      ),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/seed-library/ui/pages/stock_page/plant_card.dart',
    'PlantCard',
    PlantCard,
    (c, _) => PlantCard(
      plant: PlantSimple.empty().copyWith(
        nickname: longName,
        speciesId: 'species-1',
      ),
      onClicked: () {},
    ),
  ),
  SweepCard(
    'lib/super_admin/ui/pages/main_page/menu_card_ui.dart',
    'MenuCardUi',
    super_menu.MenuCardUi,
    (c, _) =>
        const super_menu.MenuCardUi(text: longTitle, icon: HeroIcons.user),
  ),
  SweepCard(
    'lib/super_admin/ui/pages/permissions/permission_tile.dart',
    'PermissionTile',
    PermissionTile,
    (c, _) => PermissionTile(
      title: longTitle,
      authorizedAccountTypes: 125000,
      totalAccountTypes: 125000,
      authorizedGroups: 125000,
      totalGroups: 125000,
      onTap: () {},
    ),
  ),
  SweepCard(
    'lib/super_admin/ui/pages/schools/school_page/school_ui.dart',
    'SchoolUi',
    SchoolUi,
    (c, _) => SchoolUi(
      school: CoreSchool.empty().copyWith(name: longName),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  SweepCard(
    'lib/tickets/ui/components/session_card.dart',
    'SessionCard',
    tickets_session.SessionCard,
    (c, _) => tickets_session.SessionCard(onChanged: (_) {}),
  ),
  SweepCard(
    'lib/tickets/ui/components/stats_card.dart',
    'StatsCard',
    StatsCard,
    (c, _) => const StatsCard(
      ticketsSold: 1250000,
      ticketsInCheckout: 1250000,
      quota: 1250000,
    ),
  ),
  SweepCard(
    'lib/tickets/ui/components/tarif_card.dart',
    'TarifCard',
    TarifCard,
    (c, _) => TarifCard(onChanged: (_) {}),
  ),
  SweepCard(
    'lib/tickets/ui/components/user_ticket_card.dart',
    'UserTicketCard',
    UserTicketCard,
    (c, _) => UserTicketCard(
      ticket: AppCoreTicketsSchemasTicketsTicketComplete.empty(),
    ),
  ),
  SweepCard(
    'lib/tools/ui/styleguide/bottom_modal_template.dart',
    'BottomModalTemplate',
    BottomModalTemplate,
    (c, _) => BottomModalTemplate(
      title: longTitle,
      description: longName,
      child: const SizedBox.shrink(),
    ),
  ),
  SweepCard(
    'lib/tools/ui/styleguide/list_item_template.dart',
    'ListItemTemplate',
    ListItemTemplate,
    (c, _) => ListItemTemplate(title: longTitle, subtitle: longName),
  ),
  SweepCard(
    'lib/tools/ui/styleguide/searchbar.dart',
    'CustomSearchBar',
    CustomSearchBar,
    (c, _) => CustomSearchBar(hintText: longName, onSearch: (_) {}),
  ),
  SweepCard(
    'lib/tools/ui/widgets/custom_dialog_box.dart',
    'CustomDialogBox',
    CustomDialogBox,
    (c, _) =>
        CustomDialogBox(title: longTitle, descriptions: longName, onYes: () {}),
  ),
  SweepCard(
    'lib/tools/ui/widgets/top_bar.dart',
    'TopBar',
    TopBar,
    (c, _) => TopBar(root: longTitle),
  ),
  SweepCard(
    'lib/vote/ui/pages/main_page/list_card.dart',
    'ListCard',
    ListCard,
    (c, anim) => ListCard(
      list: ListReturn.empty().copyWith(name: longTitle),
      animation: anim,
      index: 0,
      enableVote: true,
      votesPercent: 99.9,
    ),
  ),
  SweepCard(
    'lib/vote/ui/pages/main_page/list_list_card.dart',
    'ListListCard',
    ListListCard,
    (c, anim) {
      // ListListCard indexes sectionListProvider by section then reads
      // sectionsStatsProvider. seedSharedMaps seeds the section map; stub the
      // status provider so the card's `s` is not the default closed status.
      c.read(statusProvider.notifier).state = AsyncValue.data(
        const VoteStatus(status: enums.StatusType.open),
      );
      // sectionsStatsProvider is the second provider the card reads after the
      // section map; stub it with counts keyed by the same sections the section
      // map points at so the card's `h` computation does not throw on the list
      // inside sectionsList[section]!.whenData.
      c.read(sectionsStatsProvider.notifier).state = {
        SectionComplete.empty().copyWith(id: 'section-1', name: 'Section 1'):
            AsyncValue.data([10, 5]),
      };
      return ListListCard(animation: anim);
    },
  ),
  SweepCard(
    'lib/vote/ui/pages/main_page/side_item.dart',
    'SideItem',
    SideItem,
    (c, _) => SideItem(
      section: SectionComplete.empty().copyWith(name: longTitle),
      isSelected: true,
      alreadyVoted: true,
      onTap: () {},
    ),
  ),
];
