import 'package:titan/generated/openapi.models.swagger.dart';

extension $QuestionAdmin on QuestionAdmin {
  QuestionUpdate toQuestionUpdate() => QuestionUpdate(
    question: question,
    answerType: answerType,
    price: price,
    required: required,
    disabled: disabled,
  );
}

extension $Question on Question {
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
