import 'package:flutter/material.dart';
import 'package:infinicard/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _privacyLevel = 'Connections';
  String _cloudProvider = 'Firebase';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Settings & Security'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1A1B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF2B292A),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jahnvi Aghera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'jahnviaghera@gmail.com',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                    onPressed: () {
                      // Edit profile
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Appearance',
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Toggle dark/light theme',
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privacy',
              children: [
                _buildDropdownTile(
                  icon: Icons.lock,
                  title: 'Privacy Level',
                  value: _privacyLevel,
                  items: ['Public', 'Connections', 'Private'],
                  onChanged: (value) {
                    setState(() {
                      _privacyLevel = value!;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Cloud Storage',
              children: [
                _buildDropdownTile(
                  icon: Icons.cloud,
                  title: 'Storage Provider',
                  value: _cloudProvider,
                  items: ['Firebase', 'AWS', 'Azure'],
                  onChanged: (value) {
                    setState(() {
                      _cloudProvider = value!;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'App Info',
              children: [
                _buildInfoTile(
                  icon: Icons.info,
                  title: 'Version',
                  subtitle: '1.0.0 (Build 1)',
                ),
                _buildTile(
                  icon: Icons.feedback,
                  title: 'Send Feedback',
                  onTap: () {
                    // Send feedback
                  },
                ),
                _buildTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pushNamed(context, '/help');
                  },
                ),
                _buildTile(
                  icon: Icons.school,
                  title: 'View App Walkthrough',
                  onTap: () {
                    Navigator.pushNamed(context, '/walkthrough');
                  },
                ),
                _buildTile(
                  icon: Icons.description,
                  title: 'About',
                  onTap: () {
                    Navigator.pushNamed(context, '/about');
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Account',
              children: [
                _buildTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1C1A1B),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Logout logic
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            // Account Actions Section
            _buildSection(
              title: 'Account',
              children: [
                _buildTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  onTap: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1C1A1B),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      // Perform logout
                      final apiService = ApiService();
                      await apiService.logout();

                      if (mounted) {
                        // Navigate to login screen
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You have been logged out'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B292A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: titleColor ?? const Color(0xFF1E88E5),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.white, fontSize: 16),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[600],
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B292A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B292A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400], fontSize: 14),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E88E5),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B292A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1C1A1B),
        underline: Container(),
        style: TextStyle(color: Colors.grey[400]),
        items: items.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
