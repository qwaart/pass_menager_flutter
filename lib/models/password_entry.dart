import 'package:uuid/uuid.dart';

class PasswordEntry {
	final String id;
	final String site;
	final String username;
	final String password;
	final DateTime createdAt;

	PasswordEntry({
		required this.id,
		required this.site,
		required this.username,
		required this.password,
		required this.createdAt,
	});

	// Constructor for fake data
	PasswordEntry.fake({
		required this.site,
		required this.username,
		required this.password,
		String? id,
		DateTime? createdAt,
	})	: id = id ?? const Uuid().v4(), 
		createdAt = createdAt ?? DateTime.now();

	// morph to Map for db (sqflite)
	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'site': site,
			'username': username,
			'password': password, // i`ll encrypt it later
			'createdAt': createdAt.toIso8601String(),
		};
	}

	// From Map to back(for reading)
	factory PasswordEntry.fromMap(Map<String, dynamic> map) {
		return PasswordEntry(
			id: map['id'],
			site: map['site'],
			username: map['username'],
			password: map['password'],
			createdAt: DateTime.parse(map['createdAt']),
		);
	}
	
	// toString for debug
	@override
	String toString() {
		return 'PasswordEntry(site: $site, username: $username, createdAt: $createdAt)';
	}
}

