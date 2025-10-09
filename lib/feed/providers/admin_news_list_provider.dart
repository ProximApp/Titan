import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/class/news.dart';
import 'package:titan/feed/repositories/news_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class AdminNewsListNotifier extends ListNotifier<News> {
  NewsRepository get newsRepository => ref.watch(newsRepositoryProvider);

  @override
  AsyncValue<List<News>> build() {
    loadNewsList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<News>>> loadNewsList() async {
    return await loadList(newsRepository.getAllNews);
  }

  Future<bool> addNews(News news) async {
    return await add(newsRepository.createNews, news);
  }

  Future<bool> approveNews(News news) async {
    return await update(
      (news) => newsRepository.approveNews(news.id),
      (newsList, news) =>
          newsList..[newsList.indexWhere((d) => d.id == news.id)] = news,
      news,
    );
  }

  Future<bool> rejectNews(News news) async {
    return await update(
      (news) => newsRepository.rejectNews(news.id),
      (newsList, news) =>
          newsList..[newsList.indexWhere((d) => d.id == news.id)] = news,
      news,
    );
  }
}

final adminNewsListProvider =
    NotifierProvider<AdminNewsListNotifier, AsyncValue<List<News>>>(
      AdminNewsListNotifier.new,
    );
