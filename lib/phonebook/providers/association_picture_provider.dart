import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/phonebook/providers/associations_picture_map_provider.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/image_compression.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/repository/file_response.dart';
import 'package:titan/tools/repository/repository.dart';

class AssociationPictureProvider extends SingleNotifier<Image> {
  late final AssociationPictureMapNotifier associationPictureMapNotifier;
  final ImagePicker _picker = ImagePicker();

  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<Image> build() {
    associationPictureMapNotifier = ref.watch(
      associationPictureMapProvider.notifier,
    );
    return const AsyncLoading();
  }

  Future<Image> getAssociationPicture(String associationId) async {
    final response = await repository
        .phonebookAssociationsAssociationIdPictureGet(
          associationId: associationId,
        );
    final bytes = response.fileBytes;
    final image = bytes.isEmpty
        ? Image.asset(getTitanLogo())
        : Image.memory(bytes);
    associationPictureMapNotifier.setTData(associationId, AsyncData([image]));
    state = AsyncData(image);
    return image;
  }

  Future<bool?> setProfilePicture(
    ImageSource source,
    String associationId,
  ) async {
    final previousState = state;
    state = const AsyncLoading();
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 20,
    );
    if (image != null) {
      try {
        final bytes = await compressImageForUpload(await image.readAsBytes());
        if (bytes == null) {
          state = previousState;
          return false;
        }
        await repository.phonebookAssociationsAssociationIdPicturePost(
          associationId: associationId,
          image: bytes,
        );
        final i = Image.memory(bytes);
        state = AsyncValue.data(i);
        associationPictureMapNotifier.setTData(associationId, AsyncData([i]));
        return true;
      } catch (e) {
        state = previousState;
        return false;
      }
    }
    state = previousState;
    return null;
  }
}

final associationPictureProvider =
    NotifierProvider<AssociationPictureProvider, AsyncValue<Image>>(
      AssociationPictureProvider.new,
    );
