import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockersPage extends StatelessWidget {
  const LockersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem de fundo
            Image.asset(
              'assets/fundo.jpg', // <- coloca o caminho certo aqui
              fit: BoxFit.cover,
            ),

            // Conteúdo da tela
            Center(
              child: Text(
                'Lockers',
                style: TextStyle(fontSize: 60, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}