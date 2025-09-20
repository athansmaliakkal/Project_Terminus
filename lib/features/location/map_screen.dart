import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class FullScreenMapScreen extends StatefulWidget {
  const FullScreenMapScreen({super.key});

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.satellite;
  
  // These state variables will hold our generated map objects
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isDataProcessed = false;

  // This is called once when the widget is first built and has access to route arguments.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // We only want to process the data once.
    if (!_isDataProcessed) {
      // Receive the log data passed from the LocationScreen.
      final logData = ModalRoute.of(context)!.settings.arguments as List<Map<String, dynamic>>?;
      
      // Process the data to create the markers and polyline.
      if (logData != null && logData.isNotEmpty) {
        _processLogData(logData);
        _isDataProcessed = true;
      }
    }
  }

  void _processLogData(List<Map<String, dynamic>> logData) {
    final Set<Marker> markers = {};
    final List<LatLng> polylineCoordinates = [];

    for (int i = 0; i < logData.length; i++) {
      final log = logData[i];
      final lat = log['latitude'];
      final lng = log['longitude'];
      final timestamp = DateTime.parse(log['timestamp']);
      
      // Format the time for display in the marker's info window.
      final formattedTime = DateFormat('h:mm a').format(timestamp);

      final position = LatLng(lat, lng);
      polylineCoordinates.add(position);

      // Create a marker for each point.
      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: position,
          // When tapped, the marker will show the timestamp.
          infoWindow: InfoWindow(
            title: 'Log Point ${i + 1}',
            snippet: 'Time: $formattedTime',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
    }
    
    // Create the polyline that connects all the points.
    final Polyline routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.cyanAccent,
      width: 5,
      points: polylineCoordinates,
    );

    setState(() {
      _markers = markers;
      _polylines = {routePolyline};
    });
  }

  // This function automatically zooms the camera to fit the entire route.
  void _zoomToFitRoute(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    if (points.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    // Calculate the bounding box that contains all points.
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate the camera to the calculated bounds with some padding.
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }
  
  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite ? MapType.normal : MapType.satellite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text('ROUTE HISTORY', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: const CameraPosition(target: LatLng(10.5276, 76.2144), zoom: 11),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // Run the zoom logic after the map is created.
              if (_polylines.isNotEmpty) {
                  _zoomToFitRoute(_polylines.first.points);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: "zoomIn",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black),
                    onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "zoomOut",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black),
                    onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "mapType",
                    backgroundColor: Colors.white,
                    onPressed: _toggleMapType,
                    child: const Icon(Icons.layers, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

