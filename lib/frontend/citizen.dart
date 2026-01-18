import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; //for camera and gallery access
import 'package:geolocator/geolocator.dart'; //for gps coordinates
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';


class MyCitizen extends StatefulWidget {
  const MyCitizen({super.key});

  @override
  State<MyCitizen> createState() => _MyCitizenState();
}

class _MyCitizenState extends State<MyCitizen> {
  //STATE VARIABLES
  File? _selectedImage;
  final _descriptionController = TextEditingController();
  String _currentAddress = "No location set";
  bool _isAnalyzing = false; // tracking ML PROCESSING state
  bool _isLocating = false; // tracking GPs fetching state

  @override
  void dispose(){
    _descriptionController.dispose();
    super.dispose();
  }
  //PERMISSIONS AND IMAGE HANDLING
  // handling the user interaction for picking an image
  Future<void> _pickImage(ImageSource source) async{
    try{
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 90, //compressing to save bandwidth
      );
      if (image!= null) {
        setState(() {
          _selectedImage = File(image.path);
          _isAnalyzing = true; //ML loading animation
        });
        await _runMLModelPlaceholder();
        await _determinePosition();
      }
    } catch(e) {
      _showSnackBar("Error selecting image: $e", Colors.red);
    }
  }
  Future<void> _runMLModelPlaceholder() async {
    await Future.delayed(const Duration(seconds: 2)); //simulate ai processing
    setState((){
      _isAnalyzing = false;
      //auto-filling details based on recognition
      _descriptionController.text = "AI Detection: Pothole";
    });
  }

  //geolocator logic
//handling permission and getting the lat/longi_tude metadata
  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentAddress = "Latitude: ${position.latitude.toStringAsFixed(3)}, Longitude: ${position.longitude.toStringAsFixed(3)}";
        _isLocating = false;
      });
    } catch (e) {
      setState(() => _isLocating = false );
      _showSnackBar("Could NOT fetch location", Colors.orange);
    }
  }
  //adding: utility methods
  void _showSnackBar(String message, Color color){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  //hi, lol.
  @override
  Widget build(BuildContext context){
    return Scaffold(

      appBar: AppBar(
        title: Text("Report Issue", style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: const Icon(Icons.bug_report),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            //image preview box
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      :null,
                ),
                child: _selectedImage == null
                    ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    :null,
              ),
            ),

            if(_isAnalyzing) const LinearProgressIndicator(),

            const SizedBox(height: 20),

            //description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Issue description...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height:20),

            //location display
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(_currentAddress),
              trailing: _isLocating ? const CircularProgressIndicator() : null,
            ),
            const SizedBox(height: 30),

            //submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                onPressed: () => _showSnackBar("Report Submitted", Colors.green),
                child: const Text("Submit Report"),
              ),
            )
          ],
        ),
      ),
    );
  }

  //helper func to show Bottomsheet for gallery

  void _showPickerOptions() {
    showModalBottomSheet(context: context, builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Camera'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ],
      ),
    ),
    );
  }
}