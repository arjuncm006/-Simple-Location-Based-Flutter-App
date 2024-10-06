import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child('locations');

  Future<void> saveLocation(String deviceId, LatLng location) async {
    await _db.child(deviceId).set({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<LatLng>> getAllLocations() async {
    final snapshot = await _db.get(); // Use .get() instead of .once()
    List<LatLng> locations = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        locations.add(LatLng(value['latitude'], value['longitude']));
      });
    }

    return locations;
  }
}
