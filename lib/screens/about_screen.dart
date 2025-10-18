import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: const Text('About'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo and Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF00BCD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      size: 60,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Infinicard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart. Sustainable. Networking.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Infinicard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1A1B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2B292A)),
                    ),
                    child: Text(
                      'Infinicard is a digital business card platform promoting smart, sustainable networking. '
                      'Connect with professionals worldwide, share your information instantly, and contribute '
                      'to a paperless future. With features like OCR scanning, AI-powered networking, and '
                      'gamification, we make professional networking effortless and eco-friendly.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeature(
                    icon: Icons.credit_card,
                    title: 'Digital Business Cards',
                    description: 'Create beautiful, customizable digital cards',
                  ),
                  _buildFeature(
                    icon: Icons.qr_code_scanner,
                    title: 'OCR Scanning',
                    description: 'Scan and digitize paper business cards',
                  ),
                  _buildFeature(
                    icon: Icons.people,
                    title: 'Smart Networking',
                    description: 'AI-powered professional recommendations',
                  ),
                  _buildFeature(
                    icon: Icons.eco,
                    title: 'Sustainability',
                    description: 'Track your environmental impact',
                  ),
                  _buildFeature(
                    icon: Icons.stars,
                    title: 'Rewards & Gamification',
                    description: 'Earn points and unlock achievements',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildLinkButton(
                    icon: Icons.description,
                    title: 'Terms of Use',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TermsPrivacyScreen(showTerms: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLinkButton(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TermsPrivacyScreen(showTerms: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLinkButton(
                    icon: Icons.language,
                    title: 'Visit Website',
                    onTap: () {
                      // Open website
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '© 2025 Infinicard. All rights reserved.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ for a sustainable future',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
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
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String title,
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
            Icon(icon, color: const Color(0xFF1E88E5)),
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
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}

class TermsPrivacyScreen extends StatelessWidget {
  final bool showTerms;

  const TermsPrivacyScreen({super.key, required this.showTerms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0F),
        foregroundColor: Colors.white,
        title: Text(showTerms ? 'Terms of Use' : 'Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showTerms ? 'Terms of Use' : 'Privacy Policy',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: October 17, 2025',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: showTerms
                  ? '1. Acceptance of Terms'
                  : '1. Information We Collect',
              content: showTerms
                  ? 'By accessing and using Infinicard, you accept and agree to be bound by the terms and provision of this agreement.'
                  : 'We collect information you provide directly to us, including name, email, phone number, company information, and professional details you add to your digital business cards.',
            ),
            _buildSection(
              title: showTerms
                  ? '2. Use License'
                  : '2. How We Use Your Information',
              content: showTerms
                  ? 'Permission is granted to temporarily download one copy of the materials on Infinicard for personal, non-commercial transitory viewing only.'
                  : 'We use your information to provide, maintain, and improve our services, send you technical notices and support messages, and respond to your requests.',
            ),
            _buildSection(
              title: showTerms ? '3. Disclaimer' : '3. Data Security',
              content: showTerms
                  ? 'The materials on Infinicard are provided on an \'as is\' basis. Infinicard makes no warranties, expressed or implied.'
                  : 'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, or destruction.',
            ),
            _buildSection(
              title: showTerms ? '4. Limitations' : '4. Your Rights',
              content: showTerms
                  ? 'In no event shall Infinicard or its suppliers be liable for any damages arising out of the use or inability to use the materials on Infinicard.'
                  : 'You have the right to access, update, or delete your personal information at any time. You can also object to processing or request data portability.',
            ),
            _buildSection(
              title: showTerms ? '5. Revisions' : '5. Contact Us',
              content: showTerms
                  ? 'Infinicard may revise these terms of service at any time without notice. By using this app you are agreeing to be bound by the then current version of these terms of service.'
                  : 'If you have questions about this Privacy Policy, please contact us at privacy@infinicard.com or +91 87994 48954.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
