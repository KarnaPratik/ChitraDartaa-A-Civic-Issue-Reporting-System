import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:chitradartaa/frontend/auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Added for username access
import 'package:flutter/foundation.dart' show kIsWeb; //for platform check
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class MyCitizen extends StatefulWidget {
  const MyCitizen({super.key});

  @override
  State<MyCitizen> createState() => _MyCitizenState();
}

class _MyCitizenState extends State<MyCitizen> {
  // --- STATE VARIABLES ---
  int _selectedIndex = 0;
  XFile? _selectedImage;
  final _descriptionController = TextEditingController();
  String _currentAddress = "Tap to pin location";
  bool _isAnalyzing = false;
  double _confidenceScore = 0.0;
  String _prediction = "Awaiting image...";
  bool _isLoading = true;
  bool _isFetching = false;//for notifications
  int _refreshCounter = 0;


  // NEW: Configurable backend URL - CHANGE THIS BASED ON YOUR SETUP
  static const String backendUrl = AuthService.url; // Using ngrok URL from AuthService
  // For Android Emulator without ngrok: "http://10.0.2.2:6969"
  // For physical device without ngrok: "http://COMPUTER_IP:6969"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
      _testBackendConnection(); // NEW: Test connection on startup
    });
  }
void _refreshData() {
  setState(() {
    _refreshCounter++;
    // in the My Impact tab to re-run its future.
    print("Refreshing user reports... Sequence: $_refreshCounter" );
  });
}
void _showFullImage(String base64String) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          // The actual image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(
              base64Decode(base64String),
              fit: BoxFit.contain,
            ),
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
  // NEW: Test backend connectivity
  Future<void> _testBackendConnection() async {
    try {
      print("Testing backend connection to: $backendUrl");
      
      // Try a public endpoint first (if you have one)
      final response = await http.get(
        Uri.parse("$backendUrl/api/health"), // Should be a public endpoint
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception("Backend connection timeout");
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        // 404 means server is reachable but endpoint doesn't exist (still good)
        print("Backend connection successful");
      } else {
        print("Backend responded with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Backend connection failed: $e");
      if (mounted) {
        _showSnackBar(
          "Warning: Cannot reach backend server. Check your network configuration.",
          Colors.orange,
        );
      }
    }
  }

  Future<void> _checkAuth() async {
    try {
      print("Starting auth check...");
      bool loggedIn = await AuthService.isLoggedIn();
      bool admin_me = await AuthService.isAdmin();
      print("Auth check result: $loggedIn");
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      if (!loggedIn || admin_me) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            print("Navigating to login... Please login again!");
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    } catch (e) {
      print("Auth check error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar("Authentication error. Please login again.", Colors.red);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC METHODS ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image; //for xfile
  
        });

        await _determinePosition();
    
      }
    } catch (e) {
      print("Image picker error: $e");
      _showSnackBar("Error picking image: $e", Colors.red);
      setState(() => _isAnalyzing = false);
    }
  }

  double? _latitude;
  double? _longitude;

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permission denied", Colors.orange);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permissions are permanently denied", Colors.red);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentAddress = "Lat: ${position.latitude.toStringAsFixed(3)}, Long: ${position.longitude.toStringAsFixed(3)}";
        });
      }
    } catch (e) {
      print("Location error: $e");
      _showSnackBar("Could not fetch location: $e", Colors.orange);
    }
  }

  Future<String> image_to_base64(XFile image) async {
    final bytes = await image.readAsBytes(); //works for both web & mobile
    return base64Encode(bytes);
  }

  Future<void> _sendForInference() async {
    try {
      print("Starting inference...");
      setState(() => _isAnalyzing = true);

      // Get auth token and username from SharedPreferences
      String? token = await AuthService.getToken();
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString("user");
      
      if (token == null || token.isEmpty) {
        throw Exception("No authentication token found. Please login again.");
      }

      if (username == null || username.isEmpty) {
        throw Exception("Username not found. Please login again.");
      }

      final base64Image = await image_to_base64(_selectedImage!);
      print("Image converted to base64, size: ${base64Image.length} chars");
      print("Sending request for user: $username");
      
      final uri = Uri.parse("$backendUrl/api/infer");
      print("Sending POST to: $uri");

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": username,
          "image": base64Image,
          "location": {
            "lat": _latitude, 
            "lng": _longitude,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Request timeout - backend not responding");
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 402) {
        // Token expired or invalid
        throw Exception("Session expired. Please login again.");
      }

      if (response.statusCode != 200) {
        throw Exception("Inference failed with status: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _prediction = data["label"] ?? "Issue Detected";
          _confidenceScore = (data["confidence_score"] ?? 0.0).toDouble();
        });
        _showSnackBar("Analysis complete!", Colors.green);
      }
    } catch (e) {
      print("Inference error: $e");
      if (mounted) {
        setState(() => _isAnalyzing = false);
        
        // Handle specific error cases
        if (e.toString().contains("Session expired") || e.toString().contains("authentication token")) {
          _showSnackBar("Session expired. Redirecting to login...", Colors.red);
          await AuthService.logout();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          _showSnackBar("Inference failed: ${e.toString()}", Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

Future<void> _submitReport() async {
  // Validate inputs
  if (_selectedImage == null) {
    _showSnackBar("Please select an image first", Colors.orange);
    return;
  }

  if (_latitude == null || _longitude == null) {
    _showSnackBar("Please enable location first", Colors.orange);
    return;
  }

  try {
    // Show loading indicator
    setState(() {
      _isAnalyzing  = true;
    });

    // Get user info
    final token = await AuthService.getToken();
    final username = await AuthService.getUsername(); 
    
    if (token == null || username == null) {
      _showSnackBar("Please login first", Colors.red);
      return;
    }

    // Convert image to base64
    final bytes = await _selectedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Prepare request data
    final reportData = {
      'username': username,
      'image': base64Image,
      'location': {
        'lat': _latitude,
        'lng': _longitude
      }
    };

    print('Submitting report to: ${AuthService.url}/api/infer');

    // Send to backend
    final response = await http.post(
      Uri.parse('${AuthService.url}/api/infer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(reportData),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      
      _showSnackBar(
        "Report Submitted Successfully! Label: ${result['label']}", 
        Colors.green
      );
      
      // Clear form
      setState(() {
        _selectedImage = null;
        _descriptionController.clear();
        _selectedIndex = 1; // Navigate to reports tab
        _isAnalyzing  = false;
      });
    } else {
      final error = json.decode(response.body);
      _showSnackBar(
        "Failed to submit: ${error['error']}", 
        Colors.red
      );
      setState(() {
        _isAnalyzing  = false;
      });
    }
  } catch (e) {
    print("Error submitting report: $e");
    _showSnackBar("Error: $e", Colors.red);
    setState(() {
      _isAnalyzing  = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Checking authentication..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "ChitraDartaa",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
icon: const Icon(Icons.notifications_active_outlined),
  onPressed: _isFetching ? null : () async { // Disables button while fetching
    setState(() {
      _isFetching = true;
      _selectedIndex = 1; // Jump to impact tab
    });

    _refreshData();// to update the Future
    
    // artificial delay for the future
    await Future.delayed(const Duration(seconds: 3)); 
    
    if (mounted) setState(() => _isFetching = false);
  },   
  ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildReportTab(),
          _buildContributionsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Submit",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: "My Impact",
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImpactCard(),
          const SizedBox(height: 25),
          Text(
            "Report New Issue",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_selectedImage!.path) //web uses blob URLs
                            : FileImage(File(_selectedImage!.path)) as ImageProvider, //mobile uses file paths
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tap to select image", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : null,
            ),
          ),
          if (_isAnalyzing) 
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
          if (_selectedImage != null && !_isAnalyzing) _buildAIPanel(),
          const SizedBox(height: 15),
          _buildLocationTile(),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Additional details...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _selectedImage != null ? _submitReport : null,
              child: const Text(
                "Submit Report",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.emoji_events, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Level 4 Citizen",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "12 Issues Solved",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "AI Result: $_prediction",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          Text("${(_confidenceScore * 100).toInt()}% Confidence"),
        ],
      ),
    );
  }

Widget _buildLocationTile() {
  return Column(
    children: [
      Container(
        height: 150,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_latitude ?? 27.7, _longitude ?? 85.3),
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() {
                  _latitude = point.latitude;
                  _longitude = point.longitude;
                  _currentAddress = "Pinned: ${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}";
                });
              },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_latitude != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_latitude!, _longitude!),
                    child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                  )
                ]),
            ],
          ),
        ),
      ),
      ListTile(
        title: Text(_currentAddress, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.my_location),
        onTap: _determinePosition,
      ),
    ],
  );
}

