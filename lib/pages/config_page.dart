import 'package:flutter/material.dart';

class ConfigPage extends StatelessWidget {
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
                'Config',
                style: TextStyle(fontSize: 60, color: Colors.white),
              ),
            ),
          ],
        ),
  );
}
