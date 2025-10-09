import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/create_device.dart';
import 'package:titan/paiement/class/wallet_device.dart';
import 'package:titan/paiement/repositories/devices_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class DeviceNotifier extends SingleNotifier<WalletDevice> {
  DevicesRepository get devicesRepository =>
      ref.watch(devicesRepositoryProvider);

  @override
  AsyncValue<WalletDevice> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<WalletDevice>> getDevice(String deviceId) async {
    return await load(() => devicesRepository.getDevice(deviceId));
  }

  Future<String?> registerDevice(CreateDevice body) async {
    try {
      final fake = await devicesRepository.registerDevice(body);
      state = AsyncValue.data(fake);
      return fake.id;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
}

final deviceProvider =
    NotifierProvider<DeviceNotifier, AsyncValue<WalletDevice>>(
      DeviceNotifier.new,
    );
