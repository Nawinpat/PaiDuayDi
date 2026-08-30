import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetails {
  const RouteDetails({
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final String encodedPolyline;
  final int distanceMeters;
  final int durationSeconds;

  String get distanceLabel {
    if (distanceMeters < 1000) return '$distanceMeters ม.';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} กม.';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes นาที';
    final hours = minutes ~/ 60;
    return '$hours ชม. ${minutes % 60} นาที';
  }

  List<LatLng> get points => _decodePolyline(encodedPolyline);
}

class RouteService {
  RouteService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<RouteDetails> computeRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final result = await _functions.httpsCallable('computeTripRoute').call({
      'origin': {'latitude': origin.latitude, 'longitude': origin.longitude},
      'destination': {
        'latitude': destination.latitude,
        'longitude': destination.longitude,
      },
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return RouteDetails(
      encodedPolyline: data['encodedPolyline'] as String,
      distanceMeters: (data['distanceMeters'] as num).round(),
      durationSeconds: (data['durationSeconds'] as num).round(),
    );
  }
}

List<LatLng> _decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  while (index < encoded.length) {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    result = 0;
    shift = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }

  return points;
}
