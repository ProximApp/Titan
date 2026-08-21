import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/providers/news_images_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/providers/single_notifier.dart';
import 'package:titan/tools/repository/file_response.dart';
import 'package:titan/tools/repository/repository.dart';

class NewsImageNotifier extends SingleNotifier<Image> {
  Openapi get repository => ref.watch(repositoryProvider);

  @override
  AsyncValue<Image> build() {
    return const AsyncValue.loading();
  }

  NewsImagesNotifier get newsImagesNotifier =>
      ref.watch(newsImagesProvider.notifier);

  Future<Image> getNewsImage(String id) async {
    final response = await repository.feedNewsNewsIdImageGet(newsId: id);
    final bytes = response.fileBytes;
    final image = bytes.isEmpty
        ? Image.asset(getTitanLogo())
        : Image.memory(bytes);
    newsImagesNotifier.setTData(id, AsyncData([image]));
    return image;
  }
}

final newsImageProvider =
    NotifierProvider<NewsImageNotifier, AsyncValue<Image>>(
      NewsImageNotifier.new,
    );
