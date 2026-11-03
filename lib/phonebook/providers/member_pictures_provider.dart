import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/phonebook/providers/association_member_list_provider.dart';
import 'package:titan/tools/providers/map_provider.dart';

class MemberPicturesNotifier extends MapNotifier<MemberComplete, Image> {
  @override
  Map<MemberComplete, AsyncValue<List<Image>>?> build() {
    final members = ref.watch(associationMemberListProvider);
    final loaded = members.maybeWhen(
      data: (value) => value,
      orElse: () => <MemberComplete>[],
    );
    return {for (final member in loaded) member: null};
  }
}

final memberPicturesProvider =
    NotifierProvider<
      MemberPicturesNotifier,
      Map<MemberComplete, AsyncValue<List<Image>>?>
    >(() => MemberPicturesNotifier());
