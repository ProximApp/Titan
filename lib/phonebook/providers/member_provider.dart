import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class MemberProvider extends Notifier<MemberComplete> {
  @override
  MemberComplete build() {
    return EmptyModels.empty<MemberComplete>();
  }

  void setMember(MemberComplete i) {
    state = i;
  }
}

final memberProvider = NotifierProvider<MemberProvider, MemberComplete>(
  MemberProvider.new,
);
