import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/series_screen.dart';
import 'screens/read_screen.dart';
import 'screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? token;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.token,
  });

  static _MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainNavigationScreenState>();
  }

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  int _seriesScreenKey = 0; // 🔑 Add a key counter for SeriesScreen

  // Navigator keys for each tab
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // 🔄 Method to refresh SeriesScreen
  void refreshSeriesScreen() {
    setState(() {
      _seriesScreenKey++; // Increment key to force rebuild
    });
  }

  // Bottom tab tap handler
  void changeTab(int index) {
    if (index == _currentIndex) {
      // If same tab tapped → pop to root
      final navigator = _tabNavigatorKeys[index].currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }

      // 🔄 REFRESH SERIES SCREEN WHEN TAB IS TAPPED AGAIN
      if (index == 1) { // Resources/Series tab index
        refreshSeriesScreen();
      }

      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // 🔄 REFRESH SERIES SCREEN WHEN NAVIGATING TO IT
    if (index == 1) { // Resources/Series tab index
      refreshSeriesScreen();
    }
  }

  // Push screen inside current tab
  Future<void> pushScreen(Widget screen) async {
    await _tabNavigatorKeys[_currentIndex]
        .currentState
        ?.push(MaterialPageRoute(builder: (_) => screen));
  }

  // Android back button behavior
  bool handleTabBackButton() {
    final navigator = _tabNavigatorKeys[_currentIndex].currentState;

    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !handleTabBackButton(),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            4,
                (index) => Navigator(
              key: _tabNavigatorKeys[index],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => _getScreenForIndex(index),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFe53935),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_outlined),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Get screen for index with ability to refresh
  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return SeriesScreen(
          key: ValueKey('series_screen_$_seriesScreenKey'), // 🔑 Use dynamic key
        );
      case 2:
        return const ReadScreen();
      case 3:
        return const ProfileScreen(); // Remove onSeriesUpdated parameter
      default:
        return const HomeScreen();
    }
  }
}