import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenMapScreen extends StatefulWidget {
  const FullScreenMapScreen({super.key});

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.satellite;

  // Initial camera position centered near your location in India.
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.5276, 76.2144), // Centered near Thrissur
    zoom: 14.0,
  );

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('LIVE MAP', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
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
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "zoomOut",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black),
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "mapType",
                    backgroundColor: Colors.white,
                    onPressed: _toggleMapType,
                    child: const Icon(Icons.map, color: Colors.black),
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
