import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;

  // Initialization: key retrieval/generation
  Future<void> init() async {
    if (_encrypter != null) return;
    
    String? keyString = await _storage.read(key: 'master_key');
    if (keyString == null) {
      // Generate a new key (32 bytes for AES-256)
      keyString = encrypt.Key.fromSecureRandom(32).base64;
      await _storage.write(key: 'master_key', value: keyString);
    }
    final key = encrypt.Key.fromBase64(keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  // Text encryption
  // Format: “IV:EncryptedData” (store IV together with data)
  Future<String> encryptPassword(String plainText) async {
    await init();
    final encrypter = _encrypter!;
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Store IV and encrypted data together
    return '${iv.base64}:${encrypted.base64}';
  }

  // Text decryption
  Future<String> decryptPassword(String encryptedText) async {
    await init();
    final encrypter = _encrypter!;
    
    // Separate IV and encrypted data
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }
    
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Key cleanup (to log out of your account)
  Future<void> clearKey() async {
    await _storage.delete(key: 'master_key');
    _encrypter = null;
  }
}