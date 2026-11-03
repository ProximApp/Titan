import 'package:titan/generated/openapi.enums.swagger.dart';

String raffleStatusTypeToString(RaffleStatusType raffleStatusType) {
  switch (raffleStatusType) {
    case RaffleStatusType.creation:
      return 'creation';
    case RaffleStatusType.open:
      return 'open';
    case RaffleStatusType.lock:
      return 'lock';
    case RaffleStatusType.swaggerGeneratedUnknown:
      return 'error';
  }
}
