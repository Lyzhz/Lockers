import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.red,
    body: Center(
      child: Text(
        'Settings',
        style: TextStyle(fontSize: 60, color: Colors.white),
      ),
    ),
  );
}