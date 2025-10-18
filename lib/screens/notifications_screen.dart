import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = ApiService().getNotifications();
  }

  void _markAllAsRead() async {
    final notifications = await _notificationsFuture;
    for (var n in notifications) {
      if (n['is_read'] == false) {
        await ApiService().markNotificationAsRead(n['id']);
      }
    }
    setState(() {
      _notificationsFuture = ApiService().getNotifications();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  void _clearAll() async {
    final notifications = await _notificationsFuture;
    for (var n in notifications) {
      await ApiService().deleteNotification(n['id']);
    }
    setState(() {
      _notificationsFuture = ApiService().getNotifications();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                title: Text(n['message'] ?? ''),
                subtitle: Text(n['type'] ?? ''),
                trailing: n['is_read'] == true
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(
                        Icons.notifications_active,
                        color: Colors.orange,
                      ),
                onTap: () async {
                  if (n['is_read'] == false) {
                    await ApiService().markNotificationAsRead(n['id']);
                    setState(() {
                      _notificationsFuture = ApiService().getNotifications();
                    });
                  }
                },
                onLongPress: () async {
                  await ApiService().deleteNotification(n['id']);
                  setState(() {
                    _notificationsFuture = ApiService().getNotifications();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
