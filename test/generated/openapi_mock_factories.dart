library;
// coverage:ignore-file
// ignore_for_file: type=lint, unused_element

import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

// Auto-generated fake-factory accessors for generated OpenAPI models.
// A `MockX.any` is a deterministic inert value; `MockX.withFields(...)`
// lets a test override specific fields. These are fakes, not call-verifying
// mocks.

/// Fake factory for [AccessToken].
class MockAccessToken {
  MockAccessToken._();
  static AccessToken get any => AccessToken.empty();
  static AccessToken withFields({
    required String accessToken,
    required String tokenType,
  }) => AccessToken.empty().copyWith(
    accessToken: accessToken,
    tokenType: tokenType,
  );
}

/// Fake factory for [AdvertBase].
class MockAdvertBase {
  MockAdvertBase._();
  static AdvertBase get any => AdvertBase.empty();
  static AdvertBase withOnly({required String advertiserId}) =>
      MockAdvertBase.any.copyWith(advertiserId: advertiserId);

  static AdvertBase withFields({
    required String title,
    required String content,
    required String advertiserId,
    bool? postToFeed,
    required bool notification,
  }) => AdvertBase.empty().copyWith(
    title: title,
    content: content,
    advertiserId: advertiserId,
    postToFeed: postToFeed,
    notification: notification,
  );
}

/// Fake factory for [AdvertComplete].
class MockAdvertComplete {
  MockAdvertComplete._();
  static AdvertComplete get any => AdvertComplete.empty();
  static AdvertComplete withOnly({required String id}) =>
      MockAdvertComplete.any.copyWith(id: id);

  static AdvertComplete withFields({
    required String title,
    required String content,
    required String advertiserId,
    bool? postToFeed,
    required bool notification,
    required String id,
    DateTime? date,
  }) => AdvertComplete.empty().copyWith(
    title: title,
    content: content,
    advertiserId: advertiserId,
    postToFeed: postToFeed,
    notification: notification,
    id: id,
    date: date,
  );
}

/// Fake factory for [AdvertUpdate].
class MockAdvertUpdate {
  MockAdvertUpdate._();
  static AdvertUpdate get any => AdvertUpdate.empty();
  static AdvertUpdate withFields({String? title, String? content}) =>
      AdvertUpdate.empty().copyWith(title: title, content: content);
}

/// Fake factory for [Answer].
class MockAnswer {
  MockAnswer._();
  static Answer get any => Answer.empty();
  static Answer withOnly({required String id}) =>
      MockAnswer.any.copyWith(id: id);

  static Answer withFields({
    required String questionId,
    required dynamic answer,
    required String id,
  }) => Answer.empty().copyWith(questionId: questionId, answer: answer, id: id);
}

/// Fake factory for [AnswerBoolean].
class MockAnswerBoolean {
  MockAnswerBoolean._();
  static AnswerBoolean get any => AnswerBoolean.empty();
  static AnswerBoolean withFields({
    required String answerType,
    required bool answer,
  }) => AnswerBoolean.empty().copyWith(answerType: answerType, answer: answer);
}

/// Fake factory for [AnswerCreate].
class MockAnswerCreate {
  MockAnswerCreate._();
  static AnswerCreate get any => AnswerCreate.empty();
  static AnswerCreate withOnly({required String questionId}) =>
      MockAnswerCreate.any.copyWith(questionId: questionId);

  static AnswerCreate withFields({
    required String questionId,
    required dynamic answer,
  }) => AnswerCreate.empty().copyWith(questionId: questionId, answer: answer);
}

/// Fake factory for [AnswerNumber].
class MockAnswerNumber {
  MockAnswerNumber._();
  static AnswerNumber get any => AnswerNumber.empty();
  static AnswerNumber withFields({
    required String answerType,
    required int answer,
  }) => AnswerNumber.empty().copyWith(answerType: answerType, answer: answer);
}

/// Fake factory for [AnswerText].
class MockAnswerText {
  MockAnswerText._();
  static AnswerText get any => AnswerText.empty();
  static AnswerText withFields({
    required String answerType,
    required String answer,
  }) => AnswerText.empty().copyWith(answerType: answerType, answer: answer);
}

/// Fake factory for [Applicant].
class MockApplicant {
  MockApplicant._();
  static Applicant get any => Applicant.empty();
  static Applicant withOnly({required String id}) =>
      MockApplicant.any.copyWith(id: id);

  static Applicant withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    required String email,
    int? promo,
    String? phone,
  }) => Applicant.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    email: email,
    promo: promo,
    phone: phone,
  );
}

/// Fake factory for [Association].
class MockAssociation {
  MockAssociation._();
  static Association get any => Association.empty();
  static Association withOnly({required String id}) =>
      MockAssociation.any.copyWith(id: id);

  static Association withFields({
    required String name,
    required String groupId,
    required String id,
  }) => Association.empty().copyWith(name: name, groupId: groupId, id: id);
}

/// Fake factory for [AssociationComplete].
class MockAssociationComplete {
  MockAssociationComplete._();
  static AssociationComplete get any => AssociationComplete.empty();
  static AssociationComplete withOnly({required String id}) =>
      MockAssociationComplete.any.copyWith(id: id);

  static AssociationComplete withFields({
    required String name,
    required String groupementId,
    required int mandateYear,
    String? description,
    List<String>? associatedGroups,
    bool? deactivated,
    required String id,
  }) => AssociationComplete.empty().copyWith(
    name: name,
    groupementId: groupementId,
    mandateYear: mandateYear,
    description: description,
    associatedGroups: associatedGroups,
    deactivated: deactivated,
    id: id,
  );
}

/// Fake factory for [AssociationEdit].
class MockAssociationEdit {
  MockAssociationEdit._();
  static AssociationEdit get any => AssociationEdit.empty();
  static AssociationEdit withOnly({String? groupementId}) =>
      MockAssociationEdit.any.copyWith(groupementId: groupementId);

  static AssociationEdit withFields({
    String? name,
    String? groupementId,
    String? description,
    int? mandateYear,
  }) => AssociationEdit.empty().copyWith(
    name: name,
    groupementId: groupementId,
    description: description,
    mandateYear: mandateYear,
  );
}

/// Fake factory for [AssociationGroupement].
class MockAssociationGroupement {
  MockAssociationGroupement._();
  static AssociationGroupement get any => AssociationGroupement.empty();
  static AssociationGroupement withOnly({required String id}) =>
      MockAssociationGroupement.any.copyWith(id: id);

  static AssociationGroupement withFields({
    required String name,
    required String managerGroupId,
    required String id,
  }) => AssociationGroupement.empty().copyWith(
    name: name,
    managerGroupId: managerGroupId,
    id: id,
  );
}

/// Fake factory for [AssociationGroupementBase].
class MockAssociationGroupementBase {
  MockAssociationGroupementBase._();
  static AssociationGroupementBase get any => AssociationGroupementBase.empty();
  static AssociationGroupementBase withOnly({required String managerGroupId}) =>
      MockAssociationGroupementBase.any.copyWith(
        managerGroupId: managerGroupId,
      );

  static AssociationGroupementBase withFields({
    required String name,
    required String managerGroupId,
  }) => AssociationGroupementBase.empty().copyWith(
    name: name,
    managerGroupId: managerGroupId,
  );
}

/// Fake factory for [AssociationGroupsEdit].
class MockAssociationGroupsEdit {
  MockAssociationGroupsEdit._();
  static AssociationGroupsEdit get any => AssociationGroupsEdit.empty();
  static AssociationGroupsEdit withFields({List<String>? associatedGroups}) =>
      AssociationGroupsEdit.empty().copyWith(
        associatedGroups: associatedGroups,
      );
}

/// Fake factory for [AssociationUpdate].
class MockAssociationUpdate {
  MockAssociationUpdate._();
  static AssociationUpdate get any => AssociationUpdate.empty();
  static AssociationUpdate withOnly({String? groupId}) =>
      MockAssociationUpdate.any.copyWith(groupId: groupId);

  static AssociationUpdate withFields({String? name, String? groupId}) =>
      AssociationUpdate.empty().copyWith(name: name, groupId: groupId);
}

/// Fake factory for [BatchPurchase].
class MockBatchPurchase {
  MockBatchPurchase._();
  static BatchPurchase get any => BatchPurchase.empty();
  static BatchPurchase withOnly({required String productVariantId}) =>
      MockBatchPurchase.any.copyWith(productVariantId: productVariantId);

  static BatchPurchase withFields({
    required List<String> userEmails,
    required String productVariantId,
    required int quantity,
  }) => BatchPurchase.empty().copyWith(
    userEmails: userEmails,
    productVariantId: productVariantId,
    quantity: quantity,
  );
}

/// Fake factory for [BatchResult].
class MockBatchResult {
  MockBatchResult._();
  static BatchResult get any => BatchResult.empty();
  static BatchResult withFields({required Map<String, dynamic> failed}) =>
      BatchResult.empty().copyWith(failed: failed);
}

/// Fake factory for [BatchValidation].
class MockBatchValidation {
  MockBatchValidation._();
  static BatchValidation get any => BatchValidation.empty();
  static BatchValidation withOnly({required String productVariantId}) =>
      MockBatchValidation.any.copyWith(productVariantId: productVariantId);

  static BatchValidation withFields({
    required List<String> userEmails,
    required String productVariantId,
    required bool validated,
  }) => BatchValidation.empty().copyWith(
    userEmails: userEmails,
    productVariantId: productVariantId,
    validated: validated,
  );
}

/// Fake factory for [BodyPostAdvertAdvertsAdvertIdPicture].
class MockBodyPostAdvertAdvertsAdvertIdPicture {
  MockBodyPostAdvertAdvertsAdvertIdPicture._();
  static BodyPostAdvertAdvertsAdvertIdPicture get any =>
      BodyPostAdvertAdvertsAdvertIdPicture.empty();
  static BodyPostAdvertAdvertsAdvertIdPicture withFields({
    required String image,
  }) => BodyPostAdvertAdvertsAdvertIdPicture.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostAssociationsAssociationIdLogo].
class MockBodyPostAssociationsAssociationIdLogo {
  MockBodyPostAssociationsAssociationIdLogo._();
  static BodyPostAssociationsAssociationIdLogo get any =>
      BodyPostAssociationsAssociationIdLogo.empty();
  static BodyPostAssociationsAssociationIdLogo withFields({
    required String image,
  }) => BodyPostAssociationsAssociationIdLogo.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostAuthAuthorizationFlowAuthorizeValidation].
class MockBodyPostAuthAuthorizationFlowAuthorizeValidation {
  MockBodyPostAuthAuthorizationFlowAuthorizeValidation._();
  static BodyPostAuthAuthorizationFlowAuthorizeValidation get any =>
      BodyPostAuthAuthorizationFlowAuthorizeValidation.empty();
  static BodyPostAuthAuthorizationFlowAuthorizeValidation withOnly({
    required String clientId,
  }) => MockBodyPostAuthAuthorizationFlowAuthorizeValidation.any.copyWith(
    clientId: clientId,
  );

  static BodyPostAuthAuthorizationFlowAuthorizeValidation withFields({
    required String clientId,
    String? redirectUri,
    required String responseType,
    String? scope,
    String? state,
    String? nonce,
    String? codeChallenge,
    String? codeChallengeMethod,
    required String email,
    required String password,
  }) => BodyPostAuthAuthorizationFlowAuthorizeValidation.empty().copyWith(
    clientId: clientId,
    redirectUri: redirectUri,
    responseType: responseType,
    scope: scope,
    state: state,
    nonce: nonce,
    codeChallenge: codeChallenge,
    codeChallengeMethod: codeChallengeMethod,
    email: email,
    password: password,
  );
}

/// Fake factory for [BodyPostAuthAuthorize].
class MockBodyPostAuthAuthorize {
  MockBodyPostAuthAuthorize._();
  static BodyPostAuthAuthorize get any => BodyPostAuthAuthorize.empty();
  static BodyPostAuthAuthorize withOnly({required String clientId}) =>
      MockBodyPostAuthAuthorize.any.copyWith(clientId: clientId);

  static BodyPostAuthAuthorize withFields({
    required String responseType,
    required String clientId,
    required String redirectUri,
    String? scope,
    String? state,
    String? nonce,
    String? codeChallenge,
    String? codeChallengeMethod,
  }) => BodyPostAuthAuthorize.empty().copyWith(
    responseType: responseType,
    clientId: clientId,
    redirectUri: redirectUri,
    scope: scope,
    state: state,
    nonce: nonce,
    codeChallenge: codeChallenge,
    codeChallengeMethod: codeChallengeMethod,
  );
}

/// Fake factory for [BodyPostAuthIntrospect].
class MockBodyPostAuthIntrospect {
  MockBodyPostAuthIntrospect._();
  static BodyPostAuthIntrospect get any => BodyPostAuthIntrospect.empty();
  static BodyPostAuthIntrospect withOnly({String? clientId}) =>
      MockBodyPostAuthIntrospect.any.copyWith(clientId: clientId);

  static BodyPostAuthIntrospect withFields({
    required String token,
    String? tokenTypeHint,
    String? clientId,
    String? clientSecret,
  }) => BodyPostAuthIntrospect.empty().copyWith(
    token: token,
    tokenTypeHint: tokenTypeHint,
    clientId: clientId,
    clientSecret: clientSecret,
  );
}

/// Fake factory for [BodyPostAuthSimpleToken].
class MockBodyPostAuthSimpleToken {
  MockBodyPostAuthSimpleToken._();
  static BodyPostAuthSimpleToken get any => BodyPostAuthSimpleToken.empty();
  static BodyPostAuthSimpleToken withOnly({String? clientId}) =>
      MockBodyPostAuthSimpleToken.any.copyWith(clientId: clientId);

  static BodyPostAuthSimpleToken withFields({
    String? grantType,
    required String username,
    required String password,
    String? scope,
    String? clientId,
    String? clientSecret,
  }) => BodyPostAuthSimpleToken.empty().copyWith(
    grantType: grantType,
    username: username,
    password: password,
    scope: scope,
    clientId: clientId,
    clientSecret: clientSecret,
  );
}

/// Fake factory for [BodyPostAuthToken].
class MockBodyPostAuthToken {
  MockBodyPostAuthToken._();
  static BodyPostAuthToken get any => BodyPostAuthToken.empty();
  static BodyPostAuthToken withOnly({String? clientId}) =>
      MockBodyPostAuthToken.any.copyWith(clientId: clientId);

  static BodyPostAuthToken withFields({
    String? refreshToken,
    required String grantType,
    String? code,
    String? redirectUri,
    String? clientId,
    String? clientSecret,
    String? codeVerifier,
  }) => BodyPostAuthToken.empty().copyWith(
    refreshToken: refreshToken,
    grantType: grantType,
    code: code,
    redirectUri: redirectUri,
    clientId: clientId,
    clientSecret: clientSecret,
    codeVerifier: codeVerifier,
  );
}

/// Fake factory for [BodyPostCalendarEventsEventIdImage].
class MockBodyPostCalendarEventsEventIdImage {
  MockBodyPostCalendarEventsEventIdImage._();
  static BodyPostCalendarEventsEventIdImage get any =>
      BodyPostCalendarEventsEventIdImage.empty();
  static BodyPostCalendarEventsEventIdImage withFields({
    required String image,
  }) => BodyPostCalendarEventsEventIdImage.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostCampaignListsListIdLogo].
class MockBodyPostCampaignListsListIdLogo {
  MockBodyPostCampaignListsListIdLogo._();
  static BodyPostCampaignListsListIdLogo get any =>
      BodyPostCampaignListsListIdLogo.empty();
  static BodyPostCampaignListsListIdLogo withFields({required String image}) =>
      BodyPostCampaignListsListIdLogo.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostCinemaSessionsSessionIdPoster].
class MockBodyPostCinemaSessionsSessionIdPoster {
  MockBodyPostCinemaSessionsSessionIdPoster._();
  static BodyPostCinemaSessionsSessionIdPoster get any =>
      BodyPostCinemaSessionsSessionIdPoster.empty();
  static BodyPostCinemaSessionsSessionIdPoster withFields({
    required String image,
  }) => BodyPostCinemaSessionsSessionIdPoster.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostCompetitionParticipantsSportsSportIdCertificate].
class MockBodyPostCompetitionParticipantsSportsSportIdCertificate {
  MockBodyPostCompetitionParticipantsSportsSportIdCertificate._();
  static BodyPostCompetitionParticipantsSportsSportIdCertificate get any =>
      BodyPostCompetitionParticipantsSportsSportIdCertificate.empty();
  static BodyPostCompetitionParticipantsSportsSportIdCertificate withFields({
    required String certificate,
  }) => BodyPostCompetitionParticipantsSportsSportIdCertificate.empty()
      .copyWith(certificate: certificate);
}

/// Fake factory for [BodyPostGroupsGroupIdLogo].
class MockBodyPostGroupsGroupIdLogo {
  MockBodyPostGroupsGroupIdLogo._();
  static BodyPostGroupsGroupIdLogo get any => BodyPostGroupsGroupIdLogo.empty();
  static BodyPostGroupsGroupIdLogo withFields({required String image}) =>
      BodyPostGroupsGroupIdLogo.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostNotificationDevices].
class MockBodyPostNotificationDevices {
  MockBodyPostNotificationDevices._();
  static BodyPostNotificationDevices get any =>
      BodyPostNotificationDevices.empty();
  static BodyPostNotificationDevices withFields({
    required String firebaseToken,
  }) => BodyPostNotificationDevices.empty().copyWith(
    firebaseToken: firebaseToken,
  );
}

/// Fake factory for [BodyPostPhPaperIdPdf].
class MockBodyPostPhPaperIdPdf {
  MockBodyPostPhPaperIdPdf._();
  static BodyPostPhPaperIdPdf get any => BodyPostPhPaperIdPdf.empty();
  static BodyPostPhPaperIdPdf withFields({required String pdf}) =>
      BodyPostPhPaperIdPdf.empty().copyWith(pdf: pdf);
}

/// Fake factory for [BodyPostPhonebookAssociationsAssociationIdPicture].
class MockBodyPostPhonebookAssociationsAssociationIdPicture {
  MockBodyPostPhonebookAssociationsAssociationIdPicture._();
  static BodyPostPhonebookAssociationsAssociationIdPicture get any =>
      BodyPostPhonebookAssociationsAssociationIdPicture.empty();
  static BodyPostPhonebookAssociationsAssociationIdPicture withFields({
    required String image,
  }) => BodyPostPhonebookAssociationsAssociationIdPicture.empty().copyWith(
    image: image,
  );
}

/// Fake factory for [BodyPostRaidDocumentDocumentType].
class MockBodyPostRaidDocumentDocumentType {
  MockBodyPostRaidDocumentDocumentType._();
  static BodyPostRaidDocumentDocumentType get any =>
      BodyPostRaidDocumentDocumentType.empty();
  static BodyPostRaidDocumentDocumentType withFields({required String file}) =>
      BodyPostRaidDocumentDocumentType.empty().copyWith(file: file);
}

/// Fake factory for [BodyPostRecommendationRecommendationsRecommendationIdPicture].
class MockBodyPostRecommendationRecommendationsRecommendationIdPicture {
  MockBodyPostRecommendationRecommendationsRecommendationIdPicture._();
  static BodyPostRecommendationRecommendationsRecommendationIdPicture get any =>
      BodyPostRecommendationRecommendationsRecommendationIdPicture.empty();
  static BodyPostRecommendationRecommendationsRecommendationIdPicture
  withFields({required String image}) =>
      BodyPostRecommendationRecommendationsRecommendationIdPicture.empty()
          .copyWith(image: image);
}

/// Fake factory for [BodyPostTombolaPrizesPrizeIdPicture].
class MockBodyPostTombolaPrizesPrizeIdPicture {
  MockBodyPostTombolaPrizesPrizeIdPicture._();
  static BodyPostTombolaPrizesPrizeIdPicture get any =>
      BodyPostTombolaPrizesPrizeIdPicture.empty();
  static BodyPostTombolaPrizesPrizeIdPicture withFields({
    required String image,
  }) => BodyPostTombolaPrizesPrizeIdPicture.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostTombolaRafflesRaffleIdLogo].
class MockBodyPostTombolaRafflesRaffleIdLogo {
  MockBodyPostTombolaRafflesRaffleIdLogo._();
  static BodyPostTombolaRafflesRaffleIdLogo get any =>
      BodyPostTombolaRafflesRaffleIdLogo.empty();
  static BodyPostTombolaRafflesRaffleIdLogo withFields({
    required String image,
  }) => BodyPostTombolaRafflesRaffleIdLogo.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostUsersMeProfilePicture].
class MockBodyPostUsersMeProfilePicture {
  MockBodyPostUsersMeProfilePicture._();
  static BodyPostUsersMeProfilePicture get any =>
      BodyPostUsersMeProfilePicture.empty();
  static BodyPostUsersMeProfilePicture withFields({required String image}) =>
      BodyPostUsersMeProfilePicture.empty().copyWith(image: image);
}

/// Fake factory for [BodyPostUsersRecover].
class MockBodyPostUsersRecover {
  MockBodyPostUsersRecover._();
  static BodyPostUsersRecover get any => BodyPostUsersRecover.empty();
  static BodyPostUsersRecover withFields({required String email}) =>
      BodyPostUsersRecover.empty().copyWith(email: email);
}

/// Fake factory for [BookingBase].
class MockBookingBase {
  MockBookingBase._();
  static BookingBase get any => BookingBase.empty();
  static BookingBase withOnly({required String roomId}) =>
      MockBookingBase.any.copyWith(roomId: roomId);

  static BookingBase withFields({
    required String reason,
    required DateTime start,
    required DateTime end,
    required DateTime creation,
    String? note,
    required String roomId,
    required bool key,
    String? recurrenceRule,
    String? entity,
  }) => BookingBase.empty().copyWith(
    reason: reason,
    start: start,
    end: end,
    creation: creation,
    note: note,
    roomId: roomId,
    key: key,
    recurrenceRule: recurrenceRule,
    entity: entity,
  );
}

/// Fake factory for [BookingEdit].
class MockBookingEdit {
  MockBookingEdit._();
  static BookingEdit get any => BookingEdit.empty();
  static BookingEdit withOnly({String? roomId}) =>
      MockBookingEdit.any.copyWith(roomId: roomId);

  static BookingEdit withFields({
    String? reason,
    DateTime? start,
    DateTime? end,
    String? note,
    String? roomId,
    bool? key,
    String? recurrenceRule,
    String? entity,
  }) => BookingEdit.empty().copyWith(
    reason: reason,
    start: start,
    end: end,
    note: note,
    roomId: roomId,
    key: key,
    recurrenceRule: recurrenceRule,
    entity: entity,
  );
}

/// Fake factory for [BookingReturn].
class MockBookingReturn {
  MockBookingReturn._();
  static BookingReturn get any => BookingReturn.empty();
  static BookingReturn withOnly({required String id}) =>
      MockBookingReturn.any.copyWith(id: id);

  static BookingReturn withFields({
    required String reason,
    required DateTime start,
    required DateTime end,
    required DateTime creation,
    String? note,
    required String roomId,
    required bool key,
    String? recurrenceRule,
    String? entity,
    required String id,
    required enums.Decision decision,
    required String applicantId,
    required RoomComplete room,
  }) => BookingReturn.empty().copyWith(
    reason: reason,
    start: start,
    end: end,
    creation: creation,
    note: note,
    roomId: roomId,
    key: key,
    recurrenceRule: recurrenceRule,
    entity: entity,
    id: id,
    decision: decision,
    applicantId: applicantId,
    room: room,
  );
}

/// Fake factory for [BookingReturnApplicant].
class MockBookingReturnApplicant {
  MockBookingReturnApplicant._();
  static BookingReturnApplicant get any => BookingReturnApplicant.empty();
  static BookingReturnApplicant withOnly({required String id}) =>
      MockBookingReturnApplicant.any.copyWith(id: id);

  static BookingReturnApplicant withFields({
    required String reason,
    required DateTime start,
    required DateTime end,
    required DateTime creation,
    String? note,
    required String roomId,
    required bool key,
    String? recurrenceRule,
    String? entity,
    required String id,
    required enums.Decision decision,
    required String applicantId,
    required RoomComplete room,
    required Applicant applicant,
  }) => BookingReturnApplicant.empty().copyWith(
    reason: reason,
    start: start,
    end: end,
    creation: creation,
    note: note,
    roomId: roomId,
    key: key,
    recurrenceRule: recurrenceRule,
    entity: entity,
    id: id,
    decision: decision,
    applicantId: applicantId,
    room: room,
    applicant: applicant,
  );
}

/// Fake factory for [BookingReturnSimpleApplicant].
class MockBookingReturnSimpleApplicant {
  MockBookingReturnSimpleApplicant._();
  static BookingReturnSimpleApplicant get any =>
      BookingReturnSimpleApplicant.empty();
  static BookingReturnSimpleApplicant withOnly({required String id}) =>
      MockBookingReturnSimpleApplicant.any.copyWith(id: id);

  static BookingReturnSimpleApplicant withFields({
    required String reason,
    required DateTime start,
    required DateTime end,
    required DateTime creation,
    String? note,
    required String roomId,
    required bool key,
    String? recurrenceRule,
    String? entity,
    required String id,
    required enums.Decision decision,
    required String applicantId,
    required RoomComplete room,
    required CoreUserSimple applicant,
  }) => BookingReturnSimpleApplicant.empty().copyWith(
    reason: reason,
    start: start,
    end: end,
    creation: creation,
    note: note,
    roomId: roomId,
    key: key,
    recurrenceRule: recurrenceRule,
    entity: entity,
    id: id,
    decision: decision,
    applicantId: applicantId,
    room: room,
    applicant: applicant,
  );
}

/// Fake factory for [CashEdit].
class MockCashEdit {
  MockCashEdit._();
  static CashEdit get any => CashEdit.empty();
  static CashEdit withFields({required int balance}) =>
      CashEdit.empty().copyWith(balance: balance);
}

/// Fake factory for [Category].
class MockCategory {
  MockCategory._();
  static Category get any => Category.empty();
  static Category withOnly({required String id}) =>
      MockCategory.any.copyWith(id: id);

