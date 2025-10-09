import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/feed/class/news.dart';
import 'package:titan/tools/repository/repository.dart';

class NewsRepository extends Repository {
  @override
  // ignore: overridden_fields
  final ext = "feed/";

  Future<List<News>> getPublishedNews() async {
    return List<News>.from(
      (await getList(suffix: "news")).map((e) => News.fromJson(e)),
    );
  }

  Future<News> createNews(News news) async {
    return News.fromJson(await create(news.toJson(), suffix: "news"));
  }

  Future<List<News>> getAllNews() async {
    return List<News>.from(
      (await getList(suffix: "admin/news")).map((e) => News.fromJson(e)),
    );
  }

  Future<bool> approveNews(String id) async {
    return await create({}, suffix: "admin/news/$id/approve");
  }

  Future<bool> rejectNews(String id) async {
    return await create({}, suffix: "admin/news/$id/reject");
  }
}

final newsRepositoryProvider = Provider((ref) {
  final token = ref.watch(tokenProvider);
  return NewsRepository()..setToken(token);
});
