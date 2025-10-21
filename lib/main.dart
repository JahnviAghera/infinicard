import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

// Import all new screens
import 'package:infinicard/screens/my_cards_screen.dart';
import 'package:infinicard/screens/create_edit_card_screen.dart';
import 'package:infinicard/screens/contacts_list_screen.dart';
import 'package:infinicard/screens/discover_screen.dart';
import 'package:infinicard/screens/rewards_screen.dart';
import 'package:infinicard/screens/sustainability_screen.dart';
import 'package:infinicard/screens/integrations_screen.dart';
import 'package:infinicard/screens/enterprise_screen.dart';
import 'package:infinicard/screens/settings_screen.dart';
import 'package:infinicard/screens/help_support_screen.dart';
import 'package:infinicard/screens/about_screen.dart';
import 'package:infinicard/screens/notifications_screen.dart';
import 'package:infinicard/screens/activity_log_screen.dart';
import 'package:infinicard/screens/scan_card_screen.dart';
import 'package:infinicard/screens/onboarding_screen.dart';
import 'package:infinicard/screens/walkthrough_screen.dart';
import 'package:infinicard/screens/login_screen.dart';
import 'package:infinicard/screens/register_screen.dart';
import 'package:infinicard/screens/card_import_screen.dart';
import 'package:infinicard/services/api_service.dart';

import 'models/card_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const String _profileImageUrl = ""; // Replace with your image URL

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  StreamSubscription<Uri>? _linkSubscription;
  String? _initialLink;
  AppLinks? _appLinks; // Singleton instance for handling app/deep links

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Initialize AppLinks (singleton)
    _appLinks ??= AppLinks();

    // Subscribe to all events (initial link and subsequent links)
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        final link = uri.toString();
        // Persist the very first link observed as initial
        _initialLink ??= link;
        _handleDeepLink(link);
      },
      onError: (err) {
        debugPrint('Error listening to app links: $err');
      },
      cancelOnError: false,
    );
  }

  void _handleDeepLink(String link) {
    debugPrint('Received deep link: $link');
    final uri = Uri.parse(link);

    String? cardId;

    // Handle infinicard://share/ID
    if (uri.scheme == 'infinicard' && uri.host == 'share') {
      cardId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // Handle https://infinicard.app/c/ID (App Links/Universal Links)
    if (uri.scheme == 'https' && uri.host == 'infinicard.app') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'c') {
        cardId = uri.pathSegments[1];
      }
    }

    if (cardId != null) {
      // Navigate to card import screen
      Navigator.of(context).pushNamed('/share/$cardId');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _apiService.initialize();
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0C0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 80,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Color(0xFF1E88E5)),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Infinicard',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0C0F),
      ),
      home: _isAuthenticated ? const Home() : const LoginScreen(),
      onGenerateRoute: (settings) {
        // Handle deep links
        if (settings.name != null && settings.name!.startsWith('/share/')) {
          final cardId = settings.name!.substring(7); // Remove '/share/'
          return MaterialPageRoute(
            builder: (context) => CardImportScreen(cardId: cardId),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const Home(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/my-cards': (context) => const MyCardsScreen(),
        '/create-card': (context) => const CreateEditCardScreen(),
        '/contacts': (context) => const ContactsListScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/rewards': (context) => const RewardsScreen(),
        '/sustainability': (context) => const SustainabilityScreen(),
        '/integrations': (context) => const IntegrationsScreen(),
        '/enterprise': (context) => const EnterpriseScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpSupportScreen(),
        '/about': (context) => const AboutScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/activity': (context) => const ActivityLogScreen(),
        '/scan': (context) => const ScanCardScreen(),
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _screens = [
      HomeScreen(),
      const SettingsScreen(),
      const ScanCardScreen(),
      // const DocumentsScreen(),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        width: 360,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _navItem(
              icon: Icons.document_scanner_rounded,
              label: 'Scan',
              index: 2,
            ),
            _navItem(icon: Icons.settings_rounded, label: 'Settings', index: 1),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool selected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        width: selected ? (label.isNotEmpty ? 118 : 48) : 48,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: selected ? const Color(0xFF1C1A1B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black),
            if (selected && label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0], // use back camera
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Picture saved to: ${file.path}')));
      // You can navigate to a preview screen here
    } catch (e) {
      print('Error capturing picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),
                // Card overlay
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 300,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Capture button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _fetchAndStoreUserInfo();
  }

  Future<void> _fetchAndStoreUserInfo() async {
    try {
      // Replace with your actual API call
      final response = await ApiService().getUserInfo();
      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', jsonEncode(response));
        print('User info fetched and stored: $response');
        if (mounted) {
          setState(() {
            _userInfo = response;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }
  }

  Future<List<BusinessCard>> _loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_cards');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList
            .map((json) => BusinessCard.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading cards: $e');
    }
    return [];
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A1B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      // appBar: AppBar(
      //       //   backgroundColor: const Color(0xFF1C1A1B),
      //       //   title: const Text(
      //       //     'Infinicard',
      //       //     style: TextStyle(color: Colors.white),
      //       //   ),
      //       //   actions: [
      //       //     IconButton(
      //       //       icon:
      //       //       const Icon(Icons.notifications_outlined, color: Colors.white),
      //       //       onPressed: () {}, // TODO: add notification logic
      //       //     ),
      //       //   ],
      //       // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            if (_userInfo != null)
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      _userInfo!['profile_picture'] ??
                          'https://i.pravatar.cc/150',
                    ),
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Welcome, ${_userInfo!['fullName'] ?? 'User'}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              )
            else
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.grey[800], radius: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        color: Colors.grey[800],
                      ),
                    ],
                  ),
                ],
              ),

            // const Text(
            //   'Quick Access',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 16),
            // GridView.count(
            //   crossAxisCount: 2,
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   mainAxisSpacing: 12,
            //   crossAxisSpacing: 12,
            //   children: [
            //     _buildQuickAccessCard(
            //         context, 'My Cards', Icons.credit_card, '/my-cards', Colors.blue),
            //     _buildQuickAccessCard(
            //         context, 'Discover', Icons.explore, '/discover', Colors.purple),
            //     _buildQuickAccessCard(
            //         context, 'Rewards', Icons.emoji_events, '/rewards', Colors.amber),
            //     _buildQuickAccessCard(
            //         context, 'Sustainability', Icons.eco, '/sustainability', Colors.green),
            //     _buildQuickAccessCard(
            //         context, 'Scan Card', Icons.qr_code_scanner, '/scan', Colors.orange),
            //   ],
            // ),
            const SizedBox(height: 32),

            // Show first existing card from cache
            FutureBuilder<List<BusinessCard>>(
              future: _loadCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _CardSkeleton();
                }
                if (snapshot.hasError) {
                  return const Text(
                    'Error loading card',
                    style: TextStyle(color: Colors.white),
                  );
                }
                final cards = snapshot.data ?? [];
                if (cards.isEmpty) {
                  return const Text(
                    'No card found',
                    style: TextStyle(color: Colors.white),
                  );
                }

                final card = cards.first;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(card.themeColor),
                        Color(card.themeColor).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(card.themeColor).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        card.company,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        card.phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1A1B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  //   'Actions',
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/create-card'),
                    child: Column(
                      children: [
                        const Icon(Icons.add, color: Colors.white70),
                        const SizedBox(width: 12),
                        const Text(
                          'Create Card',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/my-cards'),
                    child: Column(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white),
                        const Text(
                          'My Cards',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/contacts'),
                    child: Column(
                      children: [
                        const Icon(Icons.contact_phone, color: Colors.white),
                        const Text(
                          'Contacts',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/discover'),
                    child: Column(
                      children: [
                        const Icon(Icons.explore, color: Colors.white),
                        const Text(
                          'Discover',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
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
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 200, height: 24),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: 150, height: 18),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: 120, height: 16),
          const SizedBox(height: 20),
          _buildSkeletonLine(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: double.infinity, height: 14),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1A1B),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.credit_card, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Infinicard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerSection('Cards'),
          _buildDrawerItem(context, 'My Cards', Icons.credit_card, '/my-cards'),
          _buildDrawerItem(
            context,
            'Create Card',
            Icons.add_card,
            '/create-card',
          ),
          const Divider(color: Colors.grey),
          _buildDrawerSection('Network'),
          _buildDrawerItem(context, 'Contacts', Icons.contacts, '/contacts'),
          _buildDrawerItem(context, 'Discover', Icons.explore, '/discover'),
          _buildDrawerItem(context, 'Activity Log', Icons.history, '/activity'),
          const Divider(color: Colors.grey),
          _buildDrawerSection('Features'),
          _buildDrawerItem(context, 'Rewards', Icons.emoji_events, '/rewards'),
          _buildDrawerItem(
            context,
            'Sustainability',
            Icons.eco,
            '/sustainability',
          ),
          _buildDrawerItem(
            context,
            'Integrations',
            Icons.sync,
            '/integrations',
          ),
          _buildDrawerItem(
            context,
            'Enterprise',
            Icons.business,
            '/enterprise',
          ),
          const Divider(color: Colors.grey),
          _buildDrawerSection('Account'),
          _buildDrawerItem(context, 'Settings', Icons.settings, '/settings'),
          _buildDrawerItem(context, 'Help & Support', Icons.help, '/help'),
          _buildDrawerItem(context, 'About', Icons.info, '/about'),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}

// ===================== CONTACTS SCREEN =====================
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _allContacts = [
    {"name": "Alice Smith", "phone": "+91 87994 48954", "designation": "CEO"},
    {
      "name": "Bob Johnson",
      "phone": "+91 98765 43211",
      "designation": "Designer",
    },
    {
      "name": "Charlie Brown",
      "phone": "+91 98765 43212",
      "designation": "Developer",
    },
    {
      "name": "Diana Prince",
      "phone": "+91 98765 43213",
      "designation": "Manager",
    },
    {
      "name": "Ethan Hunt",
      "phone": "+91 98765 43214",
      "designation": "Designer",
    },
    {
      "name": "Fiona Glenanne",
      "phone": "+91 98765 43215",
      "designation": "CEO",
    },
    {
      "name": "George Costanza",
      "phone": "+91 98765 43216",
      "designation": "Developer",
    },
    {
      "name": "Hannah Montana",
      "phone": "+91 98765 43217",
      "designation": "Intern",
    },
    {
      "name": "Ian Malcolm",
      "phone": "+91 98765 43218",
      "designation": "Designer",
    },
    {"name": "Jane Doe", "phone": "+91 98765 43219", "designation": "Manager"},
    {"name": "Kramer", "phone": "+91 98765 43220", "designation": "CEO"},
    {
      "name": "Liz Lemon",
      "phone": "+91 98765 43221",
      "designation": "Developer",
    },
  ];

  List<Map<String, String>> _filteredContacts = [];
  String? _selectedDesignation;
  late List<String> _designations;

  @override
  void initState() {
    super.initState();
    _designations = [
      "All",
      ..._allContacts.map((c) => c['designation']!).toSet().toList(),
    ];
    _selectedDesignation = _designations.first;
    _filteredContacts = _allContacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    final selectedDesignation = _selectedDesignation;
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final name = contact["name"]!.toLowerCase();
        final phone = contact["phone"]!.toLowerCase();
        final designation = contact["designation"]!;
        final matchesQuery = name.contains(query) || phone.contains(query);
        final matchesDesignation =
            selectedDesignation == 'All' || designation == selectedDesignation;
        return matchesQuery && matchesDesignation;
      }).toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch call to $phoneNumber'),
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

  void _showContactProfile(Map<String, String> contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(contact['name']!),
            backgroundColor: const Color(0xFF0D0C0F),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 75,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/300?u=${contact['name']}',
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  contact['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contact['designation']!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 18),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Mobile',
                  value: contact['phone']!,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value:
                      '${contact['name']!.toLowerCase().replaceAll(' ', '.')}@example.com',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.web,
                  label: 'Website',
                  value: 'example.com',
                ),
                // Add more details if needed
              ],
            ),
          ),
          backgroundColor: const Color(0xFF0D0C0F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1C1A1B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1A1B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDesignation,
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    dropdownColor: const Color(0xFF1C1A1B),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDesignation = newValue;
                        _filterContacts();
                      });
                    },
                    items: _designations.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return Dismissible(
                        key: Key(contact["phone"]!),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.horizontal) {
                            // _showContactProfile(contact);
                            _makePhoneCall(contact["phone"]!);
                          }
                          return false; // This prevents the item from being dismissed
                        },
                        background: Container(
                          // Swipe right for profile view
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.call, color: Colors.white),
                        ),
                        child: Card(
                          color: const Color(0xFF1C1A1B),
                          child: ListTile(
                            onTap: () => _showContactProfile(contact),
                            leading: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                            title: Text(
                              contact["name"]!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${contact["designation"]!} • ${contact["phone"]!}",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}

// ===================== PROFILE CARD =====================
class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String mobile;
  final String website;
  final String imageUrl;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
    required this.email,
    required this.mobile,
    required this.website,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const baseWidth = 430;
    const baseHeight = 932;
    final widthScale = size.width / baseWidth;
    final heightScale = size.height / baseHeight;

    return Container(
      width: 377 * widthScale,
      height: 374 * heightScale,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * widthScale),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: -50,
            child: Container(
              width: 377 * widthScale,
              height: 255,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24 * widthScale,
            top: 210 * heightScale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32 * widthScale,
                    fontWeight: FontWeight.w700,
                    height: 0.69,
                  ),
                ),
                SizedBox(height: 6 * heightScale),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20 * widthScale,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                SizedBox(height: 6 * heightScale),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20 * widthScale,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                SizedBox(height: 6 * heightScale),
                Text(
                  mobile,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20 * widthScale,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),
                SizedBox(height: 6 * heightScale),
                Text(
                  website,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20 * widthScale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
