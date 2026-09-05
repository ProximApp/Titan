import 'package:titan/generated/openapi.models.swagger.dart';

extension $SessionAdmin on SessionAdmin {
  SessionUpdate toSessionUpdate() => SessionUpdate(
    name: name,
    startDatetime: startDatetime,
    quota: quota,
    disabled: disabled,
  );
}

extension $SessionComplete on SessionComplete {
  SessionAdmin toSessionAdmin() => SessionAdmin(
    id: id,
    eventId: eventId,
    name: name,
    startDatetime: startDatetime,
    disabled: disabled,
    quota: quota,
    ticketsInCheckout: 0,
    ticketsSold: 0,
  );
}
