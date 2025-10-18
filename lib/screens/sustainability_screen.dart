import 'package:flutter/material.dart';
import 'package:infinicard/services/sustainability_service.dart';
import 'package:share_plus/share_plus.dart';

class SustainabilityScreen extends StatelessWidget {
  const SustainabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = SustainabilityService().getStats();

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('Sustainability'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Environmental Impact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every digital card makes a difference',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 32),
            _StatCard(
              title: 'Paper Cards Avoided',
              value: stats.cardsAvoided.toString(),
              icon: Icons.credit_card_off,
              color: Colors.blue,
              description: 'Traditional business cards saved',
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'Paper Saved',
              value: '${stats.paperSaved.toStringAsFixed(3)} kg',
              icon: Icons.description_outlined,
              color: Colors.orange,
              description: 'Weight of paper conserved',
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'Trees Saved',
              value: stats.treesSaved.toStringAsFixed(4),
              icon: Icons.eco,
              color: Colors.green,
              description: 'Equivalent trees preserved',
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'CO₂ Reduced',
              value: '${stats.co2Reduced.toStringAsFixed(3)} kg',
              icon: Icons.cloud_outlined,
              color: Colors.teal,
              description: 'Carbon emissions prevented',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Great Work!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re helping build a sustainable future. Keep sharing digital cards!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _shareAchievement(context, stats);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share Achievement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Additional Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1A1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2B292A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 12),
                      const Text(
                        'Did you know?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The average business person receives 25,000 business cards in their lifetime. '
                    'By going digital, you\'re making a significant positive impact on our environment!',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAchievement(BuildContext context, SustainabilityStats stats) {
    final achievement = SustainabilityService().getAchievement();
    Share.share(
      '${achievement['icon']} ${achievement['title']}\n\n'
      '${achievement['description']}\n\n'
      '🌍 Paper Cards Avoided: ${stats.cardsAvoided}\n'
      '📄 Paper Saved: ${stats.paperSaved.toStringAsFixed(3)} kg\n'
      '🌳 Trees Saved: ${stats.treesSaved.toStringAsFixed(4)}\n'
      '☁️ CO₂ Reduced: ${stats.co2Reduced.toStringAsFixed(3)} kg\n\n'
      'Join me in making a sustainable future with Infinicard!',
      subject: 'My Sustainability Achievement',
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String description;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
