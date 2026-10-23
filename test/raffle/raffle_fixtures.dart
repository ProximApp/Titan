import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../shared/app_scaffold.dart';
import '../shared/fixtures.dart' show adminGroupId;

/// The raffle admin gate group — the shared main admin group.
const raffleAdminGroupId = adminGroupId;

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

/// Build a user-owned raffle ticket with its nested pack ticket; the shape
/// every raffle card and ticket strip renders.
AppModulesRaffleSchemasRaffleTicketComplete raffleTicketFixture(
  String id,
  String raffleId, {
  int packSize = 1,
  int price = 200,
  PrizeSimple? prize,
}) => AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(
  id: id,
  packId: 'pack-$id',
  userId: 'user-1',
  prize: prize,
  packTicket: PackTicketSimple.empty().copyWith(
    id: 'pack-$id',
    raffleId: raffleId,
    packSize: packSize,
    price: price,
  ),
);

/// Stubs the tombola reads the creation-flow pages share on mount: the
/// raffle list (one raffle), its prizes, its pack tickets, and the current
/// user's tickets. Three files rebuilt this block by hand; [prizes] and
/// [packTickets] carry what each page actually renders. [withRaffleTickets]
/// additionally answers the per-raffle ticket list only the creation-edit
/// shell reads.
void stubCreationData(
  IntegrationScaffold scaffold, {
  RaffleStatusType status = RaffleStatusType.creation,
  List<PrizeSimple> prizes = const [],
  List<PackTicketSimple> packTickets = const [],
  bool withRaffleTickets = false,
}) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([raffleFixture('r-1', 'Gala', status)]),
  );
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPrizesGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(prizes));
  when(
    () => scaffold.repository.tombolaRafflesRaffleIdPackTicketsGet(
      raffleId: any(named: 'raffleId'),
    ),
  ).thenAnswer((_) async => chopperListResponse(packTickets));
  when(
    () => scaffold.repository.tombolaUsersUserIdTicketsGet(
      userId: any(named: 'userId'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
  );
  if (withRaffleTickets) {
    when(
      () => scaffold.repository.tombolaRafflesRaffleIdTicketsGet(
        raffleId: any(named: 'raffleId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );
  }
}
