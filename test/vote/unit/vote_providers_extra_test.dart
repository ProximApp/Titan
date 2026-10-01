import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';
import 'package:titan/vote/providers/voted_section_provider.dart';
import 'package:titan/vote/providers/voter_list_provider.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('VotedSectionProvider', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late VotedSectionProvider notifier;

    setUp(() {
      mockRepository = MockRepository();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(votedSectionProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('getVotedSections loads the voted section ids', () async {
      when(() => mockRepository.campaignVotesGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), ['s1', 's2']),
      );

      final result = await notifier.getVotedSections();

      expect(result.value, ['s1', 's2']);
    });

    test('getVotedSections handles error', () async {
      when(
        () => mockRepository.campaignVotesGet(),
      ).thenThrow(Exception('votes failed'));

      final result = await notifier.getVotedSections();

      expect(result, isA<AsyncError<List<String>>>());
    });

    test('addVote appends a section id to the loaded list', () async {
      notifier.state = const AsyncValue.data(['s1']);

      notifier.addVote('s2');

      expect(notifier.state.value, ['s1', 's2']);
    });

    test('addVote is a no-op while loading', () {
      notifier.addVote('s1');

      // AsyncLoading type params differ between const and runtime values;
      // compare the flag, not the object.
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.value, isNull);
    });
  });

  group('VoterListNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late VoterListNotifier notifier;

    setUp(() {
      mockRepository = MockRepository();
      when(() => mockRepository.campaignVotersGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('{}', 200), CorePermission.empty()),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(voterListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('loadVoterList loads the permission', () async {
      final permission = CorePermission.empty().copyWith(
        permissionName: 'voter',
      );
      when(() => mockRepository.campaignVotersGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), permission),
      );

      final result = await notifier.loadVoterList();

      expect(result.value!.permissionName, 'voter');
    });

    test('addVoter reloads the list after adding a group', () async {
      when(
        () => mockRepository.campaignVotersGroupIdPost(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      when(() => mockRepository.campaignVotersGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('{}', 200), CorePermission.empty()),
      );

      final result = await notifier.addVoter('group-1');

      expect(result, true);
      verify(() => mockRepository.campaignVotersGet()).called(2);
    });

    test('addVoter fails without reloading on http error', () async {
      when(
        () => mockRepository.campaignVotersGroupIdPost(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('err', 400), null),
      );

      final result = await notifier.addVoter('group-1');

      expect(result, false);
      verify(() => mockRepository.campaignVotersGet()).called(1);
    });

    test('deleteVoter reloads the list after removing a group', () async {
      when(
        () => mockRepository.campaignVotersGroupIdDelete(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );
      when(() => mockRepository.campaignVotersGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('{}', 200), CorePermission.empty()),
      );

      final result = await notifier.deleteVoter('group-1');

      expect(result, true);
      verify(() => mockRepository.campaignVotersGet()).called(2);
    });

    test('deleteVoter fails without reloading on http error', () async {
      when(
        () => mockRepository.campaignVotersGroupIdDelete(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('err', 400), null),
      );

      final result = await notifier.deleteVoter('group-1');

      expect(result, false);
      verify(() => mockRepository.campaignVotersGet()).called(1);
    });
  });
}
