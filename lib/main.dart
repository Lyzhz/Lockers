import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:restart_app/restart_app.dart';

import 'package:lockers/pages/config_page.dart';
import 'package:lockers/pages/dados_page.dart';
import 'package:lockers/pages/refectory_page.dart';
import 'package:lockers/pages/sca_page.dart';
import 'package:lockers/pages/facial_page.dart';
import 'package:lockers/pages/collectingdata_page.dart';
import 'package:lockers/pages/lockers_page.dart';
import 'services/ble_initializer.dart';

const Color selectedIconColor = Color.fromRGBO(40, 86, 155, 1);
const Color navBarColor = Color.fromRGBO(47, 180, 242, 1);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // final bleInitializer = BLEInitializer();
  // await bleInitializer.initializeBluetooth();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'InfinityBr',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(title: 'InfinityBr'),
        debugShowCheckedModeBanner: false,
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<CurvedNavigationBarState> _navigationKey = GlobalKey();

  int _selectedIndex = 2;

  static const List<Widget> _screens = [
    ScaPage(),
    RefeitorioPage(),
    LockersPage(),
    CollectingDataPage(),
    FacialPage(),
  ];

  static const List<IconData> _icons = [
    Icons.nfc,
    Icons.coffee,
    Icons.lock,
    Icons.storage_sharp,
    Icons.face,
  ];

  void _openConfigPage() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ConfigPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 100),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = List.generate(_icons.length, (i) {
      final isSelected = i == _selectedIndex;
      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          _icons[i],
          size: 45,
          color: isSelected ? selectedIconColor : Colors.white,
        ),
      );
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.red,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onLongPress: _openConfigPage,
          child: Image.asset(
            'assets/verticalduascores.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: selectedIconColor),
        ),
        child: CurvedNavigationBar(
          key: _navigationKey,
          items: items,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          color: navBarColor,
          buttonBackgroundColor: Colors.white,
          height: 75,
          backgroundColor: Colors.transparent,
          index: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
