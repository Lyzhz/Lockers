import 'package:flutter/material.dart';

class PersonPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.red,
    body: Center(
      child: Text(
        'Person',
        style: TextStyle(fontSize: 60, color: Colors.white),
      ),
    ),
  );
}