import 'package:flutter/material.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  bool _googleContactsSync = false;
  bool _outlookSync = false;
  double _syncProgress = 0.0;
  bool _isSyncing = false;

  Future<void> _toggleGoogleSync(bool value) async {
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
    });

    // Simulate sync process
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _syncProgress = i / 100;
      });
    }

    setState(() {
      _googleContactsSync = value;
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Google Contacts synced successfully!'
              : 'Google Contacts disconnected',
        ),
      ),
    );
  }

  Future<void> _importCSV() async {
    // In a real app, this would open a file picker
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV import coming soon!')));
  }

  Future<void> _exportContacts() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacts exported successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Integrations'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect Your Accounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync your contacts across platforms',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Google Contacts
            _buildIntegrationCard(
              icon: Icons.contacts,
              title: 'Google Contacts',
              description: 'Sync contacts with Google',
              isConnected: _googleContactsSync,
              onToggle: (value) => _toggleGoogleSync(value),
              color: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 16),
            // Outlook
            _buildIntegrationCard(
              icon: Icons.email,
              title: 'Microsoft Outlook',
              description: 'Sync with Outlook contacts',
              isConnected: _outlookSync,
              onToggle: (value) {
                setState(() {
                  _outlookSync = value;
                });
              },
              color: const Color(0xFF0078D4),
            ),
            if (_isSyncing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1A1B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2B292A)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Syncing contacts...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_syncProgress * 100).toInt()}% complete',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _syncProgress,
                      backgroundColor: const Color(0xFF2B292A),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Import / Export',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.upload_file,
              title: 'Import CSV',
              description: 'Import contacts from CSV file',
              onTap: _importCSV,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.download,
              title: 'Export vCard',
              description: 'Export all contacts as vCard',
              onTap: _exportContacts,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.file_download,
              title: 'Export CSV',
              description: 'Export contacts to CSV file',
              onTap: _exportContacts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isConnected,
    required Function(bool) onToggle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color : const Color(0xFF2B292A),
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                if (isConnected) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Connected',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: isConnected, onChanged: onToggle, activeColor: color),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B292A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
