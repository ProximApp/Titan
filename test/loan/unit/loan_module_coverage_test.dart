import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/loan/adapters/item.dart';
import 'package:titan/loan/adapters/loan.dart';
import 'package:titan/user/extensions/core_user_simple.dart';
import 'package:titan/loan/providers/admin_history_loan_list_provider.dart';
import 'package:titan/loan/providers/admin_loan_list_provider.dart';
import 'package:titan/loan/providers/borrower_provider.dart';
import 'package:titan/loan/providers/caution_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/history_loaner_loan_list_provider.dart';
import 'package:titan/loan/providers/item_focus_provider.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/item_provider.dart';
import 'package:titan/loan/providers/loan_focus_provider.dart';
import 'package:titan/loan/providers/loan_provider.dart';
import 'package:titan/loan/providers/loaner_id_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/providers/user_loaner_list_provider.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/logs/logger.dart';
import 'package:titan/tools/logs/logger_output.dart';
import 'package:titan/tools/logs/log.dart' show Log;
import 'package:titan/tools/repository/repository.dart' show repositoryProvider;

import '../../shared/fixtures.dart';
import '../../shared/repository_test_support.dart';

void main() {
  registerTestFallbackValues();

  group('HistoryLoanerLoanListNotifier', () {
    late MockOpenapi fake;
    late ProviderContainer container;

    setUp(() {
      fake = MockOpenapi();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(fake),
          loanerIdProvider.overrideWithBuild((_, _) => 'loaner-1'),
        ],
      );
    });
    tearDown(() => container.dispose());

    group('build/loading', () {
      test('starts in AsyncValue.loading', () {
        expect(
          container.read(historyLoanerLoanListProvider),
          const AsyncValue<List<Loan>>.loading(),
        );
      });

      test('loadLoan is called when loanerId is non-empty', () async {
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([loanFixture()]));

        await container.read(historyLoanerLoanListProvider.notifier);
        await container.read(historyLoanerLoanListProvider);

        expect(
          container.read(historyLoanerLoanListProvider).value,
          hasLength(1),
        );
        expect(
          container.read(historyLoanerLoanListProvider).value!.single.id,
          'l-1',
        );
      });
    });

    group('loadLoan / loadHistory', () {
      test('loadLoan sets state to the returned loans', () async {
        final wanted = [loanFixture(id: 'l-1'), loanFixture(id: 'l-2')];
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse(wanted));

        final n = container.read(historyLoanerLoanListProvider.notifier);
        final result = await n.loadLoan('loaner-1');

        expect(result.value, wanted);
        expect(container.read(historyLoanerLoanListProvider).value, wanted);
      });

      test('loadHistory returns the body directly on success', () async {
        final wanted = [loanFixture(id: 'l-1')];
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperResponse(wanted));

        final n = container.read(historyLoanerLoanListProvider.notifier);
        final result = await n.loadHistory('loaner-1');

        expect(result.value, wanted);
      });

      test(
        'loadHistory returns an error value on a non-200 response',
        () async {
          when(
            () => fake.loansLoanersLoanerIdLoansGet(
              loanerId: 'loaner-1',
              returned: any(named: 'returned'),
            ),
          ).thenAnswer(
            (_) async =>
                chopper.Response<List<Loan>>(http.Response('nope', 500), null),
          );

          final n = container.read(historyLoanerLoanListProvider.notifier);
          final result = await n.loadHistory('loaner-1');

          expect(result, isA<AsyncError<List<Loan>>>());
        },
      );

      test('loadHistory stores the error in state and returns it when the call throws', () async {
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenThrow(Exception('history failed'));

        final n = container.read(historyLoanerLoanListProvider.notifier);
        final result = await n.loadHistory('loaner-1');

        expect(result, isA<AsyncError<List<Loan>>>());
        expect(n.state, isA<AsyncError<List<Loan>>>());
      });
    });

    group('mutations', () {
      test('addLoan posts the loan and appends the created loan', () async {
        final added = loanFixture(id: 'l-new', borrowerId: 'borrower-new');
        when(() => fake.loansPost(body: any(named: 'body')))
            .thenAnswer((inv) async {
              return chopperResponse(added);
            });
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer(
          (_) async => chopperListResponse([loanFixture(id: 'l-1')]),
        );

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final body = loanCreationFixture(
          borrowerId: 'borrower-new',
          loanerId: 'loaner-1',
        );
        final ok = await n.addLoan(body);

        expect(ok, isTrue);
        final read = container.read(historyLoanerLoanListProvider);
        read.whenData((list) {
          expect(list.length, 2);
          expect(list.last.id, 'l-new');
        });
      });

      test('addLoan returns false when the post endpoint fails', () async {
        when(() => fake.loansPost(body: any(named: 'body')))
            .thenAnswer((inv) async {
              return chopper.Response(
                http.Response('bad', 500),
                null,
                error: Exception('server error'),
              );
            });
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer(
          (_) async => chopperListResponse([loanFixture(id: 'l-1')]),
        );

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final body = loanCreationFixture(
          borrowerId: 'borrower-new',
          loanerId: 'loaner-1',
        );
        final ok = await n.addLoan(body);

        expect(ok, isFalse);
      });

      test('updateLoan patches the loan and replaces it in the list', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(
          () => fake.loansLoanIdPatch(
            loanId: 'l-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer((inv) async {
          return chopperResponseVoid();
        });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final updated = existing.copyWith(
          notes: ' renewed notes',
          end: DateTime(2026, 2, 1),
        );
        final ok = await n.updateLoan(updated);

        expect(ok, isTrue);
        final read = container.read(historyLoanerLoanListProvider);
        read.whenData((list) {
          expect(list.single.id, 'l-1');
          expect(list.single.notes, ' renewed notes');
        });
      });

      test('updateLoan returns false when the patch endpoint fails', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(
          () => fake.loansLoanIdPatch(
            loanId: 'l-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer((inv) async {
          return chopper.Response(
            http.Response('bad', 500),
            null,
            error: Exception('server error'),
          );
        });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final updated = existing.copyWith(notes: 'should not persist');
        final ok = await n.updateLoan(updated);

        expect(ok, isFalse);
      });

      test(
        'deleteLoan removes the loan when the delete endpoint succeeds',
        () async {
          final existing = loanFixture(id: 'l-1');
          when(
            () => fake.loansLoanersLoanerIdLoansGet(
              loanerId: 'loaner-1',
              returned: any(named: 'returned'),
            ),
          ).thenAnswer((_) async => chopperListResponse([existing]));
          when(() => fake.loansLoanIdDelete(loanId: 'l-1'))
              .thenAnswer((inv) async {
                return chopperResponseVoid();
              });

          final n = container.read(historyLoanerLoanListProvider.notifier);
          await n.loadLoan('loaner-1');

          final ok = await n.deleteLoan(existing);

          expect(ok, isTrue);
          final read = container.read(historyLoanerLoanListProvider);
          read.whenData((list) {
            expect(list, isEmpty);
          });
        },
      );

      test('deleteLoan returns false when the delete endpoint fails', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(() => fake.loansLoanIdDelete(loanId: 'l-1'))
            .thenAnswer((inv) async {
              return chopper.Response(
                http.Response('bad', 500),
                null,
                error: Exception('server error'),
              );
            });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final ok = await n.deleteLoan(existing);

        expect(ok, isFalse);
      });

      test('returnLoan posts the return and removes the loan', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(() => fake.loansLoanIdReturnPost(loanId: 'l-1'))
            .thenAnswer((inv) async {
              return chopperResponseVoid();
            });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final ok = await n.returnLoan(existing);

        expect(ok, isTrue);
        final read = container.read(historyLoanerLoanListProvider);
        read.whenData((list) => expect(list, isEmpty));
      });

      test('returnLoan returns false when the return endpoint fails', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(() => fake.loansLoanIdReturnPost(loanId: 'l-1'))
            .thenAnswer((inv) async {
              return chopper.Response(
                http.Response('bad', 500),
                null,
                error: Exception('server error'),
              );
            });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final ok = await n.returnLoan(existing);

        expect(ok, isFalse);
      });

      test('extendLoan posts the extension and updates the loan end', () async {
        final existing = loanFixture(id: 'l-1', end: DateTime(2026, 1, 15));
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(
          () => fake.loansLoanIdExtendPost(
            loanId: 'l-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer((inv) async {
          return chopperResponseVoid();
        });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final ok = await n.extendLoan(existing, 7);

        expect(ok, isTrue);
        final read = container.read(historyLoanerLoanListProvider);
        read.whenData((list) {
          expect(list.single.id, 'l-1');
          expect(list.single.end.day, DateTime(2026, 1, 22).day);
        });
      });

      test('extendLoan returns false when the extend endpoint fails', () async {
        final existing = loanFixture(id: 'l-1');
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenAnswer((_) async => chopperListResponse([existing]));
        when(
          () => fake.loansLoanIdExtendPost(
            loanId: 'l-1',
            body: any(named: 'body'),
          ),
        ).thenAnswer((inv) async {
          return chopper.Response(
            http.Response('bad', 500),
            null,
            error: Exception('server error'),
          );
        });

        final n = container.read(historyLoanerLoanListProvider.notifier);
        await n.loadLoan('loaner-1');

        final ok = await n.extendLoan(existing, 7);

        expect(ok, isFalse);
      });
    });

    group('derived helpers', () {
      test('copy returns a shallow copy of the current list', () async {
        final loans = [loanFixture(id: 'l-1')];
        final n = container.read(historyLoanerLoanListProvider.notifier);
        n.state = AsyncValue.data(loans);

        final copy = await n.copy();

        expect(copy.value, loans);
        expect(identical(copy.value, loans), false);
      });

      test('filterLoans matches borrower names case-insensitively', () async {
        final loanAlice = loanFixture(
          id: 'l-1',
          borrower: coreUserSimpleFixture(name: 'Alice', firstname: 'Smith'),
        );
        final loanBob = loanFixture(
          id: 'l-2',
          borrower: coreUserSimpleFixture(name: 'Bob', firstname: 'Jones'),
        );
        final n = container.read(historyLoanerLoanListProvider.notifier);
        n.state = AsyncValue.data([loanAlice, loanBob]);

        final result = await n.filterLoans('SMI');

        expect(result.value, [loanAlice]);
      });

      test('filterLoans matches item names case-insensitively', () async {
        final loanedItem = loanFixture(
          id: 'l-1',
          itemsQty: [
            itemQuantity(itemId: 'Helmet', itemName: 'Helmet', quantity: 2),
          ],
        );
        final noItem = loanFixture(id: 'l-2');
        final n = container.read(historyLoanerLoanListProvider.notifier);
        n.state = AsyncValue.data([loanedItem, noItem]);

        final result = await n.filterLoans('helmet');

        expect(result.value, [loanedItem]);
      });

      test('filterLoans returns an empty list when nothing matches', () async {
        final loanAlice = loanFixture(
          id: 'l-1',
          borrower: coreUserSimpleFixture(name: 'Alice', firstname: 'Smith'),
        );
        final n = container.read(historyLoanerLoanListProvider.notifier);
        n.state = AsyncValue.data([loanAlice]);

        final result = await n.filterLoans('zebra');

        expect(result.value, isEmpty);
      });
    });

    group('token expiration', () {
      test('loadHistory rethrows tokenExpire errors', () {
        final n = container.read(historyLoanerLoanListProvider.notifier);
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenThrow(tokenExpire());

        expect(
          n.loadHistory('loaner-1'),
          throwsA(
            isA<AppException>().having(
              (e) => e.type,
              'type',
              ErrorType.tokenExpire,
            ),
          ),
        );
      });

      test('loadLoan rethrows tokenExpire errors', () {
        final n = container.read(historyLoanerLoanListProvider.notifier);
        when(
          () => fake.loansLoanersLoanerIdLoansGet(
            loanerId: 'loaner-1',
            returned: any(named: 'returned'),
          ),
        ).thenThrow(tokenExpire());

        expect(
          n.loadLoan('loaner-1'),
          throwsA(
            isA<AppException>().having(
              (e) => e.type,
              'type',
              ErrorType.tokenExpire,
            ),
          ),
        );
      });
    });
  });

  group('UserLoanerListNotifier', () {
    late MockOpenapi fake;
    late ProviderContainer container;

    setUp(() {
      fake = MockOpenapi();
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(fake)],
      );
    });
    tearDown(() => container.dispose());

    test('build starts loading', () {
      expect(
        container.read(userLoanerListProvider),
        const AsyncValue<List<Loaner>>.loading(),
      );
    });

    test('loads loaners from the repository on read', () async {
      final wanted = [loanerFixture(id: 'l-1')];
      when(() => fake.loansUsersMeLoanersGet())
          .thenAnswer((_) async => chopperListResponse(wanted));

      await container.read(userLoanerListProvider);

      expect(container.read(userLoanerListProvider).value, wanted);
    });

    test('returns error state on repository failure', () async {
      when(() => fake.loansUsersMeLoanersGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('bad', 500),
          null,
          error: Exception('fail'),
        ),
      );

      await container.read(userLoanerListProvider);

      expect(
        container.read(userLoanerListProvider),
        isA<AsyncError<List<Loaner>>>(),
      );
    });
  });

  group('LoanerIdProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          notifierBuildOverride(
            userLoanerListProvider,
            AsyncValue.data([loanerFixture(id: 'l-1')]),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('build returns the first loaner id', () {
      expect(container.read(loanerList), [loanerFixture(id: 'l-1')]);
      expect(container.read(loanerIdProvider), 'l-1');
    });

    test('returns empty string when the list is empty', () {
      container.read(userLoanerListProvider.notifier).state = AsyncValue.data(
        <Loaner>[],
      );
      expect(container.read(loanerList), isEmpty);
      expect(container.read(loanerIdProvider), '');
    });

    test('setId updates the loaner id', () {
      final notifier = container.read(loanerIdProvider.notifier);
      notifier.setId('l-2');
      expect(container.read(loanerIdProvider), 'l-2');
    });
  });

  group('shared loaner fixture', () {
    test('loanerFixture() creates a predictable loaner model', () {
      final value = loanerFixture(id: 'l-1', name: 'Alice');
      expect(value.id, 'l-1');
      expect(value.name, 'Alice');
    });
  });

  group('ItemListNotifier', () {
    late MockOpenapi fake;
    late ProviderContainer container;

    setUp(() {
      fake = MockOpenapi();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(fake),
          loanerIdProvider.overrideWithBuild((_, _) => 'loaner-1'),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('build starts loading', () {
      expect(
        container.read(itemListProvider),
        const AsyncValue<List<Item>>.loading(),
      );
    });

    test('loads items from the repository on read', () async {
      final wanted = <Item>[itemFixture(id: 'i-1', name: 'Helmet')];
      when(() => fake.loansLoanersLoanerIdItemsGet(loanerId: 'loaner-1'))
          .thenAnswer((_) async => chopperListResponse(wanted));

      await container.read(itemListProvider);

      expect(container.read(itemListProvider).value, wanted);
    });

    test('returns error state on repository failure', () async {
      when(() => fake.loansLoanersLoanerIdItemsGet(loanerId: 'loaner-1'))
          .thenAnswer(
            (_) async => chopper.Response(
              http.Response('bad', 500),
              null,
              error: Exception('fail'),
            ),
          );

      await container.read(itemListProvider);

      expect(container.read(itemListProvider), isA<AsyncError<List<Item>>>());
    });

    test('filterItems matches item names case-insensitively', () async {
      final helmet = itemFixture(id: 'i-1', name: 'Helmet');
      final vest = itemFixture(id: 'i-2', name: 'Vest');
      final n = container.read(itemListProvider.notifier);
      n.state = AsyncValue.data(<Item>[helmet, vest]);

      final result = await n.filterItems('hel');

      expect(result.value, [helmet]);
    });

    test('copy returns a shallow copy', () async {
      final items = <Item>[itemFixture(id: 'i-1', name: 'Helmet')];
      final n = container.read(itemListProvider.notifier);
      n.state = AsyncValue.data(items);

      final copy = await n.copy();

      expect(copy.value, items);
      expect(identical(copy.value, items), false);
    });
  });

  group('LoanDetail providers read from the loan form state', () {
    test('BorrowerProvider reads the borrower from the current loan', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(loanProvider.notifier)
          .setLoan(
            loanFixture(
              borrower: coreUserSimpleFixture(
                name: 'Alice',
                firstname: 'Smith',
              ),
            ),
          );

      final read = container.read(borrowerProvider);
      expect(read.name, 'Alice');
      expect(read.firstname, 'Smith');
    });

    test('StartProvider reads the start set via setStart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(startProvider.notifier)
          .setStart(DateTime(2026, 1, 1).toIso8601String());

      expect(
        container.read(startProvider),
        DateTime(2026, 1, 1).toIso8601String(),
      );
    });

    test('EndProvider reads the end set via setEnd', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(endProvider.notifier)
          .setEnd(DateTime(2026, 2, 1).toIso8601String());

      expect(
        container.read(endProvider),
        DateTime(2026, 2, 1).toIso8601String(),
      );
    });

    test('CautionProvider reads the caution set via setCaution', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cautionProvider.notifier).setCaution('Handle with care');

      expect(container.read(cautionProvider).value.text, 'Handle with care');
    });

    test('ItemProvider reads the item set via setItem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(itemProvider.notifier)
          .setItem(itemFixture(id: 'i-1', name: 'Helmet'));

      final read = container.read(itemProvider);
      expect(read.id, 'i-1');
      expect(read.name, 'Helmet');
    });

    test(
      'ItemProvider falls back to Item.empty() before setItem is called',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(itemProvider), Item.empty());
      },
    );
  });

  group('Loan adapter toLoanCreation path', () {
    test('Loan.toLoanCreation maps itemsQty through toItemBorrowed', () {
      final l = loanFixture(
        id: 'l-1',
        itemsQty: [
          itemQuantity(itemId: 'Helmet', itemName: 'Helmet', quantity: 2),
        ],
      );
      final creation = l.toLoanCreation();
      expect(creation.itemsBorrowed, hasLength(1));
      expect(creation.itemsBorrowed.single.itemId, 'Helmet');
      expect(creation.itemsBorrowed.single.quantity, 2);
    });

    test('Loan.toLoanCreation preserves borrowerId and loanerId', () {
      final l = loanFixture(borrowerId: 'b-1', loanerId: 'l-1');
      final creation = l.toLoanCreation();
      expect(creation.borrowerId, 'b-1');
      expect(creation.loanerId, 'l-1');
    });
  });

  group('Focus providers', () {
    test('LoanFocusProvider toggles focus on/off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanFocusProvider.notifier);
      notifier.setFocus(true);
      expect(container.read(loanFocusProvider), true);
      notifier.setFocus(false);
      expect(container.read(loanFocusProvider), false);
    });

    test('ItemFocusProvider toggles focus on/off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(itemFocusProvider.notifier);
      notifier.setFocus(true);
      expect(container.read(itemFocusProvider), true);
      notifier.setFocus(false);
      expect(container.read(itemFocusProvider), false);
    });
  });

  group('AdminLoanListNotifier and AdminHistoryLoanListNotifier', () {
    test('AdminLoanListNotifier starts empty and can store keyed data', () {
      // The widget binding has to exist and the logger has to be inert:
      // reading the notifier's build path fans out through the repository's
      // log interceptor to the real Logger, whose init() opens the on-disk
      // log file through path_provider.
      TestWidgetsFlutterBinding.ensureInitialized();
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(MockOpenapi()),
          loggerProvider.overrideWith((ref) => _InertLogger()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminLoanListProvider.notifier);
      final loanerKey = loanerFixture(id: 'l-1');
      notifier.setTData(loanerKey, AsyncValue.data([loanFixture(id: 'x')]));

      final state = container.read(adminLoanListProvider);
      expect(state[loanerKey], isA<AsyncValue<List<Loan>>>());
      state[loanerKey]?.whenData((list) => expect(list, hasLength(1)));
    });

    test('AdminHistoryLoanListNotifier pre-seeds empty data per loaner', () async {
      // The notifier reads loanerList + loanerProvider synchronously at build
      // time and seeds every known loaner with AsyncValue.data([]). It also
      // builds a historyLoanerLoanListProvider.notifier for each loaner, which
      // would hit the repository — so we override that provider with a notifier
      // whose build() is inert.
      final container = ProviderContainer(
        overrides: [
          notifierBuildOverride(
            userLoanerListProvider,
            AsyncValue.data([
              loanerFixture(id: 'l-1'),
              loanerFixture(id: 'l-2'),
            ]),
          ),
          historyLoanerLoanListProvider.overrideWith(
            () => _FakeHistoryLoanerLoanListNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(loanerIdProvider.notifier).setId('l-1');

      final state = container.read(adminHistoryLoanListProvider);
      expect(state, isA<Map<Loaner, AsyncValue<List<Loan>>?>>());
      // MapNotifier.loadTList seeds every known loaner with `null`, its
      // marker for "subscribed, not loaded yet".
      expect(state.keys.map((l) => l.id), containsAll(['l-1', 'l-2']));
      // The selected loaner's slot fills once its loadLoan resolves through
      // the overridden (inert) history notifier.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final settled = container.read(adminHistoryLoanListProvider);
      final selected = settled.entries.firstWhere(
        (entry) => entry.key.id == 'l-1',
      );
      selected.value?.whenData((list) => expect(list, isEmpty));
    });
  });

  group('Loan adapters', () {
    test('Loan.copyWith preserves unchanged fields', () {
      final original = loanFixture(
        id: 'l-1',
        notes: 'original',
        end: DateTime(2026, 1, 15),
      );
      final copy = original.copyWith(notes: 'changed');

      expect(copy.id, 'l-1');
      expect(copy.notes, 'changed');
      expect(copy.start, original.start);
      expect(copy.end, DateTime(2026, 1, 15));
    });

    test('Loan adapter mapping survives item conversions', () {
      final l = loanFixture(
        id: 'l-1',
        itemsQty: [
          itemQuantity(itemId: 'Helmet', itemName: 'Helmet', quantity: 2),
        ],
      );
      final updated = l.copyWith(notes: 'x', end: DateTime(2026, 2, 1));
      final mapped = LoanUpdate(
        borrowerId: updated.borrower.id,
        start: updated.start,
        end: updated.end,
        notes: updated.notes,
        caution: updated.caution,
        returned: updated.returned,
        itemsBorrowed: updated.itemsQty
            .map(
              (e) =>
                  ItemBorrowed(itemId: e.itemSimple.id, quantity: e.quantity),
            )
            .toList(),
      );
      expect(mapped.itemsBorrowed?.length, 1);
      expect(mapped.itemsBorrowed!.single.itemId, 'Helmet');
      expect(mapped.itemsBorrowed!.single.quantity, 2);
    });
  });

  group('CoreUserSimple.getName() extension', () {
    test('returns "firstname name" by default', () {
      final u = coreUserSimpleFixture(name: 'Doe', firstname: 'John');
      expect(u.getName(), 'John Doe');
    });

    test('returns "firstname name" even for single-name borrowers', () {
      final u = coreUserSimpleFixture(name: 'Doe', firstname: '');
      expect(u.getName(), ' Doe');
    });
  });

  group('Loaned item conversions through adapter extensions', () {
    test('Item.toItemSimple produces the right ItemSimple', () {
      final i = itemFixture(id: 'i-1', name: 'Helmet');
      final simple = i.toItemSimple();
      expect(simple.id, 'i-1');
      expect(simple.name, 'Helmet');
      expect(simple.loanerId, 'loaner-1');
    });

    test('ItemSimple.toItemBorrowed produces the right ItemBorrowed', () {
      final i = itemFixture(id: 'i-1', name: 'Helmet');
      final simple = i.toItemSimple();
      final borrowed = simple.toItemBorrowed(3);
      expect(borrowed.itemId, 'i-1');
      expect(borrowed.quantity, 3);
    });
  });
}

class _FakeHistoryLoanerLoanListNotifier extends HistoryLoanerLoanListNotifier {
  @override
  AsyncValue<List<Loan>> build() => const AsyncValue.data(<Loan>[]);

  @override
  Future<AsyncValue<List<Loan>>> loadLoan(String loanerId) async =>
      AsyncValue.data(<Loan>[]);
}

/// The real Logger's init() opens the on-disk log file through path_provider,
/// which is unavailable under plain `flutter test`. A logger whose output is
/// already wired and init() short-circuited keeps the fan-out through the
/// repository's log interceptor harmless.
class _InertLogger extends Logger {
  _InertLogger() {
    loggerOutput = _VoidLoggerOutput();
  }

  @override
  Future<void> init() async {}
}

class _VoidLoggerOutput implements LoggerOutput {
  @override
  Future<void> init() async {}

  @override
  Future<void> writeLog(Log log) async {}

  @override
  List<Log> getLogs() => const [];

  @override
  List<Log> getNotificationLogs() => const [];

  @override
  Future<void> clearLogs() async {}

  @override
  Future<void> clearNotificationLogs() async {}
}
