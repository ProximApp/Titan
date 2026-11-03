import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/service/class/firebase_toke_expiration.dart';
import 'package:titan/service/class/message.dart';

void main() {
  group('Message', () {
    test('parses from json', () {
      final message = Message.fromJson({
        'title': 'Hello',
        'content': 'World',
        'action_module': 'mypayment',
        'action_table': 'transactions',
      });

      expect(message.title, 'Hello');
      expect(message.content, 'World');
      expect(message.actionModule, 'mypayment');
      expect(message.actionTable, 'transactions');
    });

    test('round-trips through toJson', () {
      final message = Message(
        title: 'Hello',
        content: 'World',
        actionModule: 'vote',
        actionTable: 'campaigns',
      );

      final json = message.toJson();

      expect(json['title'], 'Hello');
      expect(json['action_module'], 'vote');
    });

    test('toString includes all fields', () {
      final message = Message(
        title: 'T',
        content: 'C',
        actionModule: 'M',
        actionTable: 'A',
      );

      expect(message.toString(), contains('T'));
      expect(message.toString(), contains('C'));
      expect(message.toString(), contains('M'));
      expect(message.toString(), contains('A'));
    });
  });

  group('FirebaseTokenExpiration', () {
    test('parses from json with an expiration', () {
      final token = FirebaseTokenExpiration.fromJson({
        'token': 'user-1',
        'expiration': '2026-09-25T10:00:00.000',
      });

      expect(token.userId, 'user-1');
      expect(token.expiration, DateTime(2026, 9, 25, 10));
    });

    test('parses from json without an expiration', () {
      final token = FirebaseTokenExpiration.fromJson({
        'token': 'user-1',
        'expiration': null,
      });

      expect(token.userId, 'user-1');
      expect(token.expiration, isNull);
    });

    test('toJson keeps the token and stringifies the expiration', () {
      final token = FirebaseTokenExpiration('user-2', DateTime(2026, 1, 1));

      final json = token.toJson();

      expect(json['token'], 'user-2');
      expect(json['expiration'], '2026-01-01 00:00:00.000');
    });

    // ledger #54: `toJson` used `expiration.toString()`, and `toString()` on a
    // null is the STRING "null". The row was therefore written with a value
    // its own reader could not parse, so the next launch died in
    // `getSavedDate` with a FormatException instead of re-registering.
    group('a null expiration round-trips', () {
      test('toJson writes a real null, not the string "null"', () {
        final token = FirebaseTokenExpiration.empty();

        final json = token.toJson();

        expect(
          json['expiration'],
          isNull,
          reason: 'a JSON null decodes to no date; the string "null" does not',
        );
        // The poisoning was specifically that the value survived as a String.
        expect(json['expiration'], isNot(isA<String>()));
      });

      test('the empty token survives a full encode/decode cycle', () {
        final encoded = jsonEncode(FirebaseTokenExpiration.empty().toJson());

        // Decode through JSON first: that is what the notifier does, and it
        // is where a string "null" would become indistinguishable from a real
        // value before fromJson ever saw it.
        final decoded = FirebaseTokenExpiration.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );

        expect(decoded.userId, '');
        expect(decoded.expiration, isNull);
      });

      test('a real date still survives the same cycle unchanged', () {
        final original = FirebaseTokenExpiration(
          'user-2',
          DateTime(2026, 1, 1, 9, 30),
        );

        final decoded = FirebaseTokenExpiration.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
        );

        expect(decoded.userId, 'user-2');
        expect(decoded.expiration, original.expiration);
      });
    });

    // The writer is only half the fix. Any row already written as the string
    // "null" - by the old toJson, by a future writer, or by a hand-edited
    // preference - must not take the launch down with it.
    group('an unparseable stored expiration reads as no date', () {
      for (final poisoned in {
        'the legacy string "null"': 'null',
        'an empty string': '',
        'nonsense': 'not-a-date',
      }.entries) {
        test('${poisoned.key} decodes to null instead of throwing', () {
          final token = FirebaseTokenExpiration.fromJson({
            'token': 'user-1',
            'expiration': poisoned.value,
          });

          expect(token.userId, 'user-1');
          expect(
            token.expiration,
            isNull,
            reason:
                'an unreadable date must fall back to "register a new token", '
                'the branch setup.dart already handles',
          );
        });
      }

      test('a missing key decodes to null too', () {
        final token = FirebaseTokenExpiration.fromJson({'token': 'user-1'});

        expect(token.expiration, isNull);
      });
    });

    test('copyWith replaces only the given fields', () {
      final token = FirebaseTokenExpiration('user-1', DateTime(2026, 1, 1));

      final copied = token.copyWith(userId: 'user-3');

      expect(copied.userId, 'user-3');
      expect(copied.expiration, token.expiration);
    });

    test('empty token has no user and no expiration', () {
      final token = FirebaseTokenExpiration.empty();

      expect(token.userId, '');
      expect(token.expiration, null);
    });
  });
}
