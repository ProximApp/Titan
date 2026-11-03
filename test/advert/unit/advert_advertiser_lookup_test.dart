import 'package:flutter_test/flutter_test.dart';
import 'package:titan/advert/ui/pages/admin_page/admin_page.dart';
import 'package:titan/generated/openapi.swagger.dart';

/// The admin page's Edit action preselects the advert's association. The
/// index is only as good as the catalog: an advert whose association was
/// deleted has no row, and the bare `firstWhere` that used to run here threw
/// `Bad state: No element` on the tap.
void main() {
  group('advertiserOf', () {
    test('an absent advertiser yields null instead of throwing', () {
      final advert = AdvertComplete.empty().copyWith(
        id: 'advert-1',
        advertiserId: 'association-gone',
      );

      expect(advertiserOf(advert, const <Association>[]), isNull);
    });

    test('a present advertiser still resolves', () {
      final advert = AdvertComplete.empty().copyWith(
        id: 'advert-1',
        advertiserId: 'association-1',
      );
      final association = Association.empty().copyWith(
        id: 'association-1',
        name: 'BDE',
      );

      final found = advertiserOf(advert, [
        Association.empty().copyWith(id: 'association-0'),
        association,
      ]);

      expect(found, isNotNull);
      expect(found!.id, 'association-1');
      expect(found.name, 'BDE');
    });
  });
}
