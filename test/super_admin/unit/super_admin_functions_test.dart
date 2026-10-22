import 'package:flutter_test/flutter_test.dart';
import 'package:titan/super_admin/tools/function.dart';

void main() {
  group('capitalizePermissionName', () {
    test('capitalizes each word of a snake_case permission', () {
      expect(capitalizePermissionName('my_payment_admin'), 'My Payment Admin');
    });

    test('handles a single word', () {
      expect(capitalizePermissionName('admin'), 'Admin');
    });

    test('does not crash on consecutive separators', () {
      expect(capitalizePermissionName('a__b'), 'A  B');
    });
  });

  group('snakeToCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect(snakeToCamelCase('my_payment_admin'), 'myPaymentAdmin');
    });

    test('leaves a single word untouched', () {
      expect(snakeToCamelCase('admin'), 'admin');
    });

    test('skips empty parts', () {
      expect(snakeToCamelCase('my__payment'), 'myPayment');
    });
  });
}
