import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/purchases/class/purchase.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class PurchaseNotifier extends SingleNotifier<Purchase> {
  @override
  AsyncValue<Purchase> build() {
    return const AsyncValue.loading();
  }

  void setPurchase(Purchase i) {
    state = AsyncValue.data(i);
  }
}

final purchaseProvider =
    NotifierProvider<PurchaseNotifier, AsyncValue<Purchase>>(
      PurchaseNotifier.new,
    );