  static Category withFields({
    required String id,
    required String eventId,
    required String name,
    required int price,
    String? requiredMembership,
    required bool disabled,
  }) => Category.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    price: price,
    requiredMembership: requiredMembership,
    disabled: disabled,
  );
}

/// Fake factory for [CategoryAdmin].
class MockCategoryAdmin {
  MockCategoryAdmin._();
  static CategoryAdmin get any => CategoryAdmin.empty();
  static CategoryAdmin withOnly({required String id}) =>
      MockCategoryAdmin.any.copyWith(id: id);

  static CategoryAdmin withFields({
    required String id,
    required String eventId,
    required String name,
    required int price,
    String? requiredMembership,
    required bool disabled,
    int? quota,
    required int ticketsInCheckout,
    required int ticketsSold,
  }) => CategoryAdmin.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    price: price,
    requiredMembership: requiredMembership,
    disabled: disabled,
    quota: quota,
    ticketsInCheckout: ticketsInCheckout,
    ticketsSold: ticketsSold,
  );
}

/// Fake factory for [CategoryComplete].
class MockCategoryComplete {
  MockCategoryComplete._();
  static CategoryComplete get any => CategoryComplete.empty();
  static CategoryComplete withOnly({required String id}) =>
      MockCategoryComplete.any.copyWith(id: id);

  static CategoryComplete withFields({
    required String id,
    required String eventId,
    required String name,
    required int price,
    String? requiredMembership,
    required bool disabled,
    int? quota,
  }) => CategoryComplete.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    price: price,
    requiredMembership: requiredMembership,
    disabled: disabled,
    quota: quota,
  );
}

/// Fake factory for [CategoryCreate].
class MockCategoryCreate {
  MockCategoryCreate._();
  static CategoryCreate get any => CategoryCreate.empty();
  static CategoryCreate withFields({
    required String name,
    required int price,
    int? quota,
    String? requiredMembership,
  }) => CategoryCreate.empty().copyWith(
    name: name,
    price: price,
    quota: quota,
    requiredMembership: requiredMembership,
  );
}

/// Fake factory for [CategoryPublic].
class MockCategoryPublic {
  MockCategoryPublic._();
  static CategoryPublic get any => CategoryPublic.empty();
  static CategoryPublic withOnly({required String id}) =>
      MockCategoryPublic.any.copyWith(id: id);

  static CategoryPublic withFields({
    required String id,
    required String eventId,
    required String name,
    required int price,
    String? requiredMembership,
    required bool disabled,
    required bool soldOut,
  }) => CategoryPublic.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    price: price,
    requiredMembership: requiredMembership,
    disabled: disabled,
    soldOut: soldOut,
  );
}

/// Fake factory for [CategoryUpdate].
class MockCategoryUpdate {
  MockCategoryUpdate._();
  static CategoryUpdate get any => CategoryUpdate.empty();
  static CategoryUpdate withFields({
    String? name,
    int? price,
    int? quota,
    String? requiredMembership,
    bool? disabled,
  }) => CategoryUpdate.empty().copyWith(
    name: name,
    price: price,
    quota: quota,
    requiredMembership: requiredMembership,
    disabled: disabled,
  );
}

/// Fake factory for [CdrUser].
class MockCdrUser {
  MockCdrUser._();
  static CdrUser get any => CdrUser.empty();
  static CdrUser withOnly({required String id}) =>
      MockCdrUser.any.copyWith(id: id);

  static CdrUser withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    CurriculumComplete? curriculum,
    int? promo,
    required String email,
    DateTime? birthday,
    String? phone,
    String? floor,
  }) => CdrUser.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    curriculum: curriculum,
    promo: promo,
    email: email,
    birthday: birthday,
    phone: phone,
    floor: floor,
  );
}

/// Fake factory for [CdrUserPreview].
class MockCdrUserPreview {
  MockCdrUserPreview._();
  static CdrUserPreview get any => CdrUserPreview.empty();
  static CdrUserPreview withOnly({required String id}) =>
      MockCdrUserPreview.any.copyWith(id: id);

  static CdrUserPreview withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    CurriculumComplete? curriculum,
    int? promo,
  }) => CdrUserPreview.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    curriculum: curriculum,
    promo: promo,
  );
}

/// Fake factory for [CdrUserUpdate].
class MockCdrUserUpdate {
  MockCdrUserUpdate._();
  static CdrUserUpdate get any => CdrUserUpdate.empty();
  static CdrUserUpdate withFields({
    int? promo,
    String? nickname,
    String? email,
    DateTime? birthday,
    String? phone,
    String? floor,
  }) => CdrUserUpdate.empty().copyWith(
    promo: promo,
    nickname: nickname,
    email: email,
    birthday: birthday,
    phone: phone,
    floor: floor,
  );
}

/// Fake factory for [CdrYear].
class MockCdrYear {
  MockCdrYear._();
  static CdrYear get any => CdrYear.empty();
  static CdrYear withFields({int? year}) =>
      CdrYear.empty().copyWith(year: year);
}

/// Fake factory for [ChangePasswordRequest].
class MockChangePasswordRequest {
  MockChangePasswordRequest._();
  static ChangePasswordRequest get any => ChangePasswordRequest.empty();
  static ChangePasswordRequest withFields({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) => ChangePasswordRequest.empty().copyWith(
    email: email,
    oldPassword: oldPassword,
    newPassword: newPassword,
  );
}

/// Fake factory for [Checkout].
class MockCheckout {
  MockCheckout._();
  static Checkout get any => Checkout.empty();
  static Checkout withOnly({required String categoryId}) =>
      MockCheckout.any.copyWith(categoryId: categoryId);

  static Checkout withFields({
    required String categoryId,
    required String sessionId,
    required List<AnswerCreate> answers,
    required enums.RequestType mypaymentRequestMethod,
    required String mypaymentTransferRedirectUrl,
  }) => Checkout.empty().copyWith(
    categoryId: categoryId,
    sessionId: sessionId,
    answers: answers,
    mypaymentRequestMethod: mypaymentRequestMethod,
    mypaymentTransferRedirectUrl: mypaymentTransferRedirectUrl,
  );
}

/// Fake factory for [CheckoutResponse].
class MockCheckoutResponse {
  MockCheckoutResponse._();
  static CheckoutResponse get any => CheckoutResponse.empty();
  static CheckoutResponse withFields({
    required int price,
    required DateTime expiration,
    String? paymentUrl,
  }) => CheckoutResponse.empty().copyWith(
    price: price,
    expiration: expiration,
    paymentUrl: paymentUrl,
  );
}

/// Fake factory for [CineSessionBase].
class MockCineSessionBase {
  MockCineSessionBase._();
  static CineSessionBase get any => CineSessionBase.empty();
  static CineSessionBase withFields({
    required DateTime start,
    required int duration,
    required String name,
    required String overview,
    String? genre,
    String? tagline,
  }) => CineSessionBase.empty().copyWith(
    start: start,
    duration: duration,
    name: name,
    overview: overview,
    genre: genre,
    tagline: tagline,
  );
}

/// Fake factory for [CineSessionComplete].
class MockCineSessionComplete {
  MockCineSessionComplete._();
  static CineSessionComplete get any => CineSessionComplete.empty();
  static CineSessionComplete withOnly({required String id}) =>
      MockCineSessionComplete.any.copyWith(id: id);

  static CineSessionComplete withFields({
    required DateTime start,
    required int duration,
    required String name,
    required String overview,
    String? genre,
    String? tagline,
    required String id,
  }) => CineSessionComplete.empty().copyWith(
    start: start,
    duration: duration,
    name: name,
    overview: overview,
    genre: genre,
    tagline: tagline,
    id: id,
  );
}

/// Fake factory for [CineSessionUpdate].
class MockCineSessionUpdate {
  MockCineSessionUpdate._();
  static CineSessionUpdate get any => CineSessionUpdate.empty();
  static CineSessionUpdate withFields({
    String? name,
    DateTime? start,
    int? duration,
    String? overview,
    String? genre,
    String? tagline,
  }) => CineSessionUpdate.empty().copyWith(
    name: name,
    start: start,
    duration: duration,
    overview: overview,
    genre: genre,
    tagline: tagline,
  );
}

/// Fake factory for [CompetitionEdition].
class MockCompetitionEdition {
  MockCompetitionEdition._();
  static CompetitionEdition get any => CompetitionEdition.empty();
  static CompetitionEdition withOnly({required String id}) =>
      MockCompetitionEdition.any.copyWith(id: id);

  static CompetitionEdition withFields({
    required String name,
    required int year,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    bool? inscriptionEnabled,
    required String id,
  }) => CompetitionEdition.empty().copyWith(
    name: name,
    year: year,
    startDate: startDate,
    endDate: endDate,
    active: active,
    inscriptionEnabled: inscriptionEnabled,
    id: id,
  );
}

/// Fake factory for [CompetitionEditionBase].
class MockCompetitionEditionBase {
  MockCompetitionEditionBase._();
  static CompetitionEditionBase get any => CompetitionEditionBase.empty();
  static CompetitionEditionBase withFields({
    required String name,
    required int year,
    required DateTime startDate,
    required DateTime endDate,
    bool? active,
    bool? inscriptionEnabled,
  }) => CompetitionEditionBase.empty().copyWith(
    name: name,
    year: year,
    startDate: startDate,
    endDate: endDate,
    active: active,
    inscriptionEnabled: inscriptionEnabled,
  );
}

/// Fake factory for [CompetitionEditionEdit].
class MockCompetitionEditionEdit {
  MockCompetitionEditionEdit._();
  static CompetitionEditionEdit get any => CompetitionEditionEdit.empty();
  static CompetitionEditionEdit withFields({
    String? name,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
  }) => CompetitionEditionEdit.empty().copyWith(
    name: name,
    year: year,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Fake factory for [CompetitionUser].
class MockCompetitionUser {
  MockCompetitionUser._();
  static CompetitionUser get any => CompetitionUser.empty();
  static CompetitionUser withOnly({required String userId}) =>
      MockCompetitionUser.any.copyWith(userId: userId);

  static CompetitionUser withFields({
    required enums.SportCategory sportCategory,
    bool? isPompom,
    bool? isFanfare,
    bool? isCameraman,
    bool? isAthlete,
    bool? allowPictures,
    required String userId,
    required String editionId,
    required DateTime createdAt,
    bool? validated,
    required CoreUser user,
  }) => CompetitionUser.empty().copyWith(
    sportCategory: sportCategory,
    isPompom: isPompom,
    isFanfare: isFanfare,
    isCameraman: isCameraman,
    isAthlete: isAthlete,
    allowPictures: allowPictures,
    userId: userId,
    editionId: editionId,
    createdAt: createdAt,
    validated: validated,
    user: user,
  );
}

/// Fake factory for [CompetitionUserBase].
class MockCompetitionUserBase {
  MockCompetitionUserBase._();
  static CompetitionUserBase get any => CompetitionUserBase.empty();
  static CompetitionUserBase withFields({
    required enums.SportCategory sportCategory,
    bool? isPompom,
    bool? isFanfare,
    bool? isCameraman,
    bool? isAthlete,
    bool? allowPictures,
  }) => CompetitionUserBase.empty().copyWith(
    sportCategory: sportCategory,
    isPompom: isPompom,
    isFanfare: isFanfare,
    isCameraman: isCameraman,
    isAthlete: isAthlete,
    allowPictures: allowPictures,
  );
}

/// Fake factory for [CompetitionUserEdit].
class MockCompetitionUserEdit {
  MockCompetitionUserEdit._();
  static CompetitionUserEdit get any => CompetitionUserEdit.empty();
  static CompetitionUserEdit withFields({
    enums.SportCategory? sportCategory,
    bool? validated,
    bool? isPompom,
    bool? isFanfare,
    bool? isCameraman,
    bool? isAthlete,
    bool? allowPictures,
  }) => CompetitionUserEdit.empty().copyWith(
    sportCategory: sportCategory,
    validated: validated,
    isPompom: isPompom,
    isFanfare: isFanfare,
    isCameraman: isCameraman,
    isAthlete: isAthlete,
    allowPictures: allowPictures,
  );
}

/// Fake factory for [CompetitionUserSimple].
class MockCompetitionUserSimple {
  MockCompetitionUserSimple._();
  static CompetitionUserSimple get any => CompetitionUserSimple.empty();
  static CompetitionUserSimple withOnly({required String userId}) =>
      MockCompetitionUserSimple.any.copyWith(userId: userId);

  static CompetitionUserSimple withFields({
    required enums.SportCategory sportCategory,
    bool? isPompom,
    bool? isFanfare,
    bool? isCameraman,
    bool? isAthlete,
    bool? allowPictures,
    required String userId,
    required String editionId,
    required DateTime createdAt,
    bool? validated,
  }) => CompetitionUserSimple.empty().copyWith(
    sportCategory: sportCategory,
    isPompom: isPompom,
    isFanfare: isFanfare,
    isCameraman: isCameraman,
    isAthlete: isAthlete,
    allowPictures: allowPictures,
    userId: userId,
    editionId: editionId,
    createdAt: createdAt,
    validated: validated,
  );
}

/// Fake factory for [CoreAccountTypePermission].
class MockCoreAccountTypePermission {
  MockCoreAccountTypePermission._();
  static CoreAccountTypePermission get any => CoreAccountTypePermission.empty();
  static CoreAccountTypePermission withOnly({required String permissionName}) =>
      MockCoreAccountTypePermission.any.copyWith(
        permissionName: permissionName,
      );

  static CoreAccountTypePermission withFields({
    required String permissionName,
    required enums.AccountType accountType,
  }) => CoreAccountTypePermission.empty().copyWith(
    permissionName: permissionName,
    accountType: accountType,
  );
}

/// Fake factory for [CoreBatchDeleteMembership].
class MockCoreBatchDeleteMembership {
  MockCoreBatchDeleteMembership._();
  static CoreBatchDeleteMembership get any => CoreBatchDeleteMembership.empty();
  static CoreBatchDeleteMembership withOnly({required String groupId}) =>
      MockCoreBatchDeleteMembership.any.copyWith(groupId: groupId);

  static CoreBatchDeleteMembership withFields({required String groupId}) =>
      CoreBatchDeleteMembership.empty().copyWith(groupId: groupId);
}

/// Fake factory for [CoreBatchMembership].
class MockCoreBatchMembership {
  MockCoreBatchMembership._();
  static CoreBatchMembership get any => CoreBatchMembership.empty();
  static CoreBatchMembership withOnly({required String groupId}) =>
      MockCoreBatchMembership.any.copyWith(groupId: groupId);

  static CoreBatchMembership withFields({
    required List<String> userEmails,
    required String groupId,
    String? description,
  }) => CoreBatchMembership.empty().copyWith(
    userEmails: userEmails,
    groupId: groupId,
    description: description,
  );
}

/// Fake factory for [CoreBatchUserCreateRequest].
class MockCoreBatchUserCreateRequest {
  MockCoreBatchUserCreateRequest._();
  static CoreBatchUserCreateRequest get any =>
      CoreBatchUserCreateRequest.empty();
  static CoreBatchUserCreateRequest withOnly({String? defaultGroupId}) =>
      MockCoreBatchUserCreateRequest.any.copyWith(
        defaultGroupId: defaultGroupId,
      );

  static CoreBatchUserCreateRequest withFields({
    required String email,
    String? defaultGroupId,
  }) => CoreBatchUserCreateRequest.empty().copyWith(
    email: email,
    defaultGroupId: defaultGroupId,
  );
}

/// Fake factory for [CoreGroup].
class MockCoreGroup {
  MockCoreGroup._();
  static CoreGroup get any => CoreGroup.empty();
  static CoreGroup withOnly({required String id}) =>
      MockCoreGroup.any.copyWith(id: id);

  static CoreGroup withFields({
    required String name,
    String? description,
    required String id,
    List<CoreUserSimple>? members,
  }) => CoreGroup.empty().copyWith(
    name: name,
    description: description,
    id: id,
    members: members,
  );
}

/// Fake factory for [CoreGroupCreate].
class MockCoreGroupCreate {
  MockCoreGroupCreate._();
  static CoreGroupCreate get any => CoreGroupCreate.empty();
  static CoreGroupCreate withFields({
    required String name,
    String? description,
  }) => CoreGroupCreate.empty().copyWith(name: name, description: description);
}

/// Fake factory for [CoreGroupPermission].
class MockCoreGroupPermission {
  MockCoreGroupPermission._();
  static CoreGroupPermission get any => CoreGroupPermission.empty();
  static CoreGroupPermission withOnly({required String permissionName}) =>
      MockCoreGroupPermission.any.copyWith(permissionName: permissionName);

  static CoreGroupPermission withFields({
    required String permissionName,
    required String groupId,
  }) => CoreGroupPermission.empty().copyWith(
    permissionName: permissionName,
    groupId: groupId,
  );
}

/// Fake factory for [CoreGroupSimple].
class MockCoreGroupSimple {
  MockCoreGroupSimple._();
  static CoreGroupSimple get any => CoreGroupSimple.empty();
  static CoreGroupSimple withOnly({required String id}) =>
      MockCoreGroupSimple.any.copyWith(id: id);

  static CoreGroupSimple withFields({
    required String name,
    String? description,
    required String id,
  }) => CoreGroupSimple.empty().copyWith(
    name: name,
    description: description,
    id: id,
  );
}

/// Fake factory for [CoreGroupUpdate].
class MockCoreGroupUpdate {
  MockCoreGroupUpdate._();
  static CoreGroupUpdate get any => CoreGroupUpdate.empty();
  static CoreGroupUpdate withFields({String? name, String? description}) =>
      CoreGroupUpdate.empty().copyWith(name: name, description: description);
}

/// Fake factory for [CoreInformation].
class MockCoreInformation {
  MockCoreInformation._();
  static CoreInformation get any => CoreInformation.empty();
  static CoreInformation withFields({
    required bool ready,
    required String version,
    required int minimalTitanVersionCode,
  }) => CoreInformation.empty().copyWith(
    ready: ready,
    version: version,
    minimalTitanVersionCode: minimalTitanVersionCode,
  );
}

/// Fake factory for [CoreMembership].
class MockCoreMembership {
  MockCoreMembership._();
  static CoreMembership get any => CoreMembership.empty();
  static CoreMembership withOnly({required String userId}) =>
      MockCoreMembership.any.copyWith(userId: userId);

  static CoreMembership withFields({
    required String userId,
    required String groupId,
    String? description,
  }) => CoreMembership.empty().copyWith(
    userId: userId,
    groupId: groupId,
    description: description,
  );
}

/// Fake factory for [CoreMembershipDelete].
class MockCoreMembershipDelete {
  MockCoreMembershipDelete._();
  static CoreMembershipDelete get any => CoreMembershipDelete.empty();
  static CoreMembershipDelete withOnly({required String userId}) =>
      MockCoreMembershipDelete.any.copyWith(userId: userId);

  static CoreMembershipDelete withFields({
    required String userId,
    required String groupId,
  }) => CoreMembershipDelete.empty().copyWith(userId: userId, groupId: groupId);
}

/// Fake factory for [CorePermission].
class MockCorePermission {
  MockCorePermission._();
  static CorePermission get any => CorePermission.empty();
  static CorePermission withOnly({required String permissionName}) =>
      MockCorePermission.any.copyWith(permissionName: permissionName);

  static CorePermission withFields({
    required String permissionName,
    required List<String> groups,
    required List<enums.AccountType> accountTypes,
  }) => CorePermission.empty().copyWith(
    permissionName: permissionName,
    groups: groups,
    accountTypes: accountTypes,
  );
}

/// Fake factory for [CoreSchool].
class MockCoreSchool {
  MockCoreSchool._();
  static CoreSchool get any => CoreSchool.empty();
  static CoreSchool withOnly({required String id}) =>
      MockCoreSchool.any.copyWith(id: id);

  static CoreSchool withFields({
    required String name,
    required String emailRegex,
    required String id,
  }) => CoreSchool.empty().copyWith(name: name, emailRegex: emailRegex, id: id);
}

/// Fake factory for [CoreSchoolBase].
class MockCoreSchoolBase {
  MockCoreSchoolBase._();
  static CoreSchoolBase get any => CoreSchoolBase.empty();
  static CoreSchoolBase withFields({
    required String name,
    required String emailRegex,
  }) => CoreSchoolBase.empty().copyWith(name: name, emailRegex: emailRegex);
}

/// Fake factory for [CoreSchoolUpdate].
class MockCoreSchoolUpdate {
  MockCoreSchoolUpdate._();
  static CoreSchoolUpdate get any => CoreSchoolUpdate.empty();
  static CoreSchoolUpdate withFields({String? name, String? emailRegex}) =>
      CoreSchoolUpdate.empty().copyWith(name: name, emailRegex: emailRegex);
}

/// Fake factory for [CoreUser].
class MockCoreUser {
  MockCoreUser._();
  static CoreUser get any => CoreUser.empty();
  static CoreUser withOnly({required String id}) =>
      MockCoreUser.any.copyWith(id: id);

  static CoreUser withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    required String email,
    DateTime? birthday,
    int? promo,
    String? floor,
    String? phone,
    DateTime? createdOn,
    List<CoreGroupSimple>? groups,
    CoreSchool? school,
    bool? isSuperAdmin,
  }) => CoreUser.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    email: email,
    birthday: birthday,
    promo: promo,
    floor: floor,
    phone: phone,
    createdOn: createdOn,
    groups: groups,
    school: school,
    isSuperAdmin: isSuperAdmin,
  );
}

/// Fake factory for [CoreUserActivateRequest].
class MockCoreUserActivateRequest {
  MockCoreUserActivateRequest._();
  static CoreUserActivateRequest get any => CoreUserActivateRequest.empty();
  static CoreUserActivateRequest withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String activationToken,
    required String password,
    DateTime? birthday,
    String? phone,
    String? floor,
    int? promo,
  }) => CoreUserActivateRequest.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    activationToken: activationToken,
    password: password,
    birthday: birthday,
    phone: phone,
    floor: floor,
    promo: promo,
  );
}

/// Fake factory for [CoreUserCreateRequest].
class MockCoreUserCreateRequest {
  MockCoreUserCreateRequest._();
  static CoreUserCreateRequest get any => CoreUserCreateRequest.empty();
  static CoreUserCreateRequest withFields({
    required String email,
    bool? acceptExternal,
  }) => CoreUserCreateRequest.empty().copyWith(
    email: email,
    acceptExternal: acceptExternal,
  );
}

/// Fake factory for [CoreUserFusionRequest].
class MockCoreUserFusionRequest {
  MockCoreUserFusionRequest._();
  static CoreUserFusionRequest get any => CoreUserFusionRequest.empty();
  static CoreUserFusionRequest withFields({
    required String userKeptEmail,
    required String userDeletedEmail,
  }) => CoreUserFusionRequest.empty().copyWith(
    userKeptEmail: userKeptEmail,
    userDeletedEmail: userDeletedEmail,
  );
}

/// Fake factory for [CoreUserSimple].
class MockCoreUserSimple {
  MockCoreUserSimple._();
  static CoreUserSimple get any => CoreUserSimple.empty();
  static CoreUserSimple withOnly({required String id}) =>
      MockCoreUserSimple.any.copyWith(id: id);

  static CoreUserSimple withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
  }) => CoreUserSimple.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
  );
}

/// Fake factory for [CoreUserUpdate].
class MockCoreUserUpdate {
  MockCoreUserUpdate._();
  static CoreUserUpdate get any => CoreUserUpdate.empty();
  static CoreUserUpdate withFields({
    String? nickname,
    DateTime? birthday,
    String? phone,
    String? floor,
  }) => CoreUserUpdate.empty().copyWith(
    nickname: nickname,
    birthday: birthday,
    phone: phone,
    floor: floor,
  );
}

/// Fake factory for [CoreUserUpdateAdmin].
class MockCoreUserUpdateAdmin {
  MockCoreUserUpdateAdmin._();
  static CoreUserUpdateAdmin get any => CoreUserUpdateAdmin.empty();
  static CoreUserUpdateAdmin withOnly({String? schoolId}) =>
      MockCoreUserUpdateAdmin.any.copyWith(schoolId: schoolId);

  static CoreUserUpdateAdmin withFields({
    String? email,
    String? schoolId,
    enums.AccountType? accountType,
    String? name,
    String? firstname,
    int? promo,
    String? nickname,
    DateTime? birthday,
    String? phone,
    String? floor,
  }) => CoreUserUpdateAdmin.empty().copyWith(
    email: email,
    schoolId: schoolId,
    accountType: accountType,
    name: name,
    firstname: firstname,
    promo: promo,
    nickname: nickname,
    birthday: birthday,
    phone: phone,
    floor: floor,
  );
}

/// Fake factory for [CoreVariables].
class MockCoreVariables {
  MockCoreVariables._();
  static CoreVariables get any => CoreVariables.empty();
  static CoreVariables withOnly({required String entityName}) =>
      MockCoreVariables.any.copyWith(entityName: entityName);

  static CoreVariables withFields({
    required String name,
    required String entityName,
    required String emailPlaceholder,
    required MainActivationForm mainActivationForm,
    required String studentEmailRegex,
    String? staffEmailRegex,
    String? formerStudentEmailRegex,
    required String primaryColor,
    String? playStoreUrl,
    String? appStoreUrl,
  }) => CoreVariables.empty().copyWith(
    name: name,
    entityName: entityName,
    emailPlaceholder: emailPlaceholder,
    mainActivationForm: mainActivationForm,
    studentEmailRegex: studentEmailRegex,
    staffEmailRegex: staffEmailRegex,
    formerStudentEmailRegex: formerStudentEmailRegex,
    primaryColor: primaryColor,
    playStoreUrl: playStoreUrl,
    appStoreUrl: appStoreUrl,
  );
}

/// Fake factory for [CurriculumBase].
class MockCurriculumBase {
  MockCurriculumBase._();
  static CurriculumBase get any => CurriculumBase.empty();
  static CurriculumBase withFields({required String name}) =>
      CurriculumBase.empty().copyWith(name: name);
}

/// Fake factory for [CurriculumComplete].
class MockCurriculumComplete {
  MockCurriculumComplete._();
  static CurriculumComplete get any => CurriculumComplete.empty();
  static CurriculumComplete withOnly({required String id}) =>
      MockCurriculumComplete.any.copyWith(id: id);

  static CurriculumComplete withFields({
    required String name,
    required String id,
  }) => CurriculumComplete.empty().copyWith(name: name, id: id);
}

/// Fake factory for [CustomDataBase].
class MockCustomDataBase {
  MockCustomDataBase._();
  static CustomDataBase get any => CustomDataBase.empty();
  static CustomDataBase withFields({required String value}) =>
      CustomDataBase.empty().copyWith(value: value);
}

/// Fake factory for [CustomDataComplete].
class MockCustomDataComplete {
  MockCustomDataComplete._();
  static CustomDataComplete get any => CustomDataComplete.empty();
  static CustomDataComplete withOnly({required String fieldId}) =>
      MockCustomDataComplete.any.copyWith(fieldId: fieldId);

  static CustomDataComplete withFields({
    required String value,
    required String fieldId,
    required String userId,
    required CustomDataFieldComplete field,
  }) => CustomDataComplete.empty().copyWith(
    value: value,
    fieldId: fieldId,
    userId: userId,
    field: field,
  );
}

/// Fake factory for [CustomDataFieldBase].
class MockCustomDataFieldBase {
  MockCustomDataFieldBase._();
  static CustomDataFieldBase get any => CustomDataFieldBase.empty();
  static CustomDataFieldBase withFields({
    required String name,
    required bool canUserAnswer,
  }) => CustomDataFieldBase.empty().copyWith(
    name: name,
    canUserAnswer: canUserAnswer,
  );
}

/// Fake factory for [CustomDataFieldComplete].
class MockCustomDataFieldComplete {
  MockCustomDataFieldComplete._();
  static CustomDataFieldComplete get any => CustomDataFieldComplete.empty();
  static CustomDataFieldComplete withOnly({required String id}) =>
      MockCustomDataFieldComplete.any.copyWith(id: id);

  static CustomDataFieldComplete withFields({
    required String name,
    required bool canUserAnswer,
    required String id,
    required String productId,
  }) => CustomDataFieldComplete.empty().copyWith(
    name: name,
    canUserAnswer: canUserAnswer,
    id: id,
    productId: productId,
  );
}

/// Fake factory for [DeliveryBase].
class MockDeliveryBase {
  MockDeliveryBase._();
  static DeliveryBase get any => DeliveryBase.empty();
  static DeliveryBase withFields({
    required String name,
    required DateTime deliveryDate,
    List<String>? productsIds,
  }) => DeliveryBase.empty().copyWith(
    name: name,
    deliveryDate: deliveryDate,
    productsIds: productsIds,
  );
}

/// Fake factory for [DeliveryProductsUpdate].
class MockDeliveryProductsUpdate {
  MockDeliveryProductsUpdate._();
  static DeliveryProductsUpdate get any => DeliveryProductsUpdate.empty();
  static DeliveryProductsUpdate withFields({
    required List<String> productsIds,
  }) => DeliveryProductsUpdate.empty().copyWith(productsIds: productsIds);
}

/// Fake factory for [DeliveryReturn].
class MockDeliveryReturn {
  MockDeliveryReturn._();
  static DeliveryReturn get any => DeliveryReturn.empty();
  static DeliveryReturn withOnly({required String id}) =>
      MockDeliveryReturn.any.copyWith(id: id);

  static DeliveryReturn withFields({
    required String name,
    required DateTime deliveryDate,
    List<AppModulesAmapSchemasAmapProductComplete>? products,
    required String id,
    required enums.DeliveryStatusType status,
  }) => DeliveryReturn.empty().copyWith(
    name: name,
    deliveryDate: deliveryDate,
    products: products,
    id: id,
    status: status,
  );
}

/// Fake factory for [DeliveryUpdate].
class MockDeliveryUpdate {
  MockDeliveryUpdate._();
  static DeliveryUpdate get any => DeliveryUpdate.empty();
  static DeliveryUpdate withFields({String? name, DateTime? deliveryDate}) =>
      DeliveryUpdate.empty().copyWith(name: name, deliveryDate: deliveryDate);
}

/// Fake factory for [Document].
class MockDocument {
  MockDocument._();
  static Document get any => Document.empty();
  static Document withOnly({required String id}) =>
      MockDocument.any.copyWith(id: id);

  static Document withFields({
    required enums.DocumentType type,
    required String name,
    required String id,
    required DateTime uploadedAt,
    required enums.DocumentValidation validation,
  }) => Document.empty().copyWith(
    type: type,
    name: name,
    id: id,
    uploadedAt: uploadedAt,
    validation: validation,
  );
}

/// Fake factory for [DocumentBase].
class MockDocumentBase {
  MockDocumentBase._();
  static DocumentBase get any => DocumentBase.empty();
  static DocumentBase withFields({required String name}) =>
      DocumentBase.empty().copyWith(name: name);
}

/// Fake factory for [DocumentComplete].
class MockDocumentComplete {
  MockDocumentComplete._();
  static DocumentComplete get any => DocumentComplete.empty();
  static DocumentComplete withOnly({required String id}) =>
      MockDocumentComplete.any.copyWith(id: id);

  static DocumentComplete withFields({
    required String name,
    required String id,
    required String sellerId,
  }) =>
      DocumentComplete.empty().copyWith(name: name, id: id, sellerId: sellerId);
}

/// Fake factory for [DocumentCreation].
class MockDocumentCreation {
  MockDocumentCreation._();
  static DocumentCreation get any => DocumentCreation.empty();
  static DocumentCreation withOnly({required String id}) =>
      MockDocumentCreation.any.copyWith(id: id);

  static DocumentCreation withFields({required String id}) =>
      DocumentCreation.empty().copyWith(id: id);
}

/// Fake factory for [EmergencyContact].
class MockEmergencyContact {
  MockEmergencyContact._();
  static EmergencyContact get any => EmergencyContact.empty();
  static EmergencyContact withFields({
    String? firstname,
    String? name,
    String? phone,
  }) => EmergencyContact.empty().copyWith(
    firstname: firstname,
    name: name,
    phone: phone,
  );
}

/// Fake factory for [EventAdmin].
class MockEventAdmin {
  MockEventAdmin._();
  static EventAdmin get any => EventAdmin.empty();
  static EventAdmin withOnly({required String id}) =>
      MockEventAdmin.any.copyWith(id: id);

  static EventAdmin withFields({
    required String id,
    required String name,
    required String storeId,
    required DateTime openDatetime,
    DateTime? closeDatetime,
    required bool disabled,
    int? quota,
    required List<SessionAdmin> sessions,
    required List<CategoryAdmin> categories,
    required List<QuestionAdmin> questions,
    required int ticketsInCheckout,
    required int ticketsSold,
  }) => EventAdmin.empty().copyWith(
    id: id,
    name: name,
    storeId: storeId,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
    quota: quota,
    sessions: sessions,
    categories: categories,
    questions: questions,
    ticketsInCheckout: ticketsInCheckout,
    ticketsSold: ticketsSold,
  );
}

/// Fake factory for [EventBaseCreation].
class MockEventBaseCreation {
  MockEventBaseCreation._();
  static EventBaseCreation get any => EventBaseCreation.empty();
  static EventBaseCreation withOnly({required String associationId}) =>
      MockEventBaseCreation.any.copyWith(associationId: associationId);

  static EventBaseCreation withFields({
    required String name,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    required String location,
    String? description,
    String? recurrenceRule,
    DateTime? ticketUrlOpening,
    required bool notification,
    required String associationId,
    String? ticketUrl,
    String? ticketEventId,
  }) => EventBaseCreation.empty().copyWith(
    name: name,
    start: start,
    end: end,
    allDay: allDay,
    location: location,
    description: description,
    recurrenceRule: recurrenceRule,
    ticketUrlOpening: ticketUrlOpening,
    notification: notification,
    associationId: associationId,
    ticketUrl: ticketUrl,
    ticketEventId: ticketEventId,
  );
}

/// Fake factory for [EventCompleteTicketUrl].
class MockEventCompleteTicketUrl {
  MockEventCompleteTicketUrl._();
  static EventCompleteTicketUrl get any => EventCompleteTicketUrl.empty();
  static EventCompleteTicketUrl withOnly({required String id}) =>
      MockEventCompleteTicketUrl.any.copyWith(id: id);

  static EventCompleteTicketUrl withFields({
    required String name,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    required String location,
    String? description,
    String? recurrenceRule,
    DateTime? ticketUrlOpening,
    required bool notification,
    required String associationId,
    required String id,
    required Association association,
    required enums.Decision decision,
    String? ticketUrl,
    String? ticketEventId,
  }) => EventCompleteTicketUrl.empty().copyWith(
    name: name,
    start: start,
    end: end,
    allDay: allDay,
    location: location,
    description: description,
    recurrenceRule: recurrenceRule,
    ticketUrlOpening: ticketUrlOpening,
    notification: notification,
    associationId: associationId,
    id: id,
    association: association,
    decision: decision,
    ticketUrl: ticketUrl,
    ticketEventId: ticketEventId,
  );
}

/// Fake factory for [EventCreate].
class MockEventCreate {
  MockEventCreate._();
  static EventCreate get any => EventCreate.empty();
  static EventCreate withOnly({required String storeId}) =>
      MockEventCreate.any.copyWith(storeId: storeId);

  static EventCreate withFields({
    required String storeId,
    required String name,
    int? quota,
    required DateTime openDatetime,
    DateTime? closeDatetime,
    required List<SessionCreate> sessions,
    required List<CategoryCreate> categories,
    required List<QuestionCreate> questions,
  }) => EventCreate.empty().copyWith(
    storeId: storeId,
    name: name,
    quota: quota,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    sessions: sessions,
    categories: categories,
    questions: questions,
  );
}

/// Fake factory for [EventEdit].
class MockEventEdit {
  MockEventEdit._();
  static EventEdit get any => EventEdit.empty();
  static EventEdit withOnly({String? ticketEventId}) =>
      MockEventEdit.any.copyWith(ticketEventId: ticketEventId);

  static EventEdit withFields({
    String? name,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    String? location,
    String? description,
    String? recurrenceRule,
    DateTime? ticketUrlOpening,
    String? ticketUrl,
    String? ticketEventId,
    bool? notification,
  }) => EventEdit.empty().copyWith(
    name: name,
    start: start,
    end: end,
    allDay: allDay,
    location: location,
    description: description,
    recurrenceRule: recurrenceRule,
    ticketUrlOpening: ticketUrlOpening,
    ticketUrl: ticketUrl,
    ticketEventId: ticketEventId,
    notification: notification,
  );
}

/// Fake factory for [EventPublic].
class MockEventPublic {
  MockEventPublic._();
  static EventPublic get any => EventPublic.empty();
  static EventPublic withOnly({required String id}) =>
      MockEventPublic.any.copyWith(id: id);

  static EventPublic withFields({
    required String id,
    required String name,
    required String storeId,
    required DateTime openDatetime,
    DateTime? closeDatetime,
    required bool disabled,
    required List<SessionPublic> sessions,
    required List<CategoryPublic> categories,
    required List<QuestionPublic> questions,
    required bool soldOut,
  }) => EventPublic.empty().copyWith(
    id: id,
    name: name,
    storeId: storeId,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
    sessions: sessions,
    categories: categories,
    questions: questions,
    soldOut: soldOut,
  );
}

/// Fake factory for [EventSimple].
class MockEventSimple {
  MockEventSimple._();
  static EventSimple get any => EventSimple.empty();
  static EventSimple withOnly({required String id}) =>
      MockEventSimple.any.copyWith(id: id);

  static EventSimple withFields({
    required String id,
    required String name,
    required String storeId,
    required DateTime openDatetime,
    DateTime? closeDatetime,
    required bool disabled,
  }) => EventSimple.empty().copyWith(
    id: id,
    name: name,
    storeId: storeId,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
  );
}

/// Fake factory for [EventTicketUrl].
class MockEventTicketUrl {
  MockEventTicketUrl._();
  static EventTicketUrl get any => EventTicketUrl.empty();
  static EventTicketUrl withFields({required String ticketUrl}) =>
      EventTicketUrl.empty().copyWith(ticketUrl: ticketUrl);
}

/// Fake factory for [EventUpdate].
class MockEventUpdate {
  MockEventUpdate._();
  static EventUpdate get any => EventUpdate.empty();
  static EventUpdate withFields({
    String? name,
    int? quota,
    DateTime? openDatetime,
    DateTime? closeDatetime,
    bool? disabled,
  }) => EventUpdate.empty().copyWith(
    name: name,
    quota: quota,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
  );
}

/// Fake factory for [FirebaseDevice].
class MockFirebaseDevice {
  MockFirebaseDevice._();
  static FirebaseDevice get any => FirebaseDevice.empty();
  static FirebaseDevice withOnly({required String userId}) =>
      MockFirebaseDevice.any.copyWith(userId: userId);

  static FirebaseDevice withFields({
    required String userId,
    String? firebaseDeviceToken,
  }) => FirebaseDevice.empty().copyWith(
    userId: userId,
    firebaseDeviceToken: firebaseDeviceToken,
  );
}

/// Fake factory for [FlappyBirdScoreBase].
class MockFlappyBirdScoreBase {
  MockFlappyBirdScoreBase._();
  static FlappyBirdScoreBase get any => FlappyBirdScoreBase.empty();
  static FlappyBirdScoreBase withFields({required int value}) =>
      FlappyBirdScoreBase.empty().copyWith(value: value);
}

/// Fake factory for [FlappyBirdScoreCompleteFeedBack].
class MockFlappyBirdScoreCompleteFeedBack {
  MockFlappyBirdScoreCompleteFeedBack._();
  static FlappyBirdScoreCompleteFeedBack get any =>
      FlappyBirdScoreCompleteFeedBack.empty();
  static FlappyBirdScoreCompleteFeedBack withFields({
    required int value,
    required CoreUserSimple user,
    required DateTime creationTime,
    required int position,
  }) => FlappyBirdScoreCompleteFeedBack.empty().copyWith(
    value: value,
    user: user,
    creationTime: creationTime,
    position: position,
  );
}

/// Fake factory for [FlappyBirdScoreInDB].
class MockFlappyBirdScoreInDB {
  MockFlappyBirdScoreInDB._();
  static FlappyBirdScoreInDB get any => FlappyBirdScoreInDB.empty();
  static FlappyBirdScoreInDB withOnly({required String id}) =>
      MockFlappyBirdScoreInDB.any.copyWith(id: id);

  static FlappyBirdScoreInDB withFields({
    required int value,
    required CoreUserSimple user,
    required DateTime creationTime,
    required String id,
    required String userId,
  }) => FlappyBirdScoreInDB.empty().copyWith(
    value: value,
    user: user,
    creationTime: creationTime,
    id: id,
    userId: userId,
  );
}

/// Fake factory for [GenerateTicketBase].
class MockGenerateTicketBase {
  MockGenerateTicketBase._();
  static GenerateTicketBase get any => GenerateTicketBase.empty();
  static GenerateTicketBase withFields({
    required String name,
    required int maxUse,
    required DateTime expiration,
  }) => GenerateTicketBase.empty().copyWith(
    name: name,
    maxUse: maxUse,
    expiration: expiration,
  );
}

/// Fake factory for [GenerateTicketComplete].
class MockGenerateTicketComplete {
  MockGenerateTicketComplete._();
  static GenerateTicketComplete get any => GenerateTicketComplete.empty();
  static GenerateTicketComplete withOnly({required String id}) =>
      MockGenerateTicketComplete.any.copyWith(id: id);

  static GenerateTicketComplete withFields({
    required String name,
    required int maxUse,
    required DateTime expiration,
    required String id,
  }) => GenerateTicketComplete.empty().copyWith(
    name: name,
    maxUse: maxUse,
    expiration: expiration,
    id: id,
  );
}

/// Fake factory for [GroupNotificationRequest].
class MockGroupNotificationRequest {
  MockGroupNotificationRequest._();
  static GroupNotificationRequest get any => GroupNotificationRequest.empty();
  static GroupNotificationRequest withOnly({required String groupId}) =>
      MockGroupNotificationRequest.any.copyWith(groupId: groupId);

  static GroupNotificationRequest withFields({
    required String groupId,
    required String title,
    required String content,
  }) => GroupNotificationRequest.empty().copyWith(
    groupId: groupId,
    title: title,
    content: content,
  );
}

/// Fake factory for [HTTPValidationError].
class MockHTTPValidationError {
  MockHTTPValidationError._();
  static HTTPValidationError get any => HTTPValidationError.empty();
  static HTTPValidationError withFields({List<ValidationError>? detail}) =>
      HTTPValidationError.empty().copyWith(detail: detail);
}

/// Fake factory for [History].
class MockHistory {
  MockHistory._();
  static History get any => History.empty();
  static History withOnly({required String id}) =>
      MockHistory.any.copyWith(id: id);

  static History withFields({
    required String id,
    required enums.HistoryType type,
    required enums.HistoryDirection direction,
    required String otherWalletName,
    required int total,
    required DateTime creation,
    required enums.TransactionStatus status,
    HistoryRefund? refund,
  }) => History.empty().copyWith(
    id: id,
    type: type,
    direction: direction,
    otherWalletName: otherWalletName,
    total: total,
    creation: creation,
    status: status,
    refund: refund,
  );
}

/// Fake factory for [HistoryRefund].
class MockHistoryRefund {
  MockHistoryRefund._();
  static HistoryRefund get any => HistoryRefund.empty();
  static HistoryRefund withFields({
    required int total,
    required DateTime creation,
  }) => HistoryRefund.empty().copyWith(total: total, creation: creation);
}

/// Fake factory for [IcalSecret].
class MockIcalSecret {
  MockIcalSecret._();
  static IcalSecret get any => IcalSecret.empty();
  static IcalSecret withFields({required String secret}) =>
      IcalSecret.empty().copyWith(secret: secret);
}

/// Fake factory for [Information].
class MockInformation {
  MockInformation._();
  static Information get any => Information.empty();
  static Information withFields({
    required String manager,
    required String link,
    required String description,
  }) => Information.empty().copyWith(
    manager: manager,
    link: link,
    description: description,
  );
}

/// Fake factory for [InformationEdit].
class MockInformationEdit {
  MockInformationEdit._();
  static InformationEdit get any => InformationEdit.empty();
  static InformationEdit withFields({
    String? manager,
    String? link,
    String? description,
  }) => InformationEdit.empty().copyWith(
    manager: manager,
    link: link,
    description: description,
  );
}

/// Fake factory for [IntegrityCheckData].
class MockIntegrityCheckData {
  MockIntegrityCheckData._();
  static IntegrityCheckData get any => IntegrityCheckData.empty();
  static IntegrityCheckData withFields({
    required DateTime date,
    required List<WalletBase> wallets,
    required List<TransactionBase> transactions,
    required List<Transfer> transfers,
    required List<RefundBase> refunds,
  }) => IntegrityCheckData.empty().copyWith(
    date: date,
    wallets: wallets,
    transactions: transactions,
    transfers: transfers,
    refunds: refunds,
  );
}

/// Fake factory for [IntrospectTokenResponse].
class MockIntrospectTokenResponse {
  MockIntrospectTokenResponse._();
  static IntrospectTokenResponse get any => IntrospectTokenResponse.empty();
  static IntrospectTokenResponse withFields({required bool active}) =>
      IntrospectTokenResponse.empty().copyWith(active: active);
}

/// Fake factory for [InviteToken].
class MockInviteToken {
  MockInviteToken._();
  static InviteToken get any => InviteToken.empty();
  static InviteToken withOnly({required String teamId}) =>
      MockInviteToken.any.copyWith(teamId: teamId);

  static InviteToken withFields({
    required String teamId,
    required String token,
  }) => InviteToken.empty().copyWith(teamId: teamId, token: token);
}

/// Fake factory for [Invoice].
class MockInvoice {
  MockInvoice._();
  static Invoice get any => Invoice.empty();
  static Invoice withOnly({required String id}) =>
      MockInvoice.any.copyWith(id: id);

  static Invoice withFields({
    required String id,
    required String reference,
    required String structureId,
    required DateTime creation,
    required DateTime startDate,
    required DateTime endDate,
    required int total,
    bool? paid,
    bool? received,
    required Structure structure,
    required List<InvoiceDetail> details,
  }) => Invoice.empty().copyWith(
    id: id,
    reference: reference,
    structureId: structureId,
    creation: creation,
    startDate: startDate,
    endDate: endDate,
    total: total,
    paid: paid,
    received: received,
    structure: structure,
    details: details,
  );
}

/// Fake factory for [InvoiceDetail].
class MockInvoiceDetail {
  MockInvoiceDetail._();
  static InvoiceDetail get any => InvoiceDetail.empty();
  static InvoiceDetail withOnly({required String invoiceId}) =>
      MockInvoiceDetail.any.copyWith(invoiceId: invoiceId);

  static InvoiceDetail withFields({
    required String invoiceId,
    required String storeId,
    required int total,
    required StoreSimple store,
  }) => InvoiceDetail.empty().copyWith(
    invoiceId: invoiceId,
    storeId: storeId,
    total: total,
    store: store,
  );
}

/// Fake factory for [Item].
class MockItem {
  MockItem._();
  static Item get any => Item.empty();
  static Item withOnly({required String id}) => MockItem.any.copyWith(id: id);

  static Item withFields({
    required String name,
    required int suggestedCaution,
    required int totalQuantity,
    required int suggestedLendingDuration,
    required String id,
    required String loanerId,
    required int loanedQuantity,
  }) => Item.empty().copyWith(
    name: name,
    suggestedCaution: suggestedCaution,
    totalQuantity: totalQuantity,
    suggestedLendingDuration: suggestedLendingDuration,
    id: id,
    loanerId: loanerId,
    loanedQuantity: loanedQuantity,
  );
}

/// Fake factory for [ItemBase].
class MockItemBase {
  MockItemBase._();
  static ItemBase get any => ItemBase.empty();
  static ItemBase withFields({
    required String name,
    required int suggestedCaution,
    required int totalQuantity,
    required int suggestedLendingDuration,
  }) => ItemBase.empty().copyWith(
    name: name,
    suggestedCaution: suggestedCaution,
    totalQuantity: totalQuantity,
    suggestedLendingDuration: suggestedLendingDuration,
  );
}

/// Fake factory for [ItemBorrowed].
class MockItemBorrowed {
  MockItemBorrowed._();
  static ItemBorrowed get any => ItemBorrowed.empty();
  static ItemBorrowed withOnly({required String itemId}) =>
      MockItemBorrowed.any.copyWith(itemId: itemId);

  static ItemBorrowed withFields({
    required String itemId,
    required int quantity,
  }) => ItemBorrowed.empty().copyWith(itemId: itemId, quantity: quantity);
}

/// Fake factory for [ItemQuantity].
class MockItemQuantity {
  MockItemQuantity._();
  static ItemQuantity get any => ItemQuantity.empty();
  static ItemQuantity withFields({
    required int quantity,
    required ItemSimple itemSimple,
  }) =>
      ItemQuantity.empty().copyWith(quantity: quantity, itemSimple: itemSimple);
}

/// Fake factory for [ItemSimple].
class MockItemSimple {
  MockItemSimple._();
  static ItemSimple get any => ItemSimple.empty();
  static ItemSimple withOnly({required String id}) =>
      MockItemSimple.any.copyWith(id: id);

  static ItemSimple withFields({
    required String id,
    required String name,
    required String loanerId,
  }) => ItemSimple.empty().copyWith(id: id, name: name, loanerId: loanerId);
}

/// Fake factory for [ItemUpdate].
class MockItemUpdate {
  MockItemUpdate._();
  static ItemUpdate get any => ItemUpdate.empty();
  static ItemUpdate withFields({
    String? name,
    int? suggestedCaution,
    int? totalQuantity,
    int? suggestedLendingDuration,
  }) => ItemUpdate.empty().copyWith(
    name: name,
    suggestedCaution: suggestedCaution,
    totalQuantity: totalQuantity,
    suggestedLendingDuration: suggestedLendingDuration,
  );
}

/// Fake factory for [ListBase].
class MockListBase {
  MockListBase._();
  static ListBase get any => ListBase.empty();
  static ListBase withOnly({required String sectionId}) =>
      MockListBase.any.copyWith(sectionId: sectionId);

  static ListBase withFields({
    required String name,
    required String description,
    required enums.ListType type,
    required String sectionId,
    required List<ListMemberBase> members,
    String? program,
  }) => ListBase.empty().copyWith(
    name: name,
    description: description,
    type: type,
    sectionId: sectionId,
    members: members,
    program: program,
  );
}

/// Fake factory for [ListEdit].
class MockListEdit {
  MockListEdit._();
  static ListEdit get any => ListEdit.empty();
  static ListEdit withFields({
    String? name,
    String? description,
    enums.ListType? type,
    List<ListMemberBase>? members,
    String? program,
  }) => ListEdit.empty().copyWith(
    name: name,
    description: description,
    type: type,
    members: members,
    program: program,
  );
}

/// Fake factory for [ListMemberBase].
class MockListMemberBase {
  MockListMemberBase._();
  static ListMemberBase get any => ListMemberBase.empty();
  static ListMemberBase withOnly({required String userId}) =>
      MockListMemberBase.any.copyWith(userId: userId);

  static ListMemberBase withFields({
    required String userId,
    required String role,
  }) => ListMemberBase.empty().copyWith(userId: userId, role: role);
}

/// Fake factory for [ListMemberComplete].
class MockListMemberComplete {
  MockListMemberComplete._();
  static ListMemberComplete get any => ListMemberComplete.empty();
  static ListMemberComplete withOnly({required String userId}) =>
      MockListMemberComplete.any.copyWith(userId: userId);

  static ListMemberComplete withFields({
    required String userId,
    required String role,
    required CoreUserSimple user,
  }) => ListMemberComplete.empty().copyWith(
    userId: userId,
    role: role,
    user: user,
  );
}

/// Fake factory for [ListReturn].
class MockListReturn {
  MockListReturn._();
  static ListReturn get any => ListReturn.empty();
  static ListReturn withOnly({required String id}) =>
      MockListReturn.any.copyWith(id: id);

