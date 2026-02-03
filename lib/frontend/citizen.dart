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
          _buildSocialCircleTab(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: "Social",
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
              height: 200,
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
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Tap to capture", style: TextStyle(color: Colors.grey)),
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
          const SizedBox(height: 20),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.redAccent),
        title: Text(_currentAddress, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.my_location),
        onTap: _determinePosition,
      ),
    );
  }

  Widget _buildContributionsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Active Reports",
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildTimelineCard("Pothole #102", "Team Dispatched"),
        _buildTimelineCard("Illegal Trash #99", "Solved"),
      ],
    );
  }

  Widget _buildTimelineCard(String title, String status) {
    bool isSolved = status == "Solved";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        leading: Icon(
          isSolved ? Icons.check_circle : Icons.pending,
          color: isSolved ? Colors.green : Colors.orange,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Status: $status"),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                _buildStatusStep("Submitted", true),
                _buildStatusStep("Official Viewed", true),
                _buildStatusStep("Team Dispatched", !isSolved),
                _buildStatusStep("Solved", isSolved),
              ],
            ),
          )
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

  Widget _buildSocialCircleTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "Nearby community reports appearing soon!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// The gods have blessed us.