import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/password_generator_service.dart';
import '../services/encryption_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final EncryptionService _encryption = EncryptionService();
  final PasswordGeneratorService _generator = PasswordGeneratorService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _encryption.init();
    _loadPasswords();
    _searchController.addListener(_filterPasswords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Password filtering
  void _filterPasswords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPasswords = _passwords;
      } else {
        _filteredPasswords = _passwords
            .where((entry) =>
                entry.site.toLowerCase().contains(query) ||
                entry.username.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // Loading passwords from the database
  Future<void> _loadPasswords() async {
    final passwords = await _db.getAllPasswords();
    setState(() {
      _passwords = passwords;
      _filteredPasswords = passwords;
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // We reset passwords after returning from settings
              _loadPasswords();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          if (_passwords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          // Password list
          Expanded(
            child: _passwords.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'You have not passwords.\nAdd your first password!',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _filteredPasswords.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPasswords.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredPasswords[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple[100],
                                child: const Icon(Icons.lock,
                                    color: Colors.deepPurple),
                              ),
                              title: Text(
                                entry.site,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Login: ${entry.username}'),
                                  const Text('Password: ●●●●●●●●'),
                                  Text(
                                    'Дата: ${entry.createdAt.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                try {
                                  final decrypted = await _encryption
                                      .decryptPassword(entry.encryptedPassword);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Password for ${entry.site}: $decrypted'),
                                      duration: const Duration(seconds: 5),
                                      action: SnackBarAction(
                                        label: 'Copy',
                                        onPressed: () async {
                                          await Clipboard.setData(
                                              ClipboardData(text: decrypted));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Copied!')),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Decryption error: $e')),
                                  );
                                }
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.green),
                                    tooltip: 'Copy password',
                                    onPressed: () async {
                                      try {
                                        final decrypted = await _encryption
                                            .decryptPassword(entry.encryptedPassword);
                                        await Clipboard.setData(
                                            ClipboardData(text: decrypted));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Password copied!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    tooltip: 'Edit',
                                    onPressed: () {
                                      _showEditDialog(entry);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      await _db.deletePassword(entry.id);
                                      _loadPasswords();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Password deleted!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: siteController,
                  decoration: const InputDecoration(
                    labelText: 'Site/Service',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Login',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscurePassword = !obscurePassword),
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
                  label: const Text('Gnerate strong password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cencel'),
            ),
            TextButton(
              onPressed: () async {
                if (siteController.text.isEmpty ||
                    usernameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fill in all fields!')),
                  );
                  return;
                }

                final entry = PasswordEntry.fake(
                  site: siteController.text,
                  username: usernameController.text,
                  plainPassword: passwordController.text,
                );
                await _db.addPassword(entry, passwordController.text);
                _loadPasswords();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password added!')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(PasswordEntry originalEntry) {
    final siteController = TextEditingController(text: originalEntry.site);
    final usernameController =
        TextEditingController(text: originalEntry.username);
    final passwordController = TextEditingController();

    bool obscurePassword = true;

      // Password decryption
    _encryption
        .decryptPassword(originalEntry.encryptedPassword)
        .then((decrypted) {
      passwordController.text = decrypted;
    }).catchError((e) {
      // Decryption error
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: siteController,
                  decoration: const InputDecoration(
                    labelText: 'Site/Service',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Login',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
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
                  label: const Text('Generate strong password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cencel'),
            ),
            TextButton(
              onPressed: () async {
                if (siteController.text.isEmpty ||
                    usernameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fill in all fields!')),
                  );
                  return;
                }

                final entry = PasswordEntry(
                  id: originalEntry.id,
                  site: siteController.text,
                  username: usernameController.text,
                  encryptedPassword: '',
                  createdAt: originalEntry.createdAt,
                );
                await _db.updatePassword(entry, passwordController.text);
                _loadPasswords();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}