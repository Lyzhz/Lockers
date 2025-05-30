// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'ble_service.dart';

// class BLEInitializer {
//   final BLEService _bleService = BLEService();

//   Future<void> initializeBluetooth() async {
//     await _bleService.initialize();

//     final lastDeviceId = await _bleService.getLastConnectedDeviceId();
//     if (lastDeviceId != null) {
//       print('🔄 Último dispositivo salvo: $lastDeviceId');
//       try {
//         // Faça um scan para popular a lista de dispositivos
//         await _bleService.scanForDevices(timeout: Duration(seconds: 5));
//         await _bleService.connectToDeviceId(lastDeviceId);
//       } catch (e, s) {
//         print('Erro ao conectar ao último dispositivo: $e');
//         print(s);
//       }
//     } else {
//       print('⚠️ Nenhum dispositivo salvo encontrado');
//     }
//   }
// }
