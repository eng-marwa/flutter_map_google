import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();
  Future<LatLng?> getLatLng(String address) async {
    // Call the geocoding API
    List<Location>? locations =
        await GeocodingPlatform.instance?.locationFromAddress(address);
    if (locations == null || locations.isEmpty) {
      return null;
    }
    return LatLng(locations.first.latitude, locations.first.longitude);
  }
}
