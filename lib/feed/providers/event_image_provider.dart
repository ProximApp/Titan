import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/repository/file_response.dart';
import 'package:titan/tools/repository/repository.dart';

class EventImageNotifier extends SingleNotifier<Image> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<Image> build() {
    return const AsyncValue.loading();
  }

  Future<bool> addEventImage(String id, Uint8List bytes) async {
    // The response used to be discarded, so this ALWAYS answered true: a 4xx or
    // 5xx from the upload was reported as a success by its caller, and the
    // event kept a missing poster while the UI claimed everything was saved.
    final response = await repository.calendarEventsEventIdImagePost(
      eventId: id,
      image: bytes,
    );
    if (!response.isSuccessful) {
      return false;
    }
    state = AsyncData(Image.memory(bytes));
    return true;
  }

  void getEventImage(String id) async {
    final response = await repository.calendarEventsEventIdImageGet(
      eventId: id,
    );
    final bytes = response.fileBytes;
    state = AsyncData(
      bytes.isEmpty ? Image.asset(getTitanLogo()) : Image.memory(bytes),
    );
  }
}

final eventImageProvider =
    NotifierProvider<EventImageNotifier, AsyncValue<Image>>(
      EventImageNotifier.new,
    );
