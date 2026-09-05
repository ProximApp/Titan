import 'package:titan/generated/openapi.models.swagger.dart';

extension $CategoryAdmin on CategoryAdmin {
  int get priceInEuros => price ~/ 100;

  CategoryUpdate toCategoryUpdate() => CategoryUpdate(
    name: name,
    price: price,
    quota: quota,
    requiredMembership: requiredMembership,
    disabled: disabled,
  );
}

extension $CategoryPublic on CategoryPublic {
  int get priceInEuros => price ~/ 100;
}

extension $CategoryComplete on CategoryComplete {
  CategoryAdmin toCategoryAdmin() => CategoryAdmin(
    id: id,
    eventId: eventId,
    name: name,
    price: price,
    requiredMembership: requiredMembership,
    disabled: disabled,
    quota: quota,
    ticketsInCheckout: 0,
    ticketsSold: 0,
  );
}
