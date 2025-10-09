import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/wallet_device.dart';
import 'package:titan/paiement/repositories/devices_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class DeviceListNotifier extends ListNotifier<WalletDevice> {
  DevicesRepository get devicesRepository =>
      ref.watch(devicesRepositoryProvider);

  @override
  AsyncValue<List<WalletDevice>> build() {
    getDeviceList();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<WalletDevice>>> getDeviceList() async {
    return await loadList(devicesRepository.getDevices);
  }

  Future<bool> revokeDevice(WalletDevice device) async {
    return await update(
      (device) => devicesRepository.revokeDevice(device.id),
      (devices, device) =>
          devices..[devices.indexWhere((d) => d.id == device.id)] = device,
      device,
    );
  }
}

final deviceListProvider =
    NotifierProvider<DeviceListNotifier, AsyncValue<List<WalletDevice>>>(
      DeviceListNotifier.new,
    );
