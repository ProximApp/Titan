import 'package:chopper/chopper.dart' as chopper;
import 'package:http/http.dart' as http;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'repository_test_support.dart';

/// Stubs the shared connectivity endpoint used by the authenticated shell.
void stubInformation(MockOpenapi repository) {
  when(
    () => repository.informationGet(),
  ).thenAnswer((_) async => coreInformationResponse());
}

/// Stubs the feed endpoints the boot redirect chain touches.
void stubFeed(MockOpenapi repository) {
  when(
    () => repository.feedNewsGet(),
  ).thenAnswer((_) async => chopperListResponse<News>(<News>[]));
  when(
    () => repository.feedNewsNewsIdImageGet(newsId: any(named: 'newsId')),
  ).thenAnswer((_) async => fileNotFound());
}

/// The common "no image" response accepted by picture providers.
chopper.Response<List<int>> fileNotFound() => chopper.Response<List<int>>(
  http.Response('{"detail": "File does not exist"}', 404),
  [],
  error: 'File does not exist',
);

/// Stubs the profile picture fallback (a 404 means no bytes and selects the
/// placeholder asset).
void stubProfilePicture(MockOpenapi repository) {
  stubProfilePictureFor(repository);
}

/// The implementation shared by any test which needs the profile fallback.
void stubProfilePictureFor(MockOpenapi repository) {
  when(
    () => repository.usersUserIdProfilePictureGet(userId: any(named: 'userId')),
  ).thenAnswer((_) async => fileNotFound());
}

/// Stubs the background catalog reads performed by admin's routed parent.
void stubAdminMainPage(MockOpenapi repository) {
  when(() => repository.groupsGet()).thenAnswer(
    (_) async => chopperListResponse<CoreGroupSimple>(<CoreGroupSimple>[]),
  );
  when(
    () => repository.mypaymentBankAccountHolderGet(),
  ).thenAnswer((_) async => chopperResponse(Structure.empty()));
  when(
    () => repository.mypaymentStructuresGet(),
  ).thenAnswer((_) async => chopperListResponse<Structure>(<Structure>[]));
  when(
    () => repository.associationsGet(),
  ).thenAnswer((_) async => chopperListResponse<Association>(<Association>[]));
  when(() => repository.membershipsGet()).thenAnswer(
    (_) async => chopperListResponse<MembershipSimple>(<MembershipSimple>[]),
  );
}
