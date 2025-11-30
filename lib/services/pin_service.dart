import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _pinKey = 'user_pin_hash';
  static const String _pinSetKey = 'pin_is_set';

  // PIN hashing (for secure storage)
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Checking if a PIN has been set
  Future<bool> isPinSet() async {
    final isSet = await _storage.read(key: _pinSetKey);
    return isSet == 'true';
  }

  // Setting a new PIN
  Future<void> setPin(String pin) async {
    if (pin.length != 4) {
      throw Exception('The PIN must be 4 digits long.');
    }
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashedPin);
    await _storage.write(key: _pinSetKey, value: 'true');
  }

  // PIN verification
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPin(pin);
    return inputHash == storedHash;
  }

  // Change PIN (old PIN required for confirmation)
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) {
      return false;
    }
    await setPin(newPin);
    return true;
  }

  // Deleting the PIN (for reset)
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
  }
}