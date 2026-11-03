import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/tools/functions.dart' as admin_functions;

void main() {
  group('admin parseCsvContent', () {
    test('returns nothing for an empty payload', () {
      expect(admin_functions.parseCsvContent(''), isEmpty);
    });

    test('keeps only the valid emails whatever the separator', () {
      const content = 'a@example.com;b@example.com;\nnot-an-email;c@d.fr';
      expect(admin_functions.parseCsvContent(content), [
        'a@example.com',
        'b@example.com',
        'c@d.fr',
      ]);
    });

    test('detects tabs as the dominant separator', () {
      const content = 'a@example.com\tb@example.com\nnot-an-email';
      expect(admin_functions.parseCsvContent(content), [
        'a@example.com',
        'b@example.com',
      ]);
    });

    test('deduplicates repeated addresses across lines', () {
      const content = 'dup@example.com\nother@example.com\ndup@example.com';
      expect(admin_functions.parseCsvContent(content), [
        'dup@example.com',
        'other@example.com',
      ]);
    });
  });
}
