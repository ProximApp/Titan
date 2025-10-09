import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/repository/logo_repository.dart';

class TombolaLogoRepository extends LogoRepository {
  @override
  // ignore: overridden_fields
  final ext = 'tombola/raffles/';

  Future<Image> getTombolaLogo(String id) async {
    final uint8List = await getLogo(id, suffix: "/logo");
    if (uint8List.isEmpty) {
      return Image.asset(getTitanLogo());
    }
    return Image.memory(uint8List);
  }

  Future<Image> addTombolaLogo(Uint8List bytes, String id) async {
    final uint8List = await addLogo(bytes, id, suffix: "/logo");
    return Image.memory(uint8List);
  }
}

final tombolaLogoRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return TombolaLogoRepository()..setToken(token);
});
