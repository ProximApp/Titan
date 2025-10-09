import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/raffle/class/prize.dart';
import 'package:titan/raffle/class/tickets.dart';
import 'package:titan/tools/repository/repository.dart';

class UserDetailRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "tombola/users";

  Future<List<Ticket>> getTicketsListByUserId(String userId) async {
    return List<Ticket>.from(
      (await getList(
        suffix: "/$userId/tickets",
      )).map((x) => Ticket.fromJson(x)),
    );
  }

  Future<List<Prize>> getLotListByUserId(String userId) async {
    return List<Prize>.from(
      (await getList(suffix: "/$userId/lot")).map((x) => Prize.fromJson(x)),
    );
  }
}

final userDetailRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return UserDetailRepository()..setToken(token);
});
