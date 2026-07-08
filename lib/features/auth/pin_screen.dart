import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';

class PinScreen extends StatefulWidget {
  final Future<bool> Function(String pin) onSubmit;
  final String title;
  final String? subtitle;

  const PinScreen({
    super.key,
    required this.onSubmit,
    this.title = 'Inserisci PIN',
    this.subtitle,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _error = false;
  bool _loading = false;
  late AnimationController _shakeController;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _onDigit(String d) async {
    if (_loading || _entered.length >= _pinLength) return;
    final next = _entered + d;
    setState(() { _entered = next; _error = false; });

    if (next.length == _pinLength) {
      setState(() => _loading = true);
      final ok = await widget.onSubmit(next);
      if (!mounted) return;
      if (!ok) {
        _shakeController.forward(from: 0);
        setState(() { _entered = ''; _error = true; _loading = false; });
      }
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() { _entered = _entered.substring(0, _entered.length - 1); _error = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo / titolo
            const Icon(Icons.lock_outline, color: AppColors.primary, size: 48)
                .animate().scale(duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 20),
            Text(widget.title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700))
                .animate().fadeIn(duration: 300.ms, delay: 100.ms),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 40),

            // Dots
            AnimatedBuilder(
              animation: _shakeController,
              builder: (_, child) {
                final shake = (_shakeController.value < 0.5
                    ? _shakeController.value
                    : 1 - _shakeController.value) * 16 * ((_shakeController.value * 6).floor() % 2 == 0 ? 1 : -1);
                return Transform.translate(offset: Offset(shake, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  final color = _error ? AppColors.negative : AppColors.primary;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? color : Colors.transparent,
                      border: Border.all(color: filled ? color : AppColors.border, width: 2),
                    ),
                  );
                }),
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 12),
              const Text('PIN errato', style: TextStyle(color: AppColors.negative, fontSize: 13))
                  .animate().fadeIn(duration: 200.ms),
            ],

            const Spacer(),

            // Tastiera numerica
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72),
                      _DigitKey(label: '0', onTap: () => _onDigit('0')),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: _loading
                            ? const Center(child: SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                            : IconButton(
                                icon: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary),
                                onPressed: _onDelete,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _DigitKey(label: d, onTap: () => _onDigit(d))).toList(),
    );
  }
}

class _DigitKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DigitKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
