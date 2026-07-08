import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _keyPin = 'app_pin';
  static const _keyEnabled = 'pin_enabled';

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<bool> verify(String pin) async {
    final stored = await _storage.read(key: _keyPin);
    return stored == pin;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _keyPin, value: pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
  }

  Future<void> disable() async {
    await _storage.delete(key: _keyPin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
  }
}
