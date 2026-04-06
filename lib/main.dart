import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/gastos_screen.dart';
import 'screens/estadisticas_screen.dart';
import 'screens/vencimientos_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: FletarApp()));
}

class FletarApp extends ConsumerStatefulWidget {
  const FletarApp({super.key});

  @override
  ConsumerState<FletarApp> createState() => _FletarAppState();
}

class _FletarAppState extends ConsumerState<FletarApp> {
  @override
  void initState() {
    super.initState();
    ref.read(authStateProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Fletar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: isAuthenticated ? const MainScreen() : const LoginScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/gastos': (context) => const GastosScreen(),
      },
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_navIndex);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          GastosScreen(),
          EstadisticasScreen(),
          VencimientosScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(_navIndex.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Vencimientos'),
        ],
      ),
    );
  }
}

final _navIndex = StateProvider<int>((ref) => 0);
