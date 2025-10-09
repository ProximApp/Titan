import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/phonebook/class/complete_member.dart';
import 'package:titan/tools/providers/map_provider.dart';

class MemberPicturesNotifier extends MapNotifier<CompleteMember, Image> {}

final memberPicturesProvider =
    NotifierProvider<
      MemberPicturesNotifier,
      Map<CompleteMember, AsyncValue<List<Image>>?>
    >(() => MemberPicturesNotifier());
