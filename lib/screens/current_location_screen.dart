import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/location_helper.dart';

class CurrentLocationScreen extends StatefulWidget {
  const CurrentLocationScreen({super.key});

  @override
  State<CurrentLocationScreen> createState() =>
      _CurrentLocationScreenState();
}

class _CurrentLocationScreenState
    extends State<CurrentLocationScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  final Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position =
          await LocationHelper.getCurrentPosition();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = location;

        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId('current'),
              position: location,
              infoWindow: const InfoWindow(
                title: 'Vị trí hiện tại',
              ),
            ),
          );
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16),
        ),
      );
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài 1 - Vị trí hiện tại'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: _currentPosition != null,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;

          if (_currentPosition != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                _currentPosition!,
                16,
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}