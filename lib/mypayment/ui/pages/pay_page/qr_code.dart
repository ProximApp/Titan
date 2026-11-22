import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/mypayment/providers/key_service_provider.dart';
import 'package:titan/mypayment/providers/pay_amount_provider.dart';
import 'package:titan/mypayment/tools/functions.dart';
import 'package:titan/mypayment/tools/key_service.dart';
import 'package:titan/tools/ui/widgets/loader.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class QrCode extends ConsumerStatefulWidget {
  const QrCode({super.key});

  @override
  ConsumerState<QrCode> createState() => _QrCodeState();
}

class _QrCodeState extends ConsumerState<QrCode> {
  late final String _id = const Uuid().v4();

  String? _signedAmount;
  Future<String>? _content;

  Future<String> _qrContent(String payAmount, KeyService keyService) {
    if (_content == null || _signedAmount != payAmount) {
      _signedAmount = payAmount;
      _content = getQRCodeContent(_id, payAmount, keyService, true);
    }
    return _content!;
  }

  @override
  Widget build(BuildContext context) {
    final payAmount = ref.watch(payAmountProvider);
    final keyService = ref.watch(keyServiceProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.of(context).size;
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screen.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : screen.height;
        final qrSize = min(width, height) * 0.8;
        return FutureBuilder(
          future: _qrContent(payAmount, keyService),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return SizedBox(
                width: qrSize,
                height: qrSize,
                child: const Loader(),
              );
            }
            return Center(
              child: QrImageView(
                data: snapshot.data!,
                version: QrVersions.auto,
                size: qrSize,
                eyeStyle: const QrEyeStyle(
                  color: Colors.black,
                  eyeShape: QrEyeShape.square,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
