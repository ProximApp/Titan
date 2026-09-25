import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/repository/repository.dart';

import 'mock_openapi.dart';

export 'mock_openapi.dart' show MockOpenapi;
export 'package:mocktail/mocktail.dart'
    show Mock, when, any, registerFallbackValue;

/// General-purpose provider/repository harness for unit tests. Module fixtures
/// and plugin setup belong in their own test support files.
class RepositoryTestScaffold {
  RepositoryTestScaffold({MockOpenapi? repository})
    : repository = repository ?? MockOpenapi();

  final MockOpenapi repository;

  ProviderContainer makeContainer({List<dynamic> overrides = const []}) =>
      ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          ...overrides.cast(),
        ],
      );
}

/// Builds a minimal container with the shared repository override.
ProviderContainer makeRepositoryContainer({
  MockOpenapi? repository,
  List<dynamic> overrides = const [],
}) => ProviderContainer(
  overrides: [
    repositoryProvider.overrideWithValue(repository ?? MockOpenapi()),
    ...overrides,
  ],
);

/// Successful response for an endpoint returning a value.
chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response<T>(http.Response('body', 200), body);

/// Successful response for a list endpoint.
chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response<List<T>>(http.Response('body', 200), body);

/// Successful empty response for a void endpoint.
chopper.Response<void> chopperResponseVoid() =>
    chopper.Response<void>(http.Response('body', 200), null);

/// A non-success response suitable for repository error-path tests.
chopper.Response<T> chopperError<T>(
  int statusCode, {
  Object? error,
  String body = 'error',
}) => chopper.Response<T>(
  http.Response(body, statusCode),
  null,
  error: error ?? StateError('status $statusCode'),
);

/// Shared connectivity response used by authenticated app scaffolds.
chopper.Response<CoreInformation> coreInformationResponse({
  bool ready = true,
  String version = '1.0.0',
  int minimalTitanVersionCode = 1,
}) => chopperResponse(
  CoreInformation(
    ready: ready,
    version: version,
    minimalTitanVersionCode: minimalTitanVersionCode,
  ),
);
