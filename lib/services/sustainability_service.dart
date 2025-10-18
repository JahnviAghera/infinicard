class SustainabilityStats {
  final int cardsAvoided;
  final double paperSaved;
  final double treesSaved;
  final double co2Reduced;

  SustainabilityStats({
    required this.cardsAvoided,
    required this.paperSaved,
    required this.treesSaved,
    required this.co2Reduced,
  });
}

class SustainabilityService {
  static final SustainabilityService _instance =
      SustainabilityService._internal();
  factory SustainabilityService() => _instance;
  SustainabilityService._internal();

  int _cardsShared = 0;

  void incrementCardsShared() {
    _cardsShared++;
  }

  SustainabilityStats? getStats() {
    if (_cardsShared == 0) {
      _cardsShared = 42; // Demo data
    }

    // Average business card: 2g paper, 1 card = 0.002kg
    final paperSaved = _cardsShared * 0.002;
    // 1 tree produces ~8333 sheets of paper (each sheet ~5g), business card uses ~2 sheets worth
    final treesSaved = _cardsShared / 4166.5;
    // Production of 1kg paper emits ~2.6kg CO2
    final co2Reduced = paperSaved * 2.6;

    return SustainabilityStats(
      cardsAvoided: _cardsShared,
      paperSaved: paperSaved,
      treesSaved: treesSaved,
      co2Reduced: co2Reduced,
    );
  }

  Map<String, dynamic> getAchievement() {
    return {
      'title': 'Eco Warrior',
      'description': 'Saved ${_cardsShared} paper cards from being printed!',
      'icon': '🌱',
    };
  }
}
