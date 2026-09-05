import 'package:titan/generated/openapi.models.swagger.dart';

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

extension $EventAdmin on EventAdmin {
  EventUpdate toEventUpdate() => EventUpdate(
    name: name,
    quota: quota,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
  );

  EventSimple toEventSimple() => EventSimple(
    id: id,
    name: name,
    storeId: storeId,
    openDatetime: openDatetime,
    closeDatetime: closeDatetime,
    disabled: disabled,
  );

  TicketEventStatus get status =>
      _statusFrom(disabled, openDatetime, closeDatetime);
}

extension $EventSimple on EventSimple {
  TicketEventStatus get status =>
      _statusFrom(disabled, openDatetime, closeDatetime);
}
