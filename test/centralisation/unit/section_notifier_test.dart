import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/centralisation/class/module.dart';
import 'package:titan/centralisation/class/section.dart';
import 'package:titan/centralisation/providers/centralisation_section_provider.dart';
import 'package:titan/centralisation/repositories/section_repository.dart';

class FakeSectionRepository extends SectionRepository {
  final List<Section> sections;

  FakeSectionRepository(this.sections);

  @override
  Future<List<Section>> getSectionList() async => sections;
}

void main() {
  test('starts in AsyncValue.loading() before initState runs', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Reading the notifier through the container initializes it properly.
    container.read(sectionProvider.notifier);
    expect(
      container.read(sectionProvider),
      const AsyncValue<List<Section>>.loading(),
    );
    expect(container.read(sectionProvider.notifier).allSections, isEmpty);
    expect(container.read(sectionProvider.notifier).allModules, isEmpty);
    expect(container.read(sectionProvider.notifier).modulesLiked, isEmpty);
  });

  test(
    'initState moves state to AsyncValue.data with the repository sections',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sectionProvider.notifier);
      notifier.sectionRepository = FakeSectionRepository([
        Section(
          name: 'Section A',
          moduleList: [
            Module(
              name: 'Module A',
              description: 'desc A',
              icon: 'iconA',
              url: '/a',
            ),
          ],
          expanded: true,
        ),
      ]);
      await notifier.initState();
      // Assert on the real state. The previous expectation built
      // `AsyncValue.data([isA<Section>()]).whenData(...)`, which runs its own
      // callback against a list of MATCHERS while constructing the expected
      // value — so it always failed with "is not an instance of 'Section'"
      // no matter what the notifier returned (the state below was already
      // correct).
      final state = container.read(sectionProvider);
      expect(state, isA<AsyncData<List<Section>>>());
      final sections = state.requireValue;
      expect(sections, hasLength(1));
      expect(sections.single.name, 'Section A');
      expect(sections.single.moduleList.single.name, 'Module A');
      expect(notifier.allModules.map((m) => m.name).toList(growable: false), [
        'Module A',
      ]);
    },
  );

  test('allModules is the union of every section moduleList', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(sectionProvider.notifier);
    notifier.sectionRepository = FakeSectionRepository([
      Section(
        name: 'S1',
        moduleList: [
          Module(name: 'M1', description: 'd1', icon: 'i1', url: '/m1'),
          Module(name: 'M2', description: 'd2', icon: 'i2', url: '/m2'),
        ],
        expanded: true,
      ),
      Section(
        name: 'S2',
        moduleList: [
          Module(name: 'M3', description: 'd3', icon: 'i3', url: '/m3'),
        ],
        expanded: true,
      ),
    ]);
    await notifier.initState();
    expect(notifier.allModules.map((m) => m.name).toList(growable: false), [
      'M1',
      'M2',
      'M3',
    ]);
  });

  test('state stays loading when initState has not run', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sectionProvider.notifier);
    expect(
      container.read(sectionProvider),
      const AsyncValue<List<Section>>.loading(),
    );
  });
}
