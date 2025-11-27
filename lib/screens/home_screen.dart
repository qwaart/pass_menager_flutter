import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/password_generator_service.dart';
import '../services/encryption_service.dart';

class HomeScreen extends StatefulWidget {
	@override
	_HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
	final DatabaseService _db = DatabaseService();
	final EncryptionService _encryption = EncryptionService();
	final PasswordGeneratorService _generator = PasswordGeneratorService();
	List<PasswordEntry> _passwords = [];

	@override
	void initState() {
		super.initState();
		_encryption.init();
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
				title: const Text('Passwords'),
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
										const Text('Password: ***'),
										Text('Date: ${entry.createdAt.toLocal().toString().split(' ')[0]}'), // Only date
									],
								),
								onTap: () async {
									try {
										final decrypted = await _encryption.decryptPassword(entry.encryptedPassword);

										final scaffoldContext = ScaffoldMessenger.of(context);

										scaffoldContext.showSnackBar(
											SnackBar(
												content: Text('Password for ${entry.site}: $decrypted'),
												duration: const Duration(seconds: 5),
												action: SnackBarAction(
													label: 'Copy',
													onPressed: () async {
														await Clipboard.setData(ClipboardData(text: decrypted));
													},
												),
											),
										);
									} catch (e) {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(content: Text('Error decrypting')),
										);
									}
								},
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
										//IconButton(
										//	icon: const Icon(Icons.copy, color: Colors.black)
										//)
									],
								),
							), //
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

		bool obscurePassword = true;

		//final generator = PasswordGeneratorService();

		showDialog(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialogState) => AlertDialog(
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
								obscureText: obscurePassword,
								decoration: InputDecoration(
									labelText: 'Password',
									suffixIcon: IconButton(
										icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
										onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
									),
								),
							),
							const SizedBox(height: 8),
							TextButton.icon(
								onPressed: () {
									final generated = _generator.generateStrongPassword();
									passwordController.text = generated;
									setDialogState(() {}); //update UI
								},
								icon: const Icon(Icons.autorenew, size: 16),
								label: const Text('Generate strong password'),
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
								final plainPassword = passwordController.text.isNotEmpty ? passwordController.text : 'default';
								if (siteController.text.isNotEmpty && usernameController.text.isNotEmpty) {
									final entry = PasswordEntry.fake(
										site: siteController.text,
										username: usernameController.text,
										plainPassword: plainPassword,
									);
									await _db.addPassword(entry, plainPassword);
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
			),
		);
	}

	void _showEditDialog(PasswordEntry originalEntry) {
		final siteController = TextEditingController(text: originalEntry.site);
		final usernameController = TextEditingController(text: originalEntry.username);
		final passwordController = TextEditingController();

		bool obscurePassword = true;

		//final generator = PasswordGeneratorService();

		// decrypt and entry password async
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			try {
				final decrypted = await _encryption.decryptPassword(originalEntry.encryptedPassword);
				passwordController.text = decrypted;
			} catch (e) {
				// empty
			}
			setState(() {});
		});

		showDialog(
			context: context,
			builder: (context) => StatefulBuilder(
				builder: (context, setDialogState) => AlertDialog(
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
								obscureText: obscurePassword,
								decoration: InputDecoration(
									labelText: 'Password',
									suffixIcon: IconButton(
										icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
										onPressed: () {
											setDialogState(() {
												obscurePassword = !obscurePassword;
											});
										},
									),
								),
							),
							const SizedBox(height: 8),
							TextButton.icon(
								onPressed: () {
									final generated = _generator.generateStrongPassword();
									passwordController.text = generated;
									setDialogState(() {});
								},
								icon: const Icon(Icons.autorenew, size: 16),
								label: const Text('Generate strong password')
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
								final plainPassword = passwordController.text.isNotEmpty ? passwordController.text : 'default';
								if (siteController.text.isNotEmpty && usernameController.text.isNotEmpty) {
									final entry = PasswordEntry(
										id: originalEntry.id,
										site: siteController.text,
										username: usernameController.text,
										encryptedPassword: '',
										createdAt: originalEntry.createdAt,
									);
									await _db.updatePassword(entry, plainPassword);
									_loadPasswords();
									Navigator.pop(context);
									ScaffoldMessenger.of(context).showSnackBar(
										const SnackBar(content: Text('Password updated'))
									);
								}
							},
							child: const Text('Save')
						),
					],
				),
			),
		);
	}
}