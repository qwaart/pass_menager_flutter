import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_entry.dart';
import 'encryption_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'passwords.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Створення таблиці
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE passwords (
        id TEXT PRIMARY KEY,
        site TEXT NOT NULL,
        username TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE passwords ADD COLUMN encrypted_password TEXT');
    }
  }

  // adding password
  Future<int> addPassword(PasswordEntry entry, String plainPassword) async {
    final encryption = EncryptionService();
    final encrypted = await encryption.encryptPassword(plainPassword);
    final encryptedEntry = PasswordEntry(
      id: entry.id,
      site: entry.site,
      username: entry.username,
      encryptedPassword: encrypted,
      createdAt: entry.createdAt,
    );

    final db = await database;
    return await db.insert('passwords', encryptedEntry.toMap());
  }

  // Get all passwords
  Future<List<PasswordEntry>> getAllPasswords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('passwords');
    return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
  }

  // Update passwords by id
  Future<int> updatePassword(PasswordEntry entry, String plainPassword) async {
    final encryption = EncryptionService();
    final encrypted = await encryption.encryptPassword(plainPassword);
    final encryptedEntry = PasswordEntry(
      id: entry.id,
      site: entry.site,
      username: entry.username,
      encryptedPassword: encrypted,
      createdAt: entry.createdAt,
    );
    final db = await database;
    return await db.update(
      'passwords',
      encryptedEntry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete password by id
  Future<int> deletePassword(String id) async {
    final db = await database;
    return await db.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close db
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}