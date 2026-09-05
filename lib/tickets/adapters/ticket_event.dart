import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/date_time_json.dart';

/// Lifecycle of a ticket event, derived client-side from its open/close dates.
enum TicketEventStatus { open, closed, upcoming, disabled }

TicketEventStatus _statusFrom(
  bool disabled,
  DateTime openDatetime,
  DateTime? closeDatetime,
) {
  if (disabled) return TicketEventStatus.disabled;
  final now = DateTime.now();
  if (closeDatetime != null && closeDatetime.isBefore(now)) {
    return TicketEventStatus.closed;
  }
  if (openDatetime.isAfter(now)) return TicketEventStatus.upcoming;
  return TicketEventStatus.open;
}

extension $EventCreate on EventCreate {
  /// Generated [toJson] drops null keys, but the tickets API still expects
  /// nullable fields to be present in the body.
  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json['quota'] = quota;
    json['close_datetime'] = dateTimeToJson(closeDatetime);
    json['sessions'] = sessions.map((session) {
      final sessionJson = session.toJson();
      sessionJson['quota'] = session.quota;
      return sessionJson;
    }).toList();
    json['categories'] = categories.map((category) {
      final categoryJson = category.toJson();
      categoryJson['quota'] = category.quota;
      categoryJson['required_membership'] = category.requiredMembership;
      return categoryJson;
    }).toList();
    json['questions'] = questions.map((question) {
      final questionJson = question.toJson();
      questionJson['price'] = question.price;
      return questionJson;
    }).toList();
    return json;
  }
}

extension $EventAdmin on EventAdmin {
  EventUpdate toEventUpdate() => EventUpdate(
    name: name,
    quota: quota,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
  );

  Map<String, dynamic> toUpdateJson() {
    final json = toEventUpdate().toJson();
    json['quota'] = quota;
    json['close_datetime'] = dateTimeToJson(closeDatetime);
    return json;
  }

  TicketEventStatus get status =>
      _statusFrom(disabled, openDatetime, closeDatetime);
}

extension $EventSimple on EventSimple {
  TicketEventStatus get status =>
      _statusFrom(disabled, openDatetime, closeDatetime);
}
