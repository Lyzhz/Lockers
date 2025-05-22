import 'package:flutter/material.dart';
import 'dart:io' show Platform, exit;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/services.dart';
import 'package:lockers/pages/dados_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TextEditingController _quantidadePortasController = TextEditingController();
  bool _isConnected = false;
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  String _macAddress = '';
  List<bool> _releStates = List.generate(8, (index) => false);
  BluetoothCharacteristic? _writeCharacteristic;

  @override
  void initState() {
    super.initState();
    _loadPlateConfig();
    _checkBluetooth();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      print('Verificando status da conexão...');
      if (_macAddress.isNotEmpty) {
        print('MAC encontrado: $_macAddress');
        // Inicia o escaneamento
        await FlutterBluePlus.startScan(
          timeout: Duration(seconds: 5),
          androidUsesFineLocation: true,
        );
        print('Escaneamento iniciado');

        // Aguarda os resultados do escaneamento
        BluetoothDevice? device;
        await for (final results in FlutterBluePlus.scanResults) {
          for (final result in results) {
            print('Dispositivo encontrado: ${result.device.platformName} (${result.device.remoteId.str})');
            if (result.device.remoteId.str == _macAddress) {
              device = result.device;
              print('Dispositivo correspondente encontrado');
              break;
            }
          }
          if (device != null) break;
        }

        // Para o escaneamento
        await FlutterBluePlus.stopScan();
        print('Escaneamento parado');

        if (device != null) {
          print('Verificando estado da conexão...');
          // Verifica o estado da conexão
          final state = await device.connectionState.first;
          print('Estado da conexão: $state');
          
          setState(() {
            _isConnected = state == BluetoothConnectionState.connected;
            if (_isConnected) {
              _connectedDevice = device;
              print('Dispositivo conectado');
            } else {
              _connectedDevice = null;
              _macAddress = '';
              _writeCharacteristic = null;
              print('Dispositivo desconectado');
            }
          });

          // Se estiver desconectado, tenta reconectar
          if (!_isConnected) {
            print('Tentando reconectar...');
            try {
              await device.connect(
                timeout: Duration(seconds: 10),
                autoConnect: false,
              );
              print('Reconexão bem-sucedida');
              setState(() {
                _isConnected = true;
                _connectedDevice = device;
              });
            } catch (e) {
              print('Erro ao reconectar: $e');
              setState(() {
                _isConnected = false;
                _connectedDevice = null;
                _macAddress = '';
                _writeCharacteristic = null;
              });
            }
          }
        } else {
          print('Dispositivo não encontrado');
          // Dispositivo não encontrado
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _macAddress = '';
            _writeCharacteristic = null;
          });
        }
      } else {
        print('Nenhum MAC encontrado');
      }
    } catch (e) {
      print('Erro ao verificar status da conexão: $e');
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _macAddress = '';
        _writeCharacteristic = null;
      });
    }
  }

  Future<void> _checkBluetooth() async {
    try {
      // Solicita permissões necessárias
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        print('Permissões necessárias não foram concedidas');
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _macAddress = '';
          _writeCharacteristic = null;
        });
        return;
      }

      // Verifica se o Bluetooth está disponível
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (isAvailable == false) {
        print('Bluetooth não está disponível neste dispositivo');
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _macAddress = '';
          _writeCharacteristic = null;
        });
        return;
      }

      // Verifica se o Bluetooth está ativado
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.on) {
        print('Bluetooth está ativado');
        // Verifica o status da conexão após ativar o Bluetooth
        _checkConnectionStatus();
      } else {
        print('Bluetooth está desativado');
        setState(() {
          _isConnected = false;
          _connectedDevice = null;
          _macAddress = '';
          _writeCharacteristic = null;
        });
        // Solicita ao usuário para ativar o Bluetooth
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print('Erro ao verificar Bluetooth: $e');
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _macAddress = '';
        _writeCharacteristic = null;
      });
    }
  }

  Future<void> _loadPlateConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final macAddress = prefs.getString('mac_address') ?? '';
      final quantidadePortas = prefs.getString('quantidade_portas') ?? '';
      final isConnected = prefs.getBool('is_connected') ?? false;

      setState(() {
        _macAddress = macAddress;
        _quantidadePortasController.text = quantidadePortas;
        _isConnected = isConnected;
      });

      // Se houver um MAC salvo, verifica o status da conexão
      if (macAddress.isNotEmpty) {
        _checkConnectionStatus();
      }
    } catch (e) {
      print('Erro ao carregar configurações: $e');
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _macAddress = '';
        _writeCharacteristic = null;
      });
    }
  }

  Future<void> _savePlateConfig(String macAddress, String quantidadePortas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mac_address', macAddress);
      await prefs.setString('quantidade_portas', quantidadePortas);
      await prefs.setBool('is_connected', _isConnected);
    } catch (e) {
      print('Erro ao salvar configurações: $e');
    }
  }

  void _showPairedDevices() {
    // Inicia o escaneamento
    FlutterBluePlus.startScan(
      timeout: Duration(seconds: 10),
      androidUsesFineLocation: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(maxHeight: 400, minWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dispositivos Bluetooth',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(47, 180, 242, 1),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            FlutterBluePlus.stopScan();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    StreamBuilder<List<ScanResult>>(
                      stream: FlutterBluePlus.scanResults,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(47, 180, 242, 1),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar dispositivos',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final devices = snapshot.data?.map((result) => result.device).toList() ?? [];
                        
                        if (devices.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum dispositivo encontrado.\nCertifique-se que o Bluetooth está ativado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.bluetooth_connected,
                                    color: Color.fromRGBO(47, 180, 242, 1),
                                  ),
                                  title: Text(
                                    device.platformName.isEmpty
                                        ? 'Dispositivo Desconhecido'
                                        : device.platformName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(device.remoteId.str),
                                  onTap: () async {
                                    try {
                                      await _connectToDevice(device);
                                    } catch (e) {
                                      // Mostra mensagem de erro
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao conectar: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      print('Iniciando conexão com dispositivo: ${device.platformName} (${device.remoteId.str})');
      
      // Mostra indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(47, 180, 242, 1),
                  ),
                ),
                SizedBox(width: 20),
                Text('Conectando...'),
              ],
            ),
          );
        },
      );

      // Para o escaneamento antes de conectar
      await FlutterBluePlus.stopScan();
      print('Escaneamento parado');

      // Tenta conectar ao dispositivo
      print('Tentando conectar...');
      await device.connect(
        timeout: Duration(seconds: 10),
        autoConnect: false,
      );
      print('Conexão estabelecida');
      
      // Fecha o diálogo de carregamento
      Navigator.of(context).pop();

      // Verifica se a conexão foi estabelecida
      final state = await device.connectionState.first;
      print('Estado da conexão: $state');
      
      if (state == BluetoothConnectionState.connected) {
        print('Dispositivo conectado, descobrindo serviços...');
        // Descobre os serviços
        List<BluetoothService> services = await device.discoverServices();
        print('Serviços descobertos: ${services.length}');
        
        // Procura o serviço e característica corretos
        for (var service in services) {
          print('Verificando serviço: ${service.uuid}');
          for (var characteristic in service.characteristics) {
            print('Verificando característica: ${characteristic.uuid}');
            if (characteristic.properties.write) {
              _writeCharacteristic = characteristic;
              print('Característica de escrita encontrada: ${characteristic.uuid}');
              break;
            }
          }
          if (_writeCharacteristic != null) break;
        }

        if (_writeCharacteristic == null) {
          throw Exception('Característica de escrita não encontrada');
        }

        // Salva o dispositivo conectado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('connected_device', device.remoteId.str);
        await prefs.setString('device_name', device.platformName);
        await prefs.setBool('is_connected', true);
        print('Configurações salvas');

        // Atualiza o estado
        setState(() {
          _connectedDevice = device;
          _isConnected = true;
          _macAddress = device.remoteId.str;
        });
        print('Estado atualizado');

        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Configura reconexão automática
        device.connectionState.listen((BluetoothConnectionState state) async {
          print('Estado da conexão alterado: $state');
          if (state == BluetoothConnectionState.disconnected) {
            print('Dispositivo desconectado, tentando reconectar...');
            try {
              await device.connect(
                timeout: Duration(seconds: 10),
                autoConnect: false,
              );
              print('Reconexão bem-sucedida');
            } catch (e) {
              print('Erro ao reconectar: $e');
              setState(() {
                _isConnected = false;
                _macAddress = '';
                _writeCharacteristic = null;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_connected', false);
            }
          }
        });
      } else {
        throw Exception('Falha ao conectar');
      }
    } catch (e) {
      print('Erro durante a conexão: $e');
      // Fecha o diálogo de carregamento se estiver aberto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Mostra mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao conectar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Limpa o estado
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _macAddress = '';
        _writeCharacteristic = null;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_connected', false);
    }
  }

  Future<void> _toggleRele(int index) async {
    if (_writeCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispositivo não está conectado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Atualiza o estado do relé
      setState(() {
        _releStates[index] = !_releStates[index];
      });

      // Prepara o comando para a placa
      // Formato: 'p' + número do relé (01-08)
      String command = 'p${(index + 1).toString().padLeft(2, '0')}';
      
      // Envia o comando para a placa
      await _writeCharacteristic!.write(command.codeUnits);

      // Mostra feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relé ${index + 1} ${_releStates[index] ? 'ativado' : 'desativado'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Reverte o estado em caso de erro
      setState(() {
        _releStates[index] = !_releStates[index];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao controlar relé: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReleButton(int index) {
    return ElevatedButton(
      onPressed: _isConnected ? () => _toggleRele(index) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _releStates[index] ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Relé ${index + 1}\n${_releStates[index] ? 'ON' : 'OFF'}',
        textAlign: TextAlign.center,
      ),
    );
  }

  void _stopDiscovery() {
    try {
      FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      print('Erro ao parar escaneamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: Color.fromRGBO(47, 180, 242, 1),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações da Placa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(47, 180, 242, 1),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quantidadePortasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantidade de Portas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.door_front_door),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isConnected ? null : _showPairedDevices,
                      icon: Icon(Icons.bluetooth),
                      label: Text(_isConnected ? 'Conectado' : 'Conectar Dispositivo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConnected ? Colors.green : Color.fromRGBO(47, 180, 242, 1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_isConnected) ...[
                      SizedBox(height: 8),
                      Text(
                        'Dispositivo: ${_connectedDevice?.platformName ?? 'Desconhecido'}',
                        style: TextStyle(color: Colors.green),
                      ),
                      Text(
                        'MAC: $_macAddress',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Controle de Relés',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(47, 180, 242, 1),
                        ),
                      ),
                      SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) => _buildReleButton(index),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DadosPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(47, 180, 242, 1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Ir para Dados'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantidadePortasController.dispose();
    super.dispose();
  }
}
