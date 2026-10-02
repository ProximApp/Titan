import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/service/class/message.dart';
import 'package:titan/service/local_notification_service.dart';
import 'package:titan/tools/functions.dart';

import '../../shared/app_scaffold.dart';

/// local_notification_service end-to-end: every plugin call goes through the
/// `dexterous.com/flutter/local_notifications` method channel, so a mock
/// handler there drives all the wrapper methods (init, show, periodic, image,
/// group, pending, cancel) without touching the platform. The click-to-route
/// half (provider map → QR.to) is exercised with one boot + QR.to journey:
/// `/advert` is the lightest mapped module route, and qlevar STRIPS the scheme
/// from `test.titan:///advert?...` before matching, so the advert route
/// actually mounts and its auth gate bounces the unauthenticated container to
/// /feed — the observable landing of the navigation.
///
/// The Android plugin dispatch is registered explicitly: in a test
/// environment no platform channel registers the platform implementation,
/// so `resolvePlatformSpecificImplementation<Android...>()` inside the
/// service would silently resolve to null (groupNotifications' no-op branch)
/// unless `registerWith()` installs it first.

/// Every method call the service made through the channel, in order.
List<MethodCall> channelCalls = <MethodCall>[];

/// Installs the mock channel handler. The handler itself lives in the
/// scaffold now (the FCM setup tests drive the same plugin channel).
void stubLocalNotifications({
  List<Map<String, Object?>> pending = const [],
  List<Map<String, Object?>> active = const [],
}) {
  channelCalls = stubLocalNotificationsChannel(
    pending: pending,
    active: active,
  );
}

LocalNotificationService makeService() {
  final service = LocalNotificationService();
  addTearDown(service.onNotificationClick.close);
  return service;
}

