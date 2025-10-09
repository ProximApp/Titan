import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/paiement/class/qr_code_data.dart';

class BarcodeNotifier extends Notifier<QrCodeData?> {
  @override
  QrCodeData? build() {
    return null;
  }

  QrCodeData updateBarcode(String barcode) {
    state = QrCodeData.fromJson(jsonDecode(barcode));
    return state!;
  }

  void clearBarcode() {
    state = null;
  }
}

final barcodeProvider = NotifierProvider<BarcodeNotifier, QrCodeData?>(
  BarcodeNotifier.new,
);
