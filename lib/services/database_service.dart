import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_entry.dart';

class DatabaseService {
	static final DatabaseService _instanse = DatabaseService._internal();
	factory DatabaseService() => _instanse;
	DatabaseService._internal();

	Database? _database;

	Future<Database> get database async {
		if (_database != null) return _database!;
		_database = await _initDatabase();
		return _database!;
	}

	Future<Database> _initDatabase() async {
		// path to db
		String path = join(await getDatabasesPath(), 'password.db');

		return await openDatabase(
			path,
			version: 1,
			onCreate: _onCreate,
		);
	}

	// Creating a table
	Future<void> _onCreate(Database db, int version) async {
		await db.execute('''
			CREATE TABLE passwords (
				id TEXT PRIMARY KEY,
				site TEXT NOT NULL,
				username TEXT NOT NULL,
				password TEXT NOT NULL,
				createdAt TEXT NOT NULL
			)
		''');
	}

	// Addin a password
	Future<int> addPassword(PasswordEntry entry) async {
		final db = await database;
		return await db.insert('passwords', entry.toMap());
	}

	// get all passwords
	Future<List<PasswordEntry>>  getAllPasswords() async {
		final db = await database;
		final List<Map<String, dynamic>> maps = await db.query('passwords');
		return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
	}

	// Update password (by ID)
	Future<int> updatePassword(PasswordEntry entry) async {
		final db = await database;
		return await db.update(
			'passwords',
			entry.toMap(),
			where: 'id = ?',
			whereArgs: [entry.id],
		);
	}

	// Delete password (by ID)
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