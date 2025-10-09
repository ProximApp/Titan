import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/class/purchase.dart';
import 'package:titan/tools/repository/repository.dart';

class UserPurchaseRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "cdr/me/";

  Future<List<Purchase>> getPurchaseList() async {
    return List<Purchase>.from(
      (await getList(suffix: "purchases/")).map((x) => Purchase.fromJson(x)),
    );
  }
}

final userPurchaseRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return UserPurchaseRepository()..setToken(token);
});
