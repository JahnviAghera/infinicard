import 'package:flutter/material.dart';

class FeatureTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final List<TourStep> steps;

  const FeatureTourOverlay({
    super.key,
    required this.onComplete,
    required this.steps,
  });

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.forward(from: 0);
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.forward(from: 0);
    }
  }

  void _skipTour() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: GestureDetector(
        onTap: () {}, // Prevent closing on tap
        child: Stack(
          children: [
            // Spotlight effect
            if (step.targetRect != null)
              CustomPaint(
                size: screenSize,
                painter: SpotlightPainter(
                  spotlightRect: step.targetRect!,
                  holeRadius: step.holeRadius,
                ),
              ),
            // Tooltip
            Positioned(
              left: step.tooltipPosition.left,
              top: step.tooltipPosition.top,
              right: step.tooltipPosition.right,
              bottom: step.tooltipPosition.bottom,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildTooltip(step),
              ),
            ),
            // Skip button
            Positioned(
              top: 40,
              right: 16,
              child: TextButton(
                onPressed: _skipTour,
                child: const Text(
                  'Skip Tour',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(TourStep step) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.color ?? const Color(0xFF1E88E5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (step.color ?? const Color(0xFF1E88E5)).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (step.color ?? const Color(0xFF1E88E5)).withOpacity(
                    0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  step.icon,
                  color: step.color ?? const Color(0xFF1E88E5),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of ${widget.steps.length}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            step.description,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / widget.steps.length,
            backgroundColor: Colors.grey[800],
            color: step.color ?? const Color(0xFF1E88E5),
          ),
          const SizedBox(height: 20),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                )
              else
                const SizedBox(),
              ElevatedButton.icon(
                onPressed: _nextStep,
                icon: Icon(
                  _currentStep == widget.steps.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _currentStep == widget.steps.length - 1 ? 'Got it!' : 'Next',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: step.color ?? const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double holeRadius;

  SpotlightPainter({required this.spotlightRect, this.holeRadius = 8.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create rounded rectangle hole
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(spotlightRect, Radius.circular(holeRadius)),
      );

    path.addPath(holePath, Offset.zero);
    canvas.drawPath(path, paint..blendMode = BlendMode.xor);

    // Draw border around spotlight
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect, Radius.circular(holeRadius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect;
  }
}

class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final Rect? targetRect;
  final TooltipPosition tooltipPosition;
  final double holeRadius;

  TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.targetRect,
    required this.tooltipPosition,
    this.holeRadius = 8.0,
  });
}

class TooltipPosition {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  TooltipPosition({this.left, this.top, this.right, this.bottom});
}

// Helper function to show feature tour
void showFeatureTour(BuildContext context, List<TourStep> steps) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FeatureTourOverlay(
          steps: steps,
          onComplete: () => Navigator.of(context).pop(),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
