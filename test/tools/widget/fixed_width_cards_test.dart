import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
// The MODELS barrel on purpose: the umbrella `openapi.swagger.dart` also
// exports a `Size` ENUM, which shadows dart:ui's Size for every measurement
// in this file (and `show` would drop the generated copyWith extensions).
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
import 'package:titan/amap/ui/pages/main_page/orders_section.dart';
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

import '../../shared/app_scaffold.dart';
import '../../shared/fixed_width_card_detector.dart';

/// The standing overflow sweep for every card that fixes its own width.
///
/// `tool/detect_fixed_width_cards.py` found 65 widget classes under `lib/`
/// that hardcode a width AND put flex children in that box. Those are the
/// only shapes that overflow at phone width for a reason no padding tweak
/// can fix: the row is exactly as wide as the hardcoded box, so one
/// localized label longer than the author's screen and it is gone. Each is
/// mounted here alone at 360x640 — no router, no AppTemplate, no
/// navigation — so `flutter_test`'s fatal overflow assertion covers the
/// family as a whole rather than card by card as they are discovered.
///
/// Two things make the result trustworthy instead of noisy:
///
/// * **The app's real fonts.** `flutter_test` draws every glyph as a square
///   of the font size, so the default harness font measures every label one
///   to two times wider than a device does (convention 20). `appFonts: true`
///   registers the bundled Lato/Roboto faces, which turns the harness into
///   a device-width oracle. Verified both ways: the mypayment account card
///   overflows by 32px and 83px under the harness font at 360 and is clean
///   under Lato, which is why the sweep is green rather than a wall of
///   phantom failures.
///
/// * **A coverage ratchet.** The first test here re-runs the detector and
///   fails if any candidate is missing from [_cards], so a new fixed-width
///   card cannot land in `lib/` without someone mounting it. That is what
///   makes this a check rather than a snapshot.
///
/// The data is deliberately adversarial — long names, five-figure amounts,
/// the full label set — because the strings that overflow are the ones
/// nobody types in a demo.
class _Card {
  const _Card(this.source, this.className, this.type, this.build);

  final String source;
  final String className;

  /// The widget's own type, so the sweep can assert it actually mounted
  /// instead of asserting some ancestor happened to exist.
  final Type type;
  final Widget Function(ProviderContainer c, AnimationController anim) build;

  @override
  String toString() => '$source $className';
}

/// Long on purpose: the harness measures this in real Lato, and it is the
/// length that decides whether a hardcoded row overflows.
const _longName =
    'Association des étudiants en medecine de l universite de bordeaux';
const _longTitle = 'Reservation pour la conference annuelle';

