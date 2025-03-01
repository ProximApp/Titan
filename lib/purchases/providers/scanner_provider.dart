import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/single_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

class ScannerNotifier extends SingleNotifierAPI<Ticket> {
  Openapi get scannerRepository => ref.watch(repositoryProvider);
  String secret = "";

  @override
  AsyncValue<Ticket> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Ticket>> scanTicket(
    String sellerId,
    String productId,
    String generatorId,
  ) async {
    return await load(
      () => scannerRepository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdSecretGet(
            sellerId: sellerId,
            productId: productId,
            generatorId: generatorId,
            secret: secret,
          ),
    );
  }

  void setScanner(Ticket i) {
    state = AsyncValue.data(i);
  }

  void reset() {
    state = const AsyncValue.loading();
    secret = "";
  }

  void setSecret(String secret) {
    this.secret = secret;
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, AsyncValue<Ticket>>(
  ScannerNotifier.new,
);
