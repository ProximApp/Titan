import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/map_provider.dart';

class ContenderLogoNotifier extends MapNotifier<String, Image> {}

final contenderLogosProvider =
    NotifierProvider<
      ContenderLogoNotifier,
      Map<String, AsyncValue<List<Image>>?>
    >(() => ContenderLogoNotifier());
