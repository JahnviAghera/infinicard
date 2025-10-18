import 'package:flutter/material.dart';

class HelpButton extends StatelessWidget {
  final String title;
  final List<HelpItem> helpItems;
  final Color color;

  const HelpButton({
    super.key,
    required this.title,
    required this.helpItems,
    this.color = const Color(0xFF1E88E5),
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'help_button_$title',
      onPressed: () => _showHelpDialog(context),
      backgroundColor: color,
      child: const Icon(Icons.help_outline),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A1B),
        title: Row(
          children: [
            Icon(Icons.help, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: helpItems.map((item) => _buildHelpItem(item)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(HelpItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              item.description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpItem {
  final String title;
  final String description;
  final IconData icon;

  HelpItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Tooltip widget for highlighting features
class FeatureTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final Color color;
  final bool showArrow;
  final VoidCallback? onTap;

  const FeatureTooltip({
    super.key,
    required this.child,
    required this.message,
    this.color = const Color(0xFF1E88E5),
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: message,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        child: child,
      ),
    );
  }
}

// Quick tips banner
class QuickTipBanner extends StatelessWidget {
  final String tip;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;

  const QuickTipBanner({
    super.key,
    required this.tip,
    this.icon = Icons.lightbulb_outline,
    this.color = const Color(0xFFFF9800),
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Tip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onDismiss,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

// Interactive demo overlay for showing gestures
class GestureDemo extends StatefulWidget {
  final String gesture;
  final String description;
  final VoidCallback onComplete;

  const GestureDemo({
    super.key,
    required this.gesture,
    required this.description,
    required this.onComplete,
  });

  @override
  State<GestureDemo> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.gesture,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SlideTransition(
            position: _slideAnimation,
            child: const Icon(
              Icons.touch_app,
              color: Color(0xFF1E88E5),
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
