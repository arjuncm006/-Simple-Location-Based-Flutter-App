
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'map.dart';

class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  _LocationInputScreenState createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Navigate to map with the entered location
  void _submitLocation() {
    if (_formKey.currentState!.validate()) {
      String location = _locationController.text;

      // Navigate to the map screen, passing the entered location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Mapp(enteredLocation: location),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Text field to enter location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (City, Address, Coordinates)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitLocation,
                child: Text('Submit and Show on Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}