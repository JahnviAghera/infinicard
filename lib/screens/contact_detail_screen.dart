import 'package:flutter/material.dart';
import 'package:infinicard/models/contact_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late TextEditingController _notesController;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.contact.notes);
    _reminderDate = widget.contact.reminderDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _makeCall() async {
    final phoneNumber = widget.contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone calls on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final phoneNumber = widget.contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot send messages on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final email = widget.contact.email;
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Hello from Infinicard',
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A1B),
        title: const Text(
          'Delete Contact',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.contact.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Contact deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Color(0xFF1C1A1B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Contact Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit contact
            },
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteContact),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1A1B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.contact.avatarUrl != null
                        ? NetworkImage(widget.contact.avatarUrl!)
                        : null,
                    backgroundColor: const Color(0xFF2B292A),
                    child: widget.contact.avatarUrl == null
                        ? Text(
                            widget.contact.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.contact.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.contact.title,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                  if (widget.contact.company.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.contact.company,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.message,
                        label: 'Message',
                        onTap: _sendMessage,
                      ),
                      _buildActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        onTap: _makeCall,
                      ),
                      _buildActionButton(
                        icon: Icons.email,
                        label: 'Email',
                        onTap: _sendEmail,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contact Information
            _buildSection(
              title: 'Contact Information',
              children: [
                _buildInfoRow(Icons.phone, 'Phone', widget.contact.phone),
                _buildInfoRow(Icons.email, 'Email', widget.contact.email),
                if (widget.contact.website.isNotEmpty)
                  _buildInfoRow(
                    Icons.language,
                    'Website',
                    widget.contact.website,
                  ),
                if (widget.contact.linkedIn.isNotEmpty)
                  _buildInfoRow(
                    Icons.link,
                    'LinkedIn',
                    widget.contact.linkedIn,
                  ),
                if (widget.contact.github.isNotEmpty)
                  _buildInfoRow(Icons.code, 'GitHub', widget.contact.github),
              ],
            ),
            // Tags
            if (widget.contact.tags.isNotEmpty)
              _buildSection(
                title: 'Tags',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.contact.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFF1E88E5),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ],
              ),
            // Notes Section
            _buildSection(
              title: 'Notes',
              children: [
                TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Add notes about this contact...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1C1A1B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2B292A)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickReminderDate,
                        icon: const Icon(Icons.notifications),
                        label: Text(
                          _reminderDate == null
                              ? 'Set Reminder'
                              : 'Reminder: ${_reminderDate!.month}/${_reminderDate!.day}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C1A1B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2B292A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
