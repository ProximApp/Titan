import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registers this device with Firebase Cloud Messaging, completing once the
/// registration does.
///
/// This used to call `getToken(vapidKey: "")`, which firebase_messaging 17
/// deprecates in favour of `register()` / `onRegistered`. The token it
/// returned was never read: setupNotification only reacts to the completion,
/// then caches the registration date and refreshes the topics — so the
/// provider is a `Future<void>` rather than a token it never had to expose.
final firebaseTokenProvider = Provider<Future<void>>((ref) {
  return FirebaseMessaging.instance.register();
});
