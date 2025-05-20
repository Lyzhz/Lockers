import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// INFO: Internal Pages (screens/routes of the app)
import 'package:lockers/pages/refectory_page.dart';
import 'package:lockers/pages/sca_page.dart';
import 'package:lockers/pages/facial_page.dart';
import 'package:lockers/pages/collectingdata_page.dart';
import 'package:lockers/pages/lockers_page.dart';

void main() {
  runApp(const MyApp()); // NOTE: Bootstraps the app with the root widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // NOTE: This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // NOTE: Global theme setup using a seed color
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: (const MyHomePage(
        title: 'InfinityBr',
      )), // NOTE: Sets the home screen
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // INFO: Navigation bar key (used for programmatic control if needed)
  final navigationKey = GlobalKey<CurvedNavigationBarState>();

  // INFO: Index to track the current selected tab
  int index = 2;

  // INFO: Screens corresponding to each tab in the bottom navigation
  final screens = [
    ScaPage(),
    RefectoryPage(),
    LockersPage(),
    CollectingDataPage(),
    FacialPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // INFO: Navigation bar icons
    final items = <Widget>[
      Icon(Icons.nfc, size: 45),
      Icon(Icons.coffee, size: 45),
      Icon(Icons.lock, size: 45),
      Icon(Icons.storage_sharp, size: 45),
      Icon(Icons.face, size: 45),
    ];

    return Scaffold(
      extendBody:
          true, // INFO: Allows body to render behind the navbar (useful for transparency effects)
      backgroundColor: Colors.red, // INFO: Background color of the whole screen
      appBar: AppBar(
        title: Text('INFINITY BR LOCKERS'),
        elevation: 0,
        centerTitle: true,
      ),
      body:
          screens[index], // INFO: Displays the current screen based on selected index
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: IconThemeData(color: const Color.fromRGBO(40, 86, 155, 1)),
        ),
        child: CurvedNavigationBar(
          key: navigationKey,
          items: items,
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 300),
          // INFO: Bar color
          color: const Color.fromRGBO(47, 180, 242, 1),
          // INFO: Background of the selected button
          buttonBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
          height: 75,
          backgroundColor:
              Colors.transparent, // INFO: Makes the background see-through
          index: index,
          // INFO: Updates UI on tab switch
          onTap: (index) => setState(() => this.index = index),
        ),
      ),
    );
  }
}
