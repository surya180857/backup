import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:location/location.dart'; // For fetching the user's live location
import '../services/location_service.dart';
import '../widgets/location_card.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _initialZoom = 18.0;
  google_maps.LatLng? _currentPosition;  // User's current position
  TextEditingController _searchController = TextEditingController();
  Set<google_maps.Marker> _markers = {};
  Map<String, dynamic>? _selectedLocation;
  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();  // Fetch the user's current location on startup
  }

  Future<void> _getCurrentLocation() async {
    final Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      setState(() {
        _currentPosition = google_maps.LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredLocations.clear();
        _markers.clear();
      });
      return;
    }

    try {
      List<Map<String, dynamic>> locations = await LocationService().searchLocations(query);
      setState(() {
        _filteredLocations = locations;
        _markers.clear();

        for (var location in _filteredLocations) {
          google_maps.LatLng position = google_maps.LatLng(location['Latitude'], location['Longitude']);
          _markers.add(
            google_maps.Marker(
              markerId: google_maps.MarkerId(location['LocationName']),
              position: position,
              infoWindow: google_maps.InfoWindow(
                title: location['LocationName'],
                snippet: location['Description'],
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void _startNavigation() {
    if (_selectedLocation != null && _currentPosition != null) {
      // Convert Google Maps LatLng to latlong2.LatLng
      latlong2.LatLng destinationLatLng = latlong2.LatLng(
        _selectedLocation!['Latitude'],
        _selectedLocation!['Longitude'],
      );

      latlong2.LatLng currentLatLng = latlong2.LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Use pushNamed and pass the required arguments
      Navigator.pushNamed(
        context,
        '/navigation',
        arguments: {
          'currentLocation': currentLatLng,  // Pass currentLocation as latlong2.LatLng
          'destinationLocation': destinationLatLng,  // Pass destination as latlong2.LatLng
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map (3D View)'),
      ),
      body: Stack(
        children: [
          google_maps.GoogleMap(
            initialCameraPosition: google_maps.CameraPosition(
              target: _currentPosition ?? google_maps.LatLng(16.654751, 74.262860),
              zoom: _initialZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,  // Display the markers on the map
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _searchLocation,  // Trigger search when the query changes
                  decoration: InputDecoration(
                    labelText: 'Search Location',
                    hintText: 'Enter location name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_filteredLocations.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return ListTile(
                          title: Text(location['LocationName']),
                          onTap: () {
                            setState(() {
                              _selectedLocation = location;
                              _searchController.text = location['LocationName'];  // Set the search bar text
                              _filteredLocations.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 100,
              left: 20,
              child: LocationCard(
                name: _selectedLocation!['LocationName'],
                description: _selectedLocation!['Description'],
                imageUrl: _selectedLocation!['PhotoPath'],
                locationType: _selectedLocation!['LocationType'],
                onStartNavigation: _startNavigation,  // Start navigation button
              ),
            ),
        ],
      ),
    );
  }
}
