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

  // Фільтрація паролів
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
              _loadPasswords();
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis, // Обрізає довгі назви з ...
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Login: ${entry.username}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text('Password: ●●●●●●●●'),
                                  Text(
                                    'Date: ${entry.createdAt.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                _showPasswordDetailsDialog(entry);
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

  void _showPasswordDetailsDialog(PasswordEntry entry) {
    bool showPassword = false;
    String? decryptedPassword;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Розшифровуємо пароль асинхронно
          if (decryptedPassword == null && showPassword) {
            _encryption.decryptPassword(entry.encryptedPassword).then((value) {
              setDialogState(() {
                decryptedPassword = value;
              });
            }).catchError((e) {
              decryptedPassword = 'Decryption error';
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.site,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    icon: Icons.language,
                    label: 'Site',
                    value: entry.site,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: entry.site));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Website copied!')),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDetailRow(
                    icon: Icons.person,
                    label: 'login',
                    value: entry.username,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: entry.username));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login copied!')),
                      );
                    },
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Пароль',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              showPassword
                                  ? (decryptedPassword ?? 'Loading...')
                                  : '●●●●●●●●●●',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            showPassword = !showPassword;
                            if (!showPassword) {
                              decryptedPassword = null;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.green),
                        onPressed: () async {
                          String passwordToCopy = decryptedPassword ?? '';
                          if (passwordToCopy.isEmpty) {
                            try {
                              passwordToCopy = await _encryption
                                  .decryptPassword(entry.encryptedPassword);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Decryption error')),
                              );
                              return;
                            }
                          }
                          await Clipboard.setData(
                              ClipboardData(text: passwordToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // Дата створення
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: entry.createdAt.toLocal().toString().split('.')[0],
                    showCopy: false,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showEditDialog(entry);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
    bool showCopy = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showCopy && onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.green, size: 20),
            onPressed: onCopy,
          ),
      ],
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
                    labelText: 'login',
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
                  label: const Text('Generate strong password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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

    _encryption
        .decryptPassword(originalEntry.encryptedPassword)
        .then((decrypted) {
      passwordController.text = decrypted;
    }).catchError((e) {
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
              child: const Text('Cancel'),
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