// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class Myadministrator extends StatefulWidget {
//   const Myadministrator({super.key});

//   @override
//   State<Myadministrator> createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<Myadministrator> {
//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};
  
//   List<Map<String, dynamic>> issues = [
//     {
//       'id': 1,
//       'title': 'Pothole on Main Street',
//       'description': 'Large pothole causing traffic issues',
//       'location': {'lat': 27.7172, 'lng': 85.3240},
//       'status': 'reported',
//       'timestamp': '2 hours ago',
//       'reporter': 'John Doe'
//     },
//     {
//       'id': 2,
//       'title': 'Broken Street Light',
//       'description': 'Street light not working near park',
//       'location': {'lat': 27.7140, 'lng': 85.3200},
//       'status': 'deployed',
//       'timestamp': '5 hours ago',
//       'reporter': 'Jane Smith'
//     },
//     {
//       'id': 3,
//       'title': 'Garbage Accumulation',
//       'description': 'Waste not collected for 3 days',
//       'location': {'lat': 27.7190, 'lng': 85.3280},
//       'status': 'resolved',
//       'timestamp': '1 day ago',
//       'reporter': 'Mike Johnson'
//     },
//     {
//       'id': 4,
//       'title': 'Water Leakage',
//       'description': 'Water pipe leaking continuously',
//       'location': {'lat': 27.7160, 'lng': 85.3220},
//       'status': 'underprocessed',
//       'timestamp': '3 hours ago',
//       'reporter': 'Sarah Williams'
//     }
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _updateMarkers();
//   }

//   void _updateMarkers() {
//     _markers.clear();
//     for (var issue in issues) {
//       _markers.add(
//         Marker(
//           markerId: MarkerId(issue['id'].toString()),
//           position: LatLng(
//             issue['location']['lat'],
//             issue['location']['lng'],
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             _getMarkerColor(issue['status']),
//           ),
//           infoWindow: InfoWindow(
//             title: issue['title'],
//             snippet: issue['status'],
//           ),
//         ),
//       );
//     }
//     setState(() {});
//   }

//   double _getMarkerColor(String status) {
//     switch (status) {
//       case 'reported':
//         return BitmapDescriptor.hueRed;
//       case 'deployed':
//         return BitmapDescriptor.hueOrange;
//       case 'underprocessed':
//         return BitmapDescriptor.hueBlue;
//       case 'resolved':
//         return BitmapDescriptor.hueGreen;
//       default:
//         return BitmapDescriptor.hueRed;
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'reported':
//         return const Color(0xFFEF4444);
//       case 'deployed':
//         return const Color(0xFFF59E0B);
//       case 'underprocessed':
//         return const Color(0xFF3B82F6);
//       case 'resolved':
//         return const Color(0xFF10B981);
//       default:
//         return Colors.grey;
//     }
//   }

//   String _getStatusLabel(String status) {
//     switch (status) {
//       case 'reported':
//         return 'Reported';
//       case 'deployed':
//         return 'Deployed';
//       case 'underprocessed':
//         return 'Under Process';
//       case 'resolved':
//         return 'Resolved';
//       default:
//         return status;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'reported':
//         return Icons.error_outline;
//       case 'deployed':
//         return Icons.navigation;
//       case 'underprocessed':
//         return Icons.access_time;
//       case 'resolved':
//         return Icons.check_circle_outline;
//       default:
//         return Icons.info_outline;
//     }
//   }

//   void _updateIssueStatus(int id, String newStatus) {
//     setState(() {
//       int index = issues.indexWhere((issue) => issue['id'] == id);
//       if (index != -1) {
//         issues[index]['status'] = newStatus;
//         _updateMarkers();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       body: Column(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF9333EA), Color(0xFF2563EB)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 10,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'CitizenConnect Admin',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Community Issue Management',
//                   style: TextStyle(
//                     color: Colors.purple[100],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 320,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 8,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(24),
//                       child: Stack(
//                         children: [
//                           GoogleMap(
//                             initialCameraPosition: const CameraPosition(
//                               target: LatLng(27.7172, 85.3240),
//                               zoom: 13,
//                             ),
//                             markers: _markers,
//                             onMapCreated: (controller) {
//                               _mapController = controller;
//                             },
//                           ),
//                           Positioned(
//                             bottom: 16,
//                             right: 16,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.95),
//                                 borderRadius: BorderRadius.circular(16),
//                                 boxShadow: const [
//                                   BoxShadow(
//                                     color: Colors.black12,
//                                     blurRadius: 8,
//                                     offset: Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                               padding: const EdgeInsets.all(12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Text(
//                                     'Status Legend',
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.bold,
//                                       color: Color(0xFF374151),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   _buildLegendItem('Reported', const Color(0xFFEF4444)),
//                                   _buildLegendItem('Deployed', const Color(0xFFF59E0B)),
//                                   _buildLegendItem('Under Process', const Color(0xFF3B82F6)),
//                                   _buildLegendItem('Resolved', const Color(0xFF10B981)),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'Active Issues',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1F2937),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ...issues.map((issue) => _buildIssueCard(issue)).toList(),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, Color color) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 10,
//               color: Color(0xFF4B5563),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIssueCard(Map<String, dynamic> issue) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   issue['title'],
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1F2937),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(issue['status']).withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _getStatusIcon(issue['status']),
//                       size: 14,
//                       color: _getStatusColor(issue['status']),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       _getStatusLabel(issue['status']),
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: _getStatusColor(issue['status']),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             issue['description'],
//             style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF4B5563),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               const Icon(Icons.access_time, size: 12, color: Color(0xFF6B7280)),
//               const SizedBox(width: 4),
//               Text(
//                 issue['timestamp'],
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Color(0xFF6B7280),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 'Reporter: ${issue['reporter']}',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Color(0xFF6B7280),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: [
//               if (issue['status'] != 'deployed')
//                 _buildActionButton(
//                   label: 'Deploy',
//                   icon: Icons.navigation,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
//                   ),
//                   onPressed: () => _updateIssueStatus(issue['id'], 'deployed'),
//                 ),
//               if (issue['status'] != 'underprocessed' && issue['status'] != 'resolved')
//                 _buildActionButton(
//                   label: 'Under Process',
//                   icon: Icons.access_time,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
//                   ),
//                   onPressed: () => _updateIssueStatus(issue['id'], 'underprocessed'),
//                 ),
//               if (issue['status'] != 'resolved')
//                 _buildActionButton(
//                   label: 'Mark Resolved',
//                   icon: Icons.check_circle_outline,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF10B981), Color(0xFF059669)],
//                   ),
//                   onPressed: () => _updateIssueStatus(issue['id'], 'resolved'),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required String label,
//     required IconData icon,
//     required Gradient gradient,
//     required VoidCallback onPressed,
//   }) {
//     return InkWell(
//       onTap: onPressed,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           gradient: gradient,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 6,
//               offset: Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 16, color: Colors.white),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class Myadministrator extends StatefulWidget {
  const Myadministrator({super.key});

  @override
  State<Myadministrator> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Myadministrator> {
  @override
  Widget build(BuildContext context) {
    return  Container(
      child: Scaffold(
        //dsa
      )
    );
  }
}