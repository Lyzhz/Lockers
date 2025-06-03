import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;

  BLEService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final _connectionController = StreamController<bool>.broadcast();
  final _receivedDataController = StreamController<String>.broadcast();
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();

  Stream<bool> get connectionState => _connectionController.stream;
  Stream<String> get receivedData => _receivedDataController.stream;
  Stream<List<DiscoveredDevice>> get discoveredDevices => _devicesController.stream;

  final Uuid _serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid _notifyUuid = Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid _writeUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  QualifiedCharacteristic? _writeCharacteristic;

  bool _isConnected = false;
  String? _connectedDeviceId; // Salva o ID do dispositivo conectado

  Future<void> initialize() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();

    if (!(await Permission.bluetooth.isGranted)) {
      throw Exception('Permissões Bluetooth não concedidas.');
    }

    print('✅ Permissões BLE OK!');
  }

  Future<List<DiscoveredDevice>> scanForDevices({Duration timeout = const Duration(seconds: 5)}) async {
    final List<DiscoveredDevice> foundDevices = [];
    final subscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (!foundDevices.any((d) => d.id == device.id)) {
        foundDevices.add(device);
        _devicesController.add(List<DiscoveredDevice>.from(foundDevices));
      }
    });

    await Future.delayed(timeout);
    await subscription.cancel();
    print('🔍 Scan finalizado, ${foundDevices.length} dispositivo(s) encontrado(s).');
    return foundDevices;
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (_isConnected && _connectedDeviceId == device.id) {
      print('⚠️ Já conectado a ${device.name}. Ignorando nova conexão.');
      return;
    }

    disconnect();
    print('🔗 Conectando a ${device.name} (${device.id})...');

    _connectionSubscription = _ble.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {
        _serviceUuid: [_notifyUuid, _writeUuid],
      },
    ).listen((update) {
      print('📶 Estado: ${update.connectionState}');
      if (update.connectionState == DeviceConnectionState.connected) {
        _isConnected = true;
        _connectedDeviceId = device.id;
        _connectionController.add(true);

        _writeCharacteristic = QualifiedCharacteristic(
          serviceId: _serviceUuid,
          characteristicId: _writeUuid,
          deviceId: device.id,
        );

        final notifyCharacteristic = QualifiedCharacteristic(
          serviceId: _serviceUuid,
          characteristicId: _notifyUuid,
          deviceId: device.id,
        );

        _notifySubscription = _ble.subscribeToCharacteristic(notifyCharacteristic).listen(
          (data) {
            final value = String.fromCharCodes(data);
            final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
            print('🔔 NOTIFY RAW: $data');
            print('🔔 NOTIFY ASCII: $value');
            print('🔔 NOTIFY HEX: $hex');
            _receivedDataController.add(value);
          },
          onError: (e) {
            print('❌ Erro ao receber notificação: $e');
          },
        );

        print('✅ Conexão BLE estabelecida e notificação assinada!');
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        print('🔌 Dispositivo desconectado.');
        _isConnected = false;
        _connectedDeviceId = null;
        _connectionController.add(false);
        _notifySubscription?.cancel();
      }
    }, onError: (e) {
      print('❌ Erro na conexão: $e');
      _isConnected = false;
      _connectedDeviceId = null;
      _connectionController.add(false);
    });
  }

  Future<void> reconnectIfNeeded() async {
    if (_connectedDeviceId != null && !_isConnected) {
      print('🔄 Tentando reconectar ao dispositivo $_connectedDeviceId...');
      try {
        _connectionSubscription = _ble.connectToDevice(
          id: _connectedDeviceId!,
          servicesWithCharacteristicsToDiscover: {
            _serviceUuid: [_notifyUuid, _writeUuid],
          },
        ).listen((update) {
          print('📶 Estado reconexão: ${update.connectionState}');
          if (update.connectionState == DeviceConnectionState.connected) {
            _isConnected = true;
            _connectionController.add(true);

            _writeCharacteristic = QualifiedCharacteristic(
              serviceId: _serviceUuid,
              characteristicId: _writeUuid,
              deviceId: _connectedDeviceId!,
            );

            final notifyCharacteristic = QualifiedCharacteristic(
              serviceId: _serviceUuid,
              characteristicId: _notifyUuid,
              deviceId: _connectedDeviceId!,
            );

            _notifySubscription = _ble.subscribeToCharacteristic(notifyCharacteristic).listen(
              (data) {
                final value = String.fromCharCodes(data);
                print('🔔 Reconectado - NOTIFY: $value');
                _receivedDataController.add(value);
              },
            );
          }
        });
      } catch (e) {
        print('❌ Falha na reconexão: $e');
      }
    } else {
      print('⚠️ Nenhum dispositivo para reconectar.');
    }
  }

  void sendCommand(String command) {
    if (_isConnected && _writeCharacteristic != null) {
      final data = command.codeUnits;
      _ble.writeCharacteristicWithResponse(_writeCharacteristic!, value: data);
      print('📤 Enviado: $command');
    } else {
      print('⚠️ Não conectado. Não foi possível enviar o comando.');
    }
  }

  void disconnect() {
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _receivedDataController.close();
    _devicesController.close();
  }
}
