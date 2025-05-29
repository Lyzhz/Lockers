import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _openAppSettings(BuildContext context) async {
  bool opened = await openAppSettings();
  if (!opened) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Não foi possível abrir as configurações. Conceda as permissões manualmente.')),
    );
  }
}


class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final flutterReactiveBle = FlutterReactiveBle();

  // UUIDs do serviço e características
  final Uuid serviceUuid = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid readUuid = Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
  final Uuid writeUuid = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  // Estado da conexão e dispositivo conectado
  DiscoveredDevice? _connectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _subscription;

  // Controle dos dispositivos encontrados
  List<DiscoveredDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnected = false;

  // Últimos dados lidos do dispositivo
  String _receivedData = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _connection?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  // Função para pedir permissões Bluetooth e Location (necessário Android)
  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissões necessárias não concedidas! Abra as configurações para conceder.'),
          action: SnackBarAction(
            label: 'Abrir Configurações',
            onPressed: () => _openAppSettings(context),
          ),
        ),
      );
    }

    return allGranted;
  }

  // Inicia o escaneamento Bluetooth e mostra o popup de dispositivos
  Future<void> _startScan() async {
    final granted = await _requestPermissions();
    if (!granted) return;

    setState(() {
      _foundDevices.clear();
      _isScanning = true;
    });

    flutterReactiveBle.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (!_foundDevices.any((d) => d.id == device.id)) {
        setState(() {
          _foundDevices.add(device);
        });
      }
    }, onError: (error) {
      print('Erro no scan: $error');
    });

    // Mostrar popup de seleção
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Selecione o dispositivo'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _foundDevices.isEmpty
              ? Center(child: Text(_isScanning ? 'Procurando...' : 'Nenhum dispositivo encontrado'))
              : ListView.builder(
                  itemCount: _foundDevices.length,
                  itemBuilder: (context, index) {
                    final device = _foundDevices[index];
                    return ListTile(
                      title: Text(device.name.isNotEmpty ? device.name : 'Dispositivo sem nome'),
                      subtitle: Text(device.id),
                      onTap: () {
                        Navigator.of(context).pop();
                        _connectToDevice(device);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
        ],
      ),
    );

    // Parar scan
    flutterReactiveBle.deinitialize();
    setState(() {
      _isScanning = false;
    });
  }

  // Conecta ao dispositivo escolhido e escuta notificações da característica de leitura
  void _connectToDevice(DiscoveredDevice device) {
    _connection?.cancel();

    _connection = flutterReactiveBle.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen(
      (connectionState) {
        print('Estado conexão: $connectionState');
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          setState(() {
            _connectedDevice = device;
            _isConnected = true;
          });
          _subscribeToCharacteristic(device);
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _receivedData = '';
          });
        }
      },
      onError: (error) {
        print('Erro na conexão: $error');
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _receivedData = '';
        });
      },
    );
  }

  // Se inscreve na característica que envia dados (notificações)
  void _subscribeToCharacteristic(DiscoveredDevice device) {
    _subscription?.cancel();

    final characteristic = QualifiedCharacteristic(
      characteristicId: readUuid,
      serviceId: serviceUuid,
      deviceId: device.id,
    );

    _subscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen(
      (data) {
        final text = String.fromCharCodes(data);
        setState(() {
          _receivedData = text;
        });
        print('Dados recebidos: $text');
      },
      onError: (error) {
        print('Erro na leitura do dispositivo: $error');
      },
    );
  }

  // Envia comando para o dispositivo na característica de escrita
  Future<void> _sendCommand(String command) async {
    if (!_isConnected || _connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conecte-se a um dispositivo primeiro')),
      );
      return;
    }

    final characteristic = QualifiedCharacteristic(
      characteristicId: writeUuid,
      serviceId: serviceUuid,
      deviceId: _connectedDevice!.id,
    );

    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: command.codeUnits);
      print('Comando enviado: $command');
    } catch (e) {
      print('Erro ao enviar comando: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuração Bluetooth'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              child: Text(_isConnected
                  ? 'Conectado: ${_connectedDevice?.name ?? _connectedDevice?.id ?? ""}'
                  : _isScanning
                      ? 'Procurando dispositivos...'
                      : 'Conectar dispositivo Bluetooth'),
            ),
            SizedBox(height: 20),
            Text('Dados recebidos da leitora:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              height: 80,
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: SingleChildScrollView(child: Text(_receivedData)),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (index) {
                final command = 'P0${index + 1}';
                return ElevatedButton(
                  onPressed: () => _sendCommand(command),
                  child: Text(command),
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
