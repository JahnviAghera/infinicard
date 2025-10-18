import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'type': 'share',
        'icon': Icons.share,
        'color': const Color(0xFF2196F3),
        'title': 'Shared business card',
        'description': 'Shared with Sarah Williams via QR code',
        'time': '10 minutes ago',
      },
      {
        'type': 'edit',
        'icon': Icons.edit,
        'color': const Color(0xFF9C27B0),
        'title': 'Updated card',
        'description': 'Changed title to Senior Product Manager',
        'time': '2 hours ago',
      },
      {
        'type': 'connection',
        'icon': Icons.person_add,
        'color': const Color(0xFF4CAF50),
        'title': 'New connection',
        'description': 'Connected with Michael Chen',
        'time': '5 hours ago',
      },
      {
        'type': 'scan',
        'icon': Icons.qr_code_scanner,
        'color': const Color(0xFFFF9800),
        'title': 'Scanned business card',
        'description': 'Added contact: David Kumar',
        'time': '1 day ago',
      },
      {
        'type': 'create',
        'icon': Icons.add_circle,
        'color': const Color(0xFF00BCD4),
        'title': 'Created new card',
        'description': 'Created personal business card',
        'time': '2 days ago',
      },
      {
        'type': 'reward',
        'icon': Icons.stars,
        'color': const Color(0xFFFFC107),
        'title': 'Earned points',
        'description': 'Received 50 points for sharing',
        'time': '2 days ago',
      },
      {
        'type': 'export',
        'icon': Icons.download,
        'color': const Color(0xFF009688),
        'title': 'Exported contacts',
        'description': 'Exported 25 contacts as vCard',
        'time': '3 days ago',
      },
      {
        'type': 'sync',
        'icon': Icons.sync,
        'color': const Color(0xFF673AB7),
        'title': 'Synced contacts',
        'description': 'Synced with Google Contacts',
        'time': '5 days ago',
      },
      {
        'type': 'delete',
        'icon': Icons.delete,
        'color': const Color(0xFFF44336),
        'title': 'Deleted card',
        'description': 'Removed old business card',
        'time': '1 week ago',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Activity Log'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF00BCD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('42', 'Actions', Icons.bolt),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStat('7', 'Days', Icons.calendar_today),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStat('12', 'Shares', Icons.share),
              ],
            ),
          ),
          // Activity List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isLast = index == activities.length - 1;
                return _buildActivityItem(activity, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activity['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: activity['color'], width: 2),
                ),
                child: Icon(
                  activity['icon'],
                  color: activity['color'],
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        activity['color'].withOpacity(0.5),
                        activity['color'].withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1A1B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2B292A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['description'],
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity['time'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
