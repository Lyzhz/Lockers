import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:lockers/pages/config_page.dart';
import 'package:lockers/pages/dados_page.dart';
import 'dart:io' show Platform, exit;
import 'package:restart_app/restart_app.dart';

// INFO: Internal Pages (screens/routes of the app)
import 'package:lockers/pages/refectory_page.dart';
import 'package:lockers/pages/sca_page.dart';
import 'package:lockers/pages/facial_page.dart';
import 'package:lockers/pages/collectingdata_page.dart';
import 'package:lockers/pages/lockers_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    RefeitorioPage(),
    LockersPage(),
    CollectingDataPage(),
    FacialPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // INFO: Navigation bar icons
    final icons = [
      Icons.nfc,
      Icons.coffee,
      Icons.lock,
      Icons.storage_sharp,
      Icons.face,
    ];

    final items = List.generate(icons.length, (i) {
      final isSelected = i == index;
      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          icons[i],
          size: 45,
          color:
              isSelected
                  ? const Color.fromRGBO(40, 86, 155, 1) // azul se selecionado
                  : Colors.white, // branco se não
        ),
      );
    });
    return SafeArea(
      top: false,
      child: Scaffold(
        extendBody:
            true, // INFO: Allows body to render behind the navbar (useful for transparency effects)
        backgroundColor:
            Colors.red, // INFO: Background color of the whole screen
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onLongPress: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            ConfigPage(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      const begin = Offset(
                        1.0,
                        0.0,
                      ); // Da direita para a esquerda
                      const end = Offset.zero;
                      final tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: Curves.easeInOut));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: Duration(milliseconds: 300),
                  ),
                );
              },
              child: Image.asset(
                'assets/verticalduascores.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        body:
            screens[index], // INFO: Displays the current screen based on selected index
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              color: const Color.fromRGBO(40, 86, 155, 1),
            ),
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
      ),
    );
  }

  void _onNavButtonTap(int index) {
    setState(() {
      this.index = index;
    });
    if (index == 3) {
      // Resetar Telas
      Restart.restartApp();
    } else if (index == 4) {
      // Fechar App
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } else if (index == 2) {
      // Lógica para navegar para DadosPage
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DadosPage()));
    }
  }
}
