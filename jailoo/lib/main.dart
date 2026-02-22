import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/colors.dart';
import 'theme/theme_provider.dart';
import 'screens/map_screen.dart';
import 'screens/ai_screen.dart';
import 'services/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppController()),
      ],
      child: const JailooApp(),
    ),
  );
}

class JailooApp extends StatelessWidget {
  const JailooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final lightColors = JailooColors.light;
    final darkColors = JailooColors.dark;

    return MaterialApp(
      title: 'Jailoo',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.mode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightColors.bg,
        colorScheme: ColorScheme.light(
          primary: lightColors.accent,
          surface: lightColors.surface,
        ),
        fontFamily: 'DMMono',
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkColors.bg,
        colorScheme: ColorScheme.dark(
          primary: darkColors.accent,
          surface: darkColors.surface,
        ),
        fontFamily: 'DMMono',
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
  @override
  Widget build(BuildContext context) {
    final c = JailooColors.of(context);
    final ctrl = context.watch<AppController>();
    final tab = ctrl.tab;

    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [
          MapScreen(),
          AiScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => context.read<AppController>().goToMap()..then((_) {}) == null
              ? null
              : context.read<AppController>()._tab == i
                  ? null
                  : context.read<AppController>().goToMap(),
          backgroundColor: c.bg,
          indicatorColor: c.accent.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: c.bg,
          indicatorColor: c.accent.withValues(alpha: 0.12),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: c.textMuted, size: 20),
              selectedIcon: Icon(Icons.map, color: c.accent, size: 20),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: c.textMuted, size: 20),
              selectedIcon: Icon(Icons.auto_awesome, color: c.accent, size: 20),
              label: 'AI',
            ),
          ],
        ),
      ),
    );
  }
}
