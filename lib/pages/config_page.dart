// INFO: Importações necessárias para o funcionamento da página de configuração.
// INFO: Contém widgets básicos, utilitários de plataforma, gerenciamento de estado de Bluetooth, navegação e preferências compartilhadas.
import 'package:flutter/material.dart';
import 'dart:io' show Platform, exit; // INFO: Utilitário para verificar a plataforma (Android/iOS)
import 'package:device_info_plus/device_info_plus.dart'; // INFO: Plugin para obter informações do dispositivo
import 'package:restart_app/restart_app.dart'; // INFO: Plugin para reiniciar o aplicativo
import 'package:flutter/services.dart'; // INFO: Para interações de baixo nível com a plataforma (usado para fechar o app)
import 'package:lockers/pages/dados_page.dart'; // INFO: Importação da página de visualização de dados
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // INFO: Plugin principal para comunicação Bluetooth Low Energy (BLE)
import 'package:shared_preferences/shared_preferences.dart'; // INFO: Plugin para armazenar dados simples localmente
import 'dart:async'; // INFO: Necessário para gerenciar Streams e Subscriptions
import 'dart:convert'; // INFO: Necessário para decodificar bytes recebidos via Bluetooth para String (UTF-8)
import 'package:flutter/services.dart'; // INFO: Importação para Settings
import 'package:http/http.dart' as http; // INFO: Importação do pacote http para fazer requisições web.

// INFO: Widget Statefull para a página de configuração, permitindo alteração de estado.
class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

// INFO: Estado associado a ConfigPage. Contém a lógica e variáveis para a UI.
// INFO: SingleTickerProviderStateMixin é usado para animações (neste caso, o AnimationController).
class _ConfigPageState extends State<ConfigPage>
    with SingleTickerProviderStateMixin {
  // INFO: Controlador para animações, sincronizado com o vsync (necessita de SingleTickerProviderStateMixin).
  late AnimationController _controller;

  // INFO: Variáveis de estado para controlar a UI e a lógica da página.
  int _selectedIndex = 0; // INFO: Índice do item selecionado na barra de navegação (se aplicável)
  bool _isSearching = false; // INFO: Indica se a busca por dispositivos está ativa
  bool _isConnected = false; // INFO: Estado da conexão Bluetooth (conectado ou não)
  String _macAddress = ''; // INFO: Endereço MAC do dispositivo Bluetooth conectado
  final TextEditingController _patrimonioController = TextEditingController(); // INFO: Controlador para o campo de texto de Patrimônio
  String _deviceName = ''; // INFO: Nome do dispositivo atual (tablet/celular)
  String _deviceId = ''; // INFO: ID do dispositivo atual (tablet/celular)
  bool _isPatrimonioLocked = false; // INFO: Indica se o campo Patrimônio está bloqueado após submissão
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin(); // INFO: Instância do plugin para obter info do dispositivo

  // INFO: Variáveis para gerenciar as preferências de configuração.
  String? _tipoLocacaoSelecionado; // INFO: Valor selecionado para o tipo de locação
  String? _armazenarPessoasSelecionado; // INFO: Valor selecionado para a opção Armazenar Pessoas
  final TextEditingController _releEmergenciaController =
      TextEditingController(); // INFO: Controlador para o campo de texto Relé de emergência

  // INFO: Variáveis para o escaneamento e conexão Bluetooth.
  List<ScanResult> _scanResults = []; // INFO: Lista de dispositivos BLE encontrados durante o escaneamento
  bool _isScanning = false; // INFO: Indica se o escaneamento BLE está ativo

  // INFO: Variáveis para gerenciar a conexão Bluetooth
  BluetoothDevice? _connectedDevice; // INFO: Referência ao dispositivo BLE conectado
  List<StreamSubscription> _valueSubscriptions = []; // INFO: Lista de assinaturas para ouvir dados das características BLE
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription; // INFO: Assinatura para monitorar o estado da conexão BLE

  // INFO: Listas de opções para DropdownButtonFormField.
  final List<String> _tiposLocacao = ['Armário', 'Vestiario', 'Box', 'Outro'];
  final List<String> _opcoesArmazenarPessoas = ['Sim', 'Não'];

  // INFO: Variáveis para SharedPreferences.
  late SharedPreferences _prefs; // INFO: Instância para acessar as preferências compartilhadas
  final TextEditingController _quantidadePortasController =
      TextEditingController(text: '24'); // INFO: Controlador para Quantidade de Portas, com valor inicial

  // INFO: Variáveis para armazenar os dados retornados pelo serviço web
  String _tabletName = '';
  String _accessLevelId = '';
  String _accessLevelName = '';
  String _site = '';
  String _doorId = '';
  String _token = '';
  String _wsAccessLevel = '';
  String _wsSystemEvent = '';
  String _wsLocation = '';
  String _wsLogSystem = '';
  String _wsRecoveryData = '';
  String _wsStatusPorta = '';
  String _patrimonyTablet = ''; // Added this line
  String _totalDoors = '';
  String _idDevice = '';
  bool _isValidating = false;

  bool _autoSave = false;

  // INFO: Método chamado na inicialização do widget.
  @override
  void initState() {
    super.initState();
    // INFO: Inicializa o controlador de animação.
    _controller = AnimationController(
      duration: Duration(milliseconds: 300), // NOTE: Ajustar duração da animação se necessário.
      vsync: this, // INFO: Sincroniza a animação com a taxa de atualização da tela.
    );
    _getDeviceInfo(); // INFO: Obtém informações do dispositivo atual.
    _checkBluetoothState(); // INFO: Verifica o estado atual do Bluetooth.
    _initSharedPreferences(); // INFO: Inicializa as preferências compartilhadas.
    _loadData();
  }

  // INFO: Método assíncrono para inicializar SharedPreferences.
  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // NOTE: Considerar carregar configurações salvas aqui ao iniciar o app.
  }

  // INFO: Método assíncrono para salvar a configuração da placa (MAC e quantidade de portas) localmente.
  void _savePlateConfig(String macAddress, String quantidadePortas) async {
    await _prefs.setString('macAddress', macAddress);
    await _prefs.setString('quantidadePortas', quantidadePortas);
    print(
      'Configuração da placa salva: MAC=$macAddress, Portas=$quantidadePortas',
    ); // INFO: Log para confirmar o salvamento.
    // NOTE: Adicionar feedback visual para o usuário sobre o salvamento bem-sucedido.
  }

  // INFO: Método assíncrono para obter informações do dispositivo (serial, ID).
  Future<void> _getDeviceInfo() async {
    try {
      // INFO: Verifica a plataforma e obtém as informações específicas.
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        String serialNumber = 'Unknown';
        String androidId = 'Unknown';
        
        try {
          // Tenta obter o número de série através do MethodChannel
          const platform = MethodChannel('com.example.lockers/device_info');
          serialNumber = await platform.invokeMethod('getSerialNumber') ?? 'Unknown';
          androidId = await platform.invokeMethod('getAndroidId') ?? 'Unknown';
          
          print('Número de série obtido: $serialNumber'); // Debug
          print('ANDROID_ID obtido: $androidId'); // Debug
          
          // Se o número de série for o ANDROID_ID, tenta usar o serialNumber do device_info_plus
          if (serialNumber.length == 16 && RegExp(r'^[0-9a-f]{16}$').hasMatch(serialNumber)) {
            if (androidInfo.serialNumber.isNotEmpty && androidInfo.serialNumber != 'unknown') {
              serialNumber = androidInfo.serialNumber;
              print('Usando serialNumber do device_info_plus: $serialNumber'); // Debug
            }
          }
        } catch (e) {
          print('Erro ao obter informações do dispositivo: $e');
        }

        setState(() {
          _deviceName = 'S/N: $serialNumber';
          _deviceId = androidId;
        });
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        setState(() {
          _deviceName = 'S/N: ${iosInfo.identifierForVendor ?? 'Unknown'}';
          _deviceId = iosInfo.identifierForVendor ?? 'Unknown';
        });
      } else {
        setState(() {
          _deviceName = 'S/N: Unknown';
          _deviceId = 'Unknown';
        });
      }
    } catch (e) {
      setState(() {
        _deviceName = 'S/N: Unknown';
        _deviceId = 'Unknown';
      });
      print('Erro ao obter informações do dispositivo: $e');
    }
  }

  // INFO: Método chamado ao submeter o texto no campo Patrimônio.
  void _onPatrimonioSubmitted(String value) {
    if (value.isNotEmpty) {
      setState(() {
        _isPatrimonioLocked = true; // INFO: Bloqueia o campo após a submissão.
      });
       // NOTE: Implementar lógica de salvamento ou validação do patrimônio aqui.
    }
  }

  // INFO: Libera recursos quando o widget é descartado.
  // NOTE: Importante para cancelar assinaturas de streams e desconectar do dispositivo BLE.
  @override
  void dispose() {
    _controller.dispose();
    _patrimonioController.dispose();
    // Cancelar todas as assinaturas e desconectar ao descartar o widget
    _valueSubscriptions.forEach((sub) => sub.cancel());
    _connectionStateSubscription?.cancel(); // Cancelar a assinatura do estado da conexão
    _connectedDevice?.disconnect(); // Tentar desconectar se ainda estiver conectado
    super.dispose();
  }

  // INFO: Valida os dados do dispositivo.
  Future<void> _validateData() async {
    try {
      setState(() {
        _isValidating = true;
      });

      // INFO: Prepara os dados locais para envio.
      final Map<String, dynamic> localData = {
        'patrimonyTablet': _patrimonyTablet,
        'totalDoors': _totalDoors,
        'idDevice': _idDevice,
      };

      // INFO: Faz a requisição HTTP POST para o serviço web.
      final response = await http.post(
        Uri.parse('http://10.16.16.40:2344/api/lockerId/ValidaDados'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(localData),
      );

      // INFO: Verifica se a requisição foi bem sucedida.
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // INFO: Verifica se a resposta indica sucesso.
        if (data['sucesses'] == true) {
          // INFO: Atualiza os campos da UI com os dados recebidos.
          setState(() {
            _patrimonyTablet = data['patrimonyTablet'] ?? '';
            _totalDoors = data['totalDoors'] ?? '';
            _idDevice = data['idDevice'] ?? '';
            _tabletName = data['nameTablet'] ?? '';
            _accessLevelId = data['idAccessLevel'] ?? '';
            _accessLevelName = data['nameAccessLevel'] ?? '';
            _site = data['site'] ?? '';
            _doorId = data['idDoor'] ?? '';
            _token = data['token'] ?? '';
            _wsAccessLevel = data['wsNivelAcesso'] ?? '';
            _wsSystemEvent = data['wsEventosSistema'] ?? '';
            _wsLocation = data['wsLocacao'] ?? '';
            _wsLogSystem = data['wsLogSistema'] ?? '';
            _wsRecoveryData = data['wsArmazenaPessoas'] ?? '';
            _wsStatusPorta = data['wsStatusPorta'] ?? '';
          });

          // INFO: Exibe mensagem de sucesso.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dados validados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // INFO: Exibe mensagem de erro caso a validação falhe.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['messagem'] ?? 'Erro ao validar dados'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // INFO: Exibe mensagem de erro caso a requisição falhe.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar com o servidor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // INFO: Exibe mensagem de erro caso ocorra uma exceção.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  // INFO: Método para alternar o estado de busca (ligar/desligar).
  void _toggleSearch() {
    if (!_isSearching) {
      _validateData();
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // INFO: Processa a resposta JSON recebida do serviço web.
  // NOTE: Implementa a lógica do bloco Kodular 'wsValidaDados.GotText'.
  // Este método não será mais chamado diretamente pela _validateData após a integração HTTP.
  // A lógica equivalente foi movida para dentro do try/catch da _validateData.
  // Se esta função for usada em outro lugar (ex: dados recebidos via BLE), ela pode precisar ser adaptada.
  void _processWebServiceResponse(String jsonResponse) {
    print('Chamada para _processWebServiceResponse com: $jsonResponse'); // INFO: Log para saber se esta função ainda é chamada.
    try {
      // INFO: Decodifica a string JSON para um mapa (dicionário).
      final decodedJson = jsonDecode(jsonResponse) as Map<String, dynamic>;

      // INFO: Verifica se a chave 'sucesses' existe e é 'true'.
      // NOTE: A verificação '== "true"' é baseada no bloco Kodular.
      // TODO: Verificar se a chave na API real é 'success' (booleano) ou 'sucesses' (string "true"/"false").
      // A lógica em _validateData já assume 'success' booleano.
      if (decodedJson.containsKey('sucesses') && decodedJson['sucesses'] == 'true') { // Assumindo 'sucesses' string para compatibilidade com o bloco original
        print('Serviço web respondeu com sucesso (processador antigo).'); // INFO: Log de sucesso.

        // INFO: Extrai e define os valores nos controladores e estado, verificando se as chaves existem.
        setState(() {
          // INFO: Atualiza os TextFields e variáveis de estado com os dados do JSON.
          _patrimonioController.text = decodedJson['patrimonyTablet'] ?? ''; // NOTE: Usando ?? '' para default se a chave não existir.
          // TODO: Lógica para txtNomeTablet (ex: String _nomeTablet; _nomeTablet = decodedJson['nameTablet'] ?? '';). // NOTE: Adicionar variável de estado para nameTablet se precisar exibi-lo.
          // TODO: Lógica para txtQdePortas (ex: _quantidadePortasController.text = decodedJson['totalDoors'] ?? '24';). // NOTE: Atualizar o controlador existente para Quantidade de Portas.
          // TODO: Lógica para txtNivelAcesso e txtNomeNivelAcesso. // NOTE: Adicionar controladores/variáveis de estado para Nível de Acesso.
          // TODO: Lógica para txtIdSite e txtIDPorta. // NOTE: Adicionar controladores/variáveis de estado para ID Site e ID Porta.
          // TODO: Lógica para txtNomeToken. // NOTE: Adicionar controlador/variável de estado para Token.
          // TODO: Lógica para txtWsNivelAcesso, txtWsEventosSistema, txtWsLocacao, txtWsLogSistema, txtWsArmazenaPessoas, txtIdDevice. // NOTE: Adicionar controladores/variáveis de estado para os campos restantes.
           _deviceId = decodedJson['idDevice'] ?? _deviceId; // INFO: Atualiza o deviceId com o do JSON se disponível.

          _isPatrimonioLocked = true; // INFO: Mantém o campo Patrimônio bloqueado após obter os dados.
        });
         // NOTE: Considerar adicionar feedback visual (ex: SnackBar) indicando que os dados foram carregados com sucesso.

      } else {
        // INFO: Caso 'sucesses' não seja 'true' ou não exista.
        print('Falha ao recuperar dados do serviço web (processador antigo).'); // INFO: Log de falha.
        // TODO: Lógica equivalente a "call Notificador1 Show Alert notice "Falha ao recuperar Dados"".
        // NOTE: Exibir uma mensagem de erro para o usuário, como um SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao recuperar Dados (processador antigo)'), // NOTE: Mensagem para o usuário.
            backgroundColor: Colors.red, // NOTE: Cor de fundo vermelha para erro.
          ), // INFO: Exibe um SnackBar de erro.
        ); // INFO: Exibe um SnackBar de erro.
      }

    } catch (e) {
      // INFO: Tratamento de erros durante a decodificação JSON ou processamento.
      print('Erro ao processar resposta do serviço web (processador antigo): $e'); // NOTE: Logar o erro.
      // TODO: Exibir um alerta de erro mais detalhado se possível. // NOTE: Mensagem de erro para o usuário.
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Erro ao processar dados (processador antigo): ${e.toString()}'), // INFO: Mensagem de erro para o usuário.
           backgroundColor: Colors.red, // NOTE: Cor de fundo vermelha para erro.
         ),
       ); // INFO: Exibe um SnackBar de erro com detalhes técnicos.
    }
  }

  // INFO: Método assíncrono para verificar o estado atual do Bluetooth no dispositivo.
  void _checkBluetoothState() async {
    // INFO: Verifica se a plataforma é Android, pois a API FlutterBluePlus pode variar ou ter permissões diferentes.
    if (Platform.isAndroid) {
      try {
        // INFO: Obtém o estado atual do adaptador Bluetooth.
        if (await FlutterBluePlus.adapterState.first ==
            BluetoothAdapterState.on) {
          print('Bluetooth está ativado'); // INFO: Log se Bluetooth estiver ligado.
        } else {
          print('Bluetooth está desativado'); // INFO: Log se Bluetooth estiver desligado.
          // TODO: Notificar o usuário para ligar o Bluetooth. // NOTE: Adicionar UI para solicitar que o usuário ligue o Bluetooth.
        }
      } catch (e) {
        print('Erro ao verificar estado do Bluetooth: $e'); // NOTE: Logar erro se não conseguir verificar o estado do Bluetooth.
         // TODO: Mostrar mensagem de erro para o usuário. // NOTE: Adicionar UI para informar ao usuário sobre o erro na verificação do Bluetooth.
      }
    }
     // TODO: Adicionar suporte para iOS e outras plataformas, se necessário. // NOTE: Implementar a lógica de verificação de estado do Bluetooth para iOS e outras plataformas suportadas pelo plugin.
  }

  // INFO: Método assíncrono para iniciar o escaneamento por dispositivos Bluetooth Low Energy (BLE).
  void _startDiscovery() async {
    setState(() {
      _scanResults = []; // INFO: Limpa os resultados de escaneamentos anteriores.
      _isScanning = true; // INFO: Atualiza o estado para indicar que o escaneamento está ativo.
    });

    // INFO: Mostra o diálogo de resultados de escaneamento imediatamente.
    _showDiscoveryResults();

    try {
      // INFO: Inicia o processo de escaneamento. O scanResults é um Stream que emite listas de resultados.
      // INFO: startScan gerencia o tempo limite automaticamente quando um duration é fornecido.
      FlutterBluePlus.startScan(timeout: Duration(seconds: 15)); // NOTE: Ajustar o tempo limite do escaneamento conforme a necessidade do aplicativo.

      // INFO: Ouve o stream de resultados do escaneamento. Esta callback é chamada sempre que novos resultados são encontrados/atualizados.
      // INFO: scanResults é um broadcast stream, pode ter múltiplos ouvintes.
       FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          // INFO: Atualiza a lista de resultados, filtrando dispositivos sem nome ou endereço.
          _scanResults = results
              .where((result) =>
                  result.device.platformName.isNotEmpty ||
                  result.device.remoteId.str.isNotEmpty) // NOTE: O filtro pode ser ajustado para incluir outros critérios (ex: nome específico, UUID de serviço).
              .toList();
        });
      });

      // INFO: Não é necessário parar explicitamente o escaneamento aqui se um timeout foi definido em startScan.
    } catch (e) {
      print('Erro ao iniciar escaneamento: $e'); // NOTE: Logar o erro ao iniciar o escaneamento.
      setState(() {
        _isScanning = false; // INFO: Parar indicador de escaneamento em caso de erro.
      });
       // TODO: Mostrar mensagem de erro para o usuário. // NOTE: Adicionar UI para informar ao usuário que o escaneamento falhou.
    }
  }

  // INFO: Método assíncrono para parar o escaneamento por dispositivos BLE.
  void _stopDiscovery() async {
    try {
      await FlutterBluePlus.stopScan(); // INFO: Envia o comando para parar o escaneamento.
      setState(() {
        _isScanning = false; // INFO: Atualiza o estado para indicar que o escaneamento não está ativo.
      });
       // NOTE: Pode ser útil adicionar um feedback visual para o usuário quando o escaneamento parar.
    } catch (e) {
      print('Erro ao parar escaneamento: $e'); // NOTE: Logar o erro ao parar o escaneamento.
       // TODO: Mostrar mensagem de erro para o usuário. // NOTE: Adicionar UI para informar ao usuário sobre o erro ao parar o escaneamento.
    }
  }

  // INFO: Método para exibir um diálogo com os resultados do escaneamento BLE.
  void _showDiscoveryResults() {
    showDialog(
      context: context, // INFO: Contexto da árvore de widgets.
      barrierDismissible: false, // INFO: Impede que o diálogo seja fechado clicando fora dele.
      builder: (BuildContext context) {
        // INFO: StatefulBuilder permite atualizar o estado local do diálogo.
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white.withOpacity(0.95), // NOTE: Ajustar opacidade ou cor de fundo se necessário.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // NOTE: Ajustar raio da borda se necessário.
              ),
              child: Container(
                padding: EdgeInsets.all(20), // NOTE: Ajustar preenchimento se necessário.
                constraints: BoxConstraints(maxHeight: 400, minWidth: 300), // NOTE: Definir restrições de tamanho do diálogo.
                child: Column(
                  mainAxisSize: MainAxisSize.min, // INFO: A coluna ocupa o mínimo de espaço vertical necessário.
                  crossAxisAlignment: CrossAxisAlignment.stretch, // INFO: Os filhos da coluna se expandem horizontalmente.
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // INFO: Espaça os elementos horizontalmente.
                      children: [
                        Text(
                          _isScanning ? 'Procurando Dispositivos...' : 'Dispositivos Encontrados:', // INFO: Altera o texto dependendo do estado de escaneamento.
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(47, 180, 242, 1), // NOTE: Cor tema da aplicação.
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red), // INFO: Ícone para fechar o diálogo.
                          onPressed: () {
                            _stopDiscovery(); // INFO: Para o escaneamento ao fechar o diálogo.
                            Navigator.of(context).pop(); // INFO: Fecha o diálogo.
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10), // INFO: Espaço vertical.
                    Divider(), // INFO: Linha divisória.
                    // INFO: Exibição condicional do conteúdo principal do diálogo.
                    _scanResults.isEmpty && _isScanning
                        ? Padding(
                            padding: const EdgeInsets.all(16.0), // NOTE: Ajustar preenchimento.
                            child: Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(47, 180, 242, 1), // NOTE: Cor do indicador de progresso.
                                    ),
                                  ), // INFO: Indicador de carregamento enquanto busca.
                                  SizedBox(height: 16), // INFO: Espaço vertical.
                                  Text(
                                    'Procurando dispositivos próximos...', // INFO: Texto durante o escaneamento.
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ), // NOTE: Mensagem para o usuário.
                                ],
                              ),
                            ),
                          )
                        : _scanResults.isEmpty && !_isScanning
                            ? Padding(
                                padding: const EdgeInsets.all(16.0), // NOTE: Ajustar preenchimento.
                                child: Center(
                                  child: Text(
                                    'Nenhum dispositivo encontrado.', // INFO: Mensagem se nenhum dispositivo for encontrado.
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ), // NOTE: Mensagem para o usuário.
                                ),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true, // INFO: ListView ocupa o mínimo de espaço necessário.
                                  itemCount: _scanResults.length, // INFO: Número de itens na lista é o número de resultados.
                                  itemBuilder: (context, index) {
                                    final result = _scanResults[index]; // INFO: Obtém o resultado de escaneamento atual.
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12), // NOTE: Ajustar raio da borda do Card.
                                      ),
                                      elevation: 2, // NOTE: Ajustar elevação do Card.
                                      margin: EdgeInsets.symmetric(vertical: 6), // NOTE: Ajustar margem vertical do Card.
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.bluetooth, // Ou outro ícone para BLE // NOTE: Escolher um ícone apropriado para dispositivos BLE.
                                          color: Color.fromRGBO(47, 180, 242, 1), // NOTE: Cor do ícone.
                                        ),
                                        title: Text(
                                          // INFO: Exibe o nome do dispositivo, ou 'Dispositivo Desconhecido' se o nome estiver vazio.
                                          result.device.platformName.isEmpty
                                              ? 'Dispositivo Desconhecido'
                                              : result.device.platformName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, // NOTE: Estilo do texto.
                                          ),
                                        ),
                                        subtitle: Text(result.device.remoteId.str), // INFO: Exibe o endereço MAC/ID do dispositivo.
                                        onTap: () {
                                          print(
                                            'Dispositivo selecionado: ${result.device.remoteId.str}',
                                          ); // INFO: Log da seleção do dispositivo.
                                          Navigator.of(context).pop(); // INFO: Fecha o diálogo de resultados.
                                          _connectToDevice(result.device); // INFO: Chama a função para tentar conectar ao dispositivo selecionado.
                                        },
                                      ), // INFO: ListTile representa um dispositivo encontrado.
                                    ); // INFO: Card envolvendo o ListTile para melhor visual.
                                  },
                                ), // INFO: Constrói a lista de dispositivos encontrados.
                              ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ); // INFO: Exibe o diálogo.
  }

  // INFO: Método chamado ao tocar em um botão na barra de navegação inferior.
  void _onNavButtonTap(int index) {
    // INFO: Lida com as ações baseadas no índice do botão tocado.
    if (index == 0) {
      // INFO: Se o botão de busca for tocado e a busca estiver ativa, para a busca.
      if (_isSearching) {
        _toggleSearch(); // INFO: Chama o método para alternar o estado de busca.
      }
       // NOTE: Se a busca não estiver ativa (e o botão busca/parar busca for tocado), a lógica já está no _buildSearchButton.
    } else if (index == 2) {
       // INFO: Lida com o botão 'Dados'.
       // INFO: Navega para a tela de Dados apenas se houver uma conexão Bluetooth ativa.
       if (_isConnected) {
         print('Navegando para Dados Page...'); // INFO: Log de navegação.
         Navigator.of(context).push(MaterialPageRoute(builder: (_) => DadosPage()));
       } else {
         // INFO: Se não estiver conectado, exibe uma mensagem ao usuário.
         print('Tentativa de navegar para Dados Page sem conexão.'); // INFO: Log de tentativa sem conexão.
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Por favor, conecte a uma controladora primeiro.'), // NOTE: Mensagem para o usuário.
             backgroundColor: Colors.orange, // NOTE: Cor do SnackBar.
           ), // INFO: Exibe um SnackBar informando que a conexão é necessária.
         );
       }
    }
     else if (index == 3) {
      // INFO: Lida com o botão 'Resetar Telas'.
      print('Reiniciando o aplicativo...'); // INFO: Log de reinício.
      Restart.restartApp(); // INFO: Reinicia o aplicativo usando o plugin restart_app.
       // NOTE: Considerar confirmar com o usuário antes de reiniciar o app.
    } else if (index == 4) {
      // INFO: Lida com o botão 'Fechar App'.
      print('Fechando o aplicativo...'); // INFO: Log de fechamento.
      if (Platform.isAndroid) {
        SystemNavigator.pop(); // INFO: Fecha o aplicativo no Android.
      } else {
        exit(0); // INFO: Fecha o aplicativo em outras plataformas (iOS, Desktop).
      }
       // NOTE: Considerar confirmar com o usuário antes de fechar o app.
    }
     // NOTE: Adicionar lógica para outros índices de botão se necessário.
  }

  // INFO: Conecta a um dispositivo Bluetooth LE selecionado.
  // NOTE: Esta função implementa a lógica de conexão, descoberta de serviços e características.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    // INFO: Parar qualquer escaneamento em andamento antes de conectar.
    _stopDiscovery();

    // INFO: Desconectar de qualquer dispositivo anterior se houver.
    if (_connectedDevice != null) {
      print('Desconectando do dispositivo anterior: ${_connectedDevice!.remoteId.str}'); // INFO: Log da desconexão anterior.
      await _connectedDevice!.disconnect();
       // INFO: O listener de estado de conexão irá lidar com a limpeza após a desconexão.
    }

    // INFO: Limpar assinaturas de valor antigas para evitar duplicação de listeners.
    _valueSubscriptions.forEach((sub) => sub.cancel());
    _valueSubscriptions.clear();
     _connectionStateSubscription?.cancel(); // INFO: Cancelar assinatura de estado antiga, se existir.

    try {
      // INFO: Tenta conectar ao dispositivo.
      print('Tentando conectar ao dispositivo: ${device.remoteId.str}'); // INFO: Log da tentativa de conexão.
      // INFO: Configurar o listener do estado da conexão ANTES de conectar para capturar todas as transições.
      _connectionStateSubscription = device.connectionState.listen((state) async {
        print('Estado da conexão para ${device.remoteId.str}: $state'); // INFO: Log das mudanças de estado da conexão.
        if (state == BluetoothConnectionState.connected) {
          print('Dispositivo conectado: ${device.remoteId.str}'); // INFO: Log de conexão bem-sucedida.
          setState(() {
            _connectedDevice = device; // INFO: Armazena a referência do dispositivo conectado.
            _isConnected = true; // INFO: Atualiza o estado da conexão para a UI.
             _macAddress = device.remoteId.str; // INFO: Atualiza o MAC Address exibido com o do dispositivo conectado.
             // TODO: Lógica equivalente a "set lbStatus.Text to \"Status: Connected\"". // NOTE: Atualizar o widget de status na UI.
             // TODO: Lógica equivalente a "set cpProximaTela.Visible to true" e "set ListBLE.Visible to false". // NOTE: Gerenciar a visibilidade dos widgets na UI (ex: mostrar tela de configuração, ocultar lista de scan).
             // Isso dependerá de como você estruturou a visibilidade desses widgets no Flutter.
             // Por exemplo, você pode usar Visibility ou condicionais no build()
          });

          // INFO: Descobrir serviços APENAS SE A CONEXÃO FOR BEM-SUCEDIDA.
          print('Descobrindo serviços...'); // INFO: Log de início da descoberta de serviços.
          List<BluetoothService> services = await device.discoverServices(); // INFO: Executa a descoberta de serviços.
          print('Serviços descobertos: ${services.length}'); // INFO: Log do número de serviços encontrados.

          // INFO: Encontrar o serviço e características relevantes (UUIDs dos blocos Kodular).
          final String targetServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // NOTE: UUID do serviço alvo.
          final List<String> targetCharacteristicUuids = [
            "6E400002-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 1.
            "6E400003-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 2.
            "6E400004-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 3.
            "6E400005-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 4.
            "6E400006-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 5.
            "6E400007-B5A3-F393-E0A9-E50E24DCCA9E", // NOTE: UUID da Característica de Leitura/Notificação 6.
          ]; // INFO: Lista de UUIDs das características que se deseja ouvir.

          bool foundTargetService = false; // INFO: Flag para verificar se o serviço alvo foi encontrado.
          for (BluetoothService service in services) {
            if (service.uuid.str.toUpperCase() == targetServiceUuid.toUpperCase()) {
              print('Serviço alvo encontrado: ${service.uuid.str}'); // INFO: Log ao encontrar o serviço alvo.
              foundTargetService = true;
              for (BluetoothCharacteristic characteristic in service.characteristics) {
                if (targetCharacteristicUuids.contains(characteristic.uuid.str.toUpperCase())) {
                  // INFO: Verificar se a característica suporta NOTIFY ou INDICATE antes de tentar setNotifyValue(true).
                  if (characteristic.properties.notify || characteristic.properties.indicate) {
                     print('Característica ${characteristic.uuid.str} suporta notificações/indicações. Registrando...'); // INFO: Log ao encontrar característica que suporta notificações.
                    try {
                       // INFO: Habilitar notificações/indicações para receber dados do fluxo da característica.
                       await characteristic.setNotifyValue(true); // INFO: Ativa as notificações.
                       print('Notificações habilitadas para ${characteristic.uuid.str}'); // INFO: Log de sucesso ao habilitar notificações.

                       // INFO: Ouvir o fluxo de valores desta característica. A callback é chamada a cada nova notificação/indicação.
                       final subscription = characteristic.value.listen((value) {
                         // INFO: Dados recebidos! Decodificar os bytes para string (assumindo UTF-8, como em RegisterForStrings do Kodular).
                         final receivedString = utf8.decode(value); // INFO: Decodifica os bytes recebidos.
                         print('Dados recebidos da característica ${characteristic.uuid.str}: $receivedString'); // INFO: Log dos dados recebidos.
                         // TODO: Adicione sua lógica aqui para processar o receivedString. // NOTE: Implementar o tratamento dos dados recebidos de cada característica.
                         // Dependendo do que esses dados representam, você pode atualizar a UI,
                         // armazenar, enviar para outro lugar, etc.
                         // Exemplo: processar dados de uma característica específica
                         // if (characteristic.uuid.str.toUpperCase() == "...") { ... }
                       });
                       _valueSubscriptions.add(subscription); // INFO: Armazena a assinatura na lista para cancelar posteriormente no dispose ou desconexão.

                    } catch(e) {
                       print('Erro ao habilitar notificações/indicações para ${characteristic.uuid.str}: $e'); // NOTE: Logar erro ao tentar habilitar notificações.
                       // Opcional: Notificar o usuário sobre a falha em habilitar notificações para esta característica. // TODO: Exibir feedback visual de erro.
                    }
                  } else {
                     print('Característica ${characteristic.uuid.str} NÃO suporta notificações/indicações.'); // INFO: Log se a característica não suportar notificações/indicações.
                     // Opcional: Logar ou notificar que a característica não suporta o registro desejado. // TODO: Exibir feedback visual se uma característica esperada não suportar notificações.
                  }
                }
              }
              // Opcional: Parar de procurar características em outros serviços após encontrar o serviço correto se ele for único.
              // break;
            }
          }

          // INFO: Verifica se o serviço alvo foi encontrado.
          if (!foundTargetService) {
             print('Serviço alvo (${targetServiceUuid}) não encontrado no dispositivo.'); // NOTE: Logar se o serviço alvo não for encontrado.
             // TODO: Notificar o usuário que o dispositivo pode não ser o esperado. // TODO: Exibir feedback visual de erro.
             _disconnectDevice(); // INFO: Desconectar se o serviço alvo não for encontrado para evitar estado inconsistente.
          } else {
              print('Registro para características concluído (ou tentado).'); // INFO: Log após tentar registrar para todas as características alvo.
              // Opcional: Verificar se pelo menos uma característica alvo foi registrada com sucesso.
              if(_valueSubscriptions.isEmpty) {
                  print('Nenhuma das características alvo foi registrada com sucesso. Verifique os UUIDs e propriedades.'); // NOTE: Logar se nenhuma assinatura foi criada.
                  // TODO: Notificar o usuário. // TODO: Exibir feedback visual de erro.
              }
          }

        } else if (state == BluetoothConnectionState.disconnected) {
          print('Dispositivo desconectado'); // INFO: Log ao detectar desconexão.
          setState(() {
            _isConnected = false; // INFO: Atualiza o estado da conexão para a UI.
            _connectedDevice = null; // INFO: Limpa a referência do dispositivo conectado.
            _macAddress = ''; // INFO: Limpa o MAC Address exibido.
             // INFO: Limpar assinaturas ao desconectar para parar de ouvir dados.
            _valueSubscriptions.forEach((sub) => sub.cancel());
            _valueSubscriptions.clear();
             _connectionStateSubscription?.cancel(); // INFO: Cancelar a própria assinatura do estado da conexão.
             _connectionStateSubscription = null;

            // TODO: Atualizar a UI para o estado desconectado (ex: ocultar cpProximaTela, mostrar ListBLE). // NOTE: Restaurar a UI para o estado inicial de desconectado.
          });
        }
         // INFO: Você pode adicionar outros estados (connecting, disconnecting) se precisar monitorá-los para feedback da UI.
      });

      // INFO: Conectar de fato (o listener configurado acima reagirá à mudança de estado).
       await device.connect(timeout: Duration(seconds: 10)); // NOTE: Ajustar o tempo limite da tentativa de conexão inicial.

    } catch (e) {
      print('Erro durante o processo de conexão inicial: $e'); // NOTE: Logar erros que ocorrem durante a tentativa inicial de conexão.
      setState(() {
         _isConnected = false; // INFO: Garante que o estado seja desconectado em caso de erro.
         _connectedDevice = null;
         _macAddress = '';
         _valueSubscriptions.forEach((sub) => sub.cancel()); // INFO: Limpa assinaturas em caso de erro.
         _valueSubscriptions.clear();
          _connectionStateSubscription?.cancel(); // INFO: Cancela assinatura de estado em caso de erro.
          _connectionStateSubscription = null;
      });
      // TODO: Mostrar uma mensagem de erro para o usuário, talvez um SnackBar. // TODO: Exibir feedback visual de erro na conexão.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao conectar ao dispositivo: ${e.toString()}'), // INFO: Mensagem de erro para o usuário.
          backgroundColor: Colors.red, // NOTE: Cor do SnackBar para erro.
        ), // INFO: SnackBar para exibir erro de conexão.
      );
    }
  }

  // INFO: Desconecta do dispositivo Bluetooth LE atualmente conectado.
  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        print('Desconectando manualmente do dispositivo: ${_connectedDevice!.remoteId.str}'); // INFO: Log da desconexão manual.
        await _connectedDevice!.disconnect(); // INFO: Envia o comando de desconexão.
        // INFO: A lógica de atualização de estado e limpeza de assinaturas já está no listener do connectionState.
        // INFO: O listener de estado de conexão irá capturar a transição para 'disconnected' e limpar o estado/assinaturas.
      } catch(e) {
        print('Erro ao desconectar manualmente: $e'); // NOTE: Logar erros durante a desconexão manual.
         // INFO: A lógica de atualização de estado e limpeza de assinaturas em caso de erro pode precisar ser adicionada aqui também
         setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _macAddress = '';
            _valueSubscriptions.forEach((sub) => sub.cancel());
            _valueSubscriptions.clear();
             _connectionStateSubscription?.cancel();
             _connectionStateSubscription = null;
         }); // INFO: Garante a limpeza do estado mesmo se o disconnect() falhar.
         // TODO: Exibir feedback visual de erro na desconexão.
      }
    } else {
       print('Nenhum dispositivo conectado para desconectar.'); // INFO: Log se tentar desconectar sem um dispositivo conectado.
       // TODO: Opcional: Mostrar mensagem ao usuário que não há dispositivo conectado.
    }
  }

  // INFO: Limpa todos os dados.
  Future<void> _clearData() async {
    // INFO: Mostra diálogo de confirmação.
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Limpeza'),
          content: Text('Tem certeza que deseja limpar todos os dados?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );

    // INFO: Se o usuário confirmou, limpa os dados.
    if (confirm == true) {
      setState(() {
        _patrimonyTablet = '';
        _totalDoors = '';
        _idDevice = '';
        _tabletName = '';
        _accessLevelId = '';
        _accessLevelName = '';
        _site = '';
        _doorId = '';
        _token = '';
        _wsAccessLevel = '';
        _wsSystemEvent = '';
        _wsLocation = '';
        _wsLogSystem = '';
        _wsRecoveryData = '';
        _wsStatusPorta = '';
      });

      // INFO: Exibe mensagem de sucesso.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados limpos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // INFO: Salva os dados localmente.
  Future<void> _saveData() async {
    // INFO: Mostra diálogo de confirmação.
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Salvamento'),
          content: Text('Tem certeza que deseja salvar os dados?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );

    // INFO: Se o usuário confirmou, salva os dados.
    if (confirm == true) {
      try {
        // INFO: Prepara os dados para salvar.
        final Map<String, dynamic> data = {
          'patrimonyTablet': _patrimonyTablet,
          'totalDoors': _totalDoors,
          'idDevice': _idDevice,
          'tabletName': _tabletName,
          'accessLevelId': _accessLevelId,
          'accessLevelName': _accessLevelName,
          'site': _site,
          'doorId': _doorId,
          'token': _token,
          'wsAccessLevel': _wsAccessLevel,
          'wsSystemEvent': _wsSystemEvent,
          'wsLocation': _wsLocation,
          'wsLogSystem': _wsLogSystem,
          'wsRecoveryData': _wsRecoveryData,
          'wsStatusPorta': _wsStatusPorta,
        };

        // INFO: Salva os dados usando SharedPreferences.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('config_data', jsonEncode(data));

        // INFO: Exibe mensagem de sucesso.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dados salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // INFO: Exibe mensagem de erro.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // INFO: Carrega os dados salvos localmente.
  Future<void> _loadData() async {
    // INFO: Mostra diálogo de confirmação.
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Recarga'),
          content: Text('Tem certeza que deseja recarregar os dados? Os dados não salvos serão perdidos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        );
      },
    );

    // INFO: Se o usuário confirmou, carrega os dados.
    if (confirm == true) {
      try {
        // INFO: Carrega os dados usando SharedPreferences.
        final prefs = await SharedPreferences.getInstance();
        final String? dataString = prefs.getString('config_data');

        if (dataString != null) {
          final Map<String, dynamic> data = jsonDecode(dataString);

          setState(() {
            _patrimonyTablet = data['patrimonyTablet'] ?? '';
            _totalDoors = data['totalDoors'] ?? '';
            _idDevice = data['idDevice'] ?? '';
            _tabletName = data['tabletName'] ?? '';
            _accessLevelId = data['accessLevelId'] ?? '';
            _accessLevelName = data['accessLevelName'] ?? '';
            _site = data['site'] ?? '';
            _doorId = data['doorId'] ?? '';
            _token = data['token'] ?? '';
            _wsAccessLevel = data['wsAccessLevel'] ?? '';
            _wsSystemEvent = data['wsSystemEvent'] ?? '';
            _wsLocation = data['wsLocation'] ?? '';
            _wsLogSystem = data['wsLogSystem'] ?? '';
            _wsRecoveryData = data['wsRecoveryData'] ?? '';
            _wsStatusPorta = data['wsStatusPorta'] ?? '';
          });

          // INFO: Exibe mensagem de sucesso.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dados carregados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // INFO: Exibe mensagem de erro caso não haja dados salvos.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não há dados salvos para carregar.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        // INFO: Exibe mensagem de erro.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // INFO: Salva os dados automaticamente se a opção estiver ativada.
  Future<void> _autoSaveData() async {
    if (_autoSave) {
      await _saveData();
    }
  }

  // INFO: Constrói o container para a seção Tablet.
  Widget _buildTabletContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
            'Tablet:',
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _tabletName,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Patrimônio.
  Widget _buildPatrimonyContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
            'Patrimônio:',
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
                      'Número:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _patrimonyTablet,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Total de Portas.
  Widget _buildTotalDoorsContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
            'Total de Portas:',
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
                      'Quantidade:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _totalDoors,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Nível Acesso.
  Widget _buildNivelAcessoContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _accessLevelId,
                        style: TextStyle(fontSize: 18),
                      ),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _accessLevelName,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Portas.
  Widget _buildPortasContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _site,
                        style: TextStyle(fontSize: 18),
                      ),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _doorId,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Token.
  Widget _buildTokenContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _token,
                        style: TextStyle(fontSize: 18),
                      ),
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

  // INFO: Constrói o container para a seção Web Services.
  Widget _buildWebServicesContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
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
            'Web Services:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildWebServiceField('Nível Acesso:', _wsAccessLevel),
          SizedBox(height: 10),
          _buildWebServiceField('Eventos Sistema:', _wsSystemEvent),
          SizedBox(height: 10),
          _buildWebServiceField('Locação:', _wsLocation),
          SizedBox(height: 10),
          _buildWebServiceField('Log Sistema:', _wsLogSystem),
          SizedBox(height: 10),
          _buildWebServiceField('Armazena Pessoas:', _wsRecoveryData),
          SizedBox(height: 10),
          _buildWebServiceField('Status Porta:', _wsStatusPorta),
        ],
      ),
    );
  }

  // INFO: Constrói um campo de texto para exibir um URL de serviço web.
  Widget _buildWebServiceField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // INFO: Método principal que constrói a interface visual da página de configuração.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // INFO: Cor de fundo do Scaffold, pode ser transparente se a imagem cobrir tudo.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Configurações',
          // NOTE: Ajuste o estilo do texto para ser visível sobre a imagem.
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Centraliza o título na AppBar.
        // INFO: Usa FlexibleSpace para adicionar a imagem de fundo na AppBar.
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/verticalduascores.png'), // NOTE: Caminho da imagem da barra superior.
              fit: BoxFit.cover, // Cobre a área disponível.
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Torna a AppBar transparente para mostrar a imagem.
        elevation: 0, // Remove a sombra da AppBar.
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // NOTE: Cor do ícone para ser visível.
          onPressed: () {
            // INFO: Mostra diálogo de confirmação.
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Confirmar Saída'),
                  content: Text('Deseja salvar os dados antes de sair?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // INFO: Fecha o diálogo.
                        Navigator.of(context).pop(); // INFO: Volta para a tela anterior.
                      },
                      child: Text('Sair sem Salvar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // INFO: Fecha o diálogo.
                        await _saveData(); // INFO: Salva os dados.
                        Navigator.of(context).pop(); // INFO: Volta para a tela anterior.
                      },
                      child: Text('Salvar e Sair'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          Switch(
            value: _autoSave,
            onChanged: (bool value) {
              setState(() {
                _autoSave = value;
              });
            },
            activeColor: Colors.green,
          ),
          Text(
            'Salvamento Automático',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // INFO: Imagem de fundo cobrindo toda a tela.
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo.png', // NOTE: Caminho da imagem de fundo.
              fit: BoxFit.cover, // Cobre a área disponível.
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- START BLUETOOTH AND DATA ACTIONS UI ELEMENTS ---
                // INFO: Container para exibir o status da conexão e o endereço MAC.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Fundo branco
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
                        'Status da Conexão:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _isConnected ? 'Conectado' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Endereço MAC:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _macAddress.isNotEmpty ? _macAddress : 'N/A',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      // INFO: Botão para conectar ou desconectar, dependendo do estado.
                      Center(
                        child: ElevatedButton(
                          onPressed: _isConnected ? _disconnectDevice : _startDiscovery,
                          child: Text(_isConnected ? 'Desconectar' : 'Buscar Dispositivos'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // INFO: Contêiner para exibir informações do dispositivo (tablet/celular).
                 Container(
                   width: double.infinity,
                   padding: EdgeInsets.all(20),
                   margin: EdgeInsets.only(bottom: 20),
                   decoration: BoxDecoration(
                     color: Colors.white, // Fundo branco
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
                         'Informações do Dispositivo:',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                       SizedBox(height: 10),
                       Text('Nome: $_deviceName', style: TextStyle(fontSize: 16)),
                       SizedBox(height: 5),
                       Text('ID: $_deviceId', style: TextStyle(fontSize: 16)),
                     ],
                   ),
                 ),
                SizedBox(height: 20),
                 // INFO: Contêiner para as configurações de portas e relé de emergência.
                 Container(
                   width: double.infinity,
                   padding: EdgeInsets.all(20),
                   margin: EdgeInsets.only(bottom: 20),
                   decoration: BoxDecoration(
                     color: Colors.white, // Fundo branco
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
                         'Configuração da Placa:',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                       SizedBox(height: 10),
                       TextField(
                         controller: _quantidadePortasController,
                         keyboardType: TextInputType.number,
                         decoration: InputDecoration(
                           labelText: 'Quantidade de Portas',
                           border: OutlineInputBorder(),
                         ),
                       ),
                       SizedBox(height: 10),
                       TextField(
                         controller: _releEmergenciaController,
                         decoration: InputDecoration(
                           labelText: 'Relé de Emergência',
                           border: OutlineInputBorder(),
                         ),
                       ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: (){
                               // TODO: Implementar lógica de salvar configuração da placa
                            },
                            child: Text('Salvar Configuração Placa'),
                             style: ElevatedButton.styleFrom(
                               padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                               textStyle: TextStyle(fontSize: 18),
                             ),
                          ),
                        ),
                     ],
                   ),
                 ),
                SizedBox(height: 20),
                 // INFO: Contêiner para as opções de locação e armazenar pessoas.
                 Container(
                   width: double.infinity,
                   padding: EdgeInsets.all(20),
                   margin: EdgeInsets.only(bottom: 20),
                   decoration: BoxDecoration(
                     color: Colors.white, // Fundo branco
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
                         'Configurações Adicionais:',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                       SizedBox(height: 10),
                       DropdownButtonFormField<String>(
                         value: _tipoLocacaoSelecionado,
                         hint: Text('Tipo de Locação'),
                         items: _tiposLocacao.map((String value) {
                           return DropdownMenuItem<String>(
                             value: value,
                             child: Text(value),
                           );
                         }).toList(),
                         onChanged: (newValue) {
                           setState(() {
                             _tipoLocacaoSelecionado = newValue;
                           });
                         },
                         decoration: InputDecoration(
                           border: OutlineInputBorder(),
                         ),
                       ),
                       SizedBox(height: 10),
                       DropdownButtonFormField<String>(
                         value: _armazenarPessoasSelecionado,
                         hint: Text('Armazenar Pessoas'),
                         items: _opcoesArmazenarPessoas.map((String value) {
                           return DropdownMenuItem<String>(
                             value: value,
                             child: Text(value),
                           );
                         }).toList(),
                         onChanged: (newValue) {
                           setState(() {
                             _armazenarPessoasSelecionado = newValue;
                           });
                         },
                         decoration: InputDecoration(
                           border: OutlineInputBorder(),
                         ),
                       ),
                     ],
                   ),
                 ),
                 SizedBox(height: 20),

                // INFO: Botões para as ações de dados (Validar, Salvar, Recarregar, Limpar).
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     ElevatedButton(
                       onPressed: _isValidating ? null : _validateData,
                       child: Text('Validar Dados'),
                       style: ElevatedButton.styleFrom(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Reduced padding
                         textStyle: TextStyle(fontSize: 16), // Reduced font size
                       ),
                     ),
                     SizedBox(width: 10), // Reduced spacing
                     ElevatedButton(
                       onPressed: _saveData,
                       child: Text('Salvar Dados'),
                       style: ElevatedButton.styleFrom(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Reduced padding
                         textStyle: TextStyle(fontSize: 16), // Reduced font size
                         backgroundColor: Colors.green,
                       ),
                     ),
                     SizedBox(width: 10), // Reduced spacing
                     ElevatedButton(
                       onPressed: _loadData,
                       child: Text('Recarregar'),
                       style: ElevatedButton.styleFrom(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Reduced padding
                         textStyle: TextStyle(fontSize: 16), // Reduced font size
                         backgroundColor: Colors.blue,
                       ),
                     ),
                     SizedBox(width: 10), // Reduced spacing
                     ElevatedButton(
                       onPressed: _clearData,
                       child: Text('Limpar Dados'),
                       style: ElevatedButton.styleFrom(
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Reduced padding
                         textStyle: TextStyle(fontSize: 16), // Reduced font size
                         backgroundColor: Colors.red,
                       ),
                     ),
                   ],
                 ),
                // --- END BLUETOOTH AND DATA ACTIONS UI ELEMENTS ---
              ],
            ),
          ),
          if (_isValidating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
