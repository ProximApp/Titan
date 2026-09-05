import 'package:titan/generated/openapi.models.swagger.dart';

extension $QuestionCreate on QuestionCreate {
  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json['price'] = price;
    return json;
  }
}

extension $QuestionAdmin on QuestionAdmin {
  QuestionUpdate toQuestionUpdate() => QuestionUpdate(
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );

  Map<String, dynamic> toUpdateJson() {
    final json = toQuestionUpdate().toJson();
    json['price'] = price;
    return json;
  }
}

extension $Question on Question {
  /// The create endpoint answers with a [Question]; the event holds
  /// [QuestionAdmin]. The two carry the same fields.
  QuestionAdmin toQuestionAdmin() => QuestionAdmin(
    id: id,
    eventId: eventId,
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}
