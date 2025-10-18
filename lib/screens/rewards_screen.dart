import 'package:flutter/material.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final int _userPoints = 1250;
  final int _userRank = 42;

  final List<Map<String, dynamic>> _badges = [
    {
      'name': 'First Connection',
      'icon': Icons.handshake,
      'description': 'Made your first connection',
      'earned': true,
      'points': 50,
    },
    {
      'name': 'Card Creator',
      'icon': Icons.credit_card,
      'description': 'Created your first digital card',
      'earned': true,
      'points': 100,
    },
    {
      'name': 'Eco Warrior',
      'icon': Icons.eco,
      'description': 'Saved 50 paper cards',
      'earned': true,
      'points': 200,
    },
    {
      'name': 'Networking Pro',
      'icon': Icons.people,
      'description': 'Connected with 25 people',
      'earned': false,
      'points': 300,
    },
    {
      'name': 'Share Master',
      'icon': Icons.share,
      'description': 'Shared your card 100 times',
      'earned': false,
      'points': 500,
    },
  ];

  final List<Map<String, dynamic>> _leaderboard = [
    {
      'rank': 1,
      'name': 'Alex Johnson',
      'points': 5420,
      'avatar': 'https://i.pravatar.cc/150?img=20',
    },
    {
      'rank': 2,
      'name': 'Maria Garcia',
      'points': 4890,
      'avatar': 'https://i.pravatar.cc/150?img=21',
    },
    {
      'rank': 3,
      'name': 'James Wilson',
      'points': 4250,
      'avatar': 'https://i.pravatar.cc/150?img=22',
    },
    {
      'rank': 4,
      'name': 'Emily Brown',
      'points': 3780,
      'avatar': 'https://i.pravatar.cc/150?img=23',
    },
    {
      'rank': 5,
      'name': 'Robert Taylor',
      'points': 3420,
      'avatar': 'https://i.pravatar.cc/150?img=24',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF00BCD4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_userPoints Points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rank #$_userRank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Points Activities
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Earn More Points',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      icon: Icons.share,
                      title: 'Share your card',
                      points: '+10 points',
                      color: const Color(0xFF4CAF50),
                    ),
                    _buildActivityCard(
                      icon: Icons.person_add,
                      title: 'Make a new connection',
                      points: '+25 points',
                      color: const Color(0xFF2196F3),
                    ),
                    _buildActivityCard(
                      icon: Icons.eco,
                      title: 'Go paperless for a week',
                      points: '+50 points',
                      color: const Color(0xFF009688),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Badges Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Badges',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _badges.length,
                      itemBuilder: (context, index) {
                        final badge = _badges[index];
                        return _buildBadgeCard(badge);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Leaderboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Leaderboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1A1B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2B292A)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          return _buildLeaderboardItem(
                            user,
                            index == _leaderboard.length - 1,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String points,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            points,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final earned = badge['earned'] as bool;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? const Color(0xFF1E88E5) : const Color(0xFF2B292A),
          width: earned ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge['icon'],
            color: earned ? const Color(0xFF1E88E5) : Colors.grey[700],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'],
            style: TextStyle(
              color: earned ? Colors.white : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (earned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${badge['points']}',
                style: const TextStyle(
                  color: Color(0xFF1E88E5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, bool isLast) {
    final rank = user['rank'] as int;
    Color? rankColor;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey[400];
    if (rank == 3) rankColor = Colors.brown[300];

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(bottom: BorderSide(color: Color(0xFF2B292A)))
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(user['avatar']),
              backgroundColor: const Color(0xFF2B292A),
            ),
            if (rankColor != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${user['points']} points',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        trailing: Text(
          '#$rank',
          style: TextStyle(
            color: rankColor ?? Colors.grey[600],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
