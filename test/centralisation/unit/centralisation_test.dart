import 'package:flutter_test/flutter_test.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralassociation/class/asso.dart';
import 'package:titan/centralassociation/class/link.dart';

void main() {
  group('Module (centralisation)', () {
    test('parses from json', () {
      final module = Module.fromJson({
        'name': 'AMAP',
        'description': 'Paniers bio',
        'icon': 'amap.png',
        'url': 'https://amap.example.com',
        'liked': true,
      });

      expect(module.name, 'AMAP');
      expect(module.description, 'Paniers bio');
      expect(module.icon, 'amap.png');
      expect(module.url, 'https://amap.example.com');
      expect(module.liked, true);
    });

    test('toJson defaults liked to false', () {
      final module = Module.fromJson({
        'name': 'Cine',
        'description': 'Cinéma',
        'icon': 'cine.png',
        'url': 'https://cine.example.com',
      });

      final json = module.toJson();

      expect(json['liked'], false);
    });

    test('round-trips through toJson', () {
      final module = Module.fromJson({
        'name': 'Vote',
        'description': 'Campagnes',
        'icon': 'vote.png',
        'url': 'https://vote.example.com',
        'liked': true,
      });

      expect(module.toJson()['liked'], true);
      expect(module.toJson()['name'], 'Vote');
    });

    test('copyWith replaces only the given fields', () {
      final module = Module.fromJson({
        'name': 'Old',
        'description': 'Old desc',
        'icon': 'old.png',
        'url': 'https://old.example.com',
      });

      final copied = module.copyWith(name: 'New', liked: true);

      expect(copied.name, 'New');
      expect(copied.description, 'Old desc');
      expect(copied.icon, 'old.png');
      expect(copied.url, 'https://old.example.com');
      expect(copied.liked, true);
    });

    test('copyWith falls back to the original description', () {
      final module = Module.fromJson({
        'name': 'Fallback',
        'description': 'Real desc',
        'icon': 'a.png',
        'url': 'https://a.example.com',
      });

      final copied = module.copyWith();

      expect(copied.description, 'Real desc');
    });
  });

  group('Asso (centralassociation)', () {
    test('parses from json with links', () {
      final asso = Asso.fromJson({
        'name': 'BDE',
        'description': 'Bureau des étudiants',
        'icon': 'bde.png',
        'links': [
          {'name': 'Site', 'url': 'https://bde.example.com', 'icon': 'web.png'},
        ],
      });

      expect(asso.name, 'BDE');
      expect(asso.description, 'Bureau des étudiants');
      expect(asso.icon, 'bde.png');
      expect(asso.linkList, hasLength(1));
      expect(asso.linkList.first.name, 'Site');
      expect(asso.linkList.first.url, 'https://bde.example.com');
    });

    test('toString contains the name', () {
      final asso = Asso.fromJson({
        'name': 'BDF',
        'description': 'desc',
        'icon': 'i.png',
        'links': [],
      });

      expect(asso.toString(), contains('BDF'));
    });

    test('link parses from json', () {
      final link = Link.fromJson({
        'name': 'Instagram',
        'url': 'https://instagram.com/x',
        'icon': 'insta.png',
      });

      expect(link.name, 'Instagram');
      expect(link.url, 'https://instagram.com/x');
      expect(link.icon, 'insta.png');
    });
  });
}
