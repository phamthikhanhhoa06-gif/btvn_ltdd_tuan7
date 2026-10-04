import 'package:geolocator/geolocator.dart';

class LocationHelper {
  LocationHelper._();

  static Future<Position> getCurrentPosition() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Vui lòng bật dịch vụ GPS.');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Bạn đã từ chối quyền truy cập vị trí.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị từ chối vĩnh viễn. '
        'Hãy cấp quyền trong phần cài đặt.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}