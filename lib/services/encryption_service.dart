import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;

  Future<void> init() async {
    if (_encrypter != null) return;
    
    String? keyString = await _storage.read(key: 'master_key');
    if (keyString == null) {
      keyString = encrypt.Key.fromSecureRandom(32).base64;
      await _storage.write(key: 'master_key', value: keyString);
    }
    final key = encrypt.Key.fromBase64(keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  Future<String> encryptPassword(String plainText) async {
    await init();
    final encrypter = _encrypter!;
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return '${iv.base64}:${encrypted.base64}';
  }


  Future<String> decryptPassword(String encryptedText) async {
    await init();
    final encrypter = _encrypter!;
    

    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }
    
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> clearKey() async {
    await _storage.delete(key: 'master_key');
    _encrypter = null;
  }
}