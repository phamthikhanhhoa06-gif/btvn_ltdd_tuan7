import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import '../models/favorite_route.dart';
import '../services/maps_api.dart';
import '../services/route_database.dart';
import '../utils/location_helper.dart';

class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() =>
      _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  final MapsApi _mapsApi =
      const MapsApi(AppConfig.googleMapsApiKey);

  final TextEditingController _startController =
      TextEditingController();

  final TextEditingController _endController =
      TextEditingController();

  GoogleMapController? _mapController;

  final Map<MarkerId, Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _currentPosition;
  LatLng? _startPosition;
  LatLng? _endPosition;

  RouteResult? _routeResult;

  String _mode = 'driving';
  String? _pointBeingSelected;
  bool _isLoading = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position =
          await LocationHelper.getCurrentPosition();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = location;
        _setMarker(
          id: 'current',
          position: location,
          title: 'Vị trí hiện tại',
          color: BitmapDescriptor.hueAzure,
        );
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _setMarker({
    required String id,
    required LatLng position,
    required String title,
    double color = BitmapDescriptor.hueRed,
    String? snippet,
  }) {
    _markers[MarkerId(id)] = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(color),
    );
  }

  Future<void> _useCurrentAsStart() async {
    if (_currentPosition == null) {
      await _loadCurrentLocation();
    }

    if (_currentPosition == null) return;

    setState(() {
      _startPosition = _currentPosition;
      _startController.text =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';

      _setMarker(
        id: 'start',
        position: _startPosition!,
        title: 'Điểm xuất phát',
        color: BitmapDescriptor.hueGreen,
      );
    });
  }

  Future<void> _useCurrentAsEnd() async {
    if (_currentPosition == null) {
      await _loadCurrentLocation();
    }

    if (_currentPosition == null) return;

    setState(() {
      _endPosition = _currentPosition;
      _endController.text =
          '${_currentPosition!.latitude},${_currentPosition!.longitude}';

      _setMarker(
        id: 'end',
        position: _endPosition!,
        title: 'Điểm đến',
        color: BitmapDescriptor.hueRed,
      );
    });
  }

  void _onMapTap(LatLng point) {
    if (_pointBeingSelected == null) {
      _showMessage(
        'Hãy chọn "Chọn điểm đi" hoặc "Chọn điểm đến" trước.',
      );
      return;
    }

    setState(() {
      if (_pointBeingSelected == 'start') {
        _startPosition = point;
        _startController.text =
            '${point.latitude},${point.longitude}';

        _setMarker(
          id: 'start',
          position: point,
          title: 'Điểm xuất phát',
          color: BitmapDescriptor.hueGreen,
        );
      } else {
        _endPosition = point;
        _endController.text =
            '${point.latitude},${point.longitude}';

        _setMarker(
          id: 'end',
          position: point,
          title: 'Điểm đến',
          color: BitmapDescriptor.hueRed,
        );
      }

      _pointBeingSelected = null;
    });
  }

  Future<void> _findRoute() async {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập điểm đi và điểm đến.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final start = await _mapsApi.resolveLocation(
        _startController.text.trim(),
      );

      final end = await _mapsApi.resolveLocation(
        _endController.text.trim(),
      );

      final result = await _mapsApi.getDirections(
        start: start,
        end: end,
        mode: _mode,
      );

      setState(() {
        _startPosition = start;
        _endPosition = end;
        _routeResult = result;

        _setMarker(
          id: 'start',
          position: start,
          title: 'Điểm xuất phát',
          color: BitmapDescriptor.hueGreen,
        );

        _setMarker(
          id: 'end',
          position: end,
          title: 'Điểm đến',
          color: BitmapDescriptor.hueRed,
        );

        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: result.points,
              color: Colors.blue,
              width: 6,
            ),
          );
      });

      await _fitRoute(start, end);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fitRoute(LatLng start, LatLng end) async {
    final southWest = LatLng(
      start.latitude < end.latitude
          ? start.latitude
          : end.latitude,
      start.longitude < end.longitude
          ? start.longitude
          : end.longitude,
    );

    final northEast = LatLng(
      start.latitude > end.latitude
          ? start.latitude
          : end.latitude,
      start.longitude > end.longitude
          ? start.longitude
          : end.longitude,
    );

    try {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: southWest,
            northeast: northEast,
          ),
          80,
        ),
      );
    } catch (_) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(start, 14),
      );
    }
  }

  Future<void> _searchPlaces(String keyword) async {
    final center =
        _currentPosition ?? _startPosition ?? _endPosition;

    if (center == null) {
      _showMessage('Chưa xác định được vị trí tìm kiếm.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final places = await _mapsApi.searchPlaces(
        keyword: keyword,
        center: center,
      );

      setState(() {
        _markers.removeWhere(
          (id, marker) => id.value.startsWith('place_'),
        );

        for (final place in places) {
          _setMarker(
            id: 'place_${place.id}',
            position: place.location,
            title: place.name,
            snippet: place.address,
            color: BitmapDescriptor.hueOrange,
          );
        }
      });

      _showMessage('Tìm thấy ${places.length} địa điểm.');
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveFavorite() async {
    final result = _routeResult;

    if (result == null) {
      _showMessage('Hãy tìm tuyến đường trước khi lưu.');
      return;
    }

    final favorite = FavoriteRoute(
      startText: _startController.text.trim(),
      endText: _endController.text.trim(),
      startLat: result.start.latitude,
      startLng: result.start.longitude,
      endLat: result.end.latitude,
      endLng: result.end.longitude,
      mode: _mode,
      distance: result.distance,
      duration: result.duration,
      encodedPolyline: result.encodedPolyline,
    );

    await RouteDatabase.instance.insertRoute(favorite);
    _showMessage('Đã lưu tuyến đường yêu thích.');
  }

  Future<void> _showFavorites() async {
    final routes = await RouteDatabase.instance.getRoutes();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        if (routes.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Chưa có tuyến đường yêu thích.'),
            ),
          );
        }

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];

            return ListTile(
              leading: const Icon(Icons.route),
              title: Text(
                '${route.startText} → ${route.endText}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${route.distance} • ${route.duration}',
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _restoreFavorite(route);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await RouteDatabase.instance
                      .deleteRoute(route.id!);

                  if (bottomSheetContext.mounted) {
                    Navigator.pop(bottomSheetContext);
                  }

                  _showFavorites();
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _restoreFavorite(FavoriteRoute favorite) async {
    final start = LatLng(
      favorite.startLat,
      favorite.startLng,
    );

    final end = LatLng(
      favorite.endLat,
      favorite.endLng,
    );

    final points = MapsApi.decodePolyline(
      favorite.encodedPolyline,
    );

    setState(() {
      _startController.text = favorite.startText;
      _endController.text = favorite.endText;
      _mode = favorite.mode;
      _startPosition = start;
      _endPosition = end;

      _routeResult = RouteResult(
        start: start,
        end: end,
        points: points,
        encodedPolyline: favorite.encodedPolyline,
        distance: favorite.distance,
        duration: favorite.duration,
      );

      _setMarker(
        id: 'start',
        position: start,
        title: 'Điểm xuất phát',
        color: BitmapDescriptor.hueGreen,
      );

      _setMarker(
        id: 'end',
        position: end,
        title: 'Điểm đến',
        color: BitmapDescriptor.hueRed,
      );

      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 6,
          ),
        );
    });

    await _fitRoute(start, end);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildInputArea() {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _startController,
              decoration: InputDecoration(
                labelText: 'Điểm xuất phát',
                hintText: 'Nhập địa chỉ hoặc lat,lng',
                prefixIcon:
                    const Icon(Icons.trip_origin),
                suffixIcon: IconButton(
                  tooltip: 'Lấy vị trí hiện tại',
                  onPressed: _useCurrentAsStart,
                  icon: const Icon(Icons.my_location),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endController,
              decoration: InputDecoration(
                labelText: 'Điểm đến',
                hintText: 'Nhập địa chỉ hoặc lat,lng',
                prefixIcon:
                    const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  tooltip: 'Lấy vị trí hiện tại',
                  onPressed: _useCurrentAsEnd,
                  icon: const Icon(Icons.my_location),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _mode,
                    decoration: const InputDecoration(
                      labelText: 'Phương tiện',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'driving',
                        child: Text('Ô tô'),
                      ),
                      DropdownMenuItem(
                        value: 'walking',
                        child: Text('Đi bộ'),
                      ),
                      DropdownMenuItem(
                        value: 'bicycling',
                        child: Text('Xe đạp'),
                      ),
                      DropdownMenuItem(
                        value: 'two_wheeler',
                        child: Text('Xe máy'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _mode = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _findRoute,
                  icon: const Icon(Icons.directions),
                  label: const Text('Tìm đường'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _pointBeingSelected = 'start';
                    });

                    _showMessage(
                      'Nhấn lên bản đồ để chọn điểm xuất phát.',
                    );
                  },
                  child: const Text('Chọn điểm đi'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _pointBeingSelected = 'end';
                    });

                    _showMessage(
                      'Nhấn lên bản đồ để chọn điểm đến.',
                    );
                  },
                  child: const Text('Chọn điểm đến'),
                ),
                OutlinedButton.icon(
                  onPressed: _saveFavorite,
                  icon: const Icon(Icons.favorite),
                  label: const Text('Lưu'),
                ),
                OutlinedButton.icon(
                  onPressed: _showFavorites,
                  icon: const Icon(Icons.list),
                  label: const Text('Đã lưu'),
                ),
              ],
            ),
            if (_routeResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Khoảng cách: ${_routeResult!.distance}'
                  '   •   Thời gian: ${_routeResult!.duration}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.hotel),
                    label: const Text('Khách sạn'),
                    onPressed: () =>
                        _searchPlaces('khách sạn'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.restaurant),
                    label: const Text('Quán ăn'),
                    onPressed: () =>
                        _searchPlaces('quán ăn'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar:
                        const Icon(Icons.local_hospital),
                    label: const Text('Bệnh viện'),
                    onPressed: () =>
                        _searchPlaces('bệnh viện'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.school),
                    label: const Text('Trường học'),
                    onPressed: () =>
                        _searchPlaces('trường học'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm đường Google Maps'),
      ),
      body: Column(
        children: [
          _buildInputArea(),
          if (_isLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _markers.values.toSet(),
              polylines: _polylines,
              myLocationEnabled: _currentPosition != null,
              myLocationButtonEnabled: true,
              onTap: _onMapTap,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}