import 'package:uuid/uuid.dart';

class PasswordEntry {
	final String id;
	final String site;
	final String username;
	final String encryptedPassword;
	final DateTime createdAt;

	PasswordEntry({
		required this.id,
		required this.site,
		required this.username,
		required this.encryptedPassword,
		required this.createdAt,
	});

	// Constructor for fake data
	PasswordEntry.fake({
		required this.site,
		required this.username,
		required String plainPassword,
		String? id,
		DateTime? createdAt,
	})	: id = id ?? const Uuid().v4(), 
		createdAt = createdAt ?? DateTime.now(),
		encryptedPassword = ''; // encrypting in service

	// morph to Map for db (sqflite)
	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'site': site,
			'username': username,
			'encrypted_password': encryptedPassword,
			'createdAt': createdAt.toIso8601String(),
		};
	}

	// From Map to back(for reading)
	factory PasswordEntry.fromMap(Map<String, dynamic> map) {
		return PasswordEntry(
			id: map['id'],
			site: map['site'],
			username: map['username'],
			encryptedPassword: map['encrypted_password'],
			createdAt: DateTime.parse(map['createdAt']),
		);
	}
	
	// toString for debug
	@override
	String toString() {
		return 'PasswordEntry(site: $site, username: $username, createdAt: $createdAt)';
	}
}

