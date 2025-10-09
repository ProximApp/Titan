import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ScrollControllerNotifier extends Notifier<ScrollController> {
  @override
  ScrollController build() {
    return ScrollController();
  }
}

final scrollControllerProvider =
    NotifierProvider<ScrollControllerNotifier, ScrollController>(
      ScrollControllerNotifier.new,
    );
