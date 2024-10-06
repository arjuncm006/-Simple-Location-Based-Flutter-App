import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loc/pages/map.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class Sorch extends StatefulWidget {
  const Sorch({super.key});

  @override
  _SorchState createState() => _SorchState();
}

class _SorchState extends State<Sorch> {
  List<Map<String, dynamic>> searchResults = []; // To hold search results

  // Method to search Firestore based on the query
  Future<void> searchFirestore(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    // Fetch documents from Firestore where 'name' contains the query
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    // Convert the result into a list of maps
    final List<Map<String, dynamic>> results = result.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [

          buildFloatingSearchBar(context),
        ],
      ),
    );
  }

  Widget buildFloatingSearchBar(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {
        searchFirestore(query); // Call the search method when query changes
      },
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: searchResults.map((result) {
                return ListTile(
                  title: Text(result['name'] ?? 'No Name'),
                  subtitle: Text('Latitude: ${result['latitude']}, Longitude: ${result['longitude']}'),
                  onTap: () {
                    // Handle marker selection or navigation
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }




}