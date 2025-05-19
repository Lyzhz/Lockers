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

// Bottom NavBar
  final navigationKey = GlobalKey<CurvedNavigationBarState>();
  int index = 2;
  @override
  Widget build(BuildContext context) {
    // Botoes da NavBar
    final items = <Widget>[
      Icon(Icons.lock, size: 30),
      Icon(Icons.search, size: 30),
      Icon(Icons.settings, size: 30),
      Icon(Icons.settings, size: 30),
      Icon(Icons.person, size: 30),
    ];
    // Base da NavBar
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.red, 
      appBar: AppBar(
        title: Text('INFINITY BR LOCKERS'),
        elevation: 0,
        centerTitle: true
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$index',
              style: TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: Size(250, 56),
              ),
              child: Text('Go to 0', style: TextStyle(fontSize: 32)),
              onPressed: () {
                final navigationState = navigationKey.currentState!;

                navigationState.setPage(0);
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: IconThemeData(color: const Color.fromRGBO(40, 86, 155, 1)),
        ),
        child: CurvedNavigationBar(
          key: navigationKey,
          items: items,
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 300),
          color: const Color.fromRGBO(47, 180, 242, 1),
          buttonBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
          height: 75,
          backgroundColor: Colors.transparent,
          index: index,
          onTap: (index) => setState(() => this.index = index),
          
        ),
      ),
    );
  }
}
