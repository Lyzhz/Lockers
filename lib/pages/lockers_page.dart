import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockersPage extends StatefulWidget {
  @override
  _LockersPageState createState() => _LockersPageState();
}

class _LockersPageState extends State<LockersPage> {
  int _numberOfDoors = 0; // Variável para armazenar a quantidade de portas
  String _macAddress = ''; // Variável para armazenar o endereço MAC
  List<bool> _isLockerConnected = []; // Estado para cada armário
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadPreferences();
    } catch (e) {
      print('Erro ao carregar preferências: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Função para carregar as preferências salvas
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _numberOfDoors = prefs.getInt('numberOfDoors') ?? 0;
        _macAddress = prefs.getString('macAddress') ?? '';
        // Inicializa o estado de conexão para cada armário
        _isLockerConnected = List<bool>.filled(_numberOfDoors, false);
        print(
          'Preferências carregadas: Portas = $_numberOfDoors, MAC = $_macAddress',
        );
        // Aqui você pode usar _numberOfDoors e _macAddress para construir a UI
      });
    }
  }

  // Função para simular a alternância de conexão de um armário
  void _toggleLockerConnection(int index) {
    setState(() {
      _isLockerConnected[index] = !_isLockerConnected[index];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        // Imagem de fundo
        Positioned.fill(
          child: Image.asset('assets/fundo.jpg', fit: BoxFit.cover),
        ),
        // Conteúdo principal
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Containers dos armários gerados dinamicamente
                Expanded(
                  child:
                      _numberOfDoors > 0
                          ? ListView.builder(
                            itemCount: _numberOfDoors,
                            itemBuilder: (context, index) {
                              final lockerNumber = index + 1;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    0.8,
                                  ), // Cor branca com opacidade
                                  borderRadius: BorderRadius.circular(
                                    10.0,
                                  ), // Bordas arredondadas
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Armário $lockerNumber',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ), // Espaço entre o título e os detalhes
                                    GestureDetector(
                                      onTap:
                                          () => _toggleLockerConnection(
                                            index,
                                          ), // Torna o status clicável
                                      child: Row(
                                        children: [
                                          Text(
                                            'Status: ',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  _isLockerConnected[index]
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            _isLockerConnected[index]
                                                ? 'Conectado'
                                                : 'Desconectado',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4.0,
                                    ), // Espaço entre os detalhes
                                    Text(
                                      'Bluetooth: $_macAddress',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    SizedBox(
                                      height: 4.0,
                                    ), // Espaço entre os detalhes
                                    Text(
                                      'Portas: $lockerNumber',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          : Center(
                            child: Text(
                              'Nenhuma porta configurada.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
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
