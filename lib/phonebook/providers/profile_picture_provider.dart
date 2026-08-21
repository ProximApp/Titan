import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/repository/file_response.dart';
import 'package:titan/tools/repository/repository.dart';

final profilePictureProvider =
    NotifierProvider<ProfilePictureNotifier, AsyncValue<Image>>(
      ProfilePictureNotifier.new,
    );

class ProfilePictureNotifier extends SingleNotifier<Image> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<Image> build() {
    return const AsyncLoading();
  }

  Future<Image> getProfilePicture(String profileId) async {
    final response = await repository.usersUserIdProfilePictureGet(
      userId: profileId,
    );
    final bytes = response.fileBytes;
    return bytes.isEmpty ? Image.asset(getTitanLogo()) : Image.memory(bytes);
  }
}
