import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'screens/map_screen.dart';
import 'screens/ai_screen.dart';

void main() {
  runApp(const JailooApp());
}

class JailooApp extends StatelessWidget {
  const JailooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jailoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DMMono',
        scaffoldBackgroundColor: JailooColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: JailooColors.healthy,
          surface: JailooColors.surface,
        ),
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JailooColors.surface,
      body: IndexedStack(
        index: _index,
        children: const [
          MapScreen(),
          AiScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF111811),
        selectedItemColor: const Color(0xFF2ECC71),
        unselectedItemColor: const Color(0xFF7A9A7A),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}
