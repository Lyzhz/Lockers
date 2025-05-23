import 'package:flutter/material.dart';
import 'dart:io' show Platform, exit;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/services.dart';
import 'package:lockers/pages/dados_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedIndex = 0;
  bool _isSearching = false;
  bool _isConnected = false;
  String _macAddress = '';
  final TextEditingController _patrimonioController = TextEditingController();
  String _deviceName = '';
  String _deviceId = '';
  bool _isPatrimonioLocked = false;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _tipoLocacaoSelecionado;
  String? _armazenarPessoasSelecionado;
  final TextEditingController _releEmergenciaController = TextEditingController();
  List<DiscoveredDevice> _scanResults = [];
  bool _isScanning = false;

  final List<String> _tiposLocacao = ['Armário', 'Vestiario', 'Box', 'Outro'];
  final List<String> _opcoesArmazenarPessoas = ['Sim', 'Não'];

  late SharedPreferences _prefs;
  final TextEditingController _quantidadePortasController = TextEditingController(text: '24');

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _getDeviceInfo();
    _checkBluetoothState();
    _initSharedPreferences();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _savePlateConfig(String macAddress, String quantidadePortas) async {
    await _prefs.setString('macAddress', macAddress);
    await _prefs.setString('quantidadePortas', quantidadePortas);
    print('Configuração da placa salva: MAC=$macAddress, Portas=$quantidadePortas');
  }

  Future<void> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        setState(() {
          _deviceName = androidInfo.serialNumber;
          _deviceId = androidInfo.id;
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        setState(() {
          _deviceName = iosInfo.name;
          _deviceId = iosInfo.identifierForVendor ?? 'Unknown';
        });
      } else {
        setState(() {
          _deviceName = 'Unknown Device';
          _deviceId = 'Unknown';
        });
      }
    } catch (e) {
      setState(() {
        _deviceName = 'Unknown Device';
        _deviceId = 'Unknown';
      });
    }
  }

  void _onPatrimonioSubmitted(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _isPatrimonioLocked = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _patrimonioController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
    if (_isSearching) {
      print('Iniciando busca...');
    } else {
      print('Parando busca...');
    }
  }

  void _toggleConnection() async {
    setState(() {
      _isConnected = !_isConnected;
      if (_isConnected) {
        _macAddress = '00:11:22:33:44:55';
        _savePlateConfig(_macAddress, _quantidadePortasController.text);
      } else {
        _macAddress = '';
      }
    });
  }

  void _checkBluetoothState() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetooth.status;
      if (status.isGranted) {
        print('Bluetooth está ativado');
      } else {
        print('Bluetooth está desativado ou sem permissão');
      }
    }
  }

  void _startDiscovery() async {
    setState(() {
      _scanResults = [];
      _isScanning = true;
    });

    _showDiscoveryResults();

    try {
      final subscription = _ble.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
        setState(() {
          _scanResults.add(device);
        });
      });

      await Future.delayed(Duration(seconds: 4));
      await subscription.cancel();
      setState(() => _isScanning = false);
    } catch (e) {
      print('Erro ao iniciar escaneamento: $e');
      setState(() => _isScanning = false);
    }
  }

  void _showDiscoveryResults() {
    print('Dispositivos encontrados: ${_scanResults.length}');
  }
}


  void _stopDiscovery() async {
    try {
      await FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
    } catch (e) {
      print('Erro ao parar escaneamento: $e');
    }
  }

  void _showDiscoveryResults() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Impede que o usuário feche o diálogo clicando fora
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Permite atualizar o estado do diálogo
          builder: (context, setState) {
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
                          'Procurando Dispositivos...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(47, 180, 242, 1),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            _stopDiscovery(); // Para a busca ao fechar
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    _scanResults.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromRGBO(47, 180, 242, 1),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Procurando dispositivos próximos...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _scanResults.length,
                            itemBuilder: (context, index) {
                              final result = _scanResults[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.bluetooth,
                                    color: Color.fromRGBO(47, 180, 242, 1),
                                  ),
                                  title: Text(
                                    result.device.platformName.isEmpty
                                        ? 'Dispositivo Desconhecido'
                                        : result.device.platformName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(result.device.remoteId.str),
                                  onTap: () {
                                    print(
                                      'Dispositivo selecionado: ${result.device.remoteId.str}',
                                    );
                                    _stopDiscovery(); // Para a busca ao selecionar
                                    Navigator.of(context).pop();
                                    // TODO: Implementar a lógica de conexão real aqui
                                  },
                                ),
                              );
                            },
                          ),
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

  void _onNavButtonTap(int index) {
    if (index == 0) {
      if (_isSearching) {
        _toggleSearch();
      }
    } else if (index == 3) {
      // Resetar Telas
      Restart.restartApp();
    } else if (index == 4) {
      // Fechar App
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } else if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DadosPage()));
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Image.asset(
          'assets/verticalduascores.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Imagem de fundo
        Image.asset('assets/fundo.jpg', fit: BoxFit.cover),
        // Conteúdo da tela
        Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildStatusAndConnect(), _buildMacAddress()],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildPreferenciasContainer(),
                  SizedBox(height: 20),
                  _buildLocacaoContainer(),
                  SizedBox(height: 20),
                  _buildNivelAcessoContainer(),
                  SizedBox(height: 20),
                  _buildPortasContainer(),
                  SizedBox(height: 20),
                  _buildTokenContainer(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(47, 180, 242, 1).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSearchButton(),
          _buildNavButton(Icons.storage, 2, 'Dados'),
          _buildNavButton(Icons.screen_lock_landscape, 3, 'Resetar Telas'),
          _buildNavButton(Icons.close, 4, 'Fechar App'),
        ],
      ),
    ),
  );

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _toggleSearch,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              _isSearching ? Colors.red : const Color.fromRGBO(47, 180, 242, 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSearching ? Icons.stop : Icons.search,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Text(
                _isSearching ? 'Parar Busca' : 'Buscar',
                key: ValueKey<bool>(_isSearching),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, int index, String label) {
    return GestureDetector(
      onTap: () => _onNavButtonTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndConnect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Status: ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _isConnected
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Conectado' : 'Desconectado',
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isScanning ? _stopDiscovery : _startDiscovery,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isScanning
                    ? Colors.orange
                    : const Color.fromRGBO(47, 180, 242, 1),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 3,
          ),
          icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth),
          label: Text(
            _isScanning ? 'Parar Escaneamento' : 'Procurar Dispositivos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMacAddress() {
    if (!_isConnected) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          Text(
            'MAC da Controladora: ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _macAddress,
            style: TextStyle(
              fontSize: 24,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenciasContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tablet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildInfoRow('Nome:', _deviceName),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Patrimônio:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Expanded(
                child:
                    _isPatrimonioLocked
                        ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _patrimonioController.text,
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                        : TextField(
                          controller: _patrimonioController,
                          decoration: InputDecoration(
                            hintText: 'Digite o patrimônio',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                          ),
                          style: TextStyle(fontSize: 18),
                          onSubmitted: _onPatrimonioSubmitted,
                        ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildInfoRow('Device ID:', _deviceId),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Quantidade de Portas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantidadePortasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Portas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        Text(value, style: TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildNivelAcessoContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nível Acesso:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Id Nível de Acesso:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome Nível de Acesso:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortasContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portas:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Site:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Porta:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Token:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocacaoContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Tipo de Locação
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Locação:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _tipoLocacaoSelecionado,
                  items:
                      _tiposLocacao
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoLocacaoSelecionado = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  hint: Text('add items..'),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Ativar o Armazenar Pessoas?
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ativar o Armazenar Pessoas?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _armazenarPessoasSelecionado,
                  items:
                      _opcoesArmazenarPessoas
                          .map(
                            (opcao) => DropdownMenuItem(
                              value: opcao,
                              child: Text(opcao),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _armazenarPessoasSelecionado = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  hint: Text('add items..'),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Relé de emergência
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relé de emergência',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                TextField(
                  controller: _releEmergenciaController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}