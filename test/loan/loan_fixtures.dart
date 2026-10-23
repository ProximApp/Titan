import 'package:titan/generated/openapi.models.swagger.dart';

import '../generated/openapi_mock_factories.dart';

/// Build a simple user for gate and borrower fixtures.
CoreUserSimple coreUserSimpleFixture({
  String id = 'user-1',
  String name = 'Doe',
  String firstname = 'Jane',
}) => MockCoreUserSimple.any.copyWith(id: id, name: name, firstname: firstname);

/// Build a loan fixture with predictable defaults.
Loan loanFixture({
  String id = 'l-1',
  String borrowerId = 'borrower-1',
  String loanerId = 'loaner-1',
  DateTime? start,
  DateTime? end,
  String? notes,
  String? caution,
  bool returned = false,
  DateTime? returnedDate,
  List<ItemQuantity> itemsQty = const [],
  CoreUserSimple? borrower,
  Loaner? loaner,
}) => MockLoan.any.copyWith(
  id: id,
  borrowerId: borrowerId,
  loanerId: loanerId,
  start: start ?? DateTime(2026, 1, 1),
  end: end ?? DateTime(2026, 1, 8),
  notes: notes,
  caution: caution,
  returned: returned,
  returnedDate: returnedDate,
  itemsQty: itemsQty,
  borrower: borrower ?? MockCoreUserSimple.any,
  loaner: loaner ?? MockLoaner.any,
);

LoanCreation loanCreationFixture({
  String borrowerId = 'borrower-1',
  String loanerId = 'loaner-1',
  DateTime? start,
  DateTime? end,
  String? notes,
  String? caution,
  List<ItemBorrowed> itemsBorrowed = const [],
}) => MockLoanCreation.any.copyWith(
  borrowerId: borrowerId,
  loanerId: loanerId,
  start: start ?? DateTime(2026, 1, 1),
  end: end ?? DateTime(2026, 1, 8),
  notes: notes,
  caution: caution,
  itemsBorrowed: itemsBorrowed,
);

Item itemFixture({
  String id = 'i-1',
  String name = 'Helmet',
  String loanerId = 'loaner-1',
  int totalQuantity = 1,
  int loanedQuantity = 0,
  int suggestedCaution = 0,
  int suggestedLendingDuration = 1,
}) => MockItem.any.copyWith(
  id: id,
  name: name,
  loanerId: loanerId,
  totalQuantity: totalQuantity,
  loanedQuantity: loanedQuantity,
  suggestedCaution: suggestedCaution,
  suggestedLendingDuration: suggestedLendingDuration,
);

ItemQuantity itemQuantity({
  required String itemId,
  required String itemName,
  required int quantity,
}) => MockItemQuantity.any.copyWith(
  quantity: quantity,
  itemSimple: MockItemSimple.any.copyWith(
    id: itemId,
    name: itemName,
    loanerId: 'loaner-1',
  ),
);

Loaner loanerFixture({
  String id = 'l-1',
  String name = 'Bureau',
  String groupManagerId = 'group-1',
}) =>
    MockLoaner.any.copyWith(id: id, name: name, groupManagerId: groupManagerId);
