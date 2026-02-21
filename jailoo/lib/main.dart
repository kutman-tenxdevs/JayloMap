import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/colors.dart';
import 'screens/map_screen.dart';
import 'screens/ai_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: JailooColors.bg,
    ),
  );
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: JailooColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: JailooColors.accent,
          surface: JailooColors.surface,
        ),
        fontFamily: 'DMMono',
        useMaterial3: true,
        dividerTheme: const DividerThemeData(
          color: JailooColors.border,
          thickness: 1,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: JailooColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          MapScreen(),
          AiScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: JailooColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: JailooColors.bg,
          indicatorColor: JailooColors.accent.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: JailooColors.textMuted, size: 20),
              selectedIcon: Icon(Icons.map, color: JailooColors.accent, size: 20),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: JailooColors.textMuted, size: 20),
              selectedIcon: Icon(Icons.auto_awesome, color: JailooColors.accent, size: 20),
              label: 'AI',
            ),
          ],
        ),
      ),
    );
  }
}
