import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/repository/logo_repository.dart';

class ListLogoRepository extends LogoRepository {
  @override
  // ignore: overridden_fields
  final ext = 'campaign/lists/';

  Future<Image> getListLogo(String id) async {
    final bytes = await getLogo(id, suffix: "/logo");
    if (bytes.isEmpty) {
      return Image.asset(getTitanLogo());
    }
    return Image.memory(bytes);
  }

  Future<Image> addListLogo(Uint8List bytes, String id) async {
    return Image.memory(await addLogo(bytes, id, suffix: "/logo"));
  }
}

final listLogoRepositoryProvider = Provider<ListLogoRepository>((
  ref,
) {
  final token = ref.watch(tokenProvider);
  return ListLogoRepository()..setToken(token);
});
