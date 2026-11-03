import 'package:flutter_test/flutter_test.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralisation/class/section.dart';

/// The model branches the rest of the suite never reaches: every other
/// centralisation test parses or serialises instead of calling
/// `Module.copyWith`, and `Section`'s copyWith / empty / toString trio was
/// untouched (11 of its 17 lines).
void main() {
  Module module({
    String name = 'Billets',
    String description = 'Le module de billetterie',
    String icon = 'bird.png',
    String url = 'https://tickets.example.com',
    bool? liked,
  }) => Module(
    name: name,
    description: description,
    icon: icon,
    url: url,
    liked: liked,
  );

  group('Module', () {
    test('copyWith overrides only the given fields', () {
      final base = module(liked: true);

      final copy = base.copyWith(name: 'Vote');

      expect(copy.name, 'Vote');
      expect(copy.description, base.description);
      expect(copy.icon, base.icon);
      expect(copy.url, base.url);
      expect(
        copy.liked,
        isNull,
        reason:
            'copyWith passes `liked` through verbatim (not `?? this.liked`): '
            'omitting the argument clears it, and that is observable behavior '
            'the data layer round-trips through toJson (null → false).',
      );
    });

    test('copyWith keeps an explicit liked', () {
      final copy = module().copyWith(liked: true, icon: 'logo.svg');
      expect(copy.liked, true);
      expect(copy.icon, 'logo.svg');
      expect(copy.name, 'Billets');
    });

    test('empty() is blank, not liked, and serialises to a false like', () {
      final empty = Module.empty();

      expect(empty.name, isEmpty);
      expect(empty.description, isEmpty);
      expect(empty.icon, isEmpty);
      expect(empty.url, isEmpty);
      expect(empty.liked, false);
      expect(empty.toJson()['liked'], false);

      expect(
        empty.toString(),
        'Module{name: , description: , icon: , url: , liked: false}',
      );
    });
  });

  group('Section', () {
    Section section({String name = 'Clubs', bool expanded = false}) =>
        Section(name: name, moduleList: [module()], expanded: expanded);

    test('copyWith overrides name and expanded, keeps the module list', () {
      final base = section();

      final copy = base.copyWith(name: 'Services', expanded: true);

      expect(copy.name, 'Services');
      expect(copy.expanded, true);
      expect(
        identical(copy.moduleList, base.moduleList),
        isTrue,
        reason: 'the list identity is reused when moduleList is omitted',
      );
      // And a copy that replaces the list outright.
      final replaced = base.copyWith(moduleList: []);
      expect(replaced.moduleList, isEmpty);
      expect(replaced.name, base.name);
    });

    test('empty() is a blank expanded section', () {
      final empty = Section.empty();
      expect(empty.name, isEmpty);
      expect(empty.moduleList, isEmpty);
      expect(empty.expanded, true);
    });

    test('toString carries the name, modules and expanded flag', () {
      final s = section(name: 'Clubs', expanded: false);
      final text = s.toString();
      expect(text, contains('Section{name: Clubs'));
      expect(text, contains('Billets'));
      expect(text, contains('expanded: false'));
    });
  });
}
