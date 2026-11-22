// adapter_scaffold.dart — compile-only harness for adapter smoke tests.
//
// Files that import this file get a shared set of adapter/DTO type aliases and
// a small set of fixtures so that smoke tests can import the real adapter and
// still compile. This file deliberately does NOT run any test logic at runtime:
// every adapter test that uses it must still register its own `test(...)` /
// `group(...)` bodies.
//
// Importing this file is enough to pull in every adapter target the repo cares
// about; tests that need a real constructor call a hand-written harness such as
// `test/shared/fixtures.dart` or `test/shared/app_scaffold.dart`
// instead of reaching for runtime fixtures here.

// Generated model/enum barrels (export, not import: this file is the barrel
// every adapter test pulls from — a plain `import` here would be invisible to
// its importers and flagged unused).
export 'package:titan/generated/openapi.models.swagger.dart';
export 'package:titan/generated/openapi.enums.swagger.dart';
export 'package:titan/generated/openapi.swagger.dart';

// Reachable adapter/DTO types. If one of these is removed from `lib/`, delete
// the matching export here instead of extending the barrel.
export 'package:titan/booking/adapters/manager.dart';
export 'package:titan/booking/adapters/room.dart';
export 'package:titan/booking/adapters/booking_return.dart';
// `hide $BookingReturn`: this file re-declares that extension (pre-existing at
// HEAD), and exporting both copies would be an ambiguous_export here. The
// canonical copy lives in booking_return.dart; direct importers of this file
// still see their own copy as before.
export 'package:titan/booking/adapters/booking_return_applicant.dart'
    hide $BookingReturn;
export 'package:titan/tickets/adapters/session.dart';
export 'package:titan/tickets/adapters/question.dart';
export 'package:titan/tickets/adapters/category.dart';
export 'package:titan/tickets/adapters/checkout.dart';
export 'package:titan/tickets/adapters/user_ticket.dart';
export 'package:titan/raffle/adapters/pack_ticket.dart';
export 'package:titan/raffle/adapters/prize.dart';
export 'package:titan/amap/adapters/delivery_return.dart';
export 'package:titan/amap/adapters/order_return.dart';
export 'package:titan/amap/adapters/product_complete.dart';
export 'package:titan/cinema/adapters/session.dart';
export 'package:titan/user/adapters/core_user.dart';
export 'package:titan/user/adapters/applicants.dart';
export 'package:titan/ph/adapters/ph.dart';
export 'package:titan/advert/adapters/advert_complete.dart';
export 'package:titan/seed-library/adapters/plant_complete.dart';
export 'package:titan/loan/adapters/loan.dart';
export 'package:titan/loan/adapters/item.dart';
export 'package:titan/mypayment/adapters/transaction_adapter.dart';
export 'package:titan/mypayment/adapters/store_adapter.dart';
export 'package:titan/vote/adapters/list_member_complete.dart';
export 'package:titan/vote/adapters/list_return.dart';
export 'package:titan/admin/adapters/core_group.dart';
export 'package:titan/super_admin/adapters/core_group_permission.dart';
export 'package:titan/super_admin/adapters/core_account_type_permission.dart';
export 'package:titan/recommendation/adapters/recommendation.dart';
export 'package:titan/event/adapters/event_complete_ticket_url.dart';

// Re-export generated enums under a short prefix for fixture literals.
export 'package:titan/generated/openapi.enums.swagger.dart' show AccountType;
