import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Myadministrator extends StatefulWidget {
  const Myadministrator({super.key});

  @override
  State<Myadministrator> createState() => _MyadministratorState();
}

class Problem {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
  });
}

class _MyadministratorState extends State<Myadministrator> {
  final Completer<GoogleMapController> _controller = Completer();

  // Sample data — replace with backend fetch later
  final List<Problem> _problems = [
    Problem(
      id: '1',
      title: 'Pothole on 4th Street',
      description: 'Large pothole causing traffic issues.',
      lat: 37.7749,
      lng: -122.4194,
    ),
    Problem(
      id: '2',
      title: 'Broken Streetlight',
      description: 'Streetlight not working near park.',
      lat: 37.7799,
      lng: -122.4294,
    ),
    Problem(
      id: '3',
      title: 'Overflowing Garbage Bin',
      description: 'Garbage bin overflowing for 3 days.',
      lat: 37.7690,
      lng: -122.4167,
    ),
  ];

  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = _problems
        .map((p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.lat, p.lng),
              infoWindow: InfoWindow(title: p.title, snippet: p.description),
              onTap: () => _showProblemBottomSheet(p),
            ))
        .toSet();
  }

  void _showProblemBottomSheet(Problem p) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(p.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: add action to mark resolved / navigate to detail
                    },
                    child: const Text('Mark Resolved'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _goToProblem(Problem p) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(p.lat, p.lng), zoom: 16),
    ));
    _showProblemBottomSheet(p);
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = CameraPosition(
      target: LatLng(_problems.first.lat, _problems.first.lng),
      zoom: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: initialCamera,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) _controller.complete(controller);
              },
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[50],
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _problems.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final p = _problems[index];
                  return ListTile(
                    title: Text(p.title),
                    subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: () => _goToProblem(p),
                    ),
                    onTap: () => _showProblemBottomSheet(p),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}