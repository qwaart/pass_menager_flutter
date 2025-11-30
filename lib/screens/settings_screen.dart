import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/pin_service.dart';
import '../theme/theme_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_package;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final PinService _pinService = PinService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('View'),
          SwitchListTile(
            title: const Text('Dark theme'),
            subtitle: const Text('Dark theme on'),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.deepPurple,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),

          // Section: Security
          _buildSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.pin, color: Colors.deepPurple),
            title: const Text('Change PIN'),
            subtitle: const Text('Change PIN-код for login'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePinDialog(),
          ),
          const Divider(),

          // Section: Data
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.green),
            title: const Text('Export database'),
            subtitle: const Text('Save backup passwords'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : () => _exportDatabase(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.orange),
            title: const Text('Clear all passwords'),
            subtitle: const Text('Delete all saved passwords'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearAllDialog(),
          ),
          const Divider(),

          // Section: About app
          _buildSectionHeader('About app'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text('Version'),
            subtitle: const Text('2.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('Author'),
            subtitle: const Text('me'),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: Colors.blue),
            title: const Text('Technologies'),
            subtitle: const Text('Flutter, SQLite, AES-256 encryption'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              decoration: const InputDecoration(
                labelText: 'Old PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm your new PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match!')),
                );
                return;
              }

              if (newPinController.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('The PIN must be 4 digits long!')),
                );
                return;
              }

              final success = await _pinService.changePin(
                oldPinController.text,
                newPinController.text,
              );

              Navigator.pop(dialogContext);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN successfully changed!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect old PIN!')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabase() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Get path to БД
      final dbPath = await getDatabasesPath();
      final dbFile = File(path_package.join(dbPath, 'passwords.db'));

      // Get a directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = path_package.join(directory.path, 'password_backup_$timestamp.db');

      // Copy file
      await dbFile.copy(backupPath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export successful!\nSave: $backupPath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Attention!'),
        content: const Text(
          'Are you sure you want to delete ALL saved passwords?\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearAllPasswords();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllPasswords() async {
    try {
      final passwords = await _db.getAllPasswords();
      for (final password in passwords) {
        await _db.deletePassword(password.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All passwords have been successfully deleted!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to the main screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deletion error: $e')),
      );
    }
  }
}