import 'package:flutter/material.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/seed-library/tools/functions.dart';

void main() {
  group('state helpers', () {
    test('parses french state values', () {
      expect(getStateByValue('en attente'), State.pending);
      expect(getStateByValue('récupérée'), State.retrieved);
      expect(getStateByValue('consommée'), State.consumed);
    });

    test('falls back to pending on unknown values', () {
      expect(getStateByValue('unknown'), State.pending);
    });

    test('formats states back to french values', () {
      expect(getStateValue(State.pending), 'en attente');
      expect(getStateValue(State.retrieved), 'récupérée');
      expect(getStateValue(State.consumed), 'consommée');
    });
  });

  group('propagation method helpers', () {
    test('parses french propagation values', () {
      expect(getPropagationMethodByValue('bouture'), PropagationMethod.bouture);
      expect(getPropagationMethodByValue('graine'), PropagationMethod.graine);
    });

    test('falls back to bouture on unknown values', () {
      expect(getPropagationMethodByValue('unknown'), PropagationMethod.bouture);
    });

    test('formats propagation methods back to french values', () {
      expect(getPropagationMethodValue(PropagationMethod.bouture), 'bouture');
      expect(getPropagationMethodValue(PropagationMethod.graine), 'graine');
      expect(
        getPropagationMethodValue(PropagationMethod.swaggerGeneratedUnknown),
        'inconnu',
      );
    });
  });

  group('monthToString', () {
    test('returns french month names', () {
      expect(monthToString(1), isNotEmpty);
      expect(monthToString(12), isNotEmpty);
      expect(monthToString(1), isNot(monthToString(2)));
    });
  });

  group('getColorFromDifficulty', () {
    test('maps difficulties 1 to 5 to distinct colors', () {
      final colors = {
        1: getColorFromDifficulty(1),
        2: getColorFromDifficulty(2),
        3: getColorFromDifficulty(3),
        4: getColorFromDifficulty(4),
        5: getColorFromDifficulty(5),
      };

      expect(colors[1], Colors.green);
      expect(colors[2], Colors.yellow);
      expect(colors[3], Colors.orange);
      expect(colors[4], Colors.red);
      expect(colors[5], Colors.black);
      expect(colors.values.toSet().length, 5);
    });

    test('falls back to grey outside 1-5', () {
      expect(getColorFromDifficulty(0), Colors.grey);
      expect(getColorFromDifficulty(6), Colors.grey);
    });
  });
}
