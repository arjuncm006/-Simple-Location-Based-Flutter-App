import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loc/pages/location_input_screen.dart';
import 'package:loc/pages/map.dart';


class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Controller for the name field

  // Method to handle user registration
  Future<void> _registerUser() async {
    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the newly created user's UID
      String uid = userCredential.user!.uid;

      // Create a new collection named "users" and a document with the user's UID
      await _firestore.collection('users').doc(uid).set({
        'email': _emailController.text, // Add the email field
        'name': _nameController.text, // Add the name field
        'created_at': FieldValue.serverTimestamp(), // Add a creation timestamp
        'display_name': _nameController.text,
        'latitude': 30, // Update the latitude field
        'longitude': 20, // Update the longitude field
        'timestamp': 00,// Optionally use the name as a display name
      });

      print("User registered and user document created successfully.");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LocationInputScreen()),
      );


      // Navigate to another screen or show a success message
    } catch (e) {
      print("Error during registration: $e");
      // Handle errors (e.g., show an error message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name',border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.zero))), // Input field for the user's name
            ),
            SizedBox(height: 20,),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email',border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.zero))), // Input field for the user's email
            ),SizedBox(height: 20,),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password',border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.zero))), // Input field for the user's password
              obscureText: true, // Obscure text for password
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser, // Trigger registration process
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