  static ListReturn withFields({
    required String id,
    required String name,
    required String description,
    required enums.ListType type,
    required SectionComplete section,
    required List<ListMemberComplete> members,
    String? program,
  }) => ListReturn.empty().copyWith(
    id: id,
    name: name,
    description: description,
    type: type,
    section: section,
    members: members,
    program: program,
  );
}

/// Fake factory for [Loan].
class MockLoan {
  MockLoan._();
  static Loan get any => Loan.empty();
  static Loan withOnly({required String id}) => MockLoan.any.copyWith(id: id);

  static Loan withFields({
    required String borrowerId,
    required String loanerId,
    required DateTime start,
    required DateTime end,
    String? notes,
    String? caution,
    required String id,
    required bool returned,
    DateTime? returnedDate,
    required List<ItemQuantity> itemsQty,
    required CoreUserSimple borrower,
    required Loaner loaner,
  }) => Loan.empty().copyWith(
    borrowerId: borrowerId,
    loanerId: loanerId,
    start: start,
    end: end,
    notes: notes,
    caution: caution,
    id: id,
    returned: returned,
    returnedDate: returnedDate,
    itemsQty: itemsQty,
    borrower: borrower,
    loaner: loaner,
  );
}

/// Fake factory for [LoanCreation].
class MockLoanCreation {
  MockLoanCreation._();
  static LoanCreation get any => LoanCreation.empty();
  static LoanCreation withOnly({required String borrowerId}) =>
      MockLoanCreation.any.copyWith(borrowerId: borrowerId);

  static LoanCreation withFields({
    required String borrowerId,
    required String loanerId,
    required DateTime start,
    required DateTime end,
    String? notes,
    String? caution,
    required List<ItemBorrowed> itemsBorrowed,
  }) => LoanCreation.empty().copyWith(
    borrowerId: borrowerId,
    loanerId: loanerId,
    start: start,
    end: end,
    notes: notes,
    caution: caution,
    itemsBorrowed: itemsBorrowed,
  );
}

/// Fake factory for [LoanExtend].
class MockLoanExtend {
  MockLoanExtend._();
  static LoanExtend get any => LoanExtend.empty();
  static LoanExtend withFields({DateTime? end, int? duration}) =>
      LoanExtend.empty().copyWith(end: end, duration: duration);
}

/// Fake factory for [LoanUpdate].
class MockLoanUpdate {
  MockLoanUpdate._();
  static LoanUpdate get any => LoanUpdate.empty();
  static LoanUpdate withOnly({String? borrowerId}) =>
      MockLoanUpdate.any.copyWith(borrowerId: borrowerId);

  static LoanUpdate withFields({
    String? borrowerId,
    DateTime? start,
    DateTime? end,
    String? notes,
    String? caution,
    bool? returned,
    List<ItemBorrowed>? itemsBorrowed,
  }) => LoanUpdate.empty().copyWith(
    borrowerId: borrowerId,
    start: start,
    end: end,
    notes: notes,
    caution: caution,
    returned: returned,
    itemsBorrowed: itemsBorrowed,
  );
}

/// Fake factory for [Loaner].
class MockLoaner {
  MockLoaner._();
  static Loaner get any => Loaner.empty();
  static Loaner withOnly({required String id}) =>
      MockLoaner.any.copyWith(id: id);

  static Loaner withFields({
    required String name,
    required String groupManagerId,
    required String id,
  }) => Loaner.empty().copyWith(
    name: name,
    groupManagerId: groupManagerId,
    id: id,
  );
}

/// Fake factory for [LoanerBase].
class MockLoanerBase {
  MockLoanerBase._();
  static LoanerBase get any => LoanerBase.empty();
  static LoanerBase withOnly({required String groupManagerId}) =>
      MockLoanerBase.any.copyWith(groupManagerId: groupManagerId);

  static LoanerBase withFields({
    required String name,
    required String groupManagerId,
  }) => LoanerBase.empty().copyWith(name: name, groupManagerId: groupManagerId);
}

/// Fake factory for [LoanerUpdate].
class MockLoanerUpdate {
  MockLoanerUpdate._();
  static LoanerUpdate get any => LoanerUpdate.empty();
  static LoanerUpdate withOnly({String? groupManagerId}) =>
      MockLoanerUpdate.any.copyWith(groupManagerId: groupManagerId);

  static LoanerUpdate withFields({String? name, String? groupManagerId}) =>
      LoanerUpdate.empty().copyWith(name: name, groupManagerId: groupManagerId);
}

/// Fake factory for [Location].
class MockLocation {
  MockLocation._();
  static Location get any => Location.empty();
  static Location withOnly({required String id}) =>
      MockLocation.any.copyWith(id: id);

  static Location withFields({
    required String name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    required String id,
    required String editionId,
  }) => Location.empty().copyWith(
    name: name,
    description: description,
    address: address,
    latitude: latitude,
    longitude: longitude,
    id: id,
    editionId: editionId,
  );
}

/// Fake factory for [LocationBase].
class MockLocationBase {
  MockLocationBase._();
  static LocationBase get any => LocationBase.empty();
  static LocationBase withFields({
    required String name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
  }) => LocationBase.empty().copyWith(
    name: name,
    description: description,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}

/// Fake factory for [LocationComplete].
class MockLocationComplete {
  MockLocationComplete._();
  static LocationComplete get any => LocationComplete.empty();
  static LocationComplete withOnly({required String id}) =>
      MockLocationComplete.any.copyWith(id: id);

  static LocationComplete withFields({
    required String name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    required String id,
    required String editionId,
    List<MatchComplete>? matches,
  }) => LocationComplete.empty().copyWith(
    name: name,
    description: description,
    address: address,
    latitude: latitude,
    longitude: longitude,
    id: id,
    editionId: editionId,
    matches: matches,
  );
}

/// Fake factory for [LocationEdit].
class MockLocationEdit {
  MockLocationEdit._();
  static LocationEdit get any => LocationEdit.empty();
  static LocationEdit withFields({
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
  }) => LocationEdit.empty().copyWith(
    name: name,
    description: description,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}

/// Fake factory for [MailMigrationRequest].
class MockMailMigrationRequest {
  MockMailMigrationRequest._();
  static MailMigrationRequest get any => MailMigrationRequest.empty();
  static MailMigrationRequest withFields({required String newEmail}) =>
      MailMigrationRequest.empty().copyWith(newEmail: newEmail);
}

/// Fake factory for [MainActivationForm].
class MockMainActivationForm {
  MockMainActivationForm._();
  static MainActivationForm get any => MainActivationForm.empty();
  static MainActivationForm withFields({
    required List<enums.ActivationFormField> fields,
    List<String>? floorChoices,
    int? promotionOffset,
  }) => MainActivationForm.empty().copyWith(
    fields: fields,
    floorChoices: floorChoices,
    promotionOffset: promotionOffset,
  );
}

/// Fake factory for [Manager].
class MockManager {
  MockManager._();
  static Manager get any => Manager.empty();
  static Manager withOnly({required String id}) =>
      MockManager.any.copyWith(id: id);

  static Manager withFields({
    required String name,
    required String groupId,
    required String id,
  }) => Manager.empty().copyWith(name: name, groupId: groupId, id: id);
}

/// Fake factory for [ManagerBase].
class MockManagerBase {
  MockManagerBase._();
  static ManagerBase get any => ManagerBase.empty();
  static ManagerBase withOnly({required String groupId}) =>
      MockManagerBase.any.copyWith(groupId: groupId);

  static ManagerBase withFields({
    required String name,
    required String groupId,
  }) => ManagerBase.empty().copyWith(name: name, groupId: groupId);
}

/// Fake factory for [ManagerUpdate].
class MockManagerUpdate {
  MockManagerUpdate._();
  static ManagerUpdate get any => ManagerUpdate.empty();
  static ManagerUpdate withOnly({String? groupId}) =>
      MockManagerUpdate.any.copyWith(groupId: groupId);

  static ManagerUpdate withFields({String? name, String? groupId}) =>
      ManagerUpdate.empty().copyWith(name: name, groupId: groupId);
}

/// Fake factory for [Match].
class MockMatch {
  MockMatch._();
  static Match get any => Match.empty();
  static Match withOnly({required String id}) => MockMatch.any.copyWith(id: id);

  static Match withFields({
    required String name,
    required String team1Id,
    required String team2Id,
    required String locationId,
    DateTime? date,
    int? scoreTeam1,
    int? scoreTeam2,
    String? winnerId,
    required String id,
    required String sportId,
    required String editionId,
  }) => Match.empty().copyWith(
    name: name,
    team1Id: team1Id,
    team2Id: team2Id,
    locationId: locationId,
    date: date,
    scoreTeam1: scoreTeam1,
    scoreTeam2: scoreTeam2,
    winnerId: winnerId,
    id: id,
    sportId: sportId,
    editionId: editionId,
  );
}

/// Fake factory for [MatchBase].
class MockMatchBase {
  MockMatchBase._();
  static MatchBase get any => MatchBase.empty();
  static MatchBase withOnly({required String team1Id}) =>
      MockMatchBase.any.copyWith(team1Id: team1Id);

  static MatchBase withFields({
    required String name,
    required String team1Id,
    required String team2Id,
    required String locationId,
    DateTime? date,
    int? scoreTeam1,
    int? scoreTeam2,
    String? winnerId,
  }) => MatchBase.empty().copyWith(
    name: name,
    team1Id: team1Id,
    team2Id: team2Id,
    locationId: locationId,
    date: date,
    scoreTeam1: scoreTeam1,
    scoreTeam2: scoreTeam2,
    winnerId: winnerId,
  );
}

/// Fake factory for [MatchComplete].
class MockMatchComplete {
  MockMatchComplete._();
  static MatchComplete get any => MatchComplete.empty();
  static MatchComplete withOnly({required String id}) =>
      MockMatchComplete.any.copyWith(id: id);

  static MatchComplete withFields({
    required String name,
    required String team1Id,
    required String team2Id,
    required String locationId,
    DateTime? date,
    int? scoreTeam1,
    int? scoreTeam2,
    String? winnerId,
    required String id,
    required String sportId,
    required String editionId,
    required Team team1,
    required Team team2,
    required Location location,
  }) => MatchComplete.empty().copyWith(
    name: name,
    team1Id: team1Id,
    team2Id: team2Id,
    locationId: locationId,
    date: date,
    scoreTeam1: scoreTeam1,
    scoreTeam2: scoreTeam2,
    winnerId: winnerId,
    id: id,
    sportId: sportId,
    editionId: editionId,
    team1: team1,
    team2: team2,
    location: location,
  );
}

/// Fake factory for [MatchEdit].
class MockMatchEdit {
  MockMatchEdit._();
  static MatchEdit get any => MatchEdit.empty();
  static MatchEdit withOnly({String? sportId}) =>
      MockMatchEdit.any.copyWith(sportId: sportId);

  static MatchEdit withFields({
    String? name,
    String? sportId,
    String? team1Id,
    String? team2Id,
    DateTime? date,
    String? locationId,
    int? scoreTeam1,
    int? scoreTeam2,
    String? winnerId,
  }) => MatchEdit.empty().copyWith(
    name: name,
    sportId: sportId,
    team1Id: team1Id,
    team2Id: team2Id,
    date: date,
    locationId: locationId,
    scoreTeam1: scoreTeam1,
    scoreTeam2: scoreTeam2,
    winnerId: winnerId,
  );
}

/// Fake factory for [MemberComplete].
class MockMemberComplete {
  MockMemberComplete._();
  static MemberComplete get any => MemberComplete.empty();
  static MemberComplete withOnly({required String id}) =>
      MockMemberComplete.any.copyWith(id: id);

  static MemberComplete withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    required String email,
    String? phone,
    int? promo,
    required List<MembershipComplete> memberships,
  }) => MemberComplete.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    email: email,
    phone: phone,
    promo: promo,
    memberships: memberships,
  );
}

/// Fake factory for [MembershipComplete].
class MockMembershipComplete {
  MockMembershipComplete._();
  static MembershipComplete get any => MembershipComplete.empty();
  static MembershipComplete withOnly({
    required String id,
    required String associationId,
    required String roleName,
  }) => MockMembershipComplete.any.copyWith(
    id: id,
    associationId: associationId,
    roleName: roleName,
  );

  static MembershipComplete withFields({
    required String userId,
    required String associationId,
    required int mandateYear,
    required String roleName,
    String? roleTags,
    required int memberOrder,
    required String id,
  }) => MembershipComplete.empty().copyWith(
    userId: userId,
    associationId: associationId,
    mandateYear: mandateYear,
    roleName: roleName,
    roleTags: roleTags,
    memberOrder: memberOrder,
    id: id,
  );
}

/// Fake factory for [MembershipEdit].
class MockMembershipEdit {
  MockMembershipEdit._();
  static MembershipEdit get any => MembershipEdit.empty();
  static MembershipEdit withOnly({String? roleName}) =>
      MockMembershipEdit.any.copyWith(roleName: roleName);

  static MembershipEdit withFields({
    String? roleName,
    String? roleTags,
    int? memberOrder,
  }) => MembershipEdit.empty().copyWith(
    roleName: roleName,
    roleTags: roleTags,
    memberOrder: memberOrder,
  );
}

/// Fake factory for [MembershipSimple].
class MockMembershipSimple {
  MockMembershipSimple._();
  static MembershipSimple get any => MembershipSimple.empty();
  static MembershipSimple withOnly({required String id}) =>
      MockMembershipSimple.any.copyWith(id: id);

  static MembershipSimple withFields({
    required String name,
    required String managerGroupId,
    required String id,
  }) => MembershipSimple.empty().copyWith(
    name: name,
    managerGroupId: managerGroupId,
    id: id,
  );
}

/// Fake factory for [MembershipUserMappingEmail].
class MockMembershipUserMappingEmail {
  MockMembershipUserMappingEmail._();
  static MembershipUserMappingEmail get any =>
      MembershipUserMappingEmail.empty();
  static MembershipUserMappingEmail withFields({
    required String userEmail,
    required DateTime startDate,
    required DateTime endDate,
  }) => MembershipUserMappingEmail.empty().copyWith(
    userEmail: userEmail,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Fake factory for [MyPaymentBankAccountHolder].
class MockMyPaymentBankAccountHolder {
  MockMyPaymentBankAccountHolder._();
  static MyPaymentBankAccountHolder get any =>
      MyPaymentBankAccountHolder.empty();
  static MyPaymentBankAccountHolder withOnly({
    required String holderStructureId,
  }) => MockMyPaymentBankAccountHolder.any.copyWith(
    holderStructureId: holderStructureId,
  );

  static MyPaymentBankAccountHolder withFields({
    required String holderStructureId,
  }) => MyPaymentBankAccountHolder.empty().copyWith(
    holderStructureId: holderStructureId,
  );
}

/// Fake factory for [News].
class MockNews {
  MockNews._();
  static News get any => News.empty();
  static News withOnly({required String id}) => MockNews.any.copyWith(id: id);

  static News withFields({
    required String id,
    required String title,
    required DateTime start,
    DateTime? end,
    required String entity,
    String? location,
    DateTime? actionStart,
    required String module,
    required String moduleObjectId,
    required enums.NewsStatus status,
  }) => News.empty().copyWith(
    id: id,
    title: title,
    start: start,
    end: end,
    entity: entity,
    location: location,
    actionStart: actionStart,
    module: module,
    moduleObjectId: moduleObjectId,
    status: status,
  );
}

/// Fake factory for [OrderBase].
class MockOrderBase {
  MockOrderBase._();
  static OrderBase get any => OrderBase.empty();
  static OrderBase withOnly({required String userId}) =>
      MockOrderBase.any.copyWith(userId: userId);

  static OrderBase withFields({
    required String userId,
    required String deliveryId,
    required List<String> productsIds,
    required enums.AmapSlotType collectionSlot,
    required List<int> productsQuantity,
  }) => OrderBase.empty().copyWith(
    userId: userId,
    deliveryId: deliveryId,
    productsIds: productsIds,
    collectionSlot: collectionSlot,
    productsQuantity: productsQuantity,
  );
}

/// Fake factory for [OrderEdit].
class MockOrderEdit {
  MockOrderEdit._();
  static OrderEdit get any => OrderEdit.empty();
  static OrderEdit withFields({
    List<String>? productsIds,
    enums.AmapSlotType? collectionSlot,
    List<int>? productsQuantity,
  }) => OrderEdit.empty().copyWith(
    productsIds: productsIds,
    collectionSlot: collectionSlot,
    productsQuantity: productsQuantity,
  );
}

/// Fake factory for [OrderReturn].
class MockOrderReturn {
  MockOrderReturn._();
  static OrderReturn get any => OrderReturn.empty();
  static OrderReturn withOnly({required String deliveryId}) =>
      MockOrderReturn.any.copyWith(deliveryId: deliveryId);

  static OrderReturn withFields({
    required CoreUserSimple user,
    required String deliveryId,
    required String deliveryName,
    required List<ProductQuantity> productsdetail,
    required enums.AmapSlotType collectionSlot,
    required String orderId,
    required int amount,
    required DateTime orderingDate,
    required DateTime deliveryDate,
  }) => OrderReturn.empty().copyWith(
    user: user,
    deliveryId: deliveryId,
    deliveryName: deliveryName,
    productsdetail: productsdetail,
    collectionSlot: collectionSlot,
    orderId: orderId,
    amount: amount,
    orderingDate: orderingDate,
    deliveryDate: deliveryDate,
  );
}

/// Fake factory for [PackTicketBase].
class MockPackTicketBase {
  MockPackTicketBase._();
  static PackTicketBase get any => PackTicketBase.empty();
  static PackTicketBase withOnly({required String raffleId}) =>
      MockPackTicketBase.any.copyWith(raffleId: raffleId);

  static PackTicketBase withFields({
    required int price,
    required int packSize,
    required String raffleId,
  }) => PackTicketBase.empty().copyWith(
    price: price,
    packSize: packSize,
    raffleId: raffleId,
  );
}

/// Fake factory for [PackTicketEdit].
class MockPackTicketEdit {
  MockPackTicketEdit._();
  static PackTicketEdit get any => PackTicketEdit.empty();
  static PackTicketEdit withOnly({String? raffleId}) =>
      MockPackTicketEdit.any.copyWith(raffleId: raffleId);

  static PackTicketEdit withFields({
    String? raffleId,
    int? price,
    int? packSize,
  }) => PackTicketEdit.empty().copyWith(
    raffleId: raffleId,
    price: price,
    packSize: packSize,
  );
}

/// Fake factory for [PackTicketSimple].
class MockPackTicketSimple {
  MockPackTicketSimple._();
  static PackTicketSimple get any => PackTicketSimple.empty();
  static PackTicketSimple withOnly({required String id}) =>
      MockPackTicketSimple.any.copyWith(id: id);

  static PackTicketSimple withFields({
    required int price,
    required int packSize,
    required String raffleId,
    required String id,
  }) => PackTicketSimple.empty().copyWith(
    price: price,
    packSize: packSize,
    raffleId: raffleId,
    id: id,
  );
}

/// Fake factory for [PaperBase].
class MockPaperBase {
  MockPaperBase._();
  static PaperBase get any => PaperBase.empty();
  static PaperBase withFields({
    required String name,
    required DateTime releaseDate,
  }) => PaperBase.empty().copyWith(name: name, releaseDate: releaseDate);
}

/// Fake factory for [PaperComplete].
class MockPaperComplete {
  MockPaperComplete._();
  static PaperComplete get any => PaperComplete.empty();
  static PaperComplete withOnly({required String id}) =>
      MockPaperComplete.any.copyWith(id: id);

  static PaperComplete withFields({
    required String name,
    required DateTime releaseDate,
    required String id,
  }) => PaperComplete.empty().copyWith(
    name: name,
    releaseDate: releaseDate,
    id: id,
  );
}

/// Fake factory for [PaperUpdate].
class MockPaperUpdate {
  MockPaperUpdate._();
  static PaperUpdate get any => PaperUpdate.empty();
  static PaperUpdate withFields({String? name, DateTime? releaseDate}) =>
      PaperUpdate.empty().copyWith(name: name, releaseDate: releaseDate);
}

/// Fake factory for [Participant].
class MockParticipant {
  MockParticipant._();
  static Participant get any => Participant.empty();
  static Participant withOnly({required String userId}) =>
      MockParticipant.any.copyWith(userId: userId);

  static Participant withFields({
    required String userId,
    required String sportId,
    required String editionId,
    required String schoolId,
    String? license,
    String? certificateFileId,
    required bool isLicenseValid,
    bool? substitute,
    required String teamId,
  }) => Participant.empty().copyWith(
    userId: userId,
    sportId: sportId,
    editionId: editionId,
    schoolId: schoolId,
    license: license,
    certificateFileId: certificateFileId,
    isLicenseValid: isLicenseValid,
    substitute: substitute,
    teamId: teamId,
  );
}

/// Fake factory for [ParticipantComplete].
class MockParticipantComplete {
  MockParticipantComplete._();
  static ParticipantComplete get any => ParticipantComplete.empty();
  static ParticipantComplete withOnly({required String userId}) =>
      MockParticipantComplete.any.copyWith(userId: userId);

  static ParticipantComplete withFields({
    required String userId,
    required String sportId,
    required String editionId,
    required String schoolId,
    String? license,
    String? certificateFileId,
    required bool isLicenseValid,
    bool? substitute,
    required String teamId,
    required CompetitionUser user,
    required Team team,
  }) => ParticipantComplete.empty().copyWith(
    userId: userId,
    sportId: sportId,
    editionId: editionId,
    schoolId: schoolId,
    license: license,
    certificateFileId: certificateFileId,
    isLicenseValid: isLicenseValid,
    substitute: substitute,
    teamId: teamId,
    user: user,
    team: team,
  );
}

/// Fake factory for [ParticipantInfo].
class MockParticipantInfo {
  MockParticipantInfo._();
  static ParticipantInfo get any => ParticipantInfo.empty();
  static ParticipantInfo withOnly({String? teamId}) =>
      MockParticipantInfo.any.copyWith(teamId: teamId);

  static ParticipantInfo withFields({
    String? license,
    bool? substitute,
    String? teamId,
  }) => ParticipantInfo.empty().copyWith(
    license: license,
    substitute: substitute,
    teamId: teamId,
  );
}

/// Fake factory for [PaymentUrl].
class MockPaymentUrl {
  MockPaymentUrl._();
  static PaymentUrl get any => PaymentUrl.empty();
  static PaymentUrl withFields({required String url}) =>
      PaymentUrl.empty().copyWith(url: url);
}

/// Fake factory for [PlantComplete].
class MockPlantComplete {
  MockPlantComplete._();
  static PlantComplete get any => PlantComplete.empty();
  static PlantComplete withOnly({required String id}) =>
      MockPlantComplete.any.copyWith(id: id);

  static PlantComplete withFields({
    required String id,
    required String reference,
    required enums.PlantState state,
    required String speciesId,
    required enums.PropagationMethod propagationMethod,
    int? nbSeedsEnvelope,
    DateTime? plantingDate,
    String? borrowerId,
    String? nickname,
    String? previousNote,
    String? currentNote,
    DateTime? borrowingDate,
    String? ancestorId,
    bool? confidential,
  }) => PlantComplete.empty().copyWith(
    id: id,
    reference: reference,
    state: state,
    speciesId: speciesId,
    propagationMethod: propagationMethod,
    nbSeedsEnvelope: nbSeedsEnvelope,
    plantingDate: plantingDate,
    borrowerId: borrowerId,
    nickname: nickname,
    previousNote: previousNote,
    currentNote: currentNote,
    borrowingDate: borrowingDate,
    ancestorId: ancestorId,
    confidential: confidential,
  );
}

/// Fake factory for [PlantCreation].
class MockPlantCreation {
  MockPlantCreation._();
  static PlantCreation get any => PlantCreation.empty();
  static PlantCreation withOnly({required String speciesId}) =>
      MockPlantCreation.any.copyWith(speciesId: speciesId);

  static PlantCreation withFields({
    required String speciesId,
    required enums.PropagationMethod propagationMethod,
    int? nbSeedsEnvelope,
    String? ancestorId,
    String? previousNote,
    bool? confidential,
  }) => PlantCreation.empty().copyWith(
    speciesId: speciesId,
    propagationMethod: propagationMethod,
    nbSeedsEnvelope: nbSeedsEnvelope,
    ancestorId: ancestorId,
    previousNote: previousNote,
    confidential: confidential,
  );
}

/// Fake factory for [PlantEdit].
class MockPlantEdit {
  MockPlantEdit._();
  static PlantEdit get any => PlantEdit.empty();
  static PlantEdit withFields({
    enums.PlantState? state,
    String? currentNote,
    bool? confidential,
    DateTime? plantingDate,
    DateTime? borrowingDate,
    String? nickname,
  }) => PlantEdit.empty().copyWith(
    state: state,
    currentNote: currentNote,
    confidential: confidential,
    plantingDate: plantingDate,
    borrowingDate: borrowingDate,
    nickname: nickname,
  );
}

/// Fake factory for [PlantSimple].
class MockPlantSimple {
  MockPlantSimple._();
  static PlantSimple get any => PlantSimple.empty();
  static PlantSimple withOnly({required String id}) =>
      MockPlantSimple.any.copyWith(id: id);

  static PlantSimple withFields({
    required String id,
    required String reference,
    required enums.PlantState state,
    required String speciesId,
    required enums.PropagationMethod propagationMethod,
    int? nbSeedsEnvelope,
    DateTime? plantingDate,
    String? borrowerId,
    String? nickname,
  }) => PlantSimple.empty().copyWith(
    id: id,
    reference: reference,
    state: state,
    speciesId: speciesId,
    propagationMethod: propagationMethod,
    nbSeedsEnvelope: nbSeedsEnvelope,
    plantingDate: plantingDate,
    borrowerId: borrowerId,
    nickname: nickname,
  );
}

/// Fake factory for [PrizeBase].
class MockPrizeBase {
  MockPrizeBase._();
  static PrizeBase get any => PrizeBase.empty();
  static PrizeBase withOnly({required String raffleId}) =>
      MockPrizeBase.any.copyWith(raffleId: raffleId);

  static PrizeBase withFields({
    required String name,
    required String description,
    required String raffleId,
    required int quantity,
  }) => PrizeBase.empty().copyWith(
    name: name,
    description: description,
    raffleId: raffleId,
    quantity: quantity,
  );
}

/// Fake factory for [PrizeEdit].
class MockPrizeEdit {
  MockPrizeEdit._();
  static PrizeEdit get any => PrizeEdit.empty();
  static PrizeEdit withOnly({String? raffleId}) =>
      MockPrizeEdit.any.copyWith(raffleId: raffleId);

  static PrizeEdit withFields({
    String? raffleId,
    String? description,
    String? name,
    int? quantity,
  }) => PrizeEdit.empty().copyWith(
    raffleId: raffleId,
    description: description,
    name: name,
    quantity: quantity,
  );
}

/// Fake factory for [PrizeSimple].
class MockPrizeSimple {
  MockPrizeSimple._();
  static PrizeSimple get any => PrizeSimple.empty();
  static PrizeSimple withOnly({required String id}) =>
      MockPrizeSimple.any.copyWith(id: id);

  static PrizeSimple withFields({
    required String name,
    required String description,
    required String raffleId,
    required int quantity,
    required String id,
  }) => PrizeSimple.empty().copyWith(
    name: name,
    description: description,
    raffleId: raffleId,
    quantity: quantity,
    id: id,
  );
}

/// Fake factory for [Product].
class MockProduct {
  MockProduct._();
  static Product get any => Product.empty();
  static Product withOnly({required String id}) =>
      MockProduct.any.copyWith(id: id);

  static Product withFields({
    required String name,
    bool? required,
    String? description,
    required String id,
    required String editionId,
  }) => Product.empty().copyWith(
    name: name,
    required: required,
    description: description,
    id: id,
    editionId: editionId,
  );
}

/// Fake factory for [ProductCompleteNoConstraint].
class MockProductCompleteNoConstraint {
  MockProductCompleteNoConstraint._();
  static ProductCompleteNoConstraint get any =>
      ProductCompleteNoConstraint.empty();
  static ProductCompleteNoConstraint withOnly({required String id}) =>
      MockProductCompleteNoConstraint.any.copyWith(id: id);

  static ProductCompleteNoConstraint withFields({
    required String nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    required bool availableOnline,
    required bool needsValidation,
    required int year,
    required String id,
    required String sellerId,
    List<AppModulesCdrSchemasCdrProductVariantComplete>? variants,
    MembershipSimple? relatedMembership,
    required List<GenerateTicketComplete> tickets,
  }) => ProductCompleteNoConstraint.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    availableOnline: availableOnline,
    needsValidation: needsValidation,
    year: year,
    id: id,
    sellerId: sellerId,
    variants: variants,
    relatedMembership: relatedMembership,
    tickets: tickets,
  );
}

/// Fake factory for [ProductQuantity].
class MockProductQuantity {
  MockProductQuantity._();
  static ProductQuantity get any => ProductQuantity.empty();
  static ProductQuantity withFields({
    required int quantity,
    required AppModulesAmapSchemasAmapProductComplete product,
  }) => ProductQuantity.empty().copyWith(quantity: quantity, product: product);
}

/// Fake factory for [ProductSimple].
class MockProductSimple {
  MockProductSimple._();
  static ProductSimple get any => ProductSimple.empty();
  static ProductSimple withFields({
    required String name,
    required int price,
    required String category,
  }) => ProductSimple.empty().copyWith(
    name: name,
    price: price,
    category: category,
  );
}

/// Fake factory for [ProductVariant].
class MockProductVariant {
  MockProductVariant._();
  static ProductVariant get any => ProductVariant.empty();
  static ProductVariant withOnly({required String id}) =>
      MockProductVariant.any.copyWith(id: id);

