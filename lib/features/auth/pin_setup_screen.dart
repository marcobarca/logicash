import 'package:flutter/material.dart';
import 'pin_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final Future<void> Function(String pin) onConfirmed;
  final bool isChange;

  const PinSetupScreen({
    super.key,
    required this.onConfirmed,
    this.isChange = false,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstPin;

  @override
  Widget build(BuildContext context) {
    if (_firstPin == null) {
      return PinScreen(
        key: const ValueKey('step1'),
        title: widget.isChange ? 'Nuovo PIN' : 'Crea PIN',
        subtitle: 'Scegli un PIN a 4 cifre',
        onSubmit: (pin) async {
          setState(() => _firstPin = pin);
          return true;
        },
      );
    }

    return PinScreen(
      key: const ValueKey('step2'),
      title: 'Conferma PIN',
      subtitle: 'Reinserisci il PIN scelto',
      onSubmit: (pin) async {
        if (pin == _firstPin) {
          await widget.onConfirmed(pin);
          if (context.mounted) Navigator.of(context).pop();
          return true;
        }
        setState(() => _firstPin = null);
        return false;
      },
    );
  }
}
