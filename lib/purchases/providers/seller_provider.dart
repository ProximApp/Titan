import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/builders/empty_models.dart';

class SellerNotifier extends Notifier<SellerComplete> {
  @override
  SellerComplete build() {
    return EmptyModels.empty<SellerComplete>();
  }

  void setSeller(SellerComplete i) {
    state = i;
  }
}

final sellerProvider = NotifierProvider<SellerNotifier, SellerComplete>(
  SellerNotifier.new,
);
