import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart'; // Comentado temporariamente
// import 'package:path/path.dart'; // Comentado temporariamente

class DadosPage extends StatefulWidget {
  const DadosPage({Key? key}) : super(key: key);
  @override
  _DadosPageState createState() => _DadosPageState();
}

class _DadosPageState extends State<DadosPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _dados = [];
  bool _mostrandoBanco = false;
  bool _showTable = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTable() {
    setState(() {
      _showTable = !_showTable;
      if (_showTable) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  // Comentado temporariamente
  /*
  Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'meubanco.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE IF NOT EXISTS dados(id INTEGER PRIMARY KEY, valor TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> _visualizarBanco() async {
    // final db = await _getDatabase();
    // final dados = await db.query('dados');
    setState(() {
      // _dados = dados;
      _mostrandoBanco = true;
      _dados = [ // Dados mockados para teste
        {'id': 1, 'valor': 'Dado de Teste 1'},
        {'id': 2, 'valor': 'Dado de Teste 2'},
      ];
    });
  }
  */

  // Função temporária para simular a visualização (sem banco)
  void _visualizarBancoSimulado() {
    setState(() {
      _mostrandoBanco = true;
      _dados = [
        // Dados mockados para teste
        {'id': 1, 'valor': 'Dado de Teste 1'},
        {'id': 2, 'valor': 'Dado de Teste 2'},
        {'id': 3, 'valor': 'Dado de Teste 3'},
        {'id': 4, 'valor': 'Dado de Teste 4'},
        {'id': 5, 'valor': 'Dado de Teste 5'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          Positioned.fill(
            child: Image.asset('assets/fundo.jpg', fit: BoxFit.cover),
          ),
          // Conteúdo da tela: Usando Column para organizar os elementos
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _toggleTable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(47, 180, 242, 1),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _showTable ? 'Ocultar Banco' : 'Visualizar Banco',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_showTable)
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
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
                                'Dados do Banco Local:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 15),
                              Expanded(
                                child:
                                    _dados.isEmpty
                                        ? Center(
                                          child: Text(
                                            'Nenhum dado encontrado.',
                                          ),
                                        ) // Centraliza
                                        : SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              headingRowColor:
                                                  MaterialStateColor.resolveWith(
                                                    (states) =>
                                                        const Color.fromRGBO(
                                                          47,
                                                          180,
                                                          242,
                                                          1,
                                                        ),
                                                  ),
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    'ID',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Valor',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows:
                                                  _dados
                                                      .map(
                                                        (d) => DataRow(
                                                          cells: [
                                                            DataCell(
                                                              Text(
                                                                d['id']
                                                                    .toString(),
                                                              ),
                                                            ),
                                                            DataCell(
                                                              Text(
                                                                d['valor']
                                                                    .toString(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ),
                                        ),
                              ),
                            ],
                          ),
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
}
