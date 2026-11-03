import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/vote/providers/section_id_provider.dart';
import 'package:titan/vote/providers/sections_provider.dart';

/// A section list pinned to one state, so the derived provider is exercised
/// without a repository (the real notifier fires `campaignSectionsGet`).
class _FixedSections extends SectionNotifier {
  _FixedSections(this.value);

  final AsyncValue<List<SectionComplete>> value;

  @override
  AsyncValue<List<SectionComplete>> build() => value;
}

void main() {
  group('sectionProvider', () {
    test('an absent id yields an empty section instead of throwing', () {
      final container = ProviderContainer(
        overrides: [
          sectionsProvider.overrideWith(
            () => _FixedSections(
              AsyncValue.data([
                SectionComplete.empty().copyWith(id: 's-1', name: 'Section 1'),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // A stale selection (the section was deleted, or the id came from a
      // previous list) used to reach `where(...).first`: `Bad state: No
      // element`, during a build.
      container.read(sectionIdProvider.notifier).setId('gone');
      expect(container.read(sectionProvider).id, '');
    });

    test('the selected id still resolves', () {
      final section = SectionComplete.empty().copyWith(
        id: 's-1',
        name: 'Section 1',
      );
      final container = ProviderContainer(
        overrides: [
          sectionsProvider.overrideWith(
            () => _FixedSections(
              AsyncValue.data([
                section,
                SectionComplete.empty().copyWith(id: 's-2'),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(sectionProvider).id, 's-1');
      container.read(sectionIdProvider.notifier).setId('s-2');
      expect(container.read(sectionProvider).id, 's-2');
    });

    test('an empty section list yields an empty section', () {
      final container = ProviderContainer(
        overrides: [
          sectionsProvider.overrideWith(
            () => _FixedSections(const AsyncValue.data(<SectionComplete>[])),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(sectionProvider).id, '');
    });
  });
}