Widget _buildContributionsTab() {
  return RefreshIndicator(
    onRefresh: () async {
      // This triggers a rebuild of the FutureBuilder
      _refreshData();
    },
  child: FutureBuilder<List<Map<String, dynamic>>>(
    key: ValueKey(_refreshCounter),
    future: AuthService.fetchUserReports(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
          return ListView(
            children: [
              const SizedBox(height: 100),
              Center(child: Text("Error: ${snapshot.error}")),
            ],
          );
        }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text("No reports yet. Submit one from the first tab!")),
            ],
          );
      }

      final reports = snapshot.data!;

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildTimelineCard(
            report['label'] ?? "Issue", 
            report['status'] ?? "Pending",
            report['segmented_image'],
          );
        },
      );
    },
  ),
  );
}
Widget _buildTimelineCard(String title, String status, String? base64Image) {
  final statusConfig = {
    'solved': {'color': Colors.green, 'icon': Icons.check_circle_outline},
    'team dispatched': {'color': Colors.blue, 'icon': Icons.local_shipping_outlined},
    'official viewed': {'color': Colors.orange, 'icon': Icons.visibility_outlined},
  };

  final config = statusConfig[status.toLowerCase()] ?? 
                 {'color': Colors.grey, 'icon': Icons.help_outline};
  
  final Color themeColor = config['color'] as Color;
  final IconData themeIcon = config['icon'] as IconData;

  bool isAtLeastViewed = ['official viewed', 'team dispatched', 'solved'].contains(status.toLowerCase());
  bool isAtLeastDispatched = ['team dispatched', 'solved'].contains(status.toLowerCase());
  bool isSolved = status.toLowerCase() == 'solved';

  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ExpansionTile(
      leading: GestureDetector(
        onTap: () {
          if (base64Image != null && base64Image.isNotEmpty) {
            _showFullImage(base64Image); 
          }
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            children: [
              // 1. The Image (Replaces the question mark)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: base64Image != null && base64Image.isNotEmpty
                      ? Image.memory(
                          base64Decode(base64Image),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 20),
                        )
                      : const Icon(Icons.image, size: 20, color: Colors.grey),
                ),
              ),
              // 2. The Status Icon (Positioned at bottom right of image)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle, // FIXED: Corrected from BoxCircle
                  ),
                  child: Icon(themeIcon, color: themeColor, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor.withOpacity(0.5)),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 10),
              _buildStatusStep("Complaint Submitted", true),
              _buildStatusStep("Official Viewed", isAtLeastViewed),
              _buildStatusStep("Team Dispatched", isAtLeastDispatched),
              _buildStatusStep("Issue Solved", isSolved),
            ],
          ),
        ),
      ],
    ),
  );
}
  
  Widget _buildStatusStep(String label, bool done) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: done ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 10, height: 25),
        Text(
          label,
          style: TextStyle(color: done ? Colors.black : Colors.grey),
        ),
      ],
    );
  }
}

// The gods have blessed us.