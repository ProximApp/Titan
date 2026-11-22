import 'package:chopper/chopper.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/exception.dart';

abstract class SingleNotifierAPI<T> extends Notifier<AsyncValue<T>> {
  @override
  AsyncValue<T> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<T>> load(Future<Response<T>> Function() f) async {
    try {
      final response = await f();
      final data = response.body;
      if (response.isSuccessful && data != null) {
        // The fetch runs across an await, so the provider may have been
        // rebuilt or disposed while it was in flight: a late `state=`
        // write must not resurrect a dead notifier.
        final next = AsyncValue.data(data);
        if (ref.mounted) {
          state = next;
        }
        return next;
      } else {
        throw response.error!;
      }
    } catch (e) {
      final next = AsyncValue<T>.error(e, StackTrace.current);
      if (ref.mounted) {
        state = next;
      }
      if (e is AppException && e.type == ErrorType.tokenExpire) {
        rethrow;
      } else {
        return next;
      }
    }
  }

  Future<bool> add(Future<Response<T>> Function(T t) f, T t) async {
    return state.when(
      data: (d) async {
        try {
          final response = await f(t);
          final data = response.body;
          if (response.isSuccessful && data != null) {
            state = AsyncValue.data(data);
            return true;
          } else {
            throw response.error!;
          }
        } catch (error) {
          state = AsyncValue.data(d);
          if (error is AppException && error.type == ErrorType.tokenExpire) {
            rethrow;
          } else {
            return false;
          }
        }
      },
      error: (error, s) {
        if (error is AppException && error.type == ErrorType.tokenExpire) {
          throw error;
        } else {
          state = AsyncValue.error(error, s);
          return false;
        }
      },
      loading: () {
        state = const AsyncValue.error(
          "Cannot add while loading",
          StackTrace.empty,
        );
        return false;
      },
    );
  }

  Future<bool> update(Future<Response<dynamic>> Function() f, T t) async {
    return state.when(
      data: (d) async {
        try {
          final response = await f();
          if (response.isSuccessful) {
            state = AsyncValue.data(t);
            return true;
          } else {
            throw response.error!;
          }
        } catch (error) {
          state = AsyncValue.data(d);
          if (error is AppException && error.type == ErrorType.tokenExpire) {
            rethrow;
          } else {
            return false;
          }
        }
      },
      error: (error, s) {
        if (error is AppException && error.type == ErrorType.tokenExpire) {
          throw error;
        } else {
          state = AsyncValue.error(error, s);
          return false;
        }
      },
      loading: () {
        state = const AsyncValue.error(
          "Cannot update while loading",
          StackTrace.empty,
        );
        return false;
      },
    );
  }

  Future<bool> delete(Future<Response<dynamic>> Function() f) async {
    return state.when(
      data: (d) async {
        try {
          final response = await f();
          if (response.isSuccessful) {
            state = const AsyncValue.loading();
            return true;
          } else {
            throw response.error!;
          }
        } catch (error) {
          state = AsyncValue.data(d);
          if (error is AppException && error.type == ErrorType.tokenExpire) {
            rethrow;
          } else {
            return false;
          }
        }
      },
      error: (error, s) {
        if (error is AppException && error.type == ErrorType.tokenExpire) {
          throw error;
        } else {
          state = AsyncValue.error(error, s);
          return false;
        }
      },
      loading: () {
        state = const AsyncValue.error(
          "Cannot delete while loading",
          StackTrace.empty,
        );
        return false;
      },
    );
  }
}
