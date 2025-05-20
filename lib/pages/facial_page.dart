import 'package:flutter/material.dart';

class FacialPage extends StatelessWidget {
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
                'Facial',
                style: TextStyle(fontSize: 60, color: Colors.white),
              ),
            ),
          ],
        ),
  );
}
