import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:my_activities/screens/homepage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sharedPrefActivitiesProvider.loadActivities();
  await databaseActivitiesProvider.loadFromDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: sharedPrefActivitiesProvider),
          ChangeNotifierProvider.value(value: databaseActivitiesProvider),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: themeProvider.themeData,
              home: const SplashScreen(),
            ),
          ),
        ));
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _a = false;
  bool _b = false;
  bool _c = false;
  bool _d = false;
  bool _e = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _a = true;
      });
    });
    Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _b = true;
      });
    });
    Timer(const Duration(milliseconds: 1300), () {
      setState(() {
        _c = true;
      });
    });
    Timer(const Duration(milliseconds: 1700), () {
      setState(() {
        _e = true;
      });
    });
    Timer(const Duration(milliseconds: 3400), () {
      setState(() {
        _d = true;
      });
    });
    Timer(const Duration(milliseconds: 3650), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(),
        ),
      );
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: themeProvider.themeData.colorScheme.primary,
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: _d ? 900 : 2500),
                  curve: _d ? Curves.fastLinearToSlowEaseIn : Curves.elasticOut,
                  height: _d
                      ? 0
                      : _a
                          ? h / 2
                          : 20,
                  width: 20,
                ),
                AnimatedContainer(
                  duration: Duration(
                      seconds: _d
                          ? 1
                          : _c
                              ? 2
                              : 0),
                  curve: Curves.fastLinearToSlowEaseIn,
                  height: _d
                      ? h
                      : _c
                          ? 80
                          : 20,
                  width: _d
                      ? w
                      : _c
                          ? 200
                          : 20,
                  decoration: BoxDecoration(
                    color: _b ? themeProvider.themeData.colorScheme.surface : Colors.transparent,
                    borderRadius: _d ? const BorderRadius.only() : BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
          ),
          // Add this Positioned widget for the locked text
          Center(
            child: _e
                ? Container(
                    padding: const EdgeInsets.only(top: 75),
                    child: const Text(
                      'HASEEB',
                      style: TextStyle(
                        fontSize: 30,
                        letterSpacing: 5,
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(seconds: 1),
                          curve: Curves.linear,
                        )
                        .then()
                        .fadeOut(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.linear,
                        ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
