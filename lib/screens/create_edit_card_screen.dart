import 'package:flutter/material.dart';
import 'package:infinicard/models/card_model.dart';
import 'package:infinicard/screens/sharing_screen.dart';
import '../services/api_service.dart';

class CreateEditCardScreen extends StatefulWidget {
  final BusinessCard? card;

  const CreateEditCardScreen({super.key, this.card});

  @override
  State<CreateEditCardScreen> createState() => _CreateEditCardScreenState();
}

class _CreateEditCardScreenState extends State<CreateEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedInController;
  late TextEditingController _githubController;
  Color _selectedColor = const Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _companyController = TextEditingController(
      text: widget.card?.company ?? '',
    );
    _emailController = TextEditingController(text: widget.card?.email ?? '');
    _phoneController = TextEditingController(text: widget.card?.phone ?? '');
    _websiteController = TextEditingController(
      text: widget.card?.website ?? '',
    );
    _linkedInController = TextEditingController(
      text: widget.card?.linkedIn ?? '',
    );
    _githubController = TextEditingController(text: widget.card?.github ?? '');
    if (widget.card != null) {
      _selectedColor = Color(widget.card!.themeColor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  BusinessCard _createCard() {
    return BusinessCard(
      id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      company: _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      linkedIn: _linkedInController.text.trim(),
      github: _githubController.text.trim(),
      themeColor: _selectedColor.toARGB32(),
      createdAt: widget.card?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _saveCard() async {
    // Dismiss the keyboard to commit any composing text before validation
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final fullName = _nameController.text.trim();
        final jobTitle = _titleController.text.trim();
        final companyName = _companyController.text.trim();
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final website = _websiteController.text.trim();

        // Build payloads per operation below

        Map<String, dynamic> response;

        if (widget.card != null) {
          // Update existing card: send only fields that have values
          final updates = <String, dynamic>{
            if (fullName.isNotEmpty) 'fullName': fullName,
            if (jobTitle.isNotEmpty) 'jobTitle': jobTitle,
            if (companyName.isNotEmpty) 'companyName': companyName,
            if (email.isNotEmpty) 'email': email,
            if (phone.isNotEmpty) 'phone': phone,
            if (website.isNotEmpty) 'website': website,
            'color':
                '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}',
          };
          response = await ApiService().updateCard(widget.card!.id, updates);
        } else {
          // Create new card
          response = await ApiService().createCard(
            fullName: fullName,
            jobTitle: jobTitle.isNotEmpty ? jobTitle : null,
            companyName: companyName.isNotEmpty ? companyName : null,
            email: email.isNotEmpty ? email : null,
            phone: phone.isNotEmpty ? phone : null,
            website: website.isNotEmpty ? website : null,
            color:
                '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}',
          );
        }

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (response['success'] == true) {
          final card = _createCard();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.card != null
                      ? 'Card updated successfully!'
                      : 'Card created successfully!',
                ),
              ),
            );
            Navigator.pop(context, card);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response['message']}')),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save card: $e')));
        }
      }
    }
  }

  void _previewCard() {
    if (_formKey.currentState!.validate()) {
      final card = _createCard();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SharingScreen(card: card)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: Colors.black,
        title: Text(widget.card == null ? 'Create Card' : 'Edit Card'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      icon: Icons.person,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title *',
                      icon: Icons.work,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _companyController,
                      label: 'Company *',
                      icon: Icons.business,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Company is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return null; // optional field
                        // Allow common email formats incl. '+' and long TLDs
                        final emailRegex = RegExp(
                          r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _linkedInController,
                      label: 'LinkedIn',
                      icon: Icons.link,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _githubController,
                      label: 'GitHub',
                      icon: Icons.code,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Theme Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorPicker(),
                    const SizedBox(height: 32),
                    const Text(
                      'Live Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLivePreview(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1A1B),
              border: Border(top: BorderSide(color: Color(0xFF2B292A))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _previewCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B292A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Card',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: Icon(icon, color: _selectedColor),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B292A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B292A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _selectedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Color Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedColor.withValues(alpha: 0.2),
                  _selectedColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedColor,
                        _selectedColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Color',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RGB(${(_selectedColor.r * 255.0).round() & 0xff}, ${(_selectedColor.g * 255.0).round() & 0xff}, ${(_selectedColor.b * 255.0).round() & 0xff})',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: _selectedColor, size: 20),
                  tooltip: 'Copy Hex Code',
                  onPressed: () {
                    // In a real app, you'd use clipboard package
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied: #${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        ),
                        backgroundColor: _selectedColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Professional Colors
          _buildColorSection('Professional', [
            const Color(0xFF1E88E5), // Blue
            const Color(0xFF1565C0), // Dark Blue
            const Color(0xFF0D47A1), // Navy
            const Color(0xFF424242), // Dark Gray
            const Color(0xFF37474F), // Blue Gray
            const Color(0xFF263238), // Dark Blue Gray
          ]),
          const SizedBox(height: 16),

          // Vibrant Colors
          _buildColorSection('Vibrant', [
            const Color(0xFFF44336), // Red
            const Color(0xFFE91E63), // Pink
            const Color(0xFF9C27B0), // Purple
            const Color(0xFF673AB7), // Deep Purple
            const Color(0xFF3F51B5), // Indigo
            const Color(0xFF2196F3), // Light Blue
          ]),
          const SizedBox(height: 16),

          // Nature Colors
          _buildColorSection('Nature', [
            const Color(0xFF4CAF50), // Green
            const Color(0xFF8BC34A), // Light Green
            const Color(0xFF009688), // Teal
            const Color(0xFF00BCD4), // Cyan
            const Color(0xFF03A9F4), // Sky Blue
            const Color(0xFF00ACC1), // Dark Cyan
          ]),
          const SizedBox(height: 16),

          // Warm Colors
          _buildColorSection('Warm', [
            const Color(0xFFFF9800), // Orange
            const Color(0xFFFF5722), // Deep Orange
            const Color(0xFFFF6F00), // Dark Orange
            const Color(0xFFFFC107), // Amber
            const Color(0xFFFFEB3B), // Yellow
            const Color(0xFFF57C00), // Orange Brown
          ]),
          const SizedBox(height: 16),

          // Elegant Colors
          _buildColorSection('Elegant', [
            const Color(0xFF795548), // Brown
            const Color(0xFF5D4037), // Dark Brown
            const Color(0xFF607D8B), // Blue Gray
            const Color(0xFF455A64), // Dark Blue Gray
            const Color(0xFF9E9E9E), // Gray
            const Color(0xFF757575), // Medium Gray
          ]),
          const SizedBox(height: 16),

          // Pastel Colors
          _buildColorSection('Pastel', [
            const Color(0xFFEF5350), // Light Red
            const Color(0xFFEC407A), // Light Pink
            const Color(0xFFAB47BC), // Light Purple
            const Color(0xFF7E57C2), // Light Deep Purple
            const Color(0xFF5C6BC0), // Light Indigo
            const Color(0xFF42A5F5), // Light Blue
          ]),
          const SizedBox(height: 16),

          // Metallic Colors
          _buildColorSection('Metallic', [
            const Color(0xFF546E7A), // Steel Blue
            const Color(0xFF78909C), // Light Steel
            const Color(0xFF90A4AE), // Silver
            const Color(0xFF6D4C41), // Bronze
            const Color(0xFFBF360C), // Copper
            const Color(0xFF8D6E63), // Rose Gold
          ]),
          const SizedBox(height: 24),

          // Custom Color Picker Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomColorPicker(),
              icon: const Icon(Icons.palette),
              label: const Text('Custom Color Picker'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _selectedColor,
                side: BorderSide(color: _selectedColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(String title, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = _selectedColor == color;
            return Tooltip(
              message:
                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.7),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCustomColorPicker() {
    Color tempColor = _selectedColor;
    final hexController = TextEditingController(
      text: _selectedColor
          .toARGB32()
          .toRadixString(16)
          .substring(2)
          .toUpperCase(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tempColor, tempColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Custom Color Picker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color Preview
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tempColor, tempColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: tempColor.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#${tempColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RGB(${(tempColor.r * 255.0).round() & 0xff}, ${(tempColor.g * 255.0).round() & 0xff}, ${(tempColor.b * 255.0).round() & 0xff})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hex Code Input
                    const Text(
                      'Enter Hex Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hexController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'RRGGBB',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixText: '# ',
                        prefixStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2B292A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            final hex = hexController.text
                                .replaceAll('#', '')
                                .trim();
                            if (hex.length == 6) {
                              try {
                                final color = Color(
                                  int.parse('FF$hex', radix: 16),
                                );
                                setDialogState(() {
                                  tempColor = color;
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid hex color code'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        final hex = value.replaceAll('#', '').trim();
                        if (hex.length == 6) {
                          try {
                            final color = Color(int.parse('FF$hex', radix: 16));
                            setDialogState(() {
                              tempColor = color;
                            });
                          } catch (e) {
                            // Invalid hex
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // RGB Sliders
                    const Text(
                      'Adjust RGB Values',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEnhancedSlider(
                      'Red',
                      ((tempColor.r * 255.0).round() & 0xff).toDouble(),
                      Colors.red,
                      (value) {
                        setDialogState(() {
                          tempColor = Color.fromARGB(
                            255,
                            value.toInt(),
                            (tempColor.g * 255.0).round() & 0xff,
                            (tempColor.b * 255.0).round() & 0xff,
                          );
                          hexController.text = tempColor
                              .toARGB32()
                              .toRadixString(16)
                              .substring(2)
                              .toUpperCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEnhancedSlider(
                      'Green',
                      ((tempColor.g * 255.0).round() & 0xff).toDouble(),
                      Colors.green,
                      (value) {
                        setDialogState(() {
                          tempColor = Color.fromARGB(
                            255,
                            (tempColor.r * 255.0).round() & 0xff,
                            value.toInt(),
                            (tempColor.b * 255.0).round() & 0xff,
                          );
                          hexController.text = tempColor
                              .toARGB32()
                              .toRadixString(16)
                              .substring(2)
                              .toUpperCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEnhancedSlider(
                      'Blue',
                      ((tempColor.b * 255.0).round() & 0xff).toDouble(),
                      Colors.blue,
                      (value) {
                        setDialogState(() {
                          tempColor = Color.fromARGB(
                            255,
                            (tempColor.r * 255.0).round() & 0xff,
                            (tempColor.g * 255.0).round() & 0xff,
                            value.toInt(),
                          );
                          hexController.text = tempColor
                              .toARGB32()
                              .toRadixString(16)
                              .substring(2)
                              .toUpperCase();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Quick Presets
                    const Text(
                      'Quick Presets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickPreset(
                          const Color(0xFFFF0000),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFFFFC0CB),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF9C27B0),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF2196F3),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF00BCD4),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF4CAF50),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFFFFEB3B),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFFFF9800),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF795548),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF9E9E9E),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFF000000),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                        _buildQuickPreset(
                          const Color(0xFFFFFFFF),
                          tempColor,
                          setDialogState,
                          (color) {
                            tempColor = color;
                            hexController.text = color
                                .toARGB32()
                                .toRadixString(16)
                                .substring(2)
                                .toUpperCase();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedColor = tempColor;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Apply Color'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tempColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickPreset(
    Color color,
    Color currentColor,
    StateSetter setDialogState,
    Function(Color) onTap,
  ) {
    final isSelected = currentColor == color;
    return GestureDetector(
      onTap: () => setDialogState(() => onTap(color)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildEnhancedSlider(
    String label,
    double value,
    Color sliderColor,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B292A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: sliderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1A1B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toInt().toString().padLeft(3, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: sliderColor,
              thumbColor: sliderColor,
              inactiveTrackColor: sliderColor.withValues(alpha: 0.3),
              overlayColor: sliderColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 255,
              divisions: 255,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _titleController.text.isEmpty
                ? 'Your Title'
                : _titleController.text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _companyController.text.isEmpty
                ? 'Company'
                : _companyController.text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (_emailController.text.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _emailController.text,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          if (_phoneController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _phoneController.text,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