  static ProductVariant withFields({
    required String productId,
    required String name,
    String? description,
    required int price,
    bool? enabled,
    required bool unique,
    enums.ProductSchoolType? schoolType,
    enums.ProductPublicType? publicType,
    required String editionId,
    required String id,
  }) => ProductVariant.empty().copyWith(
    productId: productId,
    name: name,
    description: description,
    price: price,
    enabled: enabled,
    unique: unique,
    schoolType: schoolType,
    publicType: publicType,
    editionId: editionId,
    id: id,
  );
}

/// Fake factory for [ProductVariantStats].
class MockProductVariantStats {
  MockProductVariantStats._();
  static ProductVariantStats get any => ProductVariantStats.empty();
  static ProductVariantStats withOnly({required String id}) =>
      MockProductVariantStats.any.copyWith(id: id);

  static ProductVariantStats withFields({
    required String productId,
    required String name,
    String? description,
    required int price,
    bool? enabled,
    required bool unique,
    enums.ProductSchoolType? schoolType,
    enums.ProductPublicType? publicType,
    required String editionId,
    required String id,
    required int booked,
    required int paid,
  }) => ProductVariantStats.empty().copyWith(
    productId: productId,
    name: name,
    description: description,
    price: price,
    enabled: enabled,
    unique: unique,
    schoolType: schoolType,
    publicType: publicType,
    editionId: editionId,
    id: id,
    booked: booked,
    paid: paid,
  );
}

/// Fake factory for [Purchase].
class MockPurchase {
  MockPurchase._();
  static Purchase get any => Purchase.empty();
  static Purchase withOnly({required String productVariantId}) =>
      MockPurchase.any.copyWith(productVariantId: productVariantId);

  static Purchase withFields({
    required String productVariantId,
    required int quantity,
    required String userId,
    required String editionId,
    required bool validated,
    required DateTime purchasedOn,
  }) => Purchase.empty().copyWith(
    productVariantId: productVariantId,
    quantity: quantity,
    userId: userId,
    editionId: editionId,
    validated: validated,
    purchasedOn: purchasedOn,
  );
}

/// Fake factory for [PurchaseEdit].
class MockPurchaseEdit {
  MockPurchaseEdit._();
  static PurchaseEdit get any => PurchaseEdit.empty();
  static PurchaseEdit withFields({int? quantity, bool? validated}) =>
      PurchaseEdit.empty().copyWith(quantity: quantity, validated: validated);
}

/// Fake factory for [PurchaseReturn].
class MockPurchaseReturn {
  MockPurchaseReturn._();
  static PurchaseReturn get any => PurchaseReturn.empty();
  static PurchaseReturn withOnly({required String userId}) =>
      MockPurchaseReturn.any.copyWith(userId: userId);

  static PurchaseReturn withFields({
    required int quantity,
    required String userId,
    required String productVariantId,
    required bool validated,
    required DateTime purchasedOn,
    required int price,
    required AppModulesCdrSchemasCdrProductComplete product,
    required SellerComplete seller,
  }) => PurchaseReturn.empty().copyWith(
    quantity: quantity,
    userId: userId,
    productVariantId: productVariantId,
    validated: validated,
    purchasedOn: purchasedOn,
    price: price,
    product: product,
    seller: seller,
  );
}

/// Fake factory for [Question].
class MockQuestion {
  MockQuestion._();
  static Question get any => Question.empty();
  static Question withOnly({required String id}) =>
      MockQuestion.any.copyWith(id: id);

  static Question withFields({
    required String id,
    required String eventId,
    required String question,
    required enums.AnswerType answerType,
    int? price,
    required bool required,
    required bool disabled,
  }) => Question.empty().copyWith(
    id: id,
    eventId: eventId,
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}

/// Fake factory for [QuestionAdmin].
class MockQuestionAdmin {
  MockQuestionAdmin._();
  static QuestionAdmin get any => QuestionAdmin.empty();
  static QuestionAdmin withOnly({required String id}) =>
      MockQuestionAdmin.any.copyWith(id: id);

  static QuestionAdmin withFields({
    required String id,
    required String eventId,
    required String question,
    required enums.AnswerType answerType,
    int? price,
    required bool required,
    required bool disabled,
  }) => QuestionAdmin.empty().copyWith(
    id: id,
    eventId: eventId,
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}

/// Fake factory for [QuestionCreate].
class MockQuestionCreate {
  MockQuestionCreate._();
  static QuestionCreate get any => QuestionCreate.empty();
  static QuestionCreate withFields({
    required String question,
    required enums.AnswerType answerType,
    int? price,
    required bool required,
  }) => QuestionCreate.empty().copyWith(
    question: question,
    answerType: answerType,
    price: price,
    required: required,
  );
}

/// Fake factory for [QuestionPublic].
class MockQuestionPublic {
  MockQuestionPublic._();
  static QuestionPublic get any => QuestionPublic.empty();
  static QuestionPublic withOnly({required String id}) =>
      MockQuestionPublic.any.copyWith(id: id);

  static QuestionPublic withFields({
    required String id,
    required String eventId,
    required String question,
    required enums.AnswerType answerType,
    int? price,
    required bool required,
    required bool disabled,
  }) => QuestionPublic.empty().copyWith(
    id: id,
    eventId: eventId,
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}

/// Fake factory for [QuestionUpdate].
class MockQuestionUpdate {
  MockQuestionUpdate._();
  static QuestionUpdate get any => QuestionUpdate.empty();
  static QuestionUpdate withFields({
    String? question,
    enums.AnswerType? answerType,
    int? price,
    bool? required,
    bool? disabled,
  }) => QuestionUpdate.empty().copyWith(
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}

/// Fake factory for [RaffleBase].
class MockRaffleBase {
  MockRaffleBase._();
  static RaffleBase get any => RaffleBase.empty();
  static RaffleBase withOnly({required String groupId}) =>
      MockRaffleBase.any.copyWith(groupId: groupId);

  static RaffleBase withFields({
    required String name,
    enums.RaffleStatusType? status,
    String? description,
    required String groupId,
  }) => RaffleBase.empty().copyWith(
    name: name,
    status: status,
    description: description,
    groupId: groupId,
  );
}

/// Fake factory for [RaffleComplete].
class MockRaffleComplete {
  MockRaffleComplete._();
  static RaffleComplete get any => RaffleComplete.empty();
  static RaffleComplete withOnly({required String id}) =>
      MockRaffleComplete.any.copyWith(id: id);

  static RaffleComplete withFields({
    required String name,
    enums.RaffleStatusType? status,
    String? description,
    required String groupId,
    required String id,
  }) => RaffleComplete.empty().copyWith(
    name: name,
    status: status,
    description: description,
    groupId: groupId,
    id: id,
  );
}

/// Fake factory for [RaffleEdit].
class MockRaffleEdit {
  MockRaffleEdit._();
  static RaffleEdit get any => RaffleEdit.empty();
  static RaffleEdit withFields({String? name, String? description}) =>
      RaffleEdit.empty().copyWith(name: name, description: description);
}

/// Fake factory for [RaffleStats].
class MockRaffleStats {
  MockRaffleStats._();
  static RaffleStats get any => RaffleStats.empty();
  static RaffleStats withFields({
    required int ticketsSold,
    required int amountRaised,
  }) => RaffleStats.empty().copyWith(
    ticketsSold: ticketsSold,
    amountRaised: amountRaised,
  );
}

/// Fake factory for [RaidDriveFoldersCreation].
class MockRaidDriveFoldersCreation {
  MockRaidDriveFoldersCreation._();
  static RaidDriveFoldersCreation get any => RaidDriveFoldersCreation.empty();
  static RaidDriveFoldersCreation withOnly({required String parentFolderId}) =>
      MockRaidDriveFoldersCreation.any.copyWith(parentFolderId: parentFolderId);

  static RaidDriveFoldersCreation withFields({
    required String parentFolderId,
  }) =>
      RaidDriveFoldersCreation.empty().copyWith(parentFolderId: parentFolderId);
}

/// Fake factory for [RaidInformation].
class MockRaidInformation {
  MockRaidInformation._();
  static RaidInformation get any => RaidInformation.empty();
  static RaidInformation withOnly({String? raidRulesId}) =>
      MockRaidInformation.any.copyWith(raidRulesId: raidRulesId);

  static RaidInformation withFields({
    DateTime? raidStartDate,
    DateTime? raidEndDate,
    DateTime? raidRegisteringEndDate,
    String? paymentLink,
    String? contact,
    EmergencyContact? president,
    EmergencyContact? volunteerResponsible,
    EmergencyContact? securityResponsible,
    EmergencyContact? rescue,
    String? raidRulesId,
    String? raidInformationId,
  }) => RaidInformation.empty().copyWith(
    raidStartDate: raidStartDate,
    raidEndDate: raidEndDate,
    raidRegisteringEndDate: raidRegisteringEndDate,
    paymentLink: paymentLink,
    contact: contact,
    president: president,
    volunteerResponsible: volunteerResponsible,
    securityResponsible: securityResponsible,
    rescue: rescue,
    raidRulesId: raidRulesId,
    raidInformationId: raidInformationId,
  );
}

/// Fake factory for [RaidParticipant].
class MockRaidParticipant {
  MockRaidParticipant._();
  static RaidParticipant get any => RaidParticipant.empty();
  static RaidParticipant withOnly({required String id}) =>
      MockRaidParticipant.any.copyWith(id: id);

  static RaidParticipant withFields({
    required String name,
    required String firstname,
    required DateTime birthday,
    required String phone,
    required String email,
    required String id,
    enums.Size? bikeSize,
    enums.Size? tShirtSize,
    String? situation,
    required double validationProgress,
    required bool payment,
    required bool tShirtPayment,
    required int numberOfDocument,
    required int numberOfValidatedDocument,
    String? address,
    String? otherSchool,
    String? company,
    String? diet,
    Document? idCard,
    Document? medicalCertificate,
    SecurityFile? securityFile,
    Document? studentCard,
    Document? raidRules,
    Document? parentAuthorization,
    required bool attestationOnHonour,
    required bool isMinor,
  }) => RaidParticipant.empty().copyWith(
    name: name,
    firstname: firstname,
    birthday: birthday,
    phone: phone,
    email: email,
    id: id,
    bikeSize: bikeSize,
    tShirtSize: tShirtSize,
    situation: situation,
    validationProgress: validationProgress,
    payment: payment,
    tShirtPayment: tShirtPayment,
    numberOfDocument: numberOfDocument,
    numberOfValidatedDocument: numberOfValidatedDocument,
    address: address,
    otherSchool: otherSchool,
    company: company,
    diet: diet,
    idCard: idCard,
    medicalCertificate: medicalCertificate,
    securityFile: securityFile,
    studentCard: studentCard,
    raidRules: raidRules,
    parentAuthorization: parentAuthorization,
    attestationOnHonour: attestationOnHonour,
    isMinor: isMinor,
  );
}

/// Fake factory for [RaidParticipantBase].
class MockRaidParticipantBase {
  MockRaidParticipantBase._();
  static RaidParticipantBase get any => RaidParticipantBase.empty();
  static RaidParticipantBase withFields({
    required String name,
    required String firstname,
    required DateTime birthday,
    required String phone,
    required String email,
  }) => RaidParticipantBase.empty().copyWith(
    name: name,
    firstname: firstname,
    birthday: birthday,
    phone: phone,
    email: email,
  );
}

/// Fake factory for [RaidParticipantPreview].
class MockRaidParticipantPreview {
  MockRaidParticipantPreview._();
  static RaidParticipantPreview get any => RaidParticipantPreview.empty();
  static RaidParticipantPreview withOnly({required String id}) =>
      MockRaidParticipantPreview.any.copyWith(id: id);

  static RaidParticipantPreview withFields({
    required String name,
    required String firstname,
    required DateTime birthday,
    required String phone,
    required String email,
    required String id,
    enums.Size? bikeSize,
    enums.Size? tShirtSize,
    String? situation,
    required double validationProgress,
    required bool payment,
    required bool tShirtPayment,
    required int numberOfDocument,
    required int numberOfValidatedDocument,
  }) => RaidParticipantPreview.empty().copyWith(
    name: name,
    firstname: firstname,
    birthday: birthday,
    phone: phone,
    email: email,
    id: id,
    bikeSize: bikeSize,
    tShirtSize: tShirtSize,
    situation: situation,
    validationProgress: validationProgress,
    payment: payment,
    tShirtPayment: tShirtPayment,
    numberOfDocument: numberOfDocument,
    numberOfValidatedDocument: numberOfValidatedDocument,
  );
}

/// Fake factory for [RaidParticipantUpdate].
class MockRaidParticipantUpdate {
  MockRaidParticipantUpdate._();
  static RaidParticipantUpdate get any => RaidParticipantUpdate.empty();
  static RaidParticipantUpdate withOnly({String? idCardId}) =>
      MockRaidParticipantUpdate.any.copyWith(idCardId: idCardId);

  static RaidParticipantUpdate withFields({
    String? name,
    String? firstname,
    DateTime? birthday,
    String? address,
    String? phone,
    String? email,
    enums.Size? bikeSize,
    enums.Size? tShirtSize,
    String? situation,
    String? otherSchool,
    String? company,
    String? diet,
    bool? attestationOnHonour,
    String? idCardId,
    String? medicalCertificateId,
    String? securityFileId,
    String? studentCardId,
    String? raidRulesId,
    String? parentAuthorizationId,
  }) => RaidParticipantUpdate.empty().copyWith(
    name: name,
    firstname: firstname,
    birthday: birthday,
    address: address,
    phone: phone,
    email: email,
    bikeSize: bikeSize,
    tShirtSize: tShirtSize,
    situation: situation,
    otherSchool: otherSchool,
    company: company,
    diet: diet,
    attestationOnHonour: attestationOnHonour,
    idCardId: idCardId,
    medicalCertificateId: medicalCertificateId,
    securityFileId: securityFileId,
    studentCardId: studentCardId,
    raidRulesId: raidRulesId,
    parentAuthorizationId: parentAuthorizationId,
  );
}

/// Fake factory for [RaidPrice].
class MockRaidPrice {
  MockRaidPrice._();
  static RaidPrice get any => RaidPrice.empty();
  static RaidPrice withFields({
    int? studentPrice,
    int? partnerPrice,
    int? externalPrice,
    int? tShirtPrice,
  }) => RaidPrice.empty().copyWith(
    studentPrice: studentPrice,
    partnerPrice: partnerPrice,
    externalPrice: externalPrice,
    tShirtPrice: tShirtPrice,
  );
}

/// Fake factory for [RaidTeam].
class MockRaidTeam {
  MockRaidTeam._();
  static RaidTeam get any => RaidTeam.empty();
  static RaidTeam withOnly({required String id}) =>
      MockRaidTeam.any.copyWith(id: id);

  static RaidTeam withFields({
    required String name,
    required String id,
    int? number,
    required RaidParticipant captain,
    RaidParticipant? second,
    enums.Difficulty? difficulty,
    enums.MeetingPlace? meetingPlace,
    required double validationProgress,
    String? fileId,
  }) => RaidTeam.empty().copyWith(
    name: name,
    id: id,
    number: number,
    captain: captain,
    second: second,
    difficulty: difficulty,
    meetingPlace: meetingPlace,
    validationProgress: validationProgress,
    fileId: fileId,
  );
}

/// Fake factory for [RaidTeamBase].
class MockRaidTeamBase {
  MockRaidTeamBase._();
  static RaidTeamBase get any => RaidTeamBase.empty();
  static RaidTeamBase withFields({required String name}) =>
      RaidTeamBase.empty().copyWith(name: name);
}

/// Fake factory for [RaidTeamPreview].
class MockRaidTeamPreview {
  MockRaidTeamPreview._();
  static RaidTeamPreview get any => RaidTeamPreview.empty();
  static RaidTeamPreview withOnly({required String id}) =>
      MockRaidTeamPreview.any.copyWith(id: id);

  static RaidTeamPreview withFields({
    required String name,
    required String id,
    int? number,
    required RaidParticipantPreview captain,
    RaidParticipantPreview? second,
    enums.Difficulty? difficulty,
    enums.MeetingPlace? meetingPlace,
    required double validationProgress,
  }) => RaidTeamPreview.empty().copyWith(
    name: name,
    id: id,
    number: number,
    captain: captain,
    second: second,
    difficulty: difficulty,
    meetingPlace: meetingPlace,
    validationProgress: validationProgress,
  );
}

/// Fake factory for [RaidTeamUpdate].
class MockRaidTeamUpdate {
  MockRaidTeamUpdate._();
  static RaidTeamUpdate get any => RaidTeamUpdate.empty();
  static RaidTeamUpdate withFields({
    String? name,
    int? number,
    enums.Difficulty? difficulty,
    enums.MeetingPlace? meetingPlace,
  }) => RaidTeamUpdate.empty().copyWith(
    name: name,
    number: number,
    difficulty: difficulty,
    meetingPlace: meetingPlace,
  );
}

/// Fake factory for [Recommendation].
class MockRecommendation {
  MockRecommendation._();
  static Recommendation get any => Recommendation.empty();
  static Recommendation withOnly({required String id}) =>
      MockRecommendation.any.copyWith(id: id);

  static Recommendation withFields({
    required String title,
    String? code,
    required String summary,
    required String description,
    required String id,
    required DateTime creation,
  }) => Recommendation.empty().copyWith(
    title: title,
    code: code,
    summary: summary,
    description: description,
    id: id,
    creation: creation,
  );
}

/// Fake factory for [RecommendationBase].
class MockRecommendationBase {
  MockRecommendationBase._();
  static RecommendationBase get any => RecommendationBase.empty();
  static RecommendationBase withFields({
    required String title,
    String? code,
    required String summary,
    required String description,
  }) => RecommendationBase.empty().copyWith(
    title: title,
    code: code,
    summary: summary,
    description: description,
  );
}

/// Fake factory for [RecommendationEdit].
class MockRecommendationEdit {
  MockRecommendationEdit._();
  static RecommendationEdit get any => RecommendationEdit.empty();
  static RecommendationEdit withFields({
    String? title,
    String? code,
    String? summary,
    String? description,
  }) => RecommendationEdit.empty().copyWith(
    title: title,
    code: code,
    summary: summary,
    description: description,
  );
}

/// Fake factory for [RefundBase].
class MockRefundBase {
  MockRefundBase._();
  static RefundBase get any => RefundBase.empty();
  static RefundBase withOnly({required String id}) =>
      MockRefundBase.any.copyWith(id: id);

  static RefundBase withFields({
    required String id,
    required int total,
    required DateTime creation,
    required String transactionId,
    String? sellerUserId,
    required String creditedWalletId,
    required String debitedWalletId,
  }) => RefundBase.empty().copyWith(
    id: id,
    total: total,
    creation: creation,
    transactionId: transactionId,
    sellerUserId: sellerUserId,
    creditedWalletId: creditedWalletId,
    debitedWalletId: debitedWalletId,
  );
}

/// Fake factory for [RefundInfo].
class MockRefundInfo {
  MockRefundInfo._();
  static RefundInfo get any => RefundInfo.empty();
  static RefundInfo withFields({required bool completeRefund, int? amount}) =>
      RefundInfo.empty().copyWith(
        completeRefund: completeRefund,
        amount: amount,
      );
}

/// Fake factory for [Request$].
class MockRequest$ {
  MockRequest$._();
  static Request$ get any => Request$.empty();
  static Request$ withOnly({required String id}) =>
      MockRequest$.any.copyWith(id: id);

  static Request$ withFields({
    required String id,
    required String walletId,
    required DateTime creation,
    required DateTime expirationDate,
    required int total,
    required String storeId,
    required String name,
    String? storeNote,
    required String module,
    required String objectId,
    required enums.RequestStatus status,
    String? transactionId,
  }) => Request$.empty().copyWith(
    id: id,
    walletId: walletId,
    creation: creation,
    expirationDate: expirationDate,
    total: total,
    storeId: storeId,
    name: name,
    storeNote: storeNote,
    module: module,
    objectId: objectId,
    status: status,
    transactionId: transactionId,
  );
}

/// Fake factory for [ResetPasswordRequest].
class MockResetPasswordRequest {
  MockResetPasswordRequest._();
  static ResetPasswordRequest get any => ResetPasswordRequest.empty();
  static ResetPasswordRequest withFields({
    required String resetToken,
    required String newPassword,
  }) => ResetPasswordRequest.empty().copyWith(
    resetToken: resetToken,
    newPassword: newPassword,
  );
}

/// Fake factory for [RoleTagsReturn].
class MockRoleTagsReturn {
  MockRoleTagsReturn._();
  static RoleTagsReturn get any => RoleTagsReturn.empty();
  static RoleTagsReturn withFields({required List<String> tags}) =>
      RoleTagsReturn.empty().copyWith(tags: tags);
}

/// Fake factory for [RoomBase].
class MockRoomBase {
  MockRoomBase._();
  static RoomBase get any => RoomBase.empty();
  static RoomBase withOnly({required String managerId}) =>
      MockRoomBase.any.copyWith(managerId: managerId);

  static RoomBase withFields({
    required String name,
    required String managerId,
  }) => RoomBase.empty().copyWith(name: name, managerId: managerId);
}

/// Fake factory for [RoomComplete].
class MockRoomComplete {
  MockRoomComplete._();
  static RoomComplete get any => RoomComplete.empty();
  static RoomComplete withOnly({required String id}) =>
      MockRoomComplete.any.copyWith(id: id);

  static RoomComplete withFields({
    required String name,
    required String managerId,
    required String id,
  }) => RoomComplete.empty().copyWith(name: name, managerId: managerId, id: id);
}

/// Fake factory for [ScanInfo].
class MockScanInfo {
  MockScanInfo._();
  static ScanInfo get any => ScanInfo.empty();
  static ScanInfo withOnly({required String id}) =>
      MockScanInfo.any.copyWith(id: id);

  static ScanInfo withFields({
    required String id,
    required int tot,
    required DateTime iat,
    required String key,
    required bool store,
    required String signature,
    bool? bypassMembership,
  }) => ScanInfo.empty().copyWith(
    id: id,
    tot: tot,
    iat: iat,
    key: key,
    store: store,
    signature: signature,
    bypassMembership: bypassMembership,
  );
}

/// Fake factory for [SchoolExtension].
class MockSchoolExtension {
  MockSchoolExtension._();
  static SchoolExtension get any => SchoolExtension.empty();
  static SchoolExtension withOnly({required String schoolId}) =>
      MockSchoolExtension.any.copyWith(schoolId: schoolId);

  static SchoolExtension withFields({
    required String schoolId,
    required bool fromLyon,
    bool? active,
    bool? inscriptionEnabled,
    required CoreSchool school,
  }) => SchoolExtension.empty().copyWith(
    schoolId: schoolId,
    fromLyon: fromLyon,
    active: active,
    inscriptionEnabled: inscriptionEnabled,
    school: school,
  );
}

/// Fake factory for [SchoolExtensionBase].
class MockSchoolExtensionBase {
  MockSchoolExtensionBase._();
  static SchoolExtensionBase get any => SchoolExtensionBase.empty();
  static SchoolExtensionBase withOnly({required String schoolId}) =>
      MockSchoolExtensionBase.any.copyWith(schoolId: schoolId);

  static SchoolExtensionBase withFields({
    required String schoolId,
    required bool fromLyon,
    bool? active,
    bool? inscriptionEnabled,
  }) => SchoolExtensionBase.empty().copyWith(
    schoolId: schoolId,
    fromLyon: fromLyon,
    active: active,
    inscriptionEnabled: inscriptionEnabled,
  );
}

/// Fake factory for [SchoolExtensionEdit].
class MockSchoolExtensionEdit {
  MockSchoolExtensionEdit._();
  static SchoolExtensionEdit get any => SchoolExtensionEdit.empty();
  static SchoolExtensionEdit withFields({
    bool? fromLyon,
    bool? active,
    bool? inscriptionEnabled,
  }) => SchoolExtensionEdit.empty().copyWith(
    fromLyon: fromLyon,
    active: active,
    inscriptionEnabled: inscriptionEnabled,
  );
}

/// Fake factory for [SchoolGeneralQuota].
class MockSchoolGeneralQuota {
  MockSchoolGeneralQuota._();
  static SchoolGeneralQuota get any => SchoolGeneralQuota.empty();
  static SchoolGeneralQuota withOnly({required String schoolId}) =>
      MockSchoolGeneralQuota.any.copyWith(schoolId: schoolId);

  static SchoolGeneralQuota withFields({
    int? athleteQuota,
    int? cameramanQuota,
    int? pompomQuota,
    int? fanfareQuota,
    int? athleteCameramanQuota,
    int? athletePompomQuota,
    int? athleteFanfareQuota,
    int? nonAthleteCameramanQuota,
    int? nonAthletePompomQuota,
    int? nonAthleteFanfareQuota,
    required String schoolId,
    required String editionId,
  }) => SchoolGeneralQuota.empty().copyWith(
    athleteQuota: athleteQuota,
    cameramanQuota: cameramanQuota,
    pompomQuota: pompomQuota,
    fanfareQuota: fanfareQuota,
    athleteCameramanQuota: athleteCameramanQuota,
    athletePompomQuota: athletePompomQuota,
    athleteFanfareQuota: athleteFanfareQuota,
    nonAthleteCameramanQuota: nonAthleteCameramanQuota,
    nonAthletePompomQuota: nonAthletePompomQuota,
    nonAthleteFanfareQuota: nonAthleteFanfareQuota,
    schoolId: schoolId,
    editionId: editionId,
  );
}

/// Fake factory for [SchoolGeneralQuotaBase].
class MockSchoolGeneralQuotaBase {
  MockSchoolGeneralQuotaBase._();
  static SchoolGeneralQuotaBase get any => SchoolGeneralQuotaBase.empty();
  static SchoolGeneralQuotaBase withFields({
    int? athleteQuota,
    int? cameramanQuota,
    int? pompomQuota,
    int? fanfareQuota,
    int? athleteCameramanQuota,
    int? athletePompomQuota,
    int? athleteFanfareQuota,
    int? nonAthleteCameramanQuota,
    int? nonAthletePompomQuota,
    int? nonAthleteFanfareQuota,
  }) => SchoolGeneralQuotaBase.empty().copyWith(
    athleteQuota: athleteQuota,
    cameramanQuota: cameramanQuota,
    pompomQuota: pompomQuota,
    fanfareQuota: fanfareQuota,
    athleteCameramanQuota: athleteCameramanQuota,
    athletePompomQuota: athletePompomQuota,
    athleteFanfareQuota: athleteFanfareQuota,
    nonAthleteCameramanQuota: nonAthleteCameramanQuota,
    nonAthletePompomQuota: nonAthletePompomQuota,
    nonAthleteFanfareQuota: nonAthleteFanfareQuota,
  );
}

/// Fake factory for [SchoolProductQuota].
class MockSchoolProductQuota {
  MockSchoolProductQuota._();
  static SchoolProductQuota get any => SchoolProductQuota.empty();
  static SchoolProductQuota withOnly({required String productId}) =>
      MockSchoolProductQuota.any.copyWith(productId: productId);

  static SchoolProductQuota withFields({
    required String productId,
    required int quota,
    required String schoolId,
    required String editionId,
  }) => SchoolProductQuota.empty().copyWith(
    productId: productId,
    quota: quota,
    schoolId: schoolId,
    editionId: editionId,
  );
}

/// Fake factory for [SchoolProductQuotaBase].
class MockSchoolProductQuotaBase {
  MockSchoolProductQuotaBase._();
  static SchoolProductQuotaBase get any => SchoolProductQuotaBase.empty();
  static SchoolProductQuotaBase withOnly({required String productId}) =>
      MockSchoolProductQuotaBase.any.copyWith(productId: productId);

  static SchoolProductQuotaBase withFields({
    required String productId,
    required int quota,
  }) => SchoolProductQuotaBase.empty().copyWith(
    productId: productId,
    quota: quota,
  );
}

/// Fake factory for [SchoolProductQuotaEdit].
class MockSchoolProductQuotaEdit {
  MockSchoolProductQuotaEdit._();
  static SchoolProductQuotaEdit get any => SchoolProductQuotaEdit.empty();
  static SchoolProductQuotaEdit withFields({required int quota}) =>
      SchoolProductQuotaEdit.empty().copyWith(quota: quota);
}

/// Fake factory for [SchoolResult].
class MockSchoolResult {
  MockSchoolResult._();
  static SchoolResult get any => SchoolResult.empty();
  static SchoolResult withOnly({required String schoolId}) =>
      MockSchoolResult.any.copyWith(schoolId: schoolId);

  static SchoolResult withFields({
    required String schoolId,
    required int totalPoints,
  }) => SchoolResult.empty().copyWith(
    schoolId: schoolId,
    totalPoints: totalPoints,
  );
}

/// Fake factory for [SchoolSportQuota].
class MockSchoolSportQuota {
  MockSchoolSportQuota._();
  static SchoolSportQuota get any => SchoolSportQuota.empty();
  static SchoolSportQuota withOnly({required String schoolId}) =>
      MockSchoolSportQuota.any.copyWith(schoolId: schoolId);

  static SchoolSportQuota withFields({
    int? participantQuota,
    int? teamQuota,
    required String schoolId,
    required String sportId,
    required String editionId,
  }) => SchoolSportQuota.empty().copyWith(
    participantQuota: participantQuota,
    teamQuota: teamQuota,
    schoolId: schoolId,
    sportId: sportId,
    editionId: editionId,
  );
}

/// Fake factory for [SchoolSportQuotaEdit].
class MockSchoolSportQuotaEdit {
  MockSchoolSportQuotaEdit._();
  static SchoolSportQuotaEdit get any => SchoolSportQuotaEdit.empty();
  static SchoolSportQuotaEdit withFields({
    int? participantQuota,
    int? teamQuota,
  }) => SchoolSportQuotaEdit.empty().copyWith(
    participantQuota: participantQuota,
    teamQuota: teamQuota,
  );
}

/// Fake factory for [SectionBase].
class MockSectionBase {
  MockSectionBase._();
  static SectionBase get any => SectionBase.empty();
  static SectionBase withFields({
    required String name,
    required String description,
  }) => SectionBase.empty().copyWith(name: name, description: description);
}

/// Fake factory for [SectionComplete].
class MockSectionComplete {
  MockSectionComplete._();
  static SectionComplete get any => SectionComplete.empty();
  static SectionComplete withOnly({required String id}) =>
      MockSectionComplete.any.copyWith(id: id);

  static SectionComplete withFields({
    required String name,
    required String description,
    required String id,
  }) => SectionComplete.empty().copyWith(
    name: name,
    description: description,
    id: id,
  );
}

/// Fake factory for [SecurityFile].
class MockSecurityFile {
  MockSecurityFile._();
  static SecurityFile get any => SecurityFile.empty();
  static SecurityFile withOnly({required String id}) =>
      MockSecurityFile.any.copyWith(id: id);

  static SecurityFile withFields({
    String? allergy,
    required bool asthma,
    bool? intensiveCareUnit,
    String? intensiveCareUnitWhen,
    String? ongoingTreatment,
    String? sicknesses,
    String? hospitalization,
    String? surgicalOperation,
    String? trauma,
    String? family,
    String? emergencyPersonFirstname,
    String? emergencyPersonName,
    String? emergencyPersonPhone,
    String? fileId,
    required enums.DocumentValidation validation,
    required String id,
  }) => SecurityFile.empty().copyWith(
    allergy: allergy,
    asthma: asthma,
    intensiveCareUnit: intensiveCareUnit,
    intensiveCareUnitWhen: intensiveCareUnitWhen,
    ongoingTreatment: ongoingTreatment,
    sicknesses: sicknesses,
    hospitalization: hospitalization,
    surgicalOperation: surgicalOperation,
    trauma: trauma,
    family: family,
    emergencyPersonFirstname: emergencyPersonFirstname,
    emergencyPersonName: emergencyPersonName,
    emergencyPersonPhone: emergencyPersonPhone,
    fileId: fileId,
    validation: validation,
    id: id,
  );
}

/// Fake factory for [SecurityFileBase].
class MockSecurityFileBase {
  MockSecurityFileBase._();
  static SecurityFileBase get any => SecurityFileBase.empty();
  static SecurityFileBase withOnly({String? emergencyPersonName}) =>
      MockSecurityFileBase.any.copyWith(
        emergencyPersonName: emergencyPersonName,
      );

  static SecurityFileBase withFields({
    String? allergy,
    required bool asthma,
    bool? intensiveCareUnit,
    String? intensiveCareUnitWhen,
    String? ongoingTreatment,
    String? sicknesses,
    String? hospitalization,
    String? surgicalOperation,
    String? trauma,
    String? family,
    String? emergencyPersonFirstname,
    String? emergencyPersonName,
    String? emergencyPersonPhone,
    String? fileId,
  }) => SecurityFileBase.empty().copyWith(
    allergy: allergy,
    asthma: asthma,
    intensiveCareUnit: intensiveCareUnit,
    intensiveCareUnitWhen: intensiveCareUnitWhen,
    ongoingTreatment: ongoingTreatment,
    sicknesses: sicknesses,
    hospitalization: hospitalization,
    surgicalOperation: surgicalOperation,
    trauma: trauma,
    family: family,
    emergencyPersonFirstname: emergencyPersonFirstname,
    emergencyPersonName: emergencyPersonName,
    emergencyPersonPhone: emergencyPersonPhone,
    fileId: fileId,
  );
}

/// Fake factory for [SeedLibraryInformation].
class MockSeedLibraryInformation {
  MockSeedLibraryInformation._();
  static SeedLibraryInformation get any => SeedLibraryInformation.empty();
  static SeedLibraryInformation withFields({
    String? facebookUrl,
    String? forumUrl,
    String? description,
    String? contact,
  }) => SeedLibraryInformation.empty().copyWith(
    facebookUrl: facebookUrl,
    forumUrl: forumUrl,
    description: description,
    contact: contact,
  );
}

/// Fake factory for [Seller].
class MockSeller {
  MockSeller._();
  static Seller get any => Seller.empty();
  static Seller withOnly({required String userId}) =>
      MockSeller.any.copyWith(userId: userId);

  static Seller withFields({
    required String userId,
    required String storeId,
    required bool canBank,
    required bool canSeeHistory,
    required bool canCancel,
    required bool canManageSellers,
    required bool canManageEvents,
    required CoreUserSimple user,
  }) => Seller.empty().copyWith(
    userId: userId,
    storeId: storeId,
    canBank: canBank,
    canSeeHistory: canSeeHistory,
    canCancel: canCancel,
    canManageSellers: canManageSellers,
    canManageEvents: canManageEvents,
    user: user,
  );
}

/// Fake factory for [SellerBase].
class MockSellerBase {
  MockSellerBase._();
  static SellerBase get any => SellerBase.empty();
  static SellerBase withOnly({required String groupId}) =>
      MockSellerBase.any.copyWith(groupId: groupId);

  static SellerBase withFields({
    required String name,
    required String groupId,
    required int order,
  }) => SellerBase.empty().copyWith(name: name, groupId: groupId, order: order);
}

/// Fake factory for [SellerComplete].
class MockSellerComplete {
  MockSellerComplete._();
  static SellerComplete get any => SellerComplete.empty();
  static SellerComplete withOnly({required String id}) =>
      MockSellerComplete.any.copyWith(id: id);

  static SellerComplete withFields({
    required String name,
    required String groupId,
    required int order,
    required String id,
  }) => SellerComplete.empty().copyWith(
    name: name,
    groupId: groupId,
    order: order,
    id: id,
  );
}

/// Fake factory for [SellerCreation].
class MockSellerCreation {
  MockSellerCreation._();
  static SellerCreation get any => SellerCreation.empty();
  static SellerCreation withOnly({required String userId}) =>
      MockSellerCreation.any.copyWith(userId: userId);

  static SellerCreation withFields({
    required String userId,
    required bool canBank,
    required bool canSeeHistory,
    required bool canCancel,
    required bool canManageSellers,
    bool? canManageEvents,
  }) => SellerCreation.empty().copyWith(
    userId: userId,
    canBank: canBank,
    canSeeHistory: canSeeHistory,
    canCancel: canCancel,
    canManageSellers: canManageSellers,
    canManageEvents: canManageEvents,
  );
}

/// Fake factory for [SellerEdit].
class MockSellerEdit {
  MockSellerEdit._();
  static SellerEdit get any => SellerEdit.empty();
  static SellerEdit withOnly({String? groupId}) =>
      MockSellerEdit.any.copyWith(groupId: groupId);

  static SellerEdit withFields({String? name, String? groupId, int? order}) =>
      SellerEdit.empty().copyWith(name: name, groupId: groupId, order: order);
}

/// Fake factory for [SellerUpdate].
class MockSellerUpdate {
  MockSellerUpdate._();
  static SellerUpdate get any => SellerUpdate.empty();
  static SellerUpdate withFields({
    bool? canBank,
    bool? canSeeHistory,
    bool? canCancel,
    bool? canManageSellers,
    bool? canManageEvents,
  }) => SellerUpdate.empty().copyWith(
    canBank: canBank,
    canSeeHistory: canSeeHistory,
    canCancel: canCancel,
    canManageSellers: canManageSellers,
    canManageEvents: canManageEvents,
  );
}

/// Fake factory for [Session].
class MockSession {
  MockSession._();
  static Session get any => Session.empty();
  static Session withOnly({required String id}) =>
      MockSession.any.copyWith(id: id);

  static Session withFields({
    required String id,
    required String eventId,
    required String name,
    required DateTime startDatetime,
    required bool disabled,
  }) => Session.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    startDatetime: startDatetime,
    disabled: disabled,
  );
}

/// Fake factory for [SessionAdmin].
class MockSessionAdmin {
  MockSessionAdmin._();
  static SessionAdmin get any => SessionAdmin.empty();
  static SessionAdmin withOnly({required String id}) =>
      MockSessionAdmin.any.copyWith(id: id);

  static SessionAdmin withFields({
    required String id,
    required String eventId,
    required String name,
    required DateTime startDatetime,
    required bool disabled,
    int? quota,
    required int ticketsInCheckout,
    required int ticketsSold,
  }) => SessionAdmin.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    startDatetime: startDatetime,
    disabled: disabled,
    quota: quota,
    ticketsInCheckout: ticketsInCheckout,
    ticketsSold: ticketsSold,
  );
}

/// Fake factory for [SessionComplete].
class MockSessionComplete {
  MockSessionComplete._();
  static SessionComplete get any => SessionComplete.empty();
  static SessionComplete withOnly({required String id}) =>
      MockSessionComplete.any.copyWith(id: id);

  static SessionComplete withFields({
    required String id,
    required String eventId,
    required String name,
    required DateTime startDatetime,
    required bool disabled,
    int? quota,
  }) => SessionComplete.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    startDatetime: startDatetime,
    disabled: disabled,
    quota: quota,
  );
}

/// Fake factory for [SessionCreate].
class MockSessionCreate {
  MockSessionCreate._();
  static SessionCreate get any => SessionCreate.empty();
  static SessionCreate withFields({
    required String name,
    required DateTime startDatetime,
    int? quota,
  }) => SessionCreate.empty().copyWith(
    name: name,
    startDatetime: startDatetime,
    quota: quota,
  );
}

/// Fake factory for [SessionPublic].
class MockSessionPublic {
  MockSessionPublic._();
  static SessionPublic get any => SessionPublic.empty();
  static SessionPublic withOnly({required String id}) =>
      MockSessionPublic.any.copyWith(id: id);

  static SessionPublic withFields({
    required String id,
    required String eventId,
    required String name,
    required DateTime startDatetime,
    required bool disabled,
    required bool soldOut,
  }) => SessionPublic.empty().copyWith(
    id: id,
    eventId: eventId,
    name: name,
    startDatetime: startDatetime,
    disabled: disabled,
    soldOut: soldOut,
  );
}

/// Fake factory for [SessionUpdate].
class MockSessionUpdate {
  MockSessionUpdate._();
  static SessionUpdate get any => SessionUpdate.empty();
  static SessionUpdate withFields({
    String? name,
    DateTime? startDatetime,
    int? quota,
    bool? disabled,
  }) => SessionUpdate.empty().copyWith(
    name: name,
    startDatetime: startDatetime,
    quota: quota,
    disabled: disabled,
  );
}

/// Fake factory for [SignatureBase].
class MockSignatureBase {
  MockSignatureBase._();
  static SignatureBase get any => SignatureBase.empty();
  static SignatureBase withOnly({String? numericSignatureId}) =>
      MockSignatureBase.any.copyWith(numericSignatureId: numericSignatureId);

  static SignatureBase withFields({
    required enums.DocumentSignatureType signatureType,
    String? numericSignatureId,
  }) => SignatureBase.empty().copyWith(
    signatureType: signatureType,
    numericSignatureId: numericSignatureId,
  );
}

/// Fake factory for [SignatureComplete].
class MockSignatureComplete {
  MockSignatureComplete._();
  static SignatureComplete get any => SignatureComplete.empty();
  static SignatureComplete withOnly({String? numericSignatureId}) =>
      MockSignatureComplete.any.copyWith(
        numericSignatureId: numericSignatureId,
      );

  static SignatureComplete withFields({
    required enums.DocumentSignatureType signatureType,
    String? numericSignatureId,
    required String userId,
    required String documentId,
  }) => SignatureComplete.empty().copyWith(
    signatureType: signatureType,
    numericSignatureId: numericSignatureId,
    userId: userId,
    documentId: documentId,
  );
}

/// Fake factory for [SignedContent].
class MockSignedContent {
  MockSignedContent._();
  static SignedContent get any => SignedContent.empty();
  static SignedContent withOnly({required String id}) =>
      MockSignedContent.any.copyWith(id: id);

  static SignedContent withFields({
    required String id,
    required int tot,
    required DateTime iat,
    required String key,
    required bool store,
    required String signature,
  }) => SignedContent.empty().copyWith(
    id: id,
    tot: tot,
    iat: iat,
    key: key,
    store: store,
    signature: signature,
  );
}

/// Fake factory for [SpeciesBase].
class MockSpeciesBase {
  MockSpeciesBase._();
  static SpeciesBase get any => SpeciesBase.empty();
  static SpeciesBase withFields({
    required String prefix,
    required String name,
    required int difficulty,
    required enums.SpeciesType speciesType,
    String? card,
    int? nbSeedsRecommended,
    DateTime? startSeason,
    DateTime? endSeason,
    int? timeMaturation,
  }) => SpeciesBase.empty().copyWith(
    prefix: prefix,
    name: name,
    difficulty: difficulty,
    speciesType: speciesType,
    card: card,
    nbSeedsRecommended: nbSeedsRecommended,
    startSeason: startSeason,
    endSeason: endSeason,
    timeMaturation: timeMaturation,
  );
}

/// Fake factory for [SpeciesComplete].
class MockSpeciesComplete {
  MockSpeciesComplete._();
  static SpeciesComplete get any => SpeciesComplete.empty();
  static SpeciesComplete withOnly({required String id}) =>
      MockSpeciesComplete.any.copyWith(id: id);

  static SpeciesComplete withFields({
    required String prefix,
    required String name,
    required int difficulty,
    required enums.SpeciesType speciesType,
    String? card,
    int? nbSeedsRecommended,
    DateTime? startSeason,
    DateTime? endSeason,
    int? timeMaturation,
    required String id,
  }) => SpeciesComplete.empty().copyWith(
    prefix: prefix,
    name: name,
    difficulty: difficulty,
    speciesType: speciesType,
    card: card,
    nbSeedsRecommended: nbSeedsRecommended,
    startSeason: startSeason,
    endSeason: endSeason,
    timeMaturation: timeMaturation,
    id: id,
  );
}

/// Fake factory for [SpeciesEdit].
class MockSpeciesEdit {
  MockSpeciesEdit._();
  static SpeciesEdit get any => SpeciesEdit.empty();
  static SpeciesEdit withFields({
    String? name,
    String? prefix,
    int? difficulty,
    String? card,
    enums.SpeciesType? speciesType,
    int? nbSeedsRecommended,
    DateTime? startSeason,
    DateTime? endSeason,
    int? timeMaturation,
  }) => SpeciesEdit.empty().copyWith(
    name: name,
    prefix: prefix,
    difficulty: difficulty,
    card: card,
    speciesType: speciesType,
    nbSeedsRecommended: nbSeedsRecommended,
    startSeason: startSeason,
    endSeason: endSeason,
    timeMaturation: timeMaturation,
  );
}

/// Fake factory for [SpeciesTypesReturn].
class MockSpeciesTypesReturn {
  MockSpeciesTypesReturn._();
  static SpeciesTypesReturn get any => SpeciesTypesReturn.empty();
  static SpeciesTypesReturn withFields({
    required List<enums.SpeciesType> speciesType,
  }) => SpeciesTypesReturn.empty().copyWith(speciesType: speciesType);
}

/// Fake factory for [Sport].
class MockSport {
  MockSport._();
  static Sport get any => Sport.empty();
  static Sport withOnly({required String id}) => MockSport.any.copyWith(id: id);

  static Sport withFields({
    required String name,
    required int teamSize,
    int? substituteMax,
    enums.SportCategory? sportCategory,
    bool? active,
    required String id,
  }) => Sport.empty().copyWith(
    name: name,
    teamSize: teamSize,
    substituteMax: substituteMax,
    sportCategory: sportCategory,
    active: active,
    id: id,
  );
}

/// Fake factory for [SportBase].
class MockSportBase {
  MockSportBase._();
  static SportBase get any => SportBase.empty();
  static SportBase withFields({
    required String name,
    required int teamSize,
    int? substituteMax,
    enums.SportCategory? sportCategory,
    bool? active,
  }) => SportBase.empty().copyWith(
    name: name,
    teamSize: teamSize,
    substituteMax: substituteMax,
    sportCategory: sportCategory,
    active: active,
  );
}

/// Fake factory for [SportEdit].
class MockSportEdit {
  MockSportEdit._();
  static SportEdit get any => SportEdit.empty();
  static SportEdit withFields({
    String? name,
    int? teamSize,
    int? substituteMax,
    enums.SportCategory? sportCategory,
    bool? active,
  }) => SportEdit.empty().copyWith(
    name: name,
    teamSize: teamSize,
    substituteMax: substituteMax,
    sportCategory: sportCategory,
    active: active,
  );
}

/// Fake factory for [SportPodiumRankings].
class MockSportPodiumRankings {
  MockSportPodiumRankings._();
  static SportPodiumRankings get any => SportPodiumRankings.empty();
  static SportPodiumRankings withFields({
    required List<TeamSportResultBase> rankings,
  }) => SportPodiumRankings.empty().copyWith(rankings: rankings);
}

/// Fake factory for [SportQuotaInfo].
class MockSportQuotaInfo {
  MockSportQuotaInfo._();
  static SportQuotaInfo get any => SportQuotaInfo.empty();
  static SportQuotaInfo withFields({int? participantQuota, int? teamQuota}) =>
      SportQuotaInfo.empty().copyWith(
        participantQuota: participantQuota,
        teamQuota: teamQuota,
      );
}

/// Fake factory for [Status].
class MockStatus {
  MockStatus._();
  static Status get any => Status.empty();
  static Status withFields({enums.CdrStatus? status}) =>
      Status.empty().copyWith(status: status);
}

/// Fake factory for [Store].
class MockStore {
  MockStore._();
  static Store get any => Store.empty();
  static Store withOnly({required String id}) => MockStore.any.copyWith(id: id);

  static Store withFields({
    required String name,
    String? associationId,
    required String id,
    required String structureId,
    required String walletId,
    required DateTime creation,
    required Structure structure,
  }) => Store.empty().copyWith(
    name: name,
    associationId: associationId,
    id: id,
    structureId: structureId,
    walletId: walletId,
    creation: creation,
    structure: structure,
  );
}

/// Fake factory for [StoreBase].
class MockStoreBase {
  MockStoreBase._();
  static StoreBase get any => StoreBase.empty();
  static StoreBase withOnly({String? associationId}) =>
      MockStoreBase.any.copyWith(associationId: associationId);

  static StoreBase withFields({required String name, String? associationId}) =>
      StoreBase.empty().copyWith(name: name, associationId: associationId);
}

/// Fake factory for [StoreSimple].
class MockStoreSimple {
  MockStoreSimple._();
  static StoreSimple get any => StoreSimple.empty();
  static StoreSimple withOnly({required String id}) =>
      MockStoreSimple.any.copyWith(id: id);

