import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/user/repositories/profile_picture_repository.dart';

final profilePictureProvider =
    NotifierProvider<ProfilePictureNotifier, AsyncValue<Image>>(
      ProfilePictureNotifier.new,
    );

class ProfilePictureNotifier extends SingleNotifier<Image> {
  final ProfilePictureRepository profilePictureRepository =
      ProfilePictureRepository();

  @override
  AsyncValue<Image> build() {
    final token = ref.watch(tokenProvider);
    profilePictureRepository.setToken(token);
    return const AsyncLoading();
  }

  Future<Image> getProfilePicture(String profileId) async {
    return Image.memory(
      await profilePictureRepository.getProfilePicture(profileId),
    );
  }
}
