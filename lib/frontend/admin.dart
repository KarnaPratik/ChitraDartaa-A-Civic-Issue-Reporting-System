  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:latlong2/latlong.dart';
  import 'package:chitradartaa/frontend/auth.dart'; 
  
  class Myadministrator extends StatefulWidget {
    const Myadministrator({super.key});

    @override
    State<Myadministrator> createState() => _MyWidgetState();
  }

  class _MyWidgetState extends State<Myadministrator> {
    // OSM Map Controller
    final MapController _mapController = MapController();
    
    // Auth Guard State
    bool _isLoading = true;

    List<Map<String, dynamic>> issues = [];

    @override
    void initState() {
      super.initState();
      _checkAuth();
    }

    // Trespassing Check Logic
    Future<void> _checkAuth() async {
      bool loggedIn = await AuthService.isLoggedIn();
      bool admin_me = await AuthService.isAdmin();
      if (!loggedIn || !admin_me) {
        if (!mounted) return;
        // If not logged in, redirect to login page immediately
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // If logged in, stop loading and show the admin panel
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        await _loadIssues();
      }
    }

    Future<void> _loadIssues() async {
      try {
        final fetchedIssues = await AuthService.fetchIssues();
        print("Fetched ${fetchedIssues.length} issues"); // Check if loaded

        final sanitizedIssues = fetchedIssues.map((issue) {
      final location = issue['location'];
      
      // Force convert lat/lng to double regardless of original type
      double lat = double.tryParse(location['lat'].toString()) ?? 0.0;
      double lng = double.tryParse(location['lng'].toString()) ?? 0.0;

      // Update the location map inside the issue
      issue['location'] = {'lat': lat, 'lng': lng};
      return issue;
    }).toList();

        setState(() {
          issues = sanitizedIssues;
        });
      } catch (e) {
        print('Error loading issues: $e');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load issues: ${e.toString()} ')),
          );
        }
      }
    }


    Future<void> _updateIssueStatus(int id, String newStatus) async {
      final success = await AuthService.updateIssueStatus(id, newStatus);
      
      try{
      if (success) {
        setState(() {
          int index = issues.indexWhere((issue) => issue['id'] == id);
          if (index != -1) {
            issues[index]['status'] = newStatus;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully')),
          );
        }
      }
      } 
      catch(e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: ${e.toString()}')),
          );
        }
      }
    }

    // --- UI Styling Helpers ---

    Color _getMarkerColor(String status) {
      switch (status) {
        case 'reported': return const Color(0xFFEF4444);
        case 'deployed': return const Color(0xFFF59E0B);
        case 'underprocessed': return const Color(0xFF3B82F6);
        case 'resolved': return const Color(0xFF10B981);
        default: return Colors.red;
      }
    }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'reported': return const Color(0xFFEF4444);
        case 'deployed': return const Color(0xFFF59E0B);
        case 'underprocessed': return const Color(0xFF3B82F6);
        case 'resolved': return const Color(0xFF10B981);
        default: return Colors.grey;
      }
    }

    String _getStatusLabel(String status) {
      switch (status) {
        case 'reported': return 'Reported';
        case 'deployed': return 'Deployed';
        case 'underprocessed': return 'Under Process';
        case 'resolved': return 'Resolved';
        default: return status;
      }
    }

    IconData _getStatusIcon(String status) {
      switch (status) {
        case 'reported': return Icons.error_outline;
        case 'deployed': return Icons.navigation;
        case 'underprocessed': return Icons.access_time;
        case 'resolved': return Icons.check_circle_outline;
        default: return Icons.info_outline;
      }
    }

    @override
    Widget build(BuildContext context) {
      // Prevent trespassing users from seeing the content during the check
      if (_isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // Header Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ChitraDartaa Admin',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Municipality Issue Management',
                        style: TextStyle(color: Colors.purple[100], fontSize: 14),
                      ),
                    ],
                  ),
                  // Logout Button
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  )
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map Section
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: const MapOptions(
                                initialCenter: LatLng(27.6194, 85.5388),
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.citizenconnect',
                                ),
                                MarkerLayer(
                                  markers: issues.map((issue) {
                                    final location = issue['location'];

    // Helper to safely parse coordinates from dynamic types
    double parseCoordinate(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final double lat = parseCoordinate(location['lat']);
    final double lng = parseCoordinate(location['lng']);
                                    

                                    return Marker(
                                      point: LatLng(lat,lng),
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.location_on,
                                        color: _getMarkerColor(issue['status']),
                                        size: 40,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            // Legend Overlay
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Status Legend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildLegendItem('Reported', const Color(0xFFEF4444)),
                                    _buildLegendItem('Deployed', const Color(0xFFF59E0B)),
                                    _buildLegendItem('Under Process', const Color(0xFF3B82F6)),
                                    _buildLegendItem('Resolved', const Color(0xFF10B981)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Active Issues',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 16),
                    ...issues.map((issue) => _buildIssueCard(issue)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildLegendItem(String label, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563))),
          ],
        ),
      );
    }

    Widget _buildIssueCard(Map<String, dynamic> issue) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(issue['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue['status']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(issue['status']), size: 14, color: _getStatusColor(issue['status'])),
                      const SizedBox(width: 4),
                      Text(_getStatusLabel(issue['status']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(issue['status']))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(issue['description'], style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(issue['timestamp'], style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(width: 16),
                Text('Reporter: ${issue['reporter']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (issue['status'] != 'deployed')
                  _buildActionButton(
                    label: 'Deploy',
                    icon: Icons.navigation,
                    gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFF59E0B)]),
                    onPressed: () => _updateIssueStatus(issue['id'], 'deployed'),
                  ),
                if (issue['status'] != 'underprocessed' && issue['status'] != 'resolved')
                  _buildActionButton(
                    label: 'Under Process',
                    icon: Icons.access_time,
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                    onPressed: () => _updateIssueStatus(issue['id'], 'underprocessed'),
                  ),
                if (issue['status'] != 'resolved')
                  _buildActionButton(
                    label: 'Mark Resolved',
                    icon: Icons.check_circle_outline,
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    onPressed: () => _updateIssueStatus(issue['id'], 'resolved'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _buildActionButton({required String label, required IconData icon, required Gradient gradient, required VoidCallback onPressed}) {
      return InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }



  // =======


  // import 'package:flutter/material.dart';
  // import 'package:chitradartaa/frontend/auth.dart';

  // class Myadministrator extends StatefulWidget {
  //   const Myadministrator({super.key});

  //   @override
  //   State<Myadministrator> createState() => _MyWidgetState();
  // }

  // class _MyWidgetState extends State<Myadministrator> {
  //    @override
  // void initState() {
  //   super.initState();
  //   _checkAuth();
  // } //for bypassing

  // Future<void> _checkAuth() async {
  //   bool loggedIn = await AuthService.isLoggedIn();
  //   if (!loggedIn) {
  //     // If no token is found, they are trespassing!
  //     if (!mounted) return;
  //     Navigator.pushReplacementNamed(context, '/login');
  //   }
  // }
  //   @override
  //   Widget build(BuildContext context) {
  //     return  Container(
  //       child: Scaffold(
  //         //dsa
  //       )
  //     );
  //   }
  // }
