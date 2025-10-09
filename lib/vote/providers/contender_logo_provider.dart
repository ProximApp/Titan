import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/vote/providers/contender_logos_provider.dart';
import 'package:titan/vote/repositories/contender_logo_repository.dart';

class ContenderLogoProvider extends SingleNotifier<Image> {
  late final ContenderLogoRepository contenderLogoRepository;
  late final ContenderLogoNotifier contenderLogosNotifier;

  @override
  AsyncValue<Image> build() {
    contenderLogoRepository = ref.watch(contenderLogoRepositoryProvider);
    contenderLogosNotifier = ref.watch(contenderLogosProvider.notifier);
    return const AsyncValue.loading();
  }

  Future<Image> getLogo(String id) async {
    return await contenderLogoRepository.getContenderLogo(id).then((image) {
      contenderLogosNotifier.setTData(id, AsyncData([image]));
      return image;
    });
  }

  Future<Image> updateLogo(String id, Uint8List bytes) async {
    final image = await contenderLogoRepository.addContenderLogo(bytes, id);
    contenderLogosNotifier.setTData(id, AsyncData([image]));
    return image;
  }
}

final contenderLogoProvider =
    NotifierProvider<ContenderLogoProvider, AsyncValue<Image>>(
      ContenderLogoProvider.new,
    );