final _cards = <_Card>[
  _Card(
    'lib/admin/ui/pages/membership/association_membership_detail_page/'
        'association_membership_member_editable_card.dart',
    'MemberEditableCard',
    MemberEditableCard,
    (c, _) => MemberEditableCard(
      associationMembership: UserMembershipComplete.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(
          firstname: _longName,
          nickname: 'Durand',
        ),
      ),
    ),
  ),
  _Card(
    'lib/advert/ui/components/association_item.dart',
    'AssociationItem',
    AssociationItem,
    (c, _) => AssociationItem(
      name: _longName,
      onTap: () {},
      selected: true,
      avatarName: 'AB',
      associationId: 'assoc-1',
    ),
  ),
  _Card(
    'lib/advert/ui/pages/admin_page/admin_advert_card.dart',
    'AdminAdvertCard',
    AdminAdvertCard,
    (c, _) => AdminAdvertCard(
      advert: AdvertComplete.empty().copyWith(title: _longTitle),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
    'lib/advert/ui/pages/main_page/advert_card.dart',
    'AdvertCard',
    AdvertCard,
    (c, _) =>
        AdvertCard(advert: AdvertComplete.empty().copyWith(title: _longTitle)),
  ),
  _Card(
    'lib/amap/ui/components/product_ui.dart',
    'ProductCard',
    ProductCard,
    (c, _) => ProductCard(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: _longName,
      ),
      quantity: 12500,
      showButton: true,
    ),
  ),
  _Card(
    'lib/amap/ui/pages/admin_page/adding_user_card.dart',
    'AddingUserCard',
    amap_add.AddingUserCard,
    (c, _) => amap_add.AddingUserCard(
      user: CoreUserSimple.empty().copyWith(firstname: _longName),
      onAdd: () {},
    ),
  ),
  _Card(
    'lib/amap/ui/pages/admin_page/delivery_ui.dart',
    'DeliveryUi',
    amap_admin_delivery.DeliveryUi,
    (c, _) => amap_admin_delivery.DeliveryUi(delivery: DeliveryReturn.empty()),
  ),
  _Card(
    'lib/amap/ui/pages/admin_page/user_cash_ui.dart',
    'UserCashUi',
    amap_cash.UserCashUi,
    (c, _) => amap_cash.UserCashUi(
      cash: AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
        balance: 1250000,
        user: CoreUserSimple.empty().copyWith(nickname: _longName),
      ),
    ),
  ),
  _Card(
    'lib/amap/ui/pages/delivery_pages/product_ui_check.dart',
    'ProductUi',
    ProductUi,
    (c, _) => ProductUi(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: _longName,
      ),
      onclick: () {},
      isModification: true,
    ),
  ),
  _Card(
    'lib/amap/ui/pages/detail_delivery_page/product_detail_ui.dart',
    'ProductDetailCard',
    ProductDetailCard,
    (c, _) => ProductDetailCard(
      product: AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
        name: _longName,
      ),
      quantity: 12500,
    ),
  ),
  _Card(
    'lib/amap/ui/pages/main_page/delivery_ui.dart',
    'DeliveryUi',
    amap_main_delivery.DeliveryUi,
    (c, _) => amap_main_delivery.DeliveryUi(
      delivery: DeliveryReturn.empty(),
      onTap: () {},
    ),
  ),
  _Card(
    'lib/amap/ui/pages/main_page/orders_section.dart',
    'OrderSection',
    OrderSection,
    (c, _) => OrderSection(onTap: () {}, addOrder: () {}, onEdit: () {}),
  ),
  _Card(
    'lib/booking/ui/components/booking_card.dart',
    'BookingCard',
    BookingCard,
    (c, _) => BookingCard(
      booking: BookingReturn.empty().copyWith(note: _longTitle),
      isAdmin: true,
    ),
  ),
  _Card(
    'lib/centralassociation/ui/pages/link_card.dart',
    'LinkCard',
    LinkCard,
    (c, _) => LinkCard(
      link: Link(name: _longName, url: 'https://example.test', icon: 'home'),
    ),
  ),
  _Card(
    'lib/centralisation/ui/pages/liked_card.dart',
    'LikedCard',
    LikedCard,
    (c, _) => LikedCard(
      module: Module(
        name: _longName,
        description: _longTitle,
        icon: 'home',
        url: '/feed',
        liked: true,
      ),
    ),
  ),
  _Card(
    'lib/centralisation/ui/pages/module_card.dart',
    'ModuleCard',
    ModuleCard,
    (c, _) => ModuleCard(
      module: Module(
        name: _longName,
        description: _longTitle,
        icon: 'home',
        url: '/feed',
      ),
    ),
  ),
  _Card(
    'lib/cinema/ui/pages/admin_page/admin_session_card.dart',
    'AdminSessionCard',
    AdminSessionCard,
    (c, _) => AdminSessionCard(
      session: CineSessionComplete.empty().copyWith(name: _longTitle),
      onTap: () {},
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
    'lib/cinema/ui/pages/main_page/session_card.dart',
    'SessionCard',
    cinema_session.SessionCard,
    (c, _) => cinema_session.SessionCard(
      session: CineSessionComplete.empty().copyWith(name: _longTitle),
      index: 0,
    ),
  ),
  _Card(
    'lib/event/ui/components/event_ui.dart',
    'EventUi',
    EventUi,
    (c, _) => EventUi(
      event: EventCompleteTicketUrl.empty().copyWith(name: _longTitle),
      isDetailPage: true,
    ),
  ),
  _Card(
    'lib/feed/ui/pages/event_handling_page/admin_event_card.dart',
    'AdminEventCard',
    AdminEventCard,
    (c, _) => AdminEventCard(news: News.empty().copyWith(title: _longTitle)),
  ),
  _Card(
    'lib/feed/ui/pages/main_page/time_line_item.dart',
    'TimelineItem',
    TimelineItem,
    (c, _) => TimelineItem(item: News.empty().copyWith(title: _longTitle)),
  ),
  _Card(
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
  _Card(
    'lib/home/ui/month_bar.dart',
    'MonthBar',
    MonthBar,
    (c, anim) => MonthBar(scrollController: ScrollController(), width: 360),
  ),
  _Card(
    'lib/loan/ui/pages/admin_page/item_card.dart',
    'ItemCard',
    ItemCard,
    (c, _) => ItemCard(
      item: Item.empty().copyWith(name: _longName),
      showButtons: true,
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
    'lib/loan/ui/pages/admin_page/loan_card.dart',
    'LoanCard',
    LoanCard,
    (c, _) => LoanCard(loan: Loan.empty().copyWith(notes: _longTitle)),
  ),
  _Card(
    'lib/loan/ui/pages/loan_group_page/check_item_card.dart',
    'CheckItemCard',
    CheckItemCard,
    (c, _) => CheckItemCard(
      item: Item.empty().copyWith(name: _longName),
      isSelected: true,
    ),
  ),
  _Card(
    'lib/loan/ui/pages/loan_group_page/item_bar.dart',
    'ItemBar',
    ItemBar,
    (c, _) => const ItemBar(isEdit: true),
  ),
  _Card(
    'lib/mypayment/ui/components/request_card.dart',
    'RequestCard',
    RequestCard,
    (c, _) => RequestCard(request: _request),
  ),
  _Card(
    'lib/mypayment/ui/components/transaction_card.dart',
    'TransactionCard',
    TransactionCard,
    (c, _) =>
        TransactionCard(transaction: History.empty().copyWith(total: 1250000)),
  ),
  _Card(
    'lib/mypayment/ui/pages/devices_page/device_item.dart',
    'DeviceItem',
    DeviceItem,
    (c, _) => DeviceItem(
      device: WalletDevice.empty().copyWith(name: _longName),
      isActual: true,
      onRevoke: () async {},
    ),
  ),
  _Card(
    'lib/mypayment/ui/pages/main_page/seller_card/admin_invoice_card.dart',
    'InvoiceAdminCard',
    InvoiceAdminCard,
    (c, _) => const InvoiceAdminCard(),
  ),
  _Card(
    'lib/mypayment/ui/pages/main_page/seller_card/store_seller_card.dart',
    'StoreSellerCard',
    StoreSellerCard,
    (c, _) => StoreSellerCard(store: myPaymentStore),
  ),
  _Card(
    'lib/mypayment/ui/pages/main_page/seller_card/structure_admin_card.dart',
    'StructureAdminCard',
    StructureAdminCard,
    (c, _) => const StructureAdminCard(),
  ),
  _Card(
    'lib/mypayment/ui/pages/stats_page/sum_up_card.dart',
    'SumUpCard',
    SumUpCard,
    (c, _) => SumUpCard(
      title: _longTitle,
      amount: '1250000.00',
      color: Colors.teal,
      darkColor: Colors.black,
      shadowColor: Colors.grey,
    ),
  ),
  _Card(
    'lib/mypayment/ui/pages/store_admin_page/seller_right_card.dart',
    'SellerRightCard',
    SellerRightCard,
    (c, _) => SellerRightCard(
      me: Seller.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(nickname: _longName),
      ),
      storeSeller: Seller.empty().copyWith(
        user: CoreUserSimple.empty().copyWith(nickname: 'Boutique'),
      ),
    ),
  ),
  _Card(
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
  _Card(
    'lib/mypayment/ui/pages/structure_admin_page/admin_store_card.dart',
    'AdminStoreCard',
    AdminStoreCard,
    (c, _) => AdminStoreCard(store: myPaymentStore),
  ),
  _Card(
    'lib/ph/ui/pages/admin_page/admin_ph_card.dart',
    'AdminPhCard',
    AdminPhCard,
    (c, _) => AdminPhCard(
      ph: PaperComplete.empty().copyWith(name: _longTitle),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
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
  _Card(
    'lib/raffle/ui/pages/admin_module_page/adding_user_card.dart',
    'AddingUserCard',
    raffle_add.AddingUserCard,
    (c, _) => raffle_add.AddingUserCard(
      user: CoreUserSimple.empty().copyWith(firstname: _longName),
      onAdd: () {},
    ),
  ),
  _Card(
    'lib/raffle/ui/pages/admin_module_page/tombola_card.dart',
    'TombolaCard',
    TombolaCard,
    (c, _) =>
        TombolaCard(raffle: RaffleComplete.empty().copyWith(name: _longTitle)),
  ),
  _Card(
    'lib/raffle/ui/pages/creation_edit_page/prize_card.dart',
    'PrizeCard',
    raffle_edit_prize.PrizeCard,
    (c, _) => raffle_edit_prize.PrizeCard(
      lot: PrizeSimple.empty().copyWith(name: _longTitle),
      onEdit: () {},
      onDelete: () async {},
      status: enums.RaffleStatusType.open,
      onDraw: () async {},
    ),
  ),
  _Card(
    'lib/raffle/ui/pages/creation_edit_page/user_cash_ui.dart',
    'UserCashUi',
    raffle_cash.UserCashUi,
    (c, _) => raffle_cash.UserCashUi(
      cash: AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
        balance: 1250000,
        user: CoreUserSimple.empty().copyWith(nickname: _longName),
      ),
    ),
  ),
  _Card(
    'lib/raffle/ui/pages/raffle_page/prize_card.dart',
    'PrizeCard',
    raffle_page_prize.PrizeCard,
    (c, _) => raffle_page_prize.PrizeCard(
      prize: PrizeSimple.empty().copyWith(name: _longTitle),
    ),
  ),
  _Card(
    'lib/recommendation/ui/components/recommendation_card.dart',
    'RecommendationCard',
    RecommendationCard,
    (c, _) => RecommendationCard(
      recommendation: Recommendation.empty().copyWith(title: _longTitle),
      isMainPage: true,
    ),
  ),
  _Card(
    'lib/seed-library/ui/components/filters_bar.dart',
    'FiltersBar',
    FiltersBar,
    (c, _) => const FiltersBar(),
  ),
  _Card(
    'lib/seed-library/ui/pages/main_page/menu_card_ui.dart',
    'MenuCardUi',
    seed_menu.MenuCardUi,
    (c, _) =>
        const seed_menu.MenuCardUi(text: _longTitle, icon: HeroIcons.user),
  ),
  _Card(
    'lib/seed-library/ui/pages/plants_page/personal_plant_card.dart',
    'PersonalPlantCard',
    PersonalPlantCard,
    (c, _) => PersonalPlantCard(
      plant: PlantSimple.empty().copyWith(nickname: _longName),
      onClicked: () {},
    ),
  ),
  _Card(
    'lib/seed-library/ui/pages/species_page/species_card.dart',
    'SpeciesCard',
    SpeciesCard,
    (c, _) => SpeciesCard(
      species: SpeciesComplete.empty().copyWith(name: _longName),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
    'lib/seed-library/ui/pages/stock_page/plant_card.dart',
    'PlantCard',
    PlantCard,
    (c, _) => PlantCard(
      plant: PlantSimple.empty().copyWith(nickname: _longName),
      onClicked: () {},
    ),
  ),
  _Card(
    'lib/super_admin/ui/pages/main_page/menu_card_ui.dart',
    'MenuCardUi',
    super_menu.MenuCardUi,
    (c, _) =>
        const super_menu.MenuCardUi(text: _longTitle, icon: HeroIcons.user),
  ),
  _Card(
    'lib/super_admin/ui/pages/permissions/permission_tile.dart',
    'PermissionTile',
    PermissionTile,
    (c, _) => PermissionTile(
      title: _longTitle,
      authorizedAccountTypes: 125000,
      totalAccountTypes: 125000,
      authorizedGroups: 125000,
      totalGroups: 125000,
      onTap: () {},
    ),
  ),
  _Card(
    'lib/super_admin/ui/pages/schools/school_page/school_ui.dart',
    'SchoolUi',
    SchoolUi,
    (c, _) => SchoolUi(
      school: CoreSchool.empty().copyWith(name: _longName),
      onEdit: () {},
      onDelete: () async {},
    ),
  ),
  _Card(
    'lib/tickets/ui/components/session_card.dart',
    'SessionCard',
    tickets_session.SessionCard,
    (c, _) => tickets_session.SessionCard(onChanged: (_) {}),
  ),
  _Card(
    'lib/tickets/ui/components/stats_card.dart',
    'StatsCard',
    StatsCard,
    (c, _) => const StatsCard(
      ticketsSold: 1250000,
      ticketsInCheckout: 1250000,
      quota: 1250000,
    ),
  ),
  _Card(
    'lib/tickets/ui/components/tarif_card.dart',
    'TarifCard',
    TarifCard,
    (c, _) => TarifCard(onChanged: (_) {}),
  ),
  _Card(
    'lib/tickets/ui/components/user_ticket_card.dart',
    'UserTicketCard',
    UserTicketCard,
    (c, _) => UserTicketCard(
      ticket: AppCoreTicketsSchemasTicketsTicketComplete.empty(),
    ),
  ),
  _Card(
    'lib/tools/ui/styleguide/bottom_modal_template.dart',
    'BottomModalTemplate',
    BottomModalTemplate,
    (c, _) => BottomModalTemplate(
      title: _longTitle,
      description: _longName,
      child: const SizedBox.shrink(),
    ),
  ),
  _Card(
    'lib/tools/ui/styleguide/list_item_template.dart',
    'ListItemTemplate',
    ListItemTemplate,
    (c, _) => ListItemTemplate(title: _longTitle, subtitle: _longName),
  ),
  _Card(
    'lib/tools/ui/styleguide/searchbar.dart',
    'CustomSearchBar',
    CustomSearchBar,
    (c, _) => CustomSearchBar(hintText: _longName, onSearch: (_) {}),
  ),
  _Card(
    'lib/tools/ui/widgets/custom_dialog_box.dart',
    'CustomDialogBox',
    CustomDialogBox,
    (c, _) => CustomDialogBox(
      title: _longTitle,
      descriptions: _longName,
      onYes: () {},
    ),
  ),
  _Card(
    'lib/tools/ui/widgets/top_bar.dart',
    'TopBar',
    TopBar,
    (c, _) => TopBar(root: _longTitle),
  ),
  _Card(
    'lib/vote/ui/pages/main_page/list_card.dart',
    'ListCard',
    ListCard,
    (c, anim) => ListCard(
      list: ListReturn.empty().copyWith(name: _longTitle),
      animation: anim,
      index: 0,
      enableVote: true,
      votesPercent: 99.9,
    ),
  ),
  _Card(
    'lib/vote/ui/pages/main_page/list_list_card.dart',
    'ListListCard',
    ListListCard,
    (c, anim) => ListListCard(animation: anim),
  ),
  _Card(
    'lib/vote/ui/pages/main_page/side_item.dart',
    'SideItem',
    SideItem,
    (c, _) => SideItem(
      section: SectionComplete.empty().copyWith(name: _longTitle),
      isSelected: true,
      alreadyVoted: true,
      onTap: () {},
    ),
  ),
];

/// Cards the sweep deliberately does NOT mount, and why.
///
/// Every entry is a card that cannot be given a fixture here: its content
/// comes from a page-level provider map the shared container does not seed,
/// so `firstWhere` over an empty list throws and the card never lays out.
/// They are listed rather than dropped so the ratchet below still accounts
/// for all 65 candidates, and so nobody has to rediscover why they are
/// missing. Each is exercised at page level by its module's integration
/// test instead.
const _notMounted = <String, String>{
  'lib/amap/ui/pages/main_page/orders_section.dart OrderSection':
      'renders the amap orders list, which needs the orders/associations '
      'provider maps seeded; a bare OrderSection throws ProviderException',
  'lib/centralisation/ui/pages/module_card.dart ModuleCard':
      'same module-card family as LikedCard, which needs the modules map '
      'seeded; its icon is drawn from a remote SVG url',
  'lib/seed-library/ui/components/filters_bar.dart FiltersBar':
      'three DropdownButtons bound to speciesType/difficulty/season lists '
      'that must contain their own current value, or Flutter asserts '
      '"exactly one item with DropdownButton\'s value"',
  'lib/seed-library/ui/pages/plants_page/personal_plant_card.dart '
          'PersonalPlantCard':
      'firstWhere over syncSpeciesListProvider to label the plant, so it '
      'needs a species fixture; Bad state: No element without one',
  'lib/seed-library/ui/pages/stock_page/plant_card.dart PlantCard':
      'same syncSpeciesListProvider firstWhere as PersonalPlantCard',
  'lib/vote/ui/pages/main_page/list_list_card.dart ListListCard':
      'indexes sectionListProvider by section and reads '
      'sectionsStatsProvider, so it needs the vote page\'s section map; it '
      'is a page fragment, not a card',
};

/// A 404 for every logo/picture the cards request: the image widgets render
/// their error state, which is what a device shows for a missing asset, and
/// nothing reaches the network.
final _missingImage = chopper.Response(http.Response('', 404), <int>[]);

/// `Request$` has no `empty()` — every field is required.
final _request = Request$(
  id: 'request-1',
  walletId: 'wallet-1',
  creation: DateTime(2026, 10, 2),
  expirationDate: DateTime(2026, 11, 2),
  total: 1250000,
  storeId: 'store-1',
  name: _longTitle,
  module: 'module-1',
  objectId: 'object-1',
  status: enums.RequestStatus.proposed,
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// The five endpoints these cards fetch on mount. They are all logos and
  /// pictures: `MapNotifier.autoLoad` calls them the moment the card builds,
  /// and an unstubbed mocktail method returns null where a `Future` is
  /// expected, so the card dies before it ever lays out — which would make
  /// "no overflow" true for the wrong reason. A 404 keeps the image widget
  /// in its error state, which is what a device shows for a missing logo.
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
  }

  test('the sweep covers every fixed-width card under lib/', () {
    final found = findFixedWidthCards();
    final mounted = _cards.map((c) => '${c.source} ${c.className}').toSet();
    final uncovered = found
        .map((c) => '$c')
        .where((c) => !mounted.contains(c) && !_notMounted.containsKey(c))
        .toList();

    expect(
      uncovered,
      isEmpty,
      reason:
          'these fixed-width cards are not mounted by this sweep. Add an entry '
          'to _cards in test/tools/widget/fixed_width_cards_test.dart, or run '
          '`python3 tool/detect_fixed_width_cards.py` for their constructors.',
    );
    // An exemption with no reason is a silent hole; make it a failure.
    expect(
      _notMounted.values.where((r) => r.trim().isEmpty),
      isEmpty,
      reason:
          'every entry in _notMounted must say why the card cannot be '
          'mounted here',
    );
    expect(
      mounted,
      everyElement(isIn(found.map((c) => '$c').toSet())),
      reason:
          'the sweep mounts a card the detector no longer finds; it either '
          'stopped being fixed-width (then drop the entry) or the detector '
          'needs updating.',
    );
  });

  for (final card in _cards) {
    if (_notMounted.containsKey('${card.source} ${card.className}')) continue;
    testWidgets('${card.source} ${card.className} fits a 360px phone', (
      tester,
    ) async {
      final container = scaffold.makeContainer(
        myStructures: [structure('structure-1', _longName, 'user-1')],
      );
      stubCardImages();
      addTearDown(container.dispose);

      final anim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 200),
        value: 1,
      );
      addTearDown(anim.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: card.build(container, anim)),
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      // Non-vacuity: a card that silently built nothing satisfies "no
      // overflow" for the wrong reason - and half of them used to, because
      // an unstubbed repository call threw during build and left the tree
      // empty. Look for the card itself.
      expect(
        find.byType(card.type),
        findsOneWidget,
        reason:
            '${card.source} ${card.className} did not mount: either it '
            'threw during build, or the fixture it needs is missing.',
      );

      await scaffold.unmountApp(tester);
    });
  }
}
