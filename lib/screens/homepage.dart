import 'package:flutter/material.dart';
import 'package:my_activities/providers/active_activities.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//providers init data

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String getColorName(Color color) {
    if (color == Colors.blue) {
      return 'Blue';
    } else if (color == Colors.indigoAccent) {
      return 'Indigo';
    } else if (color == Colors.green) {
      return 'Green';
    } else if (color == Colors.deepPurple) {
      return 'Purple';
    } else if (color == Colors.orange) {
      return 'Orange';
    } else if (color == Colors.teal) {
      return 'Teal';
    } else {
      return 'Unknown';
    }
  }

  int _selectedIndex = 0;

  Widget getScreen() {
    switch (_selectedIndex) {
      case 0:
        return const ActiveActivitiesScreen();
      case 1:
        return const Text('Groups');
      case 2:
        return const Text('Summary');
      default:
        return const Text('Unknown');
    }
  }

  Text getText() {
    switch (_selectedIndex) {
      case 0:
        return const Text('Active Activities');
      case 1:
        return const Text('Groups');
      case 2:
        return const Text('Summary');
      default:
        return const Text('Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent going back
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => Scaffold(
          appBar: AppBar(
            backgroundColor: themeProvider.themeData.colorScheme.inversePrimary,
            title: getText(),
            actions: [
//lets add a switch for dark and light mode
              IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
              PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: themeProvider.colorSeeds
                            .map((color) => ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  leading: Container(
                                    margin: const EdgeInsets.only(left: 30),
                                    width: 20,
                                    height: 20, //rounded rectangle
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    getColorName(color),
                                    // style: TextStyle(color: color),
                                  ),
                                  onTap: () {
                                    themeProvider.setColorSeed(color);
                                    Navigator.of(context).pop();
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: getScreen(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.track_changes_outlined),
                selectedIcon: Icon(Icons.track_changes),
                label: 'Active',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.summarize_outlined),
                selectedIcon: Icon(Icons.summarize),
                label: 'Summary',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//lets create a theme provider with a dark and light theme switch and list of colors for colorSeed

class ThemeProvider with ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  static const String COLOR_KEY = 'color_seed';

  late SharedPreferences _prefs;
  bool _isDarkMode = true;
  Color _colorSeed = Colors.blue;

  final List<Color> colorSeeds = [
    Colors.blue,
    Colors.indigoAccent,
    Colors.green,
    Colors.deepPurple,
    Colors.orange,
    Colors.teal,
  ];

  bool get isDarkMode => _isDarkMode;
  Color get colorSeed => _colorSeed;

  ThemeProvider() {
    _loadFromPrefs();
  }

  _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _isDarkMode = _prefs.getBool(THEME_KEY) ?? false;
    final colorIndex = _prefs.getInt(COLOR_KEY) ?? 0;
    _colorSeed = colorSeeds[colorIndex];
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    await _prefs.setBool(THEME_KEY, _isDarkMode);
    await _prefs.setInt(COLOR_KEY, colorSeeds.indexOf(_colorSeed));
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  void setColorSeed(Color color) {
    _colorSeed = color;
    _saveToPrefs();
    notifyListeners();
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      colorSchemeSeed: _colorSeed,
    );
  }
}

//other providers
