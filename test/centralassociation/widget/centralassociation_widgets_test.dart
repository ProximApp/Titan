import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/centralassociation/class/asso.dart';
import 'package:titan/centralassociation/class/link.dart';
import 'package:titan/centralassociation/router.dart';
import 'package:titan/centralassociation/ui/centralassociation.dart';
import 'package:titan/centralassociation/ui/pages/asso_list.dart';
import 'package:titan/centralassociation/ui/pages/link_card.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../shared/app_scaffold.dart';

/// Answers `openLink`'s platform queries: LinkCard.onPressed fires it on
/// tap, and `UrlLauncherPlatform.instance` is the seam it goes through.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  bool canLaunchResult = true;
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Asso fixtureAsso() => Asso.fromJson({
    'name': 'BDE',
    'description': 'Bureau des étudiants',
    'icon': 'bde.png',
    'links': [
      {'name': 'Site', 'url': 'https://bde.example.com', 'icon': 'web.png'},
      {'name': 'Insta', 'url': 'https://instagram.com/bde', 'icon': 'ig.svg'},
    ],
  });

  testWidgets('AssoList renders the association name and every link card', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      AssoList(asso: fixtureAsso()),
      container: container,
    );

    expect(find.text('BDE'), findsOneWidget);
    expect(find.byType(LinkCard), findsNWidgets(2));
    expect(find.text('Site'), findsOneWidget);
    expect(find.text('Insta'), findsOneWidget);
    // The .svg icon routes through flutter_svg, the .png one through
    // Image.network (both fed the scaffold's stubbed bytes).
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a link card launches its url externally', (
    tester,
  ) async {
    final original = UrlLauncherPlatform.instance;
    final fake = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = original);

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      LinkCard(
        link: Link(
          name: 'Site',
          url: 'https://bde.example.com',
          icon: 'web.png',
        ),
      ),
      container: container,
    );

    // pumpEventQueue would deadlock the test's fake clock — pump instead:
    // the openLink canLaunch/launch hops are plain microtasks.
    await tester.tap(find.byType(LinkCard));
    await tester.pump();
    await tester.pump();

    expect(fake.launched, ['https://bde.example.com']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the template stacks the top bar over its page content', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      const CentralassociationTemplate(child: Text('inner body')),
      container: container,
    );

    expect(find.text('myemapp'), findsOneWidget);
    expect(find.text('inner body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the module exposes its localized name and description', (
    tester,
  ) async {
    String? name;
    String? description;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = CentralassociationRouter.module.getName(context);
          description = CentralassociationRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
    );

    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
    expect(name, isNot(equals(description)));
    expect(tester.takeException(), isNull);
  });
}
