import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_theme.dart';
import '../settings/settings_api_keys_screen.dart';
import '../transactions/transactions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  static const _prefKey = 'onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primary,
      title: 'Benvenuto in Logicash',
      body: 'La tua app per gestire le finanze personali con l\'aiuto '
          'dell\'intelligenza artificiale. Bastano due passaggi per iniziare.',
    ),
    _OnboardingPageData(
      icon: Icons.key_outlined,
      color: AppColors.primary,
      title: 'Aggiungi una chiave API',
      body: 'Logicash usa Gemini (gratuito) per generare insight, previsioni '
          'e rispondere alle tue domande in chat. Aggiungi la tua chiave API '
          'per sbloccare l\'assistente Logi.',
      actionLabel: 'Aggiungi chiave API',
    ),
    _OnboardingPageData(
      icon: Icons.upload_file_outlined,
      color: AppColors.positive,
      title: 'Importa il tuo estratto conto',
      body: 'Carica un file Excel o CSV del tuo conto corrente: Logicash '
          'riconosce automaticamente entrate, uscite e categorie per '
          'iniziare l\'analisi.',
      actionLabel: 'Importa estratto conto',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen._prefKey, true);
    widget.onDone();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeOut);
    } else {
      _complete();
    }
  }

  void _onAction(_OnboardingPageData page) {
    if (page.actionLabel == 'Aggiungi chiave API') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsApiKeysScreen()));
    } else if (page.actionLabel == 'Importa estratto conto') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('Salta',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardingPage(
                  data: _pages[i],
                  onAction: () => _onAction(_pages[i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Inizia ad usare l\'app' : 'Avanti'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? actionLabel;
  const _OnboardingPageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.actionLabel,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final VoidCallback onAction;
  const _OnboardingPage({required this.data, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(data.icon, color: data.color, size: 56),
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
          if (data.actionLabel != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAction,
              child: Text(data.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

extension on int {
  Duration get ms => Duration(milliseconds: this);
}