/// The JSON payload the service round-trips through the plugin.
String payloadOf({String? module, String? table}) => json.encode({
  'title': 'T',
  'content': 'C',
  'action_module': module,
  'action_table': table,
});

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // No test environment registers the plugin platform implementations.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  testWidgets(
    'clicking a mapped notification routes through the module provider map',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(
        () => scaffold.repository.notificationTopicsGet(),
      ).thenAnswer((_) async => chopperListResponse<models.TopicUser>([]));
      // The advert main page auto-loads both lists on mount.
      when(
        () => scaffold.repository.advertAdvertsGet(),
      ).thenAnswer((_) async => chopperListResponse<AdvertComplete>([]));
      when(
        () => scaffold.repository.associationsGet(),
      ).thenAnswer((_) async => chopperListResponse<Association>([]));

      await scaffold.pumpApp(tester, container, initialPath: '/settings');
      await settle(tester, frames: 8);
      expect(find.text('Account'), findsOneWidget);

      // handleAction('advert', 'advert') resolves AdvertRouter.root and the
      // listener navigates to
      // `test.titan:///advert?actionModule=advert&actionTable=advert`. Qlevar
      // strips the scheme before matching, so /advert mounts and its
      // authenticated gate bounces this container to /feed — the observable
      // landing of the navigation.
      final service = makeService();
      service.onNotificationClickListener(
        Message(
          title: 'Garage sale',
          content: 'This weekend',
          actionModule: 'advert',
          actionTable: 'advert',
        ),
      );
      await settle(tester, frames: 20);

      expect(QR.currentPath, '/feed');
      expect(find.text('Account'), findsNothing);
    },
  );

  testWidgets('init registers the plugin on the Android channel once', (
    tester,
  ) async {
    stubLocalNotifications();
    final service = makeService();

    await service.init();

    expect(channelCalls.map((c) => c.method), ['initialize']);
  });

  testWidgets('showNotification derives an int id and encodes the payload', (
    tester,
  ) async {
    stubLocalNotifications();
    final service = makeService();
    await service.init();

    await service.showNotification(
      Message(
        title: 'Hello',
        content: 'World',
        actionModule: 'advert',
        actionTable: 'advert',
      ),
    );

    final show = channelCalls.singleWhere((c) => c.method == 'show');
    final args = show.arguments as Map<Object?, Object?>;
    expect(args['title'], 'Hello');
    expect(args['body'], 'World');
    expect(args['id'], isA<int>());
    final decoded = json.decode(args['payload'] as String);
    expect(decoded['action_module'], 'advert');
    expect(decoded['action_table'], 'advert');
  });

  testWidgets('periodic, image, cancel and cancelAll reach the channel', (
    tester,
  ) async {
    stubLocalNotifications();
    final service = makeService();
    await service.init();

    await service.showPeriodicNotification(
      'abc',
      'Repeating',
      'Body',
      'payload',
      RepeatInterval.daily,
    );
    await service.showNotificationWithImage(
      'abc',
      'Big',
      'Style',
      'payload',
      'image.png',
      'icon.png',
    );
    await service.cancelNotificationById('abc');
    await service.cancelAllNotifications();

    expect(
      channelCalls.where((c) => c.method == 'periodicallyShow'),
      hasLength(1),
    );
    // The big-picture show carries the image paths through the style.
    final show = channelCalls.singleWhere((c) => c.method == 'show');
    expect(jsonEncode(show.arguments), contains('image.png'));
    expect(jsonEncode(show.arguments), contains('icon.png'));
    expect(channelCalls.where((c) => c.method == 'cancel'), hasLength(1));
    expect(channelCalls.where((c) => c.method == 'cancelAll'), hasLength(1));
  });

  testWidgets(
    'pending queries resolve the derived id, found and miss branches',
    (tester) async {
      final derivedId = generateIntFromString('abc');
      stubLocalNotifications(
        pending: [
          {
            'id': derivedId,
            'title': 'Pending title',
            'body': 'Pending',
            'payload': 'p',
          },
          {'id': 999, 'title': 'Other', 'body': 'Other', 'payload': 'o'},
        ],
      );
      final service = makeService();
      await service.init();

      final found = await service.getNotificationDetail('abc');
      expect(found, isNotNull);
      expect(found!.id, derivedId);
      expect(found.title, 'Pending title');

      // An id no pending request hashes to lands in the firstWhereOrNull
      // miss branch.
      final miss = await service.getNotificationDetail('no-such-id');
      expect(miss, isNull);

      final all = await service.pendingNotificationRequests();
      expect(all, hasLength(2));
    },
  );

  testWidgets('groupNotifications skips the summary when nothing is active', (
    tester,
  ) async {
    stubLocalNotifications(active: []);
    final service = makeService();
    await service.init();

    await service.groupNotifications();

    expect(
      channelCalls.where((c) => c.method == 'getActiveNotifications'),
      hasLength(1),
    );
    expect(channelCalls.where((c) => c.method == 'show'), isEmpty);
  });

  testWidgets('groupNotifications paints an inbox of the active titles', (
    tester,
  ) async {
    stubLocalNotifications(
      active: [
        {
          'id': 1,
          'channelId': 'channel',
          'groupKey': 'group',
          'tag': null,
          'title': 'First alert',
          'body': 'b1',
          'payload': null,
          'bigText': null,
        },
        {
          'id': 2,
          'channelId': 'channel',
          'groupKey': 'group',
          'tag': null,
          'title': 'Second alert',
          'body': 'b2',
          'payload': null,
          'bigText': null,
        },
      ],
    );
    final service = makeService();
    await service.init();

    await service.groupNotifications();

    expect(
      channelCalls.where((c) => c.method == 'createNotificationChannelGroup'),
      hasLength(1),
    );
    // The summary show: fixed id 0, empty title/body, and an inbox style
    // with one line per active notification ("n - 1 Updates").
    final show = channelCalls.singleWhere((c) => c.method == 'show');
    final args = show.arguments as Map<Object?, Object?>;
    expect(args['id'], 0);
    expect(args['title'], '');
    final encoded = jsonEncode(args);
    expect(encoded, contains('First alert'));
    expect(encoded, contains('Second alert'));
    expect(encoded, contains('1 Updates'));
  });

  testWidgets('onDidReceiveNotificationResponse decodes the payload once', (
    tester,
  ) async {
    stubLocalNotifications();
    final service = makeService();
    final received = <Message>[];
    final subscription = service.onNotificationClick.listen(received.add);
    addTearDown(subscription.cancel);

    // Any non-null module+table makes the constructor-subscribed listener
    // navigate (which needs a booted router), so this decode test uses a
    // payload without action fields: the stream still delivers the decoded
    // message.
    service.onDidReceiveNotificationResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payloadOf(),
      ),
    );
    await tester.pump();
    expect(received, hasLength(1));
    expect(received.single.title, 'T');
    expect(received.single.actionModule, isNull);

    // A null payload returns before the decode: nothing is pushed.
    service.onDidReceiveNotificationResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    await tester.pump();
    expect(received, hasLength(1));
  });

  testWidgets('the background response handler ignores null payloads', (
    tester,
  ) async {
    stubLocalNotifications();

    onDidReceiveBackgroundNotificationResponse(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    await tester.pump();

    // Early return: no navigation, no crash.
    expect(QR.currentPath, '/');
  });

  group('handleAction', () {
    test(
      'unknown module and unknown table both resolve to an empty path',
      () async {
        final service = makeService();
        expect(await service.handleAction('no-such-module', 'advert'), '');
        expect(await service.handleAction('advert', 'no-such-table'), '');
      },
    );

    test('a known module+table resolves to the module route', () async {
      final service = makeService();
      expect(await service.handleAction('advert', 'advert'), AdvertRouter.root);
    });
  });
}
