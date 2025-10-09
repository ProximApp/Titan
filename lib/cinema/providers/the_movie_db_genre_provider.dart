import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/cinema/class/the_movie_db_genre.dart';
import 'package:titan/cinema/repositories/the_movie_db_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class TheMovieDBGenreNotifier extends SingleNotifier<TheMovieDBMovie> {
  TheMovieDBRepository get theMoviesDBRepository =>
      ref.watch(theMovieDBRepository);

  @override
  AsyncValue<TheMovieDBMovie> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<TheMovieDBMovie>> loadMovie(String id) async {
    return await load(() => theMoviesDBRepository.getMovie(id));
  }
}

final theMovieDBMovieProvider =
    NotifierProvider<TheMovieDBGenreNotifier, AsyncValue<TheMovieDBMovie>>(
      () => TheMovieDBGenreNotifier(),
    );
