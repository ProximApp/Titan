import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

extension $EventComplete on EventComplete {
  EventBaseCreation toEventBaseCreation() {
    return EventBaseCreation(
      name: name,
      start: start,
      end: end,
      allDay: allDay,
      location: location,
      description: description,
      recurrenceRule: recurrenceRule,
      notification: notification,
      associationId: associationId,
    );
  }
}
