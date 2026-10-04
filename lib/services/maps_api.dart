import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteResult {
  final LatLng start;
  final LatLng end;
  final List<LatLng> points;
  final String encodedPolyline;
  final String distance;
  final String duration;

  const RouteResult({
    required this.start,
    required this.end,
    required this.points,
    required this.encodedPolyline,
    required this.distance,
    required this.duration,
  });
}

class PlaceResult {
  final String id;
  final String name;
  final String address;
  final LatLng location;

  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });
}

class MapsApi {
  final String apiKey;

  const MapsApi(this.apiKey);

  /// Cho phép nhập:
  /// 10.7769,106.7009
  /// hoặc địa chỉ: 227 Nguyễn Văn Cừ, TP.HCM
  Future<LatLng> resolveLocation(String input) async {
    final coordinate = _tryParseCoordinate(input);

    if (coordinate != null) {
      return coordinate;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': input,
        'key': apiKey,
        'language': 'vi',
        'region': 'vn',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Lỗi Geocoding API: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final String status = data['status'] ?? '';

    if (status != 'OK' || (data['results'] as List).isEmpty) {
      throw Exception(
        data['error_message'] ??
            'Không tìm thấy địa chỉ "$input". Trạng thái: $status',
      );
    }

    final location =
        data['results'][0]['geometry']['location'];

    return LatLng(
      (location['lat'] as num).toDouble(),
      (location['lng'] as num).toDouble(),
    );
  }

  Future<RouteResult> getDirections({
    required LatLng start,
    required LatLng end,
    required String mode,
  }) async {
    final String googleMode;

    switch (mode) {
      case 'walking':
        googleMode = 'walking';
        break;
      case 'bicycling':
        googleMode = 'bicycling';
        break;
      case 'two_wheeler':
        googleMode = 'two-wheeler';
        break;
      default:
        googleMode = 'driving';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      {
        'origin': '${start.latitude},${start.longitude}',
        'destination': '${end.latitude},${end.longitude}',
        'mode': googleMode,
        'key': apiKey,
        'language': 'vi',
        'region': 'vn',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Lỗi Directions API: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final String status = data['status'] ?? '';

    if (status != 'OK' || (data['routes'] as List).isEmpty) {
      throw Exception(
        data['error_message'] ??
            'Không tìm thấy tuyến đường. Trạng thái: $status',
      );
    }

    final route = data['routes'][0];
    final leg = route['legs'][0];

    final String encoded =
        route['overview_polyline']['points'];

    return RouteResult(
      start: start,
      end: end,
      points: decodePolyline(encoded),
      encodedPolyline: encoded,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
    );
  }

  Future<List<PlaceResult>> searchPlaces({
    required String keyword,
    required LatLng center,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': keyword,
        'location': '${center.latitude},${center.longitude}',
        'radius': '5000',
        'language': 'vi',
        'key': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Lỗi Places API: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final String status = data['status'] ?? '';

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception(
        data['error_message'] ??
            'Không tìm kiếm được địa điểm. Trạng thái: $status',
      );
    }

    final results = data['results'] as List? ?? [];

    return results.take(20).map((item) {
      final location = item['geometry']['location'];

      return PlaceResult(
        id: item['place_id'] ?? item['name'],
        name: item['name'] ?? 'Địa điểm',
        address: item['formatted_address'] ?? '',
        location: LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        ),
      );
    }).toList();
  }

  LatLng? _tryParseCoordinate(String input) {
    final parts = input.split(',');

    if (parts.length != 2) {
      return null;
    }

    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());

    if (latitude == null || longitude == null) {
      return null;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];

    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLatitude =
          (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      latitude += deltaLatitude;

      result = 0;
      shift = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLongitude =
          (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      longitude += deltaLongitude;

      points.add(
        LatLng(
          latitude / 100000.0,
          longitude / 100000.0,
        ),
      );
    }

    return points;
  }
}