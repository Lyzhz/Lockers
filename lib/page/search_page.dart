import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.red,
    body: Center(
      child: Text(
        'Search',
        style: TextStyle(fontSize: 60, color: Colors.white),
      ),
    ),
  );
}