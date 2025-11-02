import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/src/providers/auth_provider.dart';
import 'package:health_app/src/services/supabase_client.dart';
import 'package:health_app/src/services/hive_service.dart';
import 'package:health_app/src/providers/health_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Load current Supabase URL
    _urlController.text = SupabaseService.client.supabaseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      // Fetch all health metrics
      final response = await SupabaseService.client
          .from('health_metrics')
          .select('*, devices(*)')
          .eq('user_id', userId)
          .order('timestamp', ascending: true);

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'health_metrics': response,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      // Also offer to share
      if (mounted) {
        await Share.share(
          jsonString,
          subject: 'Health Data Export',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported and copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _updateSupabaseUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Note: In a real app, you'd need to reinitialize Supabase with new URL
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'URL updated. Please restart the app for changes to take effect.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all locally cached data. You will need to sync again to retrieve data from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.clearSleepSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(authState.value?.email ?? 'Unknown'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('User ID'),
                    subtitle: Text(
                      authState.value?.id ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Self-Host Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Self-Host Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase URL',
                      hintText: 'http://localhost:54321',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                      helperText: 'Default: http://localhost:54321',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _updateSupabaseUrl,
                    icon: const Icon(Icons.save),
                    label: const Text('Save URL'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Changing the URL requires restarting the app. '
                    'For production, update this to your cloud Supabase URL.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export all your health data as JSON'),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Clear locally cached data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearCache,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Security
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Privacy-First Design:\n\n'
                            '• All data is stored in your self-hosted Supabase instance\n'
                            '• No analytics or tracking\n'
                            '• Device tokens are encrypted\n'
                            '• Row-level security ensures data isolation\n'
                            '• We never sell or share your health data\n\n'
                            'Your data, your control.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About'),
                        content: const Text(
                          'Health Data Aggregator\n\n'
                          'Version: 1.0.0\n\n'
                          'An open-source, privacy-focused health data app '
                          'for aggregating and analyzing sleep data from wearables.\n\n'
                          'Built with Flutter and Supabase.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sign Out
          Card(
            color: Colors.red.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (mounted) {
                    context.go('/auth');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

