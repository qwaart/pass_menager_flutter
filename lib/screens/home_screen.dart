import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
	@override

	_HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
	final DatabaseService _db = DatabaseService();
	List<PasswordEntry> _passwords = [];

	@override
	void initState() {
		super.initState();
		_loadPasswords();
	}

	// Load passwords from db
	Future<void> _loadPasswords() async {
		final passwords = await _db.getAllPasswords();
		setState(() {
			_passwords = passwords;
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text('Passwords'),
				backgroundColor: Theme.of(context).colorScheme.inversePrimary,
				actions: [
					IconButton(
						icon: const Icon(Icons.settings),
						onPressed: () {
							// Nothing now, but for future auth
							ScaffoldMessenger.of(context).showSnackBar(
								const SnackBar(content: Text('Setting (soon)')),
							);
						},
					),
				],
			),
			body: _passwords.isEmpty
				? const Center(
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(Icons.lock_outline, size: 64, color: Colors.grey),
							SizedBox(height: 16),
							Text('You have not passwords. Add your first password!', style: TextStyle(fontSize: 18)),
						],
					),
				)
				: ListView.builder(
					itemCount: _passwords.length,
					itemBuilder: (context, index) {
						final entry = _passwords[index];
						return Card(
							margin: const EdgeInsets.all(8),
							child: ListTile(
								leading: const Icon(Icons.lock, color: Colors.deepPurple),
								title: Text(entry.site),
								subtitle: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text('Login: ${entry.username}'),
										Text('Date: ${entry.createdAt.toLocal().toString().split(' ')[0]}'), // Only date
									],
								),
								trailing: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										IconButton(
											icon: const Icon(Icons.edit, color: Colors.black),
											onPressed: () {
												_showEditDialog(entry);
											},
										),
										IconButton(
											icon: const Icon(Icons.delete, color: Colors.red),
											onPressed: () async {
												await _db.deletePassword(entry.id);
												_loadPasswords(); // reload list
												ScaffoldMessenger.of(context).showSnackBar(
													const SnackBar(content: Text('Password deleted!')),
												);
											},
										),
									],
								),
							),
						);
					},
				),
			floatingActionButton: FloatingActionButton(
				onPressed: () => _showAddDialog(),
				child: const Icon(Icons.add),
			),
		);
	}

	void _showAddDialog() {
		final siteController = TextEditingController();
		final usernameController = TextEditingController();
		final passwordController = TextEditingController();

		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Add password'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: siteController,
							decoration: const InputDecoration(labelText: 'Site'),
						),
						TextField(
							controller: usernameController,
							decoration: const InputDecoration(labelText: 'Login')
						),
						TextField(
							controller: passwordController,
							decoration: const InputDecoration(labelText: 'Password'),
							obscureText: true,
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel')
					),
					TextButton(
						onPressed: () async {
							if (siteController.text.isNotEmpty && usernameController.text.isNotEmpty) {
								final entry = PasswordEntry.fake(
									site: siteController.text,
									username: usernameController.text,
									password: passwordController.text,
								);
								await _db.addPassword(entry);
								_loadPasswords();
								Navigator.pop(context);
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(content: Text('Password added!')),
								);
							}
						},
						child: const Text('Add')
					),
				],
			),
		);
	}

	void _showEditDialog(PasswordEntry originalEntry) {
		final siteController = TextEditingController(text: originalEntry.site);
		final usernameController = TextEditingController(text: originalEntry.username);
		final passwordController = TextEditingController(text: originalEntry.password);

		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Edit password'),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: siteController,
							decoration: const InputDecoration(labelText: 'Site'),
						),
						TextField(
							controller: usernameController,
							decoration: const InputDecoration(labelText: 'Login')
						),
						TextField(
							controller: passwordController,
							decoration: const InputDecoration(labelText: 'Password'),
							obscureText: true,
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel')
					),
					TextButton(
						onPressed: () async {
							if (siteController.text.isNotEmpty && usernameController.text.isNotEmpty) {
								final entry = PasswordEntry.fake(
									id: originalEntry.id,
									site: siteController.text,
									username: usernameController.text,
									password: passwordController.text,
									createdAt: originalEntry.createdAt,
								);
								await _db.updatePassword(entry);
								_loadPasswords();
								Navigator.pop(context);
							}
						},
						child: const Text('Save')
					),
				],
			),
		);
	} //
}