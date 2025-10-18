import 'package:flutter/material.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  // In a real app, use SharedPreferences or similar
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedHomeTour = false;
  bool _hasCompletedCardTour = false;
  bool _hasCompletedContactsTour = false;
  bool _hasCompletedScanTour = false;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCompletedHomeTour => _hasCompletedHomeTour;
  bool get hasCompletedCardTour => _hasCompletedCardTour;
  bool get hasCompletedContactsTour => _hasCompletedContactsTour;
  bool get hasCompletedScanTour => _hasCompletedScanTour;

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    // Save to SharedPreferences
  }

  void completeHomeTour() {
    _hasCompletedHomeTour = true;
    // Save to SharedPreferences
  }

  void completeCardTour() {
    _hasCompletedCardTour = true;
    // Save to SharedPreferences
  }

  void completeContactsTour() {
    _hasCompletedContactsTour = true;
    // Save to SharedPreferences
  }

  void completeScanTour() {
    _hasCompletedScanTour = true;
    // Save to SharedPreferences
  }

  void resetAllTours() {
    _hasCompletedOnboarding = false;
    _hasCompletedHomeTour = false;
    _hasCompletedCardTour = false;
    _hasCompletedContactsTour = false;
    _hasCompletedScanTour = false;
    // Clear SharedPreferences
  }
}

// Home Screen Tour Steps
List<dynamic> getHomeScreenTourSteps() {
  return [
    {
      'title': 'Welcome to Home',
      'description':
          'This is your main dashboard. Access all features from here quickly.',
      'icon': Icons.home,
      'color': const Color(0xFF1E88E5),
    },
    {
      'title': 'Quick Access Cards',
      'description':
          'Tap these cards to quickly access My Cards, Discover, Rewards, and Sustainability features.',
      'icon': Icons.dashboard,
      'color': const Color(0xFF00BCD4),
    },
    {
      'title': 'Notifications',
      'description':
          'Tap the bell icon to view your notifications and stay updated.',
      'icon': Icons.notifications,
      'color': const Color(0xFFFF9800),
    },
    {
      'title': 'Menu Drawer',
      'description':
          'Tap the menu icon to access all app features organized by category.',
      'icon': Icons.menu,
      'color': const Color(0xFF9C27B0),
    },
  ];
}

// My Cards Tour Steps
List<dynamic> getMyCardsTourSteps() {
  return [
    {
      'title': 'Your Cards',
      'description':
          'All your digital business cards are stored here. You can have multiple cards for different purposes.',
      'icon': Icons.credit_card,
      'color': const Color(0xFF1E88E5),
    },
    {
      'title': 'Create New Card',
      'description':
          'Tap the + button to create a new business card with custom colors and information.',
      'icon': Icons.add_circle,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'View Modes',
      'description':
          'Switch between grid and list view to see your cards in different layouts.',
      'icon': Icons.view_module,
      'color': const Color(0xFF00BCD4),
    },
    {
      'title': 'Search & Sort',
      'description':
          'Use search to find specific cards and sort them by date, name, or company.',
      'icon': Icons.search,
      'color': const Color(0xFFFF9800),
    },
  ];
}

// Contacts Tour Steps
List<dynamic> getContactsTourSteps() {
  return [
    {
      'title': 'Your Contacts',
      'description':
          'All saved contacts from scanned cards and connections are here.',
      'icon': Icons.contacts,
      'color': const Color(0xFF1E88E5),
    },
    {
      'title': 'Quick Actions',
      'description':
          'Tap the phone, message, or email icons to contact someone instantly without opening their profile.',
      'icon': Icons.touch_app,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Search Contacts',
      'description':
          'Use the search bar to quickly find any contact by name, company, or phone number.',
      'icon': Icons.search,
      'color': const Color(0xFF00BCD4),
    },
    {
      'title': 'Filter Options',
      'description':
          'Use filters to organize contacts by company, tags, or other criteria.',
      'icon': Icons.filter_list,
      'color': const Color(0xFF9C27B0),
    },
  ];
}

// Scan Card Tour Steps
List<dynamic> getScanCardTourSteps() {
  return [
    {
      'title': 'OCR Scanner',
      'description':
          'Point your camera at a business card to scan and extract information automatically.',
      'icon': Icons.document_scanner,
      'color': const Color(0xFF1E88E5),
    },
    {
      'title': 'Align Card',
      'description':
          'Position the business card within the frame for best results. Make sure the text is clear and well-lit.',
      'icon': Icons.crop_free,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Capture',
      'description':
          'Tap the capture button to take a photo and extract the contact information.',
      'icon': Icons.camera,
      'color': const Color(0xFF00BCD4),
    },
    {
      'title': 'Review & Save',
      'description':
          'Review the extracted information, make any necessary edits, and save the contact.',
      'icon': Icons.check_circle,
      'color': const Color(0xFF9C27B0),
    },
  ];
}

// Create Card Tour Steps
List<dynamic> getCreateCardTourSteps() {
  return [
    {
      'title': 'Card Information',
      'description':
          'Fill in your professional information. Fields marked with * are required.',
      'icon': Icons.edit,
      'color': const Color(0xFF1E88E5),
    },
    {
      'title': 'Choose Theme Color',
      'description':
          'Select from 42 pre-defined colors or create your own custom color using hex codes or RGB sliders.',
      'icon': Icons.palette,
      'color': const Color(0xFF00BCD4),
    },
    {
      'title': 'Live Preview',
      'description':
          'See how your card will look in real-time as you make changes.',
      'icon': Icons.visibility,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Save & Share',
      'description':
          'Preview your card, then save it to your collection or share it immediately.',
      'icon': Icons.share,
      'color': const Color(0xFF9C27B0),
    },
  ];
}
