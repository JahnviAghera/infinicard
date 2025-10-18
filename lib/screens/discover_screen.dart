import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedLocation = 'All';
  String _selectedField = 'All';
  final List<String> _locations = [
    'All',
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Pune',
  ];
  final List<String> _fields = [
    'All',
    'Technology',
    'Marketing',
    'Design',
    'Finance',
  ];
  final int _userPoints = 1250; // Demo points

  final List<Map<String, dynamic>> _professionals = [
    {
      'name': 'Sarah Williams',
      'profession': 'Full Stack Developer',
      'location': 'Mumbai',
      'field': 'Technology',
      'avatar': 'https://i.pravatar.cc/150?img=10',
      'tags': ['React', 'Node.js', 'Python'],
      'connections': 245,
    },
    {
      'name': 'Michael Chen',
      'profession': 'Product Designer',
      'location': 'Bangalore',
      'field': 'Design',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'tags': ['UI/UX', 'Figma', 'Prototyping'],
      'connections': 189,
    },
    {
      'name': 'Priya Sharma',
      'profession': 'Marketing Manager',
      'location': 'Delhi',
      'field': 'Marketing',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'tags': ['Digital Marketing', 'SEO', 'Content'],
      'connections': 312,
    },
    {
      'name': 'David Kumar',
      'profession': 'Data Scientist',
      'location': 'Pune',
      'field': 'Technology',
      'avatar': 'https://i.pravatar.cc/150?img=13',
      'tags': ['ML', 'Python', 'Analytics'],
      'connections': 156,
    },
  ];

  List<Map<String, dynamic>> get _filteredProfessionals {
    return _professionals.where((prof) {
      final locationMatch =
          _selectedLocation == 'All' || prof['location'] == _selectedLocation;
      final fieldMatch =
          _selectedField == 'All' || prof['field'] == _selectedField;
      return locationMatch && fieldMatch;
    }).toList();
  }

  void _connectWithProfessional(Map<String, dynamic> professional) {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Connection request sent to ${professional['name']}!',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
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
              child: _filteredProfessionals.isEmpty
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredProfessionals.length,
                      itemBuilder: (context, index) {
                        final professional = _filteredProfessionals[index];
                        return _buildProfessionalCard(professional);
                      },
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
            children: (professional['tags'] as List<String>).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B292A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _connectWithProfessional(professional),
              icon: const Icon(Icons.person_add),
              label: const Text('Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
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
}
