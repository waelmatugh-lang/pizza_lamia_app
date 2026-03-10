import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// يجلب الإحداثيات الحالية بأمان كامل.
  /// يرجع [Position] أو [null] عند الفشل.
  static Future<Position?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// يحوّل إحداثيات (lat, lng) إلى عنوان نصي قابل للقراءة.
  /// يرجع String أو null عند الفشل.
  static Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );
      if (placemarks.isEmpty) return null;
      final Placemark place = placemarks.first;

      // بناء العنوان من الأجزاء المتاحة
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
      ].where((p) => p != null && p.isNotEmpty).toList();

      return parts.isNotEmpty ? parts.join('، ') : null;
    } catch (_) {
      return null;
    }
  }

  /// يحسب المسافة بالمتر بين نقطتين جغرافيتين.
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
