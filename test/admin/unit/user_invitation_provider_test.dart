import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/user_invitation_provider.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

/// `UserInvitationNotifier` is the backend of the invite-users modal: it
/// batches the CSV-parsed addresses into one POST. The two things worth
/// pinning here are the forwarding contract (the batch keeps each address AND
/// the group chosen in the modal) and the failed half of `BatchResult`, which
/// the modal turns into the failure dialog.
void main() {
  group('UserInvitationNotifier', () {
    late MockOpenapi repo;
    late ProviderContainer container;
    late UserInvitationNotifier notifier;

    setUp(() {
      repo = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      notifier = container.read(userInvitationProvider.notifier);
      addTearDown(container.dispose);
    });

    test(
      'createUsers posts the whole batch and stores the BatchResult',
      () async {
        List<CoreBatchUserCreateRequest>? sent;
        when(
          () => repo.usersBatchCreationPost(body: any(named: 'body')),
        ).thenAnswer((inv) async {
          sent = inv.namedArguments[#body] as List<CoreBatchUserCreateRequest>?;
          return repo.ok(BatchResult.empty());
        });

        final result = await notifier.createUsers([
          CoreBatchUserCreateRequest(
            email: 'ada@lovelace.fr',
            defaultGroupId: 'g1',
          ),
          CoreBatchUserCreateRequest(email: 'alan@turing.uk'),
        ]);

        expect(result, isA<AsyncData<BatchResult>>());
        expect(notifier.state, isA<AsyncData<BatchResult>>());
        // Nothing may be dropped or reordered: the modal shows a per-address
        // failure dialog built from exactly what was sent.
        expect(sent, hasLength(2));
        expect(sent!.first.email, 'ada@lovelace.fr');
        expect(sent!.first.defaultGroupId, 'g1');
        expect(sent!.last.email, 'alan@turing.uk');
        expect(sent!.last.defaultGroupId, isNull);
      },
    );

    test('createUsers surfaces a rejected batch as AsyncError', () async {
      when(() => repo.usersBatchCreationPost(body: any(named: 'body')))
          .thenAnswer((_) async => repo.fail(400));

      final result = await notifier.createUsers([
        CoreBatchUserCreateRequest(email: 'bad address'),
      ]);

      expect(result, isA<AsyncError<BatchResult>>());
      expect(notifier.state, isA<AsyncError<BatchResult>>());
    });
  });
}
