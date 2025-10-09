import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/class/seller.dart';

class SellerNotifier extends Notifier<Seller> {
  @override
  Seller build() {
    return Seller.empty();
  }

  void setSeller(Seller i) {
    state = i;
  }
}

final sellerProvider = NotifierProvider<SellerNotifier, Seller>(
  SellerNotifier.new,
);
