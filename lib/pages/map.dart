import 'dart:async'; // Import the dart async package for Timer
import 'dart:convert';  // For decoding JSON
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

 // For HTTP requests

class Mapp extends StatefulWidget {
  final String enteredLocation; // Location entered by the user

  const Mapp({super.key, required this.enteredLocation});

  @override
  State<Mapp> createState() => _MappState();
}

class _MappState extends State<Mapp> {
  User? user = FirebaseAuth.instance.currentUser;
  LatLng? _currentLocation;
  LatLng? _enteredLocationCoords;
  double _zoomLevel = 9.2;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get current location
    _getEnteredLocation(); // Convert entered location to coordinates
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Method to convert entered location (string) to coordinates using Nominatim API
  Future<void> _getEnteredLocation() async {
    final location = widget.enteredLocation;

    // Encode the entered location for use in the URL
    final encodedLocation = Uri.encodeComponent(location);

    // Construct the Nominatim API URL
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedLocation&format=json&limit=1');

    try {
      // Send the request to Nominatim
      final response = await http.get(url);

      // Check if the response is successful
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.isNotEmpty) {
          // Extract latitude and longitude from the response
          final lat = double.parse(responseData[0]['lat']);
          final lon = double.parse(responseData[0]['lon']);
          _enteredLocationCoords = LatLng(lat, lon);

          setState(() {
            _zoomLevel = 12.0;  // Zoom in on the entered location
          });
        } else {
          print('No results found for the entered location');
          // Handle case where no results were found
        }
      } else {
        print('Failed to load data from Nominatim');
      }
    } catch (e) {
      print('Error fetching location data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final locationData = await location.getLocation();
    setState(() {
      _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
    });

    _updateLocationInFirebase(locationData.latitude!, locationData.longitude!);
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _getCurrentLocation();
    });
  }

  Future<void> _updateLocationInFirebase(
      double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(user?.uid).update({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Location data updated in Firebase');
    } catch (e) {
      print('Error updating location data: $e');
    }
  }

  Future<List<Marker>> _buildMarkers() async {
    List<Marker> markers = [];

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      for (var doc in querySnapshot.docs) {
        if (doc.id != user?.uid) {
          final data = doc.data() as Map<String, dynamic>;
          final latitude = data['latitude'];
          final longitude = data['longitude'];
          final name = data['name'];
          final timestamp = data['timestamp']?.toDate();

          if (latitude != null && longitude != null) {
            markers.add(
              Marker(
                point: LatLng(latitude, longitude),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 40),
                    Text(name ?? 'Unknown', style: TextStyle(fontSize: 12)),
                    Text(
                      timestamp != null
                          ? '${timestamp.year}-${timestamp.month}-${timestamp.day} ${timestamp.hour}:${timestamp.minute}'
                          : 'No Date',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching markers: $e');
    }

    // Add marker for entered location
    if (_enteredLocationCoords != null) {
      markers.add(
        Marker(
          point: _enteredLocationCoords!,
          width: 80,
          height: 80,
          child: Icon(Icons.location_on_outlined, color: Colors.blue, size: 40),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Marker>>(
        future: _buildMarkers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching markers'));
          }

          List<Marker> markers = snapshot.data!;

          return FlutterMap(
            options: MapOptions(
              initialCenter: _enteredLocationCoords ?? _currentLocation!,
              initialZoom: _zoomLevel,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: markers),
              CurrentLocationLayer(),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse(
                        'https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}