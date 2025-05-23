import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  QualifiedCharacteristic? _characteristic;
  DiscoveredDevice? _device;
  bool _isConnected = false;
  bool _isScanning = false;
  final List<DiscoveredDevice> _discoveredDevices = [];

  final _connectionStateController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();

  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<List<DiscoveredDevice>> get discoveredDevices => _devicesController.stream;

  final String _serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String _characteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  DiscoveredDevice? get device => _device;
  List<DiscoveredDevice> get currentDevices => _discoveredDevices;

  // Inicializa permissões BLE
  Future<void> initialize() async {
    print('🔧 Inicializando BLE...');
    try {
      final statuses = <PermissionStatus>[];

statuses.add(await Permission.bluetooth.request());
statuses.add(await Permission.bluetoothScan.request());
statuses.add(await Permission.bluetoothConnect.request());
statuses.add(await Permission.location.request());

      if (statuses.any((s) => s.isDenied)) {
        print('🚫 Permissões negadas: não é possível prosseguir.');
        return;
      }

      print('✅ Permissões concedidas. BLE pronto para uso.');
    } catch (e) {
      print('💥 Erro na inicialização do BLE: $e');
    }
  }

  Future<void> startScan() async {
    print('🔍 Iniciando escaneamento BLE...');
    if (_isScanning) {
      print('⚠️ Já está escaneando.');
      return;
    }

    _isScanning = true;
    _scanSubscription?.cancel();
    _discoveredDevices.clear();
    _devicesController.add(_discoveredDevices);

    try {
      _scanSubscription = _ble.scanForDevices(
        withServices: [], // Pode filtrar por serviço se quiser
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          _discoveredDevices.add(device);
          _devicesController.add(_discoveredDevices);
          print('📡 Dispositivo encontrado: ${device.name} (${device.id})');
        }
      }, onError: (error) {
        print('💥 Erro ao escanear: $error');
        _isScanning = false;
      });

      Future.delayed(const Duration(seconds: 5), stopScan);
    } catch (e) {
      print('💥 Exceção no escaneamento: $e');
      _isScanning = false;
    }
  }

  void stopScan() {
    if (!_isScanning) return;
    print('🛑 Parando escaneamento...');
    _scanSubscription?.cancel();
    _isScanning = false;
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    print('🔗 Conectando ao dispositivo: ${device.name} (${device.id})');
    if (_isConnected) {
      print('⚠️ Já está conectado.');
      return;
    }

    _device = device;
    _connectionSubscription?.cancel();

    try {
      _connectionSubscription = _ble
          .connectToDevice(
            id: device.id,
            connectionTimeout: const Duration(seconds: 20),
          )
          .listen(_handleConnectionUpdate, onError: _handleConnectionError);
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  Future<void> connectToDeviceId(String deviceId) async {
    print('🔗 Conectando via ID: $deviceId');
    if (_isConnected) {
      print('⚠️ Já está conectado.');
      return;
    }

    _connectionSubscription?.cancel();

    try {
      _connectionSubscription = _ble
          .connectToDevice(
            id: deviceId,
            connectionTimeout: const Duration(seconds: 20),
          )
          .listen((update) => _handleConnectionUpdate(update, idOverride: deviceId),
              onError: _handleConnectionError);
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _handleConnectionUpdate(ConnectionStateUpdate update, {String? idOverride}) {
    switch (update.connectionState) {
      case DeviceConnectionState.connected:
        print('✅ Dispositivo conectado.');
        _isConnected = true;
        _connectionStateController.add(true);
        _discoverServices(deviceId: idOverride ?? _device!.id);
        _saveLastConnectedDeviceId(idOverride ?? _device!.id);
        break;
      case DeviceConnectionState.disconnected:
        print('🔌 Dispositivo desconectado.');
        _resetConnectionState();
        // Reconecta automático
        if (idOverride != null) {
          Future.delayed(const Duration(seconds: 2), () {
            connectToDeviceId(idOverride);
          });
        } else if (_device != null) {
          Future.delayed(const Duration(seconds: 2), () {
            connectToDevice(_device!);
          });
        }
        break;
      default:
        print('🔄 Estado da conexão: ${update.connectionState}');
    }
  }

  void _handleConnectionError(Object error) {
    print('💥 Erro de conexão: $error');
    _resetConnectionState();
  }

  void _resetConnectionState() {
    _isConnected = false;
    _connectionStateController.add(false);
    _device = null;
    _characteristic = null;
  }

  Future<void> disconnect() async {
    print('🔌 Desconectando...');
    if (_device == null || !_isConnected) {
      print('⚠️ Nenhum dispositivo para desconectar.');
      return;
    }

    await _connectionSubscription?.cancel();
    _resetConnectionState();
  }

  Future<void> _discoverServices({String? deviceId}) async {
    final id = deviceId ?? _device?.id;
    if (id == null) {
      print('❌ Sem dispositivo conectado para descoberta de serviço.');
      return;
    }

    try {
      print('🔎 Descobrindo serviços de $id...');
      final services = await _ble.discoverServices(id);

      final service = services.firstWhere(
        (s) => s.serviceId.toString().toUpperCase() == _serviceUUID.toUpperCase(),
        orElse: () => throw Exception('Serviço não encontrado'),
      );

      final char = service.characteristics.firstWhere(
        (c) => c.characteristicId.toString().toUpperCase() == _characteristicUUID.toUpperCase(),
        orElse: () => throw Exception('Característica não encontrada'),
      );

      if (!char.isWritableWithResponse && !char.isWritableWithoutResponse) {
        throw Exception('Característica não é writable');
      }

      _characteristic = QualifiedCharacteristic(
        serviceId: service.serviceId,
        characteristicId: char.characteristicId,
        deviceId: id,
      );
      print('✅ Característica configurada com sucesso!');
    } catch (e) {
      print('💥 Falha na descoberta de serviços: $e');
      _characteristic = null;
    }
  }

  Future<void> sendCommand(String command) async {
    print('📤 Enviando comando: $command');
    if (!_isConnected || _characteristic == null) {
      print('❌ Não é possível enviar: sem conexão ou characteristic inválida.');
      return;
    }

    try {
      await _ble.writeCharacteristicWithoutResponse(
        _characteristic!,
        value: command.codeUnits,
      );
      print('✅ Comando enviado.');
    } catch (e) {
      print('💥 Erro ao enviar comando: $e');
    }
  }

  Future<void> _saveLastConnectedDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastConnectedDeviceId', deviceId);
    print('💾 Último dispositivo salvo: $deviceId');
  }

  Future<String?> getLastConnectedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastConnectedDeviceId');
  }

  void dispose() {
    print('🧹 Limpando BLEService...');
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectionStateController.close();
    _devicesController.close();
  }
}
