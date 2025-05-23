import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_service.dart';

class BLEInitializer {
  final BLEService _bleService = BLEService();

  Future<void> initializeBluetooth() async {
    await _bleService.initialize();

    final lastDeviceId = await _bleService.getLastConnectedDeviceId();
    if (lastDeviceId != null) {
      print('Último dispositivo salvo: $lastDeviceId');
      // Aqui, você pode conectar automaticamente se quiser:
      _bleService.connectToDeviceId(lastDeviceId);
    } else {
      print('Nenhum dispositivo salvo encontrado');
    }
  }
}
