import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For camera and gallery access
import 'package:geolocator/geolocator.dart'; // For GPS coordinates
import 'package:google_fonts/google_fonts.dart'; // Modern typography
import 'dart:io';
import 'package:chitradartaa/frontend/auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyCitizen extends StatefulWidget {
  const MyCitizen({super.key});
  

  @override
  State<MyCitizen> createState() => _MyCitizenState();
}

class _MyCitizenState extends State<MyCitizen> {
  // --- STATE VARIABLES ---
  int _selectedIndex = 0;
  File? _selectedImage;
  final _descriptionController = TextEditingController();
  String _currentAddress = "Tap to pin location";
  bool _isAnalyzing = false; // Tracks ML processing state

  double _confidenceScore = 0.0;
  String _prediction = "Awaiting image...";


  @override
void initState() {
  super.initState();
  _checkAuth();
} //for bypassing

Future<void> _checkAuth() async {
  bool loggedIn = await AuthService.isLoggedIn();
  if (!loggedIn && mounted) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC METHODS ---

  // Unified Image Picker: Handles both selection and triggering AI/GPS logic
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isAnalyzing = true; // Show loading animation for ML
        });

        // Automatically trigger location fetching after photo is taken
        await _determinePosition();
        await _sendForInference();
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Unified Location Logic: Handles permissions and fetching coordinates
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentAddress = "Lat: ${position.latitude.toStringAsFixed(3)}, Long: ${position.longitude.toStringAsFixed(3)}";
      });
    } catch (e) {
      _showSnackBar("Could not fetch location", Colors.orange);
    }
  }

  
  // -------------------- BASE64 --------------------

  Future<String> image_to_base64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  // -------------------- BACKEND CALL --------------------

  Future<void> _sendForInference() async {
    try {
      setState(() => _isAnalyzing = true);

      final token = await AuthService.getToken();
      final base64Image = await image_to_base64(_selectedImage!);

      final response = await http.post(
        Uri.parse("http://10.0.2.2:6969/api/infer"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "image": base64Image,
          "location": _currentAddress,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Inference failed");
      }

      final data = jsonDecode(response.body);

      setState(() {
        _isAnalyzing = false;
        _prediction = "Issue Detected";
        _confidenceScore = data["confidence_score"];
      });

    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showSnackBar("Inference failed", Colors.red);
    }
  }


  // Unified Snackbar for feedback
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // Logic to handle final submission
  void _submitReport() {
    _showSnackBar("Report Submitted Successfully", Colors.green);
    setState(() {
      _selectedImage = null;
      _descriptionController.clear();
      _selectedIndex = 1; // NEW: Automatically jump to 'My Reports' tab after submission
    });
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // NEW: Modern off-white background
      appBar: AppBar(
        title: Text("CitizenConnect", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
    await AuthService.logout(); // This removes the token from SharedPreferences
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); // Send back to login
  }
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex, // Keeps tab states alive
        children: [
          _buildReportTab(),        // Submission Form
          _buildContributionsTab(), // NEW: Status Tracking Timeline
          _buildSocialCircleTab(),  // NEW: Social/Nearby Tab
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Submit"), // FIXED: Valid icon
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "My Impact"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: "Social"),
        ],
      ),
    );
  }

  // TAB 1: SUBMISSION FORM
  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImpactCard(), // NEW: Gamified impact card
          const SizedBox(height: 25),
          Text("Report New Issue", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          // Image Preview
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
              ),
              child: _selectedImage == null ? const Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey) : null,
            ),
          ),
          
          if (_isAnalyzing) const LinearProgressIndicator(),

          // NEW: Prediction Metadata Display
          if (_selectedImage != null && !_isAnalyzing) _buildAIPanel(),

          const SizedBox(height: 20),
          _buildLocationTile(),
          
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Additional details...",
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _submitReport,
              child: const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // NEW: Gamified Header
  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.emoji_events, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Level 4 Citizen", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("12 Issues Solved", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: AI Feedback Panel
  Widget _buildAIPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("AI Result: $_prediction", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          Text("${(_confidenceScore * 100).toInt()}% Confidence"),
        ],
      ),
    );
  }

  Widget _buildLocationTile() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.redAccent),
        title: Text(_currentAddress, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.my_location),
        onTap: _determinePosition,
      ),
    );
  }

  // TAB 2: CONTRIBUTIONS TIMELINE
  Widget _buildContributionsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Active Reports", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
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
      child: ExpansionTile(
        leading: Icon(isSolved ? Icons.check_circle : Icons.pending, color: isSolved ? Colors.green : Colors.orange),
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
        Icon(done ? Icons.check_circle : Icons.circle_outlined, size: 16, color: done ? Colors.blue : Colors.grey),
        const SizedBox(width: 10, height: 25),
        Text(label, style: TextStyle(color: done ? Colors.black : Colors.grey)),
      ],
    );
  }

  // TAB 3: SOCIAL
  Widget _buildSocialCircleTab() {
    return const Center(child: Text("Nearby community reports appearing soon!"));
  }
}