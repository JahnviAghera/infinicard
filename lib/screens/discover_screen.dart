import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ApiService _apiService = ApiService();
  String _selectedLocation = 'All';
  String _selectedField = 'All';
  List<String> _locations = ['All'];
  List<String> _fields = ['All'];
  final int _userPoints =
      1250; // Demo points - could be fetched from user profile

  List<Map<String, dynamic>> _professionals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadLocations(), _loadFields(), _loadProfessionals()]);
  }

  Future<void> _loadLocations() async {
    try {
      final result = await _apiService.getLocations();
      if (result['success'] == true && mounted) {
        setState(() {
          _locations = List<String>.from(result['data'] ?? ['All']);
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> _loadFields() async {
    try {
      final result = await _apiService.getFields();
      if (result['success'] == true && mounted) {
        setState(() {
          _fields = List<String>.from(result['data'] ?? ['All']);
        });
      }
    } catch (e) {
      print('Error loading fields: $e');
    }
  }

  Future<void> _loadProfessionals() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getProfessionals(
        location: _selectedLocation != 'All' ? _selectedLocation : null,
        field: _selectedField != 'All' ? _selectedField : null,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          _professionals = List<Map<String, dynamic>>.from(
            result['data'] ?? [],
          );
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load professionals';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connectWithProfessional(
    Map<String, dynamic> professional,
  ) async {
    // Check if already connected or request pending
    final connectionStatus = professional['connectionStatus'];

    if (connectionStatus == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection request already pending'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (connectionStatus == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already connected with this professional'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A1B),
        title: const Text(
          'Send Connection Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Send a connection request to ${professional['name']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Sending connection request...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Always use professional['userId'] for connections, as it must exist in users table
        final receiverId = professional['userId'];
        if (receiverId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot send request: Professional has no user account.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final result = await _apiService.sendConnectionRequest(
          receiverId: receiverId,
        );

        if (!mounted) return;

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connection request sent to ${professional['name']}!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the professionals list to update connection status
          await _loadProfessionals();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to send connection request',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Points
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1A1B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF00BCD4)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_userPoints pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with professionals',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _selectedLocation,
                          items: _locations,
                          icon: Icons.location_on,
                          onChanged: (value) {
                            setState(() {
                              _selectedLocation = value!;
                            });
                            _loadProfessionals();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _selectedField,
                          items: _fields,
                          icon: Icons.work,
                          onChanged: (value) {
                            setState(() {
                              _selectedField = value!;
                            });
                            _loadProfessionals();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Professionals List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E88E5),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadProfessionals,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _professionals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No professionals found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfessionals,
                      color: const Color(0xFF1E88E5),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _professionals.length,
                        itemBuilder: (context, index) {
                          final professional = _professionals[index];
                          return _buildProfessionalCard(professional);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0C0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          dropdownColor: const Color(0xFF1C1A1B),
          style: const TextStyle(color: Colors.white),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF1E88E5), size: 18),
                  const SizedBox(width: 8),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> professional) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B292A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(professional['avatar']),
                backgroundColor: const Color(0xFF2B292A),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      professional['profession'],
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          professional['location'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${professional['connections']} connections',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (professional['tags'] as List<dynamic>)
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B292A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag.toString(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildConnectionButton(professional),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(Map<String, dynamic> professional) {
    final connectionStatus = professional['connectionStatus'];

    if (connectionStatus == 'accepted') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: const Text('Connected'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.3),
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else if (connectionStatus == 'pending') {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule),
        label: const Text('Pending'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.withOpacity(0.3),
          foregroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _connectWithProfessional(professional),
        icon: const Icon(Icons.person_add),
        label: const Text('Connect'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