  static StoreSimple withFields({
    required String name,
    String? associationId,
    required String id,
    required String structureId,
    required String walletId,
    required DateTime creation,
  }) => StoreSimple.empty().copyWith(
    name: name,
    associationId: associationId,
    id: id,
    structureId: structureId,
    walletId: walletId,
    creation: creation,
  );
}

/// Fake factory for [StoreUpdate].
class MockStoreUpdate {
  MockStoreUpdate._();
  static StoreUpdate get any => StoreUpdate.empty();
  static StoreUpdate withOnly({String? associationId}) =>
      MockStoreUpdate.any.copyWith(associationId: associationId);

  static StoreUpdate withFields({String? name, String? associationId}) =>
      StoreUpdate.empty().copyWith(name: name, associationId: associationId);
}

/// Fake factory for [Structure].
class MockStructure {
  MockStructure._();
  static Structure get any => Structure.empty();
  static Structure withOnly({required String id}) =>
      MockStructure.any.copyWith(id: id);

  static Structure withFields({
    required String shortId,
    required String name,
    String? associationMembershipId,
    required String managerUserId,
    required String siegeAddressStreet,
    required String siegeAddressCity,
    required String siegeAddressZipcode,
    required String siegeAddressCountry,
    String? siret,
    required String iban,
    required String bic,
    required String id,
    required DateTime creation,
    required CoreUserSimple managerUser,
    MembershipSimple? associationMembership,
  }) => Structure.empty().copyWith(
    shortId: shortId,
    name: name,
    associationMembershipId: associationMembershipId,
    managerUserId: managerUserId,
    siegeAddressStreet: siegeAddressStreet,
    siegeAddressCity: siegeAddressCity,
    siegeAddressZipcode: siegeAddressZipcode,
    siegeAddressCountry: siegeAddressCountry,
    siret: siret,
    iban: iban,
    bic: bic,
    id: id,
    creation: creation,
    managerUser: managerUser,
    associationMembership: associationMembership,
  );
}

/// Fake factory for [StructureBase].
class MockStructureBase {
  MockStructureBase._();
  static StructureBase get any => StructureBase.empty();
  static StructureBase withOnly({required String shortId}) =>
      MockStructureBase.any.copyWith(shortId: shortId);

  static StructureBase withFields({
    required String shortId,
    required String name,
    String? associationMembershipId,
    required String managerUserId,
    required String siegeAddressStreet,
    required String siegeAddressCity,
    required String siegeAddressZipcode,
    required String siegeAddressCountry,
    String? siret,
    required String iban,
    required String bic,
  }) => StructureBase.empty().copyWith(
    shortId: shortId,
    name: name,
    associationMembershipId: associationMembershipId,
    managerUserId: managerUserId,
    siegeAddressStreet: siegeAddressStreet,
    siegeAddressCity: siegeAddressCity,
    siegeAddressZipcode: siegeAddressZipcode,
    siegeAddressCountry: siegeAddressCountry,
    siret: siret,
    iban: iban,
    bic: bic,
  );
}

/// Fake factory for [StructureTranfert].
class MockStructureTranfert {
  MockStructureTranfert._();
  static StructureTranfert get any => StructureTranfert.empty();
  static StructureTranfert withOnly({required String newManagerUserId}) =>
      MockStructureTranfert.any.copyWith(newManagerUserId: newManagerUserId);

  static StructureTranfert withFields({required String newManagerUserId}) =>
      StructureTranfert.empty().copyWith(newManagerUserId: newManagerUserId);
}

/// Fake factory for [StructureUpdate].
class MockStructureUpdate {
  MockStructureUpdate._();
  static StructureUpdate get any => StructureUpdate.empty();
  static StructureUpdate withOnly({String? shortId}) =>
      MockStructureUpdate.any.copyWith(shortId: shortId);

  static StructureUpdate withFields({
    String? name,
    String? shortId,
    String? associationMembershipId,
    String? siret,
    String? siegeAddressStreet,
    String? siegeAddressCity,
    String? siegeAddressZipcode,
    String? siegeAddressCountry,
    String? iban,
    String? bic,
  }) => StructureUpdate.empty().copyWith(
    name: name,
    shortId: shortId,
    associationMembershipId: associationMembershipId,
    siret: siret,
    siegeAddressStreet: siegeAddressStreet,
    siegeAddressCity: siegeAddressCity,
    siegeAddressZipcode: siegeAddressZipcode,
    siegeAddressCountry: siegeAddressCountry,
    iban: iban,
    bic: bic,
  );
}

/// Fake factory for [TOSSignature].
class MockTOSSignature {
  MockTOSSignature._();
  static TOSSignature get any => TOSSignature.empty();
  static TOSSignature withFields({required int acceptedTosVersion}) =>
      TOSSignature.empty().copyWith(acceptedTosVersion: acceptedTosVersion);
}

/// Fake factory for [TOSSignatureResponse].
class MockTOSSignatureResponse {
  MockTOSSignatureResponse._();
  static TOSSignatureResponse get any => TOSSignatureResponse.empty();
  static TOSSignatureResponse withFields({
    required int acceptedTosVersion,
    required int latestTosVersion,
    required String tosContent,
    int? maxTransactionTotal,
    required int maxWalletBalance,
  }) => TOSSignatureResponse.empty().copyWith(
    acceptedTosVersion: acceptedTosVersion,
    latestTosVersion: latestTosVersion,
    tosContent: tosContent,
    maxTransactionTotal: maxTransactionTotal,
    maxWalletBalance: maxWalletBalance,
  );
}

/// Fake factory for [Team].
class MockTeam {
  MockTeam._();
  static Team get any => Team.empty();
  static Team withOnly({required String id}) => MockTeam.any.copyWith(id: id);

  static Team withFields({
    required String name,
    required String editionId,
    required String schoolId,
    required String sportId,
    required String captainId,
    required String id,
    required DateTime createdAt,
  }) => Team.empty().copyWith(
    name: name,
    editionId: editionId,
    schoolId: schoolId,
    sportId: sportId,
    captainId: captainId,
    id: id,
    createdAt: createdAt,
  );
}

/// Fake factory for [TeamComplete].
class MockTeamComplete {
  MockTeamComplete._();
  static TeamComplete get any => TeamComplete.empty();
  static TeamComplete withOnly({required String id}) =>
      MockTeamComplete.any.copyWith(id: id);

  static TeamComplete withFields({
    required String name,
    required String editionId,
    required String schoolId,
    required String sportId,
    required String captainId,
    required String id,
    required DateTime createdAt,
    required List<ParticipantComplete> participants,
  }) => TeamComplete.empty().copyWith(
    name: name,
    editionId: editionId,
    schoolId: schoolId,
    sportId: sportId,
    captainId: captainId,
    id: id,
    createdAt: createdAt,
    participants: participants,
  );
}

/// Fake factory for [TeamEdit].
class MockTeamEdit {
  MockTeamEdit._();
  static TeamEdit get any => TeamEdit.empty();
  static TeamEdit withOnly({String? captainId}) =>
      MockTeamEdit.any.copyWith(captainId: captainId);

  static TeamEdit withFields({String? name, String? captainId}) =>
      TeamEdit.empty().copyWith(name: name, captainId: captainId);
}

/// Fake factory for [TeamInfo].
class MockTeamInfo {
  MockTeamInfo._();
  static TeamInfo get any => TeamInfo.empty();
  static TeamInfo withOnly({required String schoolId}) =>
      MockTeamInfo.any.copyWith(schoolId: schoolId);

  static TeamInfo withFields({
    required String name,
    required String schoolId,
    required String sportId,
    required String captainId,
  }) => TeamInfo.empty().copyWith(
    name: name,
    schoolId: schoolId,
    sportId: sportId,
    captainId: captainId,
  );
}

/// Fake factory for [TeamSportResult].
class MockTeamSportResult {
  MockTeamSportResult._();
  static TeamSportResult get any => TeamSportResult.empty();
  static TeamSportResult withOnly({required String schoolId}) =>
      MockTeamSportResult.any.copyWith(schoolId: schoolId);

  static TeamSportResult withFields({
    required String schoolId,
    required String sportId,
    required String teamId,
    required int points,
    required String editionId,
    required int rank,
  }) => TeamSportResult.empty().copyWith(
    schoolId: schoolId,
    sportId: sportId,
    teamId: teamId,
    points: points,
    editionId: editionId,
    rank: rank,
  );
}

/// Fake factory for [TeamSportResultBase].
class MockTeamSportResultBase {
  MockTeamSportResultBase._();
  static TeamSportResultBase get any => TeamSportResultBase.empty();
  static TeamSportResultBase withOnly({required String schoolId}) =>
      MockTeamSportResultBase.any.copyWith(schoolId: schoolId);

  static TeamSportResultBase withFields({
    required String schoolId,
    required String sportId,
    required String teamId,
    required int points,
  }) => TeamSportResultBase.empty().copyWith(
    schoolId: schoolId,
    sportId: sportId,
    teamId: teamId,
    points: points,
  );
}

/// Fake factory for [TeamSportResultComplete].
class MockTeamSportResultComplete {
  MockTeamSportResultComplete._();
  static TeamSportResultComplete get any => TeamSportResultComplete.empty();
  static TeamSportResultComplete withOnly({required String schoolId}) =>
      MockTeamSportResultComplete.any.copyWith(schoolId: schoolId);

  static TeamSportResultComplete withFields({
    required String schoolId,
    required String sportId,
    required String teamId,
    required int points,
    required String editionId,
    required int rank,
    required Team team,
  }) => TeamSportResultComplete.empty().copyWith(
    schoolId: schoolId,
    sportId: sportId,
    teamId: teamId,
    points: points,
    editionId: editionId,
    rank: rank,
    team: team,
  );
}

/// Fake factory for [TheMovieDB].
class MockTheMovieDB {
  MockTheMovieDB._();
  static TheMovieDB get any => TheMovieDB.empty();
  static TheMovieDB withFields({
    required List<Object> genres,
    required String overview,
    required String posterPath,
    required String title,
    required int runtime,
    required String tagline,
  }) => TheMovieDB.empty().copyWith(
    genres: genres,
    overview: overview,
    posterPath: posterPath,
    title: title,
    runtime: runtime,
    tagline: tagline,
  );
}

/// Fake factory for [TicketChangeOverInvitation].
class MockTicketChangeOverInvitation {
  MockTicketChangeOverInvitation._();
  static TicketChangeOverInvitation get any =>
      TicketChangeOverInvitation.empty();
  static TicketChangeOverInvitation withOnly({required String ticketId}) =>
      MockTicketChangeOverInvitation.any.copyWith(ticketId: ticketId);

  static TicketChangeOverInvitation withFields({
    required String ticketId,
    required String email,
  }) => TicketChangeOverInvitation.empty().copyWith(
    ticketId: ticketId,
    email: email,
  );
}

/// Fake factory for [TicketScan].
class MockTicketScan {
  MockTicketScan._();
  static TicketScan get any => TicketScan.empty();
  static TicketScan withFields({required String tag}) =>
      TicketScan.empty().copyWith(tag: tag);
}

/// Fake factory for [TicketSecret].
class MockTicketSecret {
  MockTicketSecret._();
  static TicketSecret get any => TicketSecret.empty();
  static TicketSecret withFields({required String qrCodeSecret}) =>
      TicketSecret.empty().copyWith(qrCodeSecret: qrCodeSecret);
}

/// Fake factory for [TicketSimple].
class MockTicketSimple {
  MockTicketSimple._();
  static TicketSimple get any => TicketSimple.empty();
  static TicketSimple withOnly({required String id}) =>
      MockTicketSimple.any.copyWith(id: id);

  static TicketSimple withFields({
    required String packId,
    required String userId,
    String? winningPrize,
    required String id,
  }) => TicketSimple.empty().copyWith(
    packId: packId,
    userId: userId,
    winningPrize: winningPrize,
    id: id,
  );
}

/// Fake factory for [TokenResponse].
class MockTokenResponse {
  MockTokenResponse._();
  static TokenResponse get any => TokenResponse.empty();
  static TokenResponse withFields({
    required String accessToken,
    String? tokenType,
    int? expiresIn,
    String? scope,
    required String refreshToken,
    String? idToken,
  }) => TokenResponse.empty().copyWith(
    accessToken: accessToken,
    tokenType: tokenType,
    expiresIn: expiresIn,
    scope: scope,
    refreshToken: refreshToken,
    idToken: idToken,
  );
}

/// Fake factory for [TopicUser].
class MockTopicUser {
  MockTopicUser._();
  static TopicUser get any => TopicUser.empty();
  static TopicUser withOnly({required String id}) =>
      MockTopicUser.any.copyWith(id: id);

  static TopicUser withFields({
    required String id,
    required String name,
    required String moduleRoot,
    String? topicIdentifier,
    required bool isUserSubscribed,
  }) => TopicUser.empty().copyWith(
    id: id,
    name: name,
    moduleRoot: moduleRoot,
    topicIdentifier: topicIdentifier,
    isUserSubscribed: isUserSubscribed,
  );
}

/// Fake factory for [TransactionBase].
class MockTransactionBase {
  MockTransactionBase._();
  static TransactionBase get any => TransactionBase.empty();
  static TransactionBase withOnly({required String id}) =>
      MockTransactionBase.any.copyWith(id: id);

  static TransactionBase withFields({
    required String id,
    required String debitedWalletId,
    required String creditedWalletId,
    required enums.TransactionType transactionType,
    String? sellerUserId,
    required int total,
    required DateTime creation,
    required enums.TransactionStatus status,
    String? qrCodeId,
  }) => TransactionBase.empty().copyWith(
    id: id,
    debitedWalletId: debitedWalletId,
    creditedWalletId: creditedWalletId,
    transactionType: transactionType,
    sellerUserId: sellerUserId,
    total: total,
    creation: creation,
    status: status,
    qrCodeId: qrCodeId,
  );
}

/// Fake factory for [Transfer].
class MockTransfer {
  MockTransfer._();
  static Transfer get any => Transfer.empty();
  static Transfer withOnly({required String id}) =>
      MockTransfer.any.copyWith(id: id);

  static Transfer withFields({
    required String id,
    required enums.TransferOrigin origin,
    required String transferIdentifier,
    String? approverUserId,
    required String walletId,
    required int total,
    required DateTime creation,
    required bool confirmed,
    String? module,
    String? objectId,
    required enums.TransferType type,
  }) => Transfer.empty().copyWith(
    id: id,
    origin: origin,
    transferIdentifier: transferIdentifier,
    approverUserId: approverUserId,
    walletId: walletId,
    total: total,
    creation: creation,
    confirmed: confirmed,
    module: module,
    objectId: objectId,
    type: type,
  );
}

/// Fake factory for [TransferInfo].
class MockTransferInfo {
  MockTransferInfo._();
  static TransferInfo get any => TransferInfo.empty();
  static TransferInfo withFields({
    required int amount,
    required String redirectUrl,
  }) => TransferInfo.empty().copyWith(amount: amount, redirectUrl: redirectUrl);
}

/// Fake factory for [UserGroupMembership].
class MockUserGroupMembership {
  MockUserGroupMembership._();
  static UserGroupMembership get any => UserGroupMembership.empty();
  static UserGroupMembership withOnly({required String userId}) =>
      MockUserGroupMembership.any.copyWith(userId: userId);

  static UserGroupMembership withFields({
    required String userId,
    required enums.CompetitionGroupType group,
    required String editionId,
  }) => UserGroupMembership.empty().copyWith(
    userId: userId,
    group: group,
    editionId: editionId,
  );
}

/// Fake factory for [UserGroupMembershipComplete].
class MockUserGroupMembershipComplete {
  MockUserGroupMembershipComplete._();
  static UserGroupMembershipComplete get any =>
      UserGroupMembershipComplete.empty();
  static UserGroupMembershipComplete withOnly({required String userId}) =>
      MockUserGroupMembershipComplete.any.copyWith(userId: userId);

  static UserGroupMembershipComplete withFields({
    required String userId,
    required enums.CompetitionGroupType group,
    required String editionId,
    required CoreUser user,
  }) => UserGroupMembershipComplete.empty().copyWith(
    userId: userId,
    group: group,
    editionId: editionId,
    user: user,
  );
}

/// Fake factory for [UserMembershipBase].
class MockUserMembershipBase {
  MockUserMembershipBase._();
  static UserMembershipBase get any => UserMembershipBase.empty();
  static UserMembershipBase withOnly({
    required String associationMembershipId,
  }) => MockUserMembershipBase.any.copyWith(
    associationMembershipId: associationMembershipId,
  );

  static UserMembershipBase withFields({
    required String associationMembershipId,
    required DateTime startDate,
    required DateTime endDate,
  }) => UserMembershipBase.empty().copyWith(
    associationMembershipId: associationMembershipId,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Fake factory for [UserMembershipComplete].
class MockUserMembershipComplete {
  MockUserMembershipComplete._();
  static UserMembershipComplete get any => UserMembershipComplete.empty();
  static UserMembershipComplete withOnly({required String id}) =>
      MockUserMembershipComplete.any.copyWith(id: id);

  static UserMembershipComplete withFields({
    required String associationMembershipId,
    required DateTime startDate,
    required DateTime endDate,
    required String id,
    required String userId,
    required CoreUserSimple user,
  }) => UserMembershipComplete.empty().copyWith(
    associationMembershipId: associationMembershipId,
    startDate: startDate,
    endDate: endDate,
    id: id,
    userId: userId,
    user: user,
  );
}

/// Fake factory for [UserMembershipEdit].
class MockUserMembershipEdit {
  MockUserMembershipEdit._();
  static UserMembershipEdit get any => UserMembershipEdit.empty();
  static UserMembershipEdit withFields({
    DateTime? startDate,
    DateTime? endDate,
  }) => UserMembershipEdit.empty().copyWith(
    startDate: startDate,
    endDate: endDate,
  );
}

/// Fake factory for [UserStore].
class MockUserStore {
  MockUserStore._();
  static UserStore get any => UserStore.empty();
  static UserStore withOnly({required String id}) =>
      MockUserStore.any.copyWith(id: id);

  static UserStore withFields({
    required String name,
    String? associationId,
    required String id,
    required String structureId,
    required String walletId,
    required DateTime creation,
    required Structure structure,
    required bool canBank,
    required bool canSeeHistory,
    required bool canCancel,
    required bool canManageSellers,
  }) => UserStore.empty().copyWith(
    name: name,
    associationId: associationId,
    id: id,
    structureId: structureId,
    walletId: walletId,
    creation: creation,
    structure: structure,
    canBank: canBank,
    canSeeHistory: canSeeHistory,
    canCancel: canCancel,
    canManageSellers: canManageSellers,
  );
}

/// Fake factory for [UserTicket].
class MockUserTicket {
  MockUserTicket._();
  static UserTicket get any => UserTicket.empty();
  static UserTicket withOnly({required String id}) =>
      MockUserTicket.any.copyWith(id: id);

  static UserTicket withFields({
    required String name,
    required String firstname,
    String? nickname,
    required String id,
    required enums.AccountType accountType,
    required String schoolId,
    int? promo,
    String? floor,
    DateTime? createdOn,
  }) => UserTicket.empty().copyWith(
    name: name,
    firstname: firstname,
    nickname: nickname,
    id: id,
    accountType: accountType,
    schoolId: schoolId,
    promo: promo,
    floor: floor,
    createdOn: createdOn,
  );
}

/// Fake factory for [ValidationError].
class MockValidationError {
  MockValidationError._();
  static ValidationError get any => ValidationError.empty();
  static ValidationError withFields({
    required List<Object> loc,
    required String msg,
    required String type,
    required dynamic input,
    Object? ctx,
  }) => ValidationError.empty().copyWith(
    loc: loc,
    msg: msg,
    type: type,
    input: input,
    ctx: ctx,
  );
}

/// Fake factory for [VolunteerRegistrationComplete].
class MockVolunteerRegistrationComplete {
  MockVolunteerRegistrationComplete._();
  static VolunteerRegistrationComplete get any =>
      VolunteerRegistrationComplete.empty();
  static VolunteerRegistrationComplete withOnly({required String userId}) =>
      MockVolunteerRegistrationComplete.any.copyWith(userId: userId);

  static VolunteerRegistrationComplete withFields({
    required String userId,
    required String editionId,
    required String shiftId,
    required DateTime registeredAt,
    required bool validated,
    required VolunteerShiftComplete shift,
  }) => VolunteerRegistrationComplete.empty().copyWith(
    userId: userId,
    editionId: editionId,
    shiftId: shiftId,
    registeredAt: registeredAt,
    validated: validated,
    shift: shift,
  );
}

/// Fake factory for [VolunteerShift].
class MockVolunteerShift {
  MockVolunteerShift._();
  static VolunteerShift get any => VolunteerShift.empty();
  static VolunteerShift withOnly({required String id}) =>
      MockVolunteerShift.any.copyWith(id: id);

  static VolunteerShift withFields({
    required String name,
    required String managerId,
    String? description,
    required int value,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    required int maxVolunteers,
    required String id,
    required String editionId,
  }) => VolunteerShift.empty().copyWith(
    name: name,
    managerId: managerId,
    description: description,
    value: value,
    startTime: startTime,
    endTime: endTime,
    location: location,
    maxVolunteers: maxVolunteers,
    id: id,
    editionId: editionId,
  );
}

/// Fake factory for [VolunteerShiftBase].
class MockVolunteerShiftBase {
  MockVolunteerShiftBase._();
  static VolunteerShiftBase get any => VolunteerShiftBase.empty();
  static VolunteerShiftBase withOnly({required String managerId}) =>
      MockVolunteerShiftBase.any.copyWith(managerId: managerId);

  static VolunteerShiftBase withFields({
    required String name,
    required String managerId,
    String? description,
    required int value,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    required int maxVolunteers,
  }) => VolunteerShiftBase.empty().copyWith(
    name: name,
    managerId: managerId,
    description: description,
    value: value,
    startTime: startTime,
    endTime: endTime,
    location: location,
    maxVolunteers: maxVolunteers,
  );
}

/// Fake factory for [VolunteerShiftComplete].
class MockVolunteerShiftComplete {
  MockVolunteerShiftComplete._();
  static VolunteerShiftComplete get any => VolunteerShiftComplete.empty();
  static VolunteerShiftComplete withOnly({required String id}) =>
      MockVolunteerShiftComplete.any.copyWith(id: id);

  static VolunteerShiftComplete withFields({
    required String name,
    required String managerId,
    String? description,
    required int value,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    required int maxVolunteers,
    required String id,
    required String editionId,
    required CoreUser manager,
  }) => VolunteerShiftComplete.empty().copyWith(
    name: name,
    managerId: managerId,
    description: description,
    value: value,
    startTime: startTime,
    endTime: endTime,
    location: location,
    maxVolunteers: maxVolunteers,
    id: id,
    editionId: editionId,
    manager: manager,
  );
}

/// Fake factory for [VolunteerShiftEdit].
class MockVolunteerShiftEdit {
  MockVolunteerShiftEdit._();
  static VolunteerShiftEdit get any => VolunteerShiftEdit.empty();
  static VolunteerShiftEdit withFields({
    String? name,
    String? description,
    int? value,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    int? maxVolunteers,
  }) => VolunteerShiftEdit.empty().copyWith(
    name: name,
    description: description,
    value: value,
    startTime: startTime,
    endTime: endTime,
    location: location,
    maxVolunteers: maxVolunteers,
  );
}

/// Fake factory for [VoteBase].
class MockVoteBase {
  MockVoteBase._();
  static VoteBase get any => VoteBase.empty();
  static VoteBase withOnly({required String listId}) =>
      MockVoteBase.any.copyWith(listId: listId);

  static VoteBase withFields({required String listId}) =>
      VoteBase.empty().copyWith(listId: listId);
}

/// Fake factory for [VoteStats].
class MockVoteStats {
  MockVoteStats._();
  static VoteStats get any => VoteStats.empty();
  static VoteStats withOnly({required String sectionId}) =>
      MockVoteStats.any.copyWith(sectionId: sectionId);

  static VoteStats withFields({
    required String sectionId,
    required int count,
  }) => VoteStats.empty().copyWith(sectionId: sectionId, count: count);
}

/// Fake factory for [VoteStatus].
class MockVoteStatus {
  MockVoteStatus._();
  static VoteStatus get any => VoteStatus.empty();
  static VoteStatus withFields({required enums.StatusType status}) =>
      VoteStatus.empty().copyWith(status: status);
}

/// Fake factory for [Wallet].
class MockWallet {
  MockWallet._();
  static Wallet get any => Wallet.empty();
  static Wallet withOnly({required String id}) =>
      MockWallet.any.copyWith(id: id);

  static Wallet withFields({
    required String id,
    required enums.WalletType type,
    required int balance,
    Store? store,
    CoreUser? user,
  }) => Wallet.empty().copyWith(
    id: id,
    type: type,
    balance: balance,
    store: store,
    user: user,
  );
}

/// Fake factory for [WalletBase].
class MockWalletBase {
  MockWalletBase._();
  static WalletBase get any => WalletBase.empty();
  static WalletBase withOnly({required String id}) =>
      MockWalletBase.any.copyWith(id: id);

  static WalletBase withFields({
    required String id,
    required enums.WalletType type,
    required int balance,
  }) => WalletBase.empty().copyWith(id: id, type: type, balance: balance);
}

/// Fake factory for [WalletDevice].
class MockWalletDevice {
  MockWalletDevice._();
  static WalletDevice get any => WalletDevice.empty();
  static WalletDevice withOnly({required String id}) =>
      MockWalletDevice.any.copyWith(id: id);

  static WalletDevice withFields({
    required String name,
    required String id,
    required String walletId,
    required DateTime creation,
    required enums.WalletDeviceStatus status,
  }) => WalletDevice.empty().copyWith(
    name: name,
    id: id,
    walletId: walletId,
    creation: creation,
    status: status,
  );
}

/// Fake factory for [WalletDeviceCreation].
class MockWalletDeviceCreation {
  MockWalletDeviceCreation._();
  static WalletDeviceCreation get any => WalletDeviceCreation.empty();
  static WalletDeviceCreation withOnly({required String ed25519PublicKey}) =>
      MockWalletDeviceCreation.any.copyWith(ed25519PublicKey: ed25519PublicKey);

  static WalletDeviceCreation withFields({
    required String name,
    required String ed25519PublicKey,
  }) => WalletDeviceCreation.empty().copyWith(
    name: name,
    ed25519PublicKey: ed25519PublicKey,
  );
}

/// Fake factory for [AppCoreAssociationsSchemasAssociationsAssociationBase].
class MockAppCoreAssociationsSchemasAssociationsAssociationBase {
  MockAppCoreAssociationsSchemasAssociationsAssociationBase._();
  static AppCoreAssociationsSchemasAssociationsAssociationBase get any =>
      AppCoreAssociationsSchemasAssociationsAssociationBase.empty();
  static AppCoreAssociationsSchemasAssociationsAssociationBase withOnly({
    required String groupId,
  }) => MockAppCoreAssociationsSchemasAssociationsAssociationBase.any.copyWith(
    groupId: groupId,
  );

  static AppCoreAssociationsSchemasAssociationsAssociationBase withFields({
    required String name,
    required String groupId,
  }) => AppCoreAssociationsSchemasAssociationsAssociationBase.empty().copyWith(
    name: name,
    groupId: groupId,
  );
}

/// Fake factory for [AppCoreMembershipsSchemasMembershipsMembershipBase].
class MockAppCoreMembershipsSchemasMembershipsMembershipBase {
  MockAppCoreMembershipsSchemasMembershipsMembershipBase._();
  static AppCoreMembershipsSchemasMembershipsMembershipBase get any =>
      AppCoreMembershipsSchemasMembershipsMembershipBase.empty();
  static AppCoreMembershipsSchemasMembershipsMembershipBase withOnly({
    required String managerGroupId,
  }) => MockAppCoreMembershipsSchemasMembershipsMembershipBase.any.copyWith(
    managerGroupId: managerGroupId,
  );

  static AppCoreMembershipsSchemasMembershipsMembershipBase withFields({
    required String name,
    required String managerGroupId,
  }) => AppCoreMembershipsSchemasMembershipsMembershipBase.empty().copyWith(
    name: name,
    managerGroupId: managerGroupId,
  );
}

/// Fake factory for [AppCoreTicketsSchemasTicketsTicket].
class MockAppCoreTicketsSchemasTicketsTicket {
  MockAppCoreTicketsSchemasTicketsTicket._();
  static AppCoreTicketsSchemasTicketsTicket get any =>
      AppCoreTicketsSchemasTicketsTicket.empty();
  static AppCoreTicketsSchemasTicketsTicket withOnly({required String id}) =>
      MockAppCoreTicketsSchemasTicketsTicket.any.copyWith(id: id);

  static AppCoreTicketsSchemasTicketsTicket withFields({
    required String id,
    required String userId,
    required int price,
    required bool scanned,
    required String eventId,
    required String categoryId,
    required String sessionId,
    required Category category,
    required Session session,
    required CoreUserSimple user,
    required List<Answer> answers,
  }) => AppCoreTicketsSchemasTicketsTicket.empty().copyWith(
    id: id,
    userId: userId,
    price: price,
    scanned: scanned,
    eventId: eventId,
    categoryId: categoryId,
    sessionId: sessionId,
    category: category,
    session: session,
    user: user,
    answers: answers,
  );
}

/// Fake factory for [AppCoreTicketsSchemasTicketsTicketComplete].
class MockAppCoreTicketsSchemasTicketsTicketComplete {
  MockAppCoreTicketsSchemasTicketsTicketComplete._();
  static AppCoreTicketsSchemasTicketsTicketComplete get any =>
      AppCoreTicketsSchemasTicketsTicketComplete.empty();
  static AppCoreTicketsSchemasTicketsTicketComplete withOnly({
    required String id,
  }) => MockAppCoreTicketsSchemasTicketsTicketComplete.any.copyWith(id: id);

  static AppCoreTicketsSchemasTicketsTicketComplete withFields({
    required String id,
    required String userId,
    required int price,
    required bool scanned,
    required String eventId,
    required String categoryId,
    required String sessionId,
    required Category category,
    required Session session,
    required CoreUserSimple user,
    required List<Answer> answers,
    required EventSimple event,
  }) => AppCoreTicketsSchemasTicketsTicketComplete.empty().copyWith(
    id: id,
    userId: userId,
    price: price,
    scanned: scanned,
    eventId: eventId,
    categoryId: categoryId,
    sessionId: sessionId,
    category: category,
    session: session,
    user: user,
    answers: answers,
    event: event,
  );
}

/// Fake factory for [AppModulesAmapSchemasAmapCashComplete].
class MockAppModulesAmapSchemasAmapCashComplete {
  MockAppModulesAmapSchemasAmapCashComplete._();
  static AppModulesAmapSchemasAmapCashComplete get any =>
      AppModulesAmapSchemasAmapCashComplete.empty();
  static AppModulesAmapSchemasAmapCashComplete withOnly({
    required String userId,
  }) => MockAppModulesAmapSchemasAmapCashComplete.any.copyWith(userId: userId);

  static AppModulesAmapSchemasAmapCashComplete withFields({
    required int balance,
    required String userId,
    required CoreUserSimple user,
    required DateTime lastOrderDate,
  }) => AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
    balance: balance,
    userId: userId,
    user: user,
    lastOrderDate: lastOrderDate,
  );
}

/// Fake factory for [AppModulesAmapSchemasAmapProductComplete].
class MockAppModulesAmapSchemasAmapProductComplete {
  MockAppModulesAmapSchemasAmapProductComplete._();
  static AppModulesAmapSchemasAmapProductComplete get any =>
      AppModulesAmapSchemasAmapProductComplete.empty();
  static AppModulesAmapSchemasAmapProductComplete withOnly({
    required String id,
  }) => MockAppModulesAmapSchemasAmapProductComplete.any.copyWith(id: id);

