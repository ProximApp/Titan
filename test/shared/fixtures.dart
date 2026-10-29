import 'package:mocktail/mocktail.dart';
import 'package:titan/tools/exception.dart';

import '../generated/openapi_mock_factories.dart';
import 'app_scaffold.dart';

/// Cross-module test support only. Module-specific fixtures live next to
/// their module: `test/<module>/<module>_fixtures.dart`.
///
/// Shared generated OpenAPI model builders are available through this single
/// fixture library for every module's tests.
export '../generated/openapi_mock_factories.dart';
export 'provider_overrides.dart'
    show notifierBuildOverride, notifierBuildFactoryOverride;
export 'repository_stubs.dart'
    show
        fileNotFound,
        stubInformation,
        stubFeed,
        stubAdminMainPage,
        stubProfilePictureFor;
export 'repository_test_support.dart'
    show
        MockOpenapi,
        chopperResponse,
        chopperListResponse,
        chopperResponseVoid,
        chopperError,
        makeRepositoryContainer;

/// Registers generated OpenAPI model values as mocktail fallbacks.
void registerTestFallbackValues() {
  registerFallbackValue(MockAssociationGroupementBase.any);
  registerFallbackValue(MockLoaner.any);
  registerFallbackValue(MockLoanerBase.any);
  registerFallbackValue(MockLoanerUpdate.any);
}

/// The main admin gate group, aliased by the booking and raffle modules.
const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// Shared token-expiry error for notifier tests.
AppException tokenExpire() =>
    AppException(ErrorType.tokenExpire, 'token expired');

/// Standard initialization for an app-shell integration test.
void shellTestSetUp(IntegrationScaffold scaffold) => scaffold.shellSetUp();
