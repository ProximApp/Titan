import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/class/ticket.dart';
import 'package:titan/purchases/repositories/scanner_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class ScannerNotifier extends SingleNotifier<Ticket> {
  final ScannerRepository scannerRepository = ScannerRepository();

  @override
  AsyncValue<Ticket> build() {
    final token = ref.watch(tokenProvider);
    scannerRepository.setToken(token);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Ticket>> scanTicket(
    String sellerId,
    String productId,
    String ticketSecret,
    String generatorId,
  ) async {
    return await load(
      () => scannerRepository.scanTicket(
        sellerId,
        productId,
        ticketSecret,
        generatorId,
      ),
    );
  }

  void setScanner(Ticket i) {
    state = AsyncValue.data(i);
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, AsyncValue<Ticket>>(
  ScannerNotifier.new,
);
