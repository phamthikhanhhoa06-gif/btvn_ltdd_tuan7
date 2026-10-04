class FavoriteRoute {
  final int? id;
  final String startText;
  final String endText;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String mode;
  final String distance;
  final String duration;
  final String encodedPolyline;

  const FavoriteRoute({
    this.id,
    required this.startText,
    required this.endText,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.mode,
    required this.distance,
    required this.duration,
    required this.encodedPolyline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startText': startText,
      'endText': endText,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'mode': mode,
      'distance': distance,
      'duration': duration,
      'encodedPolyline': encodedPolyline,
    };
  }

  factory FavoriteRoute.fromMap(Map<String, dynamic> map) {
    return FavoriteRoute(
      id: map['id'] as int,
      startText: map['startText'],
      endText: map['endText'],
      startLat: map['startLat'],
      startLng: map['startLng'],
      endLat: map['endLat'],
      endLng: map['endLng'],
      mode: map['mode'],
      distance: map['distance'],
      duration: map['duration'],
      encodedPolyline: map['encodedPolyline'],
    );
  }
}