import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/expenses/expenses_screen.dart';
import 'features/fixed_expenses/fixed_expenses_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/settings/settings_menu_screen.dart';
import 'features/auth/pin_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'core/update/update_service.dart';
import 'core/update/update_dialog.dart';

class LogicashApp extends StatelessWidget {
  const LogicashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Logicash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _StartupGate(),
        routes: {
          '/home': (_) => const MainShell(),
          '/transactions': (_) => const TransactionsScreen(),
          '/settings': (_) => const SettingsMenuScreen(),
          '/chat': (_) => const ChatScreen(),
        },
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    OnboardingScreen.isComplete().then((done) {
      if (mounted) setState(() => _onboardingComplete = done);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (!_onboardingComplete!) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboardingComplete = true),
      );
    }
    return const _AppGate();
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final provider = context.read<AppProvider>();
    final enabled = await provider.isPinEnabled;
    if (!mounted) return;
    if (!enabled) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
    // se PIN attivo, rimane su _AppGate che mostra PinScreen
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<AppProvider>().isPinEnabled,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (!snap.data!) return const Scaffold(backgroundColor: AppColors.background);

        return PinScreen(
          title: 'Logicash',
          subtitle: 'Inserisci il PIN per accedere',
          onSubmit: (pin) async {
            final nav = Navigator.of(context);
            final ok = await context.read<AppProvider>().verifyPin(pin);
            if (ok && mounted) nav.pushReplacementNamed('/home');
            return ok;
          },
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
      useSafeArea: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => UpdateDialog(info: info),
      );
    }
  }

  final _screens = const [
    DashboardScreen(),
    ExpensesScreen(),
    GoalsScreen(),
    FixedExpensesScreen(),
  ];

  final _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Spese'),
    BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), activeIcon: Icon(Icons.flag), label: 'Obiettivi'),
    BottomNavigationBarItem(icon: Icon(Icons.lock_clock_outlined), activeIcon: Icon(Icons.lock_clock), label: 'Spese Fisse'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/chat'),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
