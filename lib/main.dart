import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  int index = 2;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Icon(Icons.lock, size: 30),
      Icon(Icons.search, size: 30),
      Icon(Icons.settings, size: 30),
      Icon(Icons.settings, size: 30),
      Icon(Icons.person, size: 30),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.red, 
      appBar: AppBar(
        title: Text('INFINITY BR LOCKERS'),
        elevation: 0,
        centerTitle: true
      ),
      body: Image.network('https://sdmntprnorthcentralus.oaiusercontent.com/files/00000000-5904-622f-b02f-6a26d6d1028b/raw?se=2025-05-19T16%3A52%3A04Z&sp=r&sv=2024-08-04&sr=b&scid=00000000-0000-0000-0000-000000000000&skoid=bbd22fc4-f881-4ea4-b2f3-c12033cf6a8b&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2025-05-19T15%3A44%3A11Z&ske=2025-05-20T15%3A44%3A11Z&sks=b&skv=2024-08-04&sig=oFosQgXks4EC1%2BiPAnDPIpqkmyM8BuqiavqtLLtiXec%3D',
      height: double.infinity,
      width: double.infinity,
      fit:BoxFit.cover,
    ),

      bottomNavigationBar: CurvedNavigationBar(items: items,
      animationCurve: Curves.easeInOut,
      animationDuration: Duration(milliseconds: 300),
      color: const Color.fromRGBO(40, 86, 155, 1),
      buttonBackgroundColor: const Color.fromRGBO(47, 180, 242, 1),
      height: 75,
      backgroundColor: Colors.transparent,
      index: index,
      onTap: (index) => setState(() => this.index = index),
      ),
    );
  }
}
