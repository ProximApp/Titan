import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/exception.dart';

import '../generated/openapi_mock_factories.dart';
import 'app_scaffold.dart';
import 'repository_stubs.dart' as stubs;

/// Shared generated OpenAPI model builders are available through this single
/// fixture library for every module's tests.
export '../generated/openapi_mock_factories.dart';
export 'provider_overrides.dart'
    show notifierBuildOverride, notifierBuildFactoryOverride;
export 'repository_stubs.dart'
    show
        fileNotFound,
        stubInformation,
        stubFeed,
        stubAdminMainPage,
        stubProfilePictureFor;
export 'repository_test_support.dart'
    show
        MockOpenapi,
        chopperResponse,
        chopperListResponse,
        chopperResponseVoid,
        chopperError,
        makeRepositoryContainer;

/// Registers generated OpenAPI model values as mocktail fallbacks.
void registerTestFallbackValues() {
  registerFallbackValue(MockAssociationGroupementBase.any);
  registerFallbackValue(MockLoaner.any);
  registerFallbackValue(MockLoanerBase.any);
  registerFallbackValue(MockLoanerUpdate.any);
}

/// Authorization group IDs shared across the module-gate tests.
const phonebookAdminGroupId = 'd3f91313-d7e5-49c6-b01f-c19932a7e09b';
const voteAdminGroupId = '2ca57402-605b-4389-a471-f2fea7b27db5';
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';
const adminPhGroupId = '4ec5ae77-f955-4309-96a5-19cc3c8be71c';
const bookingAdminGroupId = adminGroupId;
const seedLibraryAdminGroupId = '09153d2a-14f4-49a4-be57-5d0f265261b9';
const cinemaAdminGroupId = 'ce5f36e6-5377-489f-9696-de70e2477300';
const recommendationAdminGroupId = '389215b2-ea45-4991-adc1-4d3e471541cf';
const raffleAdminGroupId = adminGroupId;

/// Shared token-expiry error for notifier tests.
AppException tokenExpire() =>
    AppException(ErrorType.tokenExpire, 'token expired');

/// Standard initialization for an app-shell integration test.
void shellTestSetUp(IntegrationScaffold scaffold) => scaffold.shellSetUp();

/// Create a structure managed by the supplied user.
Structure structureFixture(String id, String name, String userId) =>
    Structure.empty().copyWith(
      id: id,
      name: name,
      managerUserId: userId,
      managerUser: CoreUserSimple.empty().copyWith(id: userId),
    );

/// Create a confirmed direct transaction with predictable common fields.
History historyFixture(String id, HistoryDirection direction, int total) =>
    History.empty().copyWith(
      id: id,
      type: HistoryType.directTransaction,
      direction: direction,
      otherWalletName: 'BDE',
      total: total,
      creation: DateTime(2026, 1, 5, 12, 30),
      status: TransactionStatus.confirmed,
    );

/// A store fixture used by mypayment pages and shared card layout tests.
final userStoreFixture = UserStore.empty().copyWith(
  id: 'store-1',
  name: 'Fridge',
  structureId: 'structure-1',
  structure: Structure.empty().copyWith(id: 'structure-1', name: 'BDE'),
);

/// Compatibility fixture for tests written before the shared naming cleanup.
History history(String id, HistoryDirection direction, int total) =>
    historyFixture(id, direction, total);

/// Compatibility fixture for tests written before the shared naming cleanup.
Structure structure(String id, String name, String userId) =>
    structureFixture(id, name, userId);

CoreUserSimple coreUserSimpleFixture({
  String id = 'user-1',
  String name = 'Doe',
  String firstname = 'Jane',
}) => MockCoreUserSimple.any.copyWith(id: id, name: name, firstname: firstname);

/// Stubs shared association/profile image fallback responses.
void stubAssociationAndProfilePictures(IntegrationScaffold scaffold) {
  when(
    () => scaffold.repository.phonebookAssociationsAssociationIdPictureGet(
      associationId: any(named: 'associationId'),
    ),
  ).thenAnswer((_) async => stubs.fileNotFound());
  stubs.stubProfilePictureFor(scaffold.repository);
}

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

LoanUpdate loanUpdateFixture({
  String? borrowerId,
  String? notes,
  bool? returned,
}) => MockLoanUpdate.any.copyWith(
  borrowerId: borrowerId,
  notes: notes,
  returned: returned,
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

ItemBorrowed itemBorrowed({required String itemId, required int quantity}) =>
    MockItemBorrowed.any.copyWith(itemId: itemId, quantity: quantity);

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

/// Create a PH paper with a predictable release day; set [month] for a
/// specific journal month, otherwise journals use March.
PaperComplete paperFixture(String id, String name, int year, [int month = 3]) =>
    PaperComplete.empty().copyWith(
      id: id,
      name: name,
      releaseDate: DateTime(year, month, 7),
    );

/// Create a raffle with predictable defaults for raffle-module tests.
RaffleComplete raffleFixture(
  String id,
  String name,
  RaffleStatusType? status,
) => RaffleComplete.empty().copyWith(
  id: id,
  name: name,
  groupId: 'group-1',
  description: 'A good cause',
  status: status,
);

/// Build the default section used by voting and campaign test fixtures.
SectionComplete sectionFixture(
  String id,
  String name, {
  String description = '',
}) => SectionComplete.empty().copyWith(
  id: id,
  name: name,
  description: description,
);

/// Build a campaign list with predictable vote-admin defaults.
ListReturn voteListFixture(
  String id,
  String name, {
  ListType type = ListType.serio,
  String description = 'Our program',
  SectionComplete? section,
}) => ListReturn.empty().copyWith(
  id: id,
  name: name,
  description: description,
  type: type,
  section: section ?? sectionFixture('s-1', 'Bureau des Sports'),
  members: const [],
);

GenerateTicketComplete ticketGeneratorFixture() =>
    GenerateTicketComplete.empty().copyWith(
      id: 'gen-1',
      name: 'Soirée des clubs',
      maxUse: 10,
      expiration: DateTime(2100),
    );

/// Build a user-owned CDR ticket that can still be scanned.
AppModulesCdrSchemasCdrTicket usableTicketFixture(String id) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: id,
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

/// Build a raffle administrator with predictable raffle-admin membership.
CoreUser raffleAdminUserFixture({String id = 'user-1'}) =>
    CoreUser.empty().copyWith(
      id: id,
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: raffleAdminGroupId,
          name: 'admin_raffle',
        ),
      ],
    );

/// Build a seed-library administrator with the module-admin group.
CoreUser seedLibraryAdminUserFixture({String id = 'user-1'}) =>
    CoreUser.empty().copyWith(
      id: id,
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: seedLibraryAdminGroupId,
          name: 'admin_seed_library',
        ),
      ],
    );

/// An administrator user for the shared booking group.
CoreUser bookingAdminUserFixture({String id = 'user-1'}) =>
    CoreUser.empty().copyWith(
      id: id,
      groups: [
        CoreGroupSimple.empty().copyWith(
          id: bookingAdminGroupId,
          name: 'admin',
        ),
      ],
    );

AssociationComplete association(
  String id,
  String name, {
  String groupementId = 'grp-1',
  String description = 'We build robots',
  int mandateYear = 2026,
}) => MockAssociationComplete.any.copyWith(
  id: id,
  name: name,
  groupementId: groupementId,
  mandateYear: mandateYear,
  description: description,
);

AssociationGroupement groupement(String id, [String name = '']) =>
    MockAssociationGroupement.any.copyWith(id: id, name: name);

MembershipComplete membershipFixture({
  String id = 'm-1',
  String userId = 'u-1',
  String associationId = 'a-1',
  int mandateYear = 2026,
  String roleName = 'President',
  String? roleTags,
  int memberOrder = 0,
}) => MockMembershipComplete.any.copyWith(
  id: id,
  userId: userId,
  associationId: associationId,
  mandateYear: mandateYear,
  roleName: roleName,
  roleTags: roleTags,
  memberOrder: memberOrder,
);

MemberComplete memberWithMemberships(
  String id,
  List<MembershipComplete> memberships,
) => MockMemberComplete.any.copyWith(id: id, memberships: memberships);

MemberComplete member(
  String id,
  String nickname,
  String firstname,
  String lastname, {
  String roleName = 'President',
  String associationId = 'a-1',
  int mandateYear = 2026,
  String? roleTags,
}) => MockMemberComplete.any.copyWith(
  id: id,
  nickname: nickname,
  firstname: firstname,
  name: lastname,
  email: '$id@myem.fr',
  memberships: [
    MockMembershipComplete.any.copyWith(
      userId: id,
      associationId: associationId,
      mandateYear: mandateYear,
      roleName: roleName,
      roleTags: roleTags,
      memberOrder: 0,
      id: 'm-$id',
    ),
  ],
);
