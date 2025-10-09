import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class RolesTagsRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "phonebook/";

  Future<List<String>> getRolesTags() async {
    return List<String>.from((await getOne("roletags"))["tags"]);
  }
}

final rolesTagsRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return RolesTagsRepository()..setToken(token);
});