  static AppModulesAmapSchemasAmapProductComplete withFields({
    required String name,
    required int price,
    required String category,
    required String id,
  }) => AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
    name: name,
    price: price,
    category: category,
    id: id,
  );
}

/// Fake factory for [AppModulesAmapSchemasAmapProductEdit].
class MockAppModulesAmapSchemasAmapProductEdit {
  MockAppModulesAmapSchemasAmapProductEdit._();
  static AppModulesAmapSchemasAmapProductEdit get any =>
      AppModulesAmapSchemasAmapProductEdit.empty();
  static AppModulesAmapSchemasAmapProductEdit withFields({
    String? category,
    String? name,
    int? price,
  }) => AppModulesAmapSchemasAmapProductEdit.empty().copyWith(
    category: category,
    name: name,
    price: price,
  );
}

/// Fake factory for [AppModulesCampaignSchemasCampaignResult].
class MockAppModulesCampaignSchemasCampaignResult {
  MockAppModulesCampaignSchemasCampaignResult._();
  static AppModulesCampaignSchemasCampaignResult get any =>
      AppModulesCampaignSchemasCampaignResult.empty();
  static AppModulesCampaignSchemasCampaignResult withOnly({
    required String listId,
  }) =>
      MockAppModulesCampaignSchemasCampaignResult.any.copyWith(listId: listId);

  static AppModulesCampaignSchemasCampaignResult withFields({
    required String listId,
    required int count,
  }) => AppModulesCampaignSchemasCampaignResult.empty().copyWith(
    listId: listId,
    count: count,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrPaymentBase].
class MockAppModulesCdrSchemasCdrPaymentBase {
  MockAppModulesCdrSchemasCdrPaymentBase._();
  static AppModulesCdrSchemasCdrPaymentBase get any =>
      AppModulesCdrSchemasCdrPaymentBase.empty();
  static AppModulesCdrSchemasCdrPaymentBase withFields({
    required int total,
    required enums.PaymentType paymentType,
  }) => AppModulesCdrSchemasCdrPaymentBase.empty().copyWith(
    total: total,
    paymentType: paymentType,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrPaymentComplete].
class MockAppModulesCdrSchemasCdrPaymentComplete {
  MockAppModulesCdrSchemasCdrPaymentComplete._();
  static AppModulesCdrSchemasCdrPaymentComplete get any =>
      AppModulesCdrSchemasCdrPaymentComplete.empty();
  static AppModulesCdrSchemasCdrPaymentComplete withOnly({
    required String id,
  }) => MockAppModulesCdrSchemasCdrPaymentComplete.any.copyWith(id: id);

  static AppModulesCdrSchemasCdrPaymentComplete withFields({
    required int total,
    required enums.PaymentType paymentType,
    required String id,
    required String userId,
    required int year,
  }) => AppModulesCdrSchemasCdrPaymentComplete.empty().copyWith(
    total: total,
    paymentType: paymentType,
    id: id,
    userId: userId,
    year: year,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductBase].
class MockAppModulesCdrSchemasCdrProductBase {
  MockAppModulesCdrSchemasCdrProductBase._();
  static AppModulesCdrSchemasCdrProductBase get any =>
      AppModulesCdrSchemasCdrProductBase.empty();
  static AppModulesCdrSchemasCdrProductBase withFields({
    required String nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    required bool availableOnline,
    bool? needsValidation,
    MembershipSimple? relatedMembership,
    List<GenerateTicketBase>? tickets,
    required List<String> productConstraints,
    required List<String> documentConstraints,
  }) => AppModulesCdrSchemasCdrProductBase.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    availableOnline: availableOnline,
    needsValidation: needsValidation,
    relatedMembership: relatedMembership,
    tickets: tickets,
    productConstraints: productConstraints,
    documentConstraints: documentConstraints,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductComplete].
class MockAppModulesCdrSchemasCdrProductComplete {
  MockAppModulesCdrSchemasCdrProductComplete._();
  static AppModulesCdrSchemasCdrProductComplete get any =>
      AppModulesCdrSchemasCdrProductComplete.empty();
  static AppModulesCdrSchemasCdrProductComplete withOnly({
    required String id,
  }) => MockAppModulesCdrSchemasCdrProductComplete.any.copyWith(id: id);

  static AppModulesCdrSchemasCdrProductComplete withFields({
    required String nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    required bool availableOnline,
    required bool needsValidation,
    required String id,
    required int year,
    required String sellerId,
    List<AppModulesCdrSchemasCdrProductVariantComplete>? variants,
    MembershipSimple? relatedMembership,
    List<ProductCompleteNoConstraint>? productConstraints,
    List<DocumentComplete>? documentConstraints,
    List<GenerateTicketComplete>? tickets,
  }) => AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    availableOnline: availableOnline,
    needsValidation: needsValidation,
    id: id,
    year: year,
    sellerId: sellerId,
    variants: variants,
    relatedMembership: relatedMembership,
    productConstraints: productConstraints,
    documentConstraints: documentConstraints,
    tickets: tickets,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductEdit].
class MockAppModulesCdrSchemasCdrProductEdit {
  MockAppModulesCdrSchemasCdrProductEdit._();
  static AppModulesCdrSchemasCdrProductEdit get any =>
      AppModulesCdrSchemasCdrProductEdit.empty();
  static AppModulesCdrSchemasCdrProductEdit withFields({
    String? nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    String? description,
    bool? availableOnline,
    MembershipSimple? relatedMembership,
    List<String>? productConstraints,
    List<String>? documentConstraints,
  }) => AppModulesCdrSchemasCdrProductEdit.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    description: description,
    availableOnline: availableOnline,
    relatedMembership: relatedMembership,
    productConstraints: productConstraints,
    documentConstraints: documentConstraints,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductVariantBase].
class MockAppModulesCdrSchemasCdrProductVariantBase {
  MockAppModulesCdrSchemasCdrProductVariantBase._();
  static AppModulesCdrSchemasCdrProductVariantBase get any =>
      AppModulesCdrSchemasCdrProductVariantBase.empty();
  static AppModulesCdrSchemasCdrProductVariantBase withFields({
    required String nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    required int price,
    required bool enabled,
    required bool unique,
    required List<String> allowedCurriculum,
    String? relatedMembershipAddedDuration,
  }) => AppModulesCdrSchemasCdrProductVariantBase.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    price: price,
    enabled: enabled,
    unique: unique,
    allowedCurriculum: allowedCurriculum,
    relatedMembershipAddedDuration: relatedMembershipAddedDuration,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductVariantComplete].
class MockAppModulesCdrSchemasCdrProductVariantComplete {
  MockAppModulesCdrSchemasCdrProductVariantComplete._();
  static AppModulesCdrSchemasCdrProductVariantComplete get any =>
      AppModulesCdrSchemasCdrProductVariantComplete.empty();
  static AppModulesCdrSchemasCdrProductVariantComplete withOnly({
    required String id,
  }) => MockAppModulesCdrSchemasCdrProductVariantComplete.any.copyWith(id: id);

  static AppModulesCdrSchemasCdrProductVariantComplete withFields({
    required String id,
    required int year,
    required String productId,
    required String nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    required int price,
    required bool enabled,
    required bool unique,
    List<CurriculumComplete>? allowedCurriculum,
    String? relatedMembershipAddedDuration,
  }) => AppModulesCdrSchemasCdrProductVariantComplete.empty().copyWith(
    id: id,
    year: year,
    productId: productId,
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    price: price,
    enabled: enabled,
    unique: unique,
    allowedCurriculum: allowedCurriculum,
    relatedMembershipAddedDuration: relatedMembershipAddedDuration,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrProductVariantEdit].
class MockAppModulesCdrSchemasCdrProductVariantEdit {
  MockAppModulesCdrSchemasCdrProductVariantEdit._();
  static AppModulesCdrSchemasCdrProductVariantEdit get any =>
      AppModulesCdrSchemasCdrProductVariantEdit.empty();
  static AppModulesCdrSchemasCdrProductVariantEdit withFields({
    String? nameFr,
    String? nameEn,
    String? descriptionFr,
    String? descriptionEn,
    int? price,
    bool? enabled,
    bool? unique,
    List<String>? allowedCurriculum,
    String? relatedMembershipAddedDuration,
  }) => AppModulesCdrSchemasCdrProductVariantEdit.empty().copyWith(
    nameFr: nameFr,
    nameEn: nameEn,
    descriptionFr: descriptionFr,
    descriptionEn: descriptionEn,
    price: price,
    enabled: enabled,
    unique: unique,
    allowedCurriculum: allowedCurriculum,
    relatedMembershipAddedDuration: relatedMembershipAddedDuration,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrPurchaseBase].
class MockAppModulesCdrSchemasCdrPurchaseBase {
  MockAppModulesCdrSchemasCdrPurchaseBase._();
  static AppModulesCdrSchemasCdrPurchaseBase get any =>
      AppModulesCdrSchemasCdrPurchaseBase.empty();
  static AppModulesCdrSchemasCdrPurchaseBase withFields({
    required int quantity,
  }) =>
      AppModulesCdrSchemasCdrPurchaseBase.empty().copyWith(quantity: quantity);
}

/// Fake factory for [AppModulesCdrSchemasCdrPurchaseComplete].
class MockAppModulesCdrSchemasCdrPurchaseComplete {
  MockAppModulesCdrSchemasCdrPurchaseComplete._();
  static AppModulesCdrSchemasCdrPurchaseComplete get any =>
      AppModulesCdrSchemasCdrPurchaseComplete.empty();
  static AppModulesCdrSchemasCdrPurchaseComplete withOnly({
    required String userId,
  }) =>
      MockAppModulesCdrSchemasCdrPurchaseComplete.any.copyWith(userId: userId);

  static AppModulesCdrSchemasCdrPurchaseComplete withFields({
    required int quantity,
    required String userId,
    required String productVariantId,
    required bool validated,
    required DateTime purchasedOn,
  }) => AppModulesCdrSchemasCdrPurchaseComplete.empty().copyWith(
    quantity: quantity,
    userId: userId,
    productVariantId: productVariantId,
    validated: validated,
    purchasedOn: purchasedOn,
  );
}

/// Fake factory for [AppModulesCdrSchemasCdrTicket].
class MockAppModulesCdrSchemasCdrTicket {
  MockAppModulesCdrSchemasCdrTicket._();
  static AppModulesCdrSchemasCdrTicket get any =>
      AppModulesCdrSchemasCdrTicket.empty();
  static AppModulesCdrSchemasCdrTicket withOnly({required String id}) =>
      MockAppModulesCdrSchemasCdrTicket.any.copyWith(id: id);

  static AppModulesCdrSchemasCdrTicket withFields({
    required String id,
    required AppModulesCdrSchemasCdrProductVariantComplete productVariant,
    required UserTicket user,
    required int scanLeft,
    required String tags,
    required DateTime expiration,
    required String name,
  }) => AppModulesCdrSchemasCdrTicket.empty().copyWith(
    id: id,
    productVariant: productVariant,
    user: user,
    scanLeft: scanLeft,
    tags: tags,
    expiration: expiration,
    name: name,
  );
}

/// Fake factory for [AppModulesPhonebookSchemasPhonebookAssociationBase].
class MockAppModulesPhonebookSchemasPhonebookAssociationBase {
  MockAppModulesPhonebookSchemasPhonebookAssociationBase._();
  static AppModulesPhonebookSchemasPhonebookAssociationBase get any =>
      AppModulesPhonebookSchemasPhonebookAssociationBase.empty();
  static AppModulesPhonebookSchemasPhonebookAssociationBase withOnly({
    required String groupementId,
  }) => MockAppModulesPhonebookSchemasPhonebookAssociationBase.any.copyWith(
    groupementId: groupementId,
  );

  static AppModulesPhonebookSchemasPhonebookAssociationBase withFields({
    required String name,
    required String groupementId,
    required int mandateYear,
    String? description,
    List<String>? associatedGroups,
    bool? deactivated,
  }) => AppModulesPhonebookSchemasPhonebookAssociationBase.empty().copyWith(
    name: name,
    groupementId: groupementId,
    mandateYear: mandateYear,
    description: description,
    associatedGroups: associatedGroups,
    deactivated: deactivated,
  );
}

/// Fake factory for [AppModulesPhonebookSchemasPhonebookMembershipBase].
class MockAppModulesPhonebookSchemasPhonebookMembershipBase {
  MockAppModulesPhonebookSchemasPhonebookMembershipBase._();
  static AppModulesPhonebookSchemasPhonebookMembershipBase get any =>
      AppModulesPhonebookSchemasPhonebookMembershipBase.empty();
  static AppModulesPhonebookSchemasPhonebookMembershipBase withOnly({
    required String userId,
    required String associationId,
    required int mandateYear,
    required String roleName,
    required int memberOrder,
  }) => MockAppModulesPhonebookSchemasPhonebookMembershipBase.any.copyWith(
    userId: userId,
    associationId: associationId,
    mandateYear: mandateYear,
    roleName: roleName,
    memberOrder: memberOrder,
  );

  static AppModulesPhonebookSchemasPhonebookMembershipBase withFields({
    required String userId,
    required String associationId,
    required int mandateYear,
    required String roleName,
    String? roleTags,
    required int memberOrder,
  }) => AppModulesPhonebookSchemasPhonebookMembershipBase.empty().copyWith(
    userId: userId,
    associationId: associationId,
    mandateYear: mandateYear,
    roleName: roleName,
    roleTags: roleTags,
    memberOrder: memberOrder,
  );
}

/// Fake factory for [AppModulesRaffleSchemasRaffleCashComplete].
class MockAppModulesRaffleSchemasRaffleCashComplete {
  MockAppModulesRaffleSchemasRaffleCashComplete._();
  static AppModulesRaffleSchemasRaffleCashComplete get any =>
      AppModulesRaffleSchemasRaffleCashComplete.empty();
  static AppModulesRaffleSchemasRaffleCashComplete withOnly({
    required String userId,
  }) => MockAppModulesRaffleSchemasRaffleCashComplete.any.copyWith(
    userId: userId,
  );

  static AppModulesRaffleSchemasRaffleCashComplete withFields({
    required int balance,
    required String userId,
    required CoreUserSimple user,
  }) => AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
    balance: balance,
    userId: userId,
    user: user,
  );
}

/// Fake factory for [AppModulesRaffleSchemasRaffleTicketComplete].
class MockAppModulesRaffleSchemasRaffleTicketComplete {
  MockAppModulesRaffleSchemasRaffleTicketComplete._();
  static AppModulesRaffleSchemasRaffleTicketComplete get any =>
      AppModulesRaffleSchemasRaffleTicketComplete.empty();
  static AppModulesRaffleSchemasRaffleTicketComplete withOnly({
    required String id,
  }) => MockAppModulesRaffleSchemasRaffleTicketComplete.any.copyWith(id: id);

  static AppModulesRaffleSchemasRaffleTicketComplete withFields({
    required String packId,
    required String userId,
    String? winningPrize,
    required String id,
    PrizeSimple? prize,
    required PackTicketSimple packTicket,
    required CoreUserSimple user,
  }) => AppModulesRaffleSchemasRaffleTicketComplete.empty().copyWith(
    packId: packId,
    userId: userId,
    winningPrize: winningPrize,
    id: id,
    prize: prize,
    packTicket: packTicket,
    user: user,
  );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionPaymentBase].
class MockAppModulesSportCompetitionSchemasSportCompetitionPaymentBase {
  MockAppModulesSportCompetitionSchemasSportCompetitionPaymentBase._();
  static AppModulesSportCompetitionSchemasSportCompetitionPaymentBase get any =>
      AppModulesSportCompetitionSchemasSportCompetitionPaymentBase.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionPaymentBase
  withFields({required int total}) =>
      AppModulesSportCompetitionSchemasSportCompetitionPaymentBase.empty()
          .copyWith(total: total);
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete].
class MockAppModulesSportCompetitionSchemasSportCompetitionPaymentComplete {
  MockAppModulesSportCompetitionSchemasSportCompetitionPaymentComplete._();
  static AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete
  withOnly({required String id}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionPaymentComplete.any
          .copyWith(id: id);

  static AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete
  withFields({
    required int total,
    required String id,
    required String userId,
    required String editionId,
    required enums.PaiementMethodType method,
  }) => AppModulesSportCompetitionSchemasSportCompetitionPaymentComplete.empty()
      .copyWith(
        total: total,
        id: id,
        userId: userId,
        editionId: editionId,
        method: method,
      );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductBase].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductBase {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductBase._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductBase get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductBase.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductBase
  withFields({required String name, bool? required, String? description}) =>
      AppModulesSportCompetitionSchemasSportCompetitionProductBase.empty()
          .copyWith(name: name, required: required, description: description);
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductComplete].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductComplete {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductComplete._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductComplete
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductComplete.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductComplete
  withOnly({required String id}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionProductComplete.any
          .copyWith(id: id);

  static AppModulesSportCompetitionSchemasSportCompetitionProductComplete
  withFields({
    required String name,
    bool? required,
    String? description,
    required String id,
    required String editionId,
    List<ProductVariantStats>? variants,
  }) => AppModulesSportCompetitionSchemasSportCompetitionProductComplete.empty()
      .copyWith(
        name: name,
        required: required,
        description: description,
        id: id,
        editionId: editionId,
        variants: variants,
      );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductEdit].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductEdit {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductEdit._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductEdit get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductEdit.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductEdit
  withFields({String? name, bool? required, String? description}) =>
      AppModulesSportCompetitionSchemasSportCompetitionProductEdit.empty()
          .copyWith(name: name, required: required, description: description);
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantBase {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantBase._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase
  withOnly({required String productId}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantBase
          .any
          .copyWith(productId: productId);

  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase
  withFields({
    required String productId,
    required String name,
    String? description,
    required int price,
    bool? enabled,
    required bool unique,
    enums.ProductSchoolType? schoolType,
    enums.ProductPublicType? publicType,
  }) =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantBase.empty()
          .copyWith(
            productId: productId,
            name: name,
            description: description,
            price: price,
            enabled: enabled,
            unique: unique,
            schoolType: schoolType,
            publicType: publicType,
          );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
  withOnly({required String id}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
          .any
          .copyWith(id: id);

  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete
  withFields({
    required String productId,
    required String name,
    String? description,
    required int price,
    bool? enabled,
    required bool unique,
    enums.ProductSchoolType? schoolType,
    enums.ProductPublicType? publicType,
    required String editionId,
    required String id,
    required Product product,
  }) =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantComplete.empty()
          .copyWith(
            productId: productId,
            name: name,
            description: description,
            price: price,
            enabled: enabled,
            unique: unique,
            schoolType: schoolType,
            publicType: publicType,
            editionId: editionId,
            id: id,
            product: product,
          );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit].
class MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit {
  MockAppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit._();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit
  withFields({
    String? name,
    String? description,
    int? price,
    bool? enabled,
    bool? unique,
    enums.ProductSchoolType? schoolType,
    enums.ProductPublicType? publicType,
  }) =>
      AppModulesSportCompetitionSchemasSportCompetitionProductVariantEdit.empty()
          .copyWith(
            name: name,
            description: description,
            price: price,
            enabled: enabled,
            unique: unique,
            schoolType: schoolType,
            publicType: publicType,
          );
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase].
class MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseBase {
  MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseBase._();
  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase
  withOnly({required String productVariantId}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseBase.any
          .copyWith(productVariantId: productVariantId);

  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase
  withFields({required String productVariantId, required int quantity}) =>
      AppModulesSportCompetitionSchemasSportCompetitionPurchaseBase.empty()
          .copyWith(productVariantId: productVariantId, quantity: quantity);
}

/// Fake factory for [AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete].
class MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete {
  MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete._();
  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete
  get any =>
      AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete.empty();
  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete
  withOnly({required String productVariantId}) =>
      MockAppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete.any
          .copyWith(productVariantId: productVariantId);

  static AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete
  withFields({
    required String productVariantId,
    required int quantity,
    required String userId,
    required String editionId,
    required bool validated,
    required DateTime purchasedOn,
    required ProductVariant productVariant,
  }) =>
      AppModulesSportCompetitionSchemasSportCompetitionPurchaseComplete.empty()
          .copyWith(
            productVariantId: productVariantId,
            quantity: quantity,
            userId: userId,
            editionId: editionId,
            validated: validated,
            purchasedOn: purchasedOn,
            productVariant: productVariant,
          );
}

/// Fake factory for [AppTypesStandardResponsesResult].
class MockAppTypesStandardResponsesResult {
  MockAppTypesStandardResponsesResult._();
  static AppTypesStandardResponsesResult get any =>
      AppTypesStandardResponsesResult.empty();
  static AppTypesStandardResponsesResult withFields({bool? success}) =>
      AppTypesStandardResponsesResult.empty().copyWith(success: success);
}
