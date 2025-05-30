import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final BLEService _bleService = BLEService();
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  bool _connected = false;
  String _receivedData = '';

  @override
void initState() {
  super.initState();
  _bleService.initialize();

  _bleService.connectionState.listen((connected) {
    setState(() => _connected = connected);
  });

  _bleService.receivedData.listen((data) {
    setState(() => _receivedData = data);
  });

  _bleService.discoveredDevices.listen((devices) {
    setState(() {
      _devices = devices;
    });
  });
}


  Future<void> _scanDevices() async {
  setState(() {
    _isScanning = true;
    _devices = [];
  });

  try {
    await _bleService.scanForDevices(timeout: const Duration(seconds: 5));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao escanear: $e')));
  } finally {
    setState(() => _isScanning = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Bluetooth')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isScanning ? null : _scanDevices,
                  child: Text(_isScanning ? 'Procurando...' : 'Scanear BLE'),
                ),
                const SizedBox(width: 16),
                Text(
                  _connected ? '✅ Conectado' : '🔌 Não conectado',
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Dispositivos encontrados:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: _devices.isEmpty
                  ? Center(child: Text(_isScanning ? 'Procurando dispositivos...' : 'Nenhum dispositivo encontrado'))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          title: Text(device.name.isNotEmpty ? device.name : 'Dispositivo sem nome'),
                          subtitle: Text(device.id),
                          onTap: () => _bleService.connectToDevice(device),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            const Text('Dados recebidos da leitora:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: SingleChildScrollView(child: Text(_receivedData)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (index) {
                final command = 'P0${index + 1}';
                return ElevatedButton(
                  onPressed: () => _bleService.sendCommand(command),
                  child: Text(command),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openAppSettings(context),
              child: const Text('Abrir configurações do app'),
            ),
          ],
        ),
      ),
    );
  }
}
