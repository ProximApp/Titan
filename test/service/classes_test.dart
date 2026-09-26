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
      expect(token.expiration, null);
    });

    test('toJson keeps the token and stringifies the expiration', () {
      final token = FirebaseTokenExpiration(
        'user-2',
        DateTime(2026, 1, 1),
      );

      final json = token.toJson();

      expect(json['token'], 'user-2');
      expect(json['expiration'], '2026-01-01 00:00:00.000');
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
