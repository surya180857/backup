import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:polyline_codec/polyline_codec.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destinationLocation;

  const NavigationScreen({
    Key? key,
    required this.currentLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  bool _isNavigating = false;
  bool _isLoading = true; // To show loading while fetching route
  String? _errorMessage;  // To display error message if there's any issue fetching the route
  final String _valhallaUrl = 'http://172.16.9.207:8002/route'; // Your Valhalla API endpoint

  @override
  void initState() {
    super.initState();
    _fetchRouteFromValhalla();
  }

  Future<void> _fetchRouteFromValhalla() async {
    final requestBody = jsonEncode({
      "locations": [
        {"lat": widget.currentLocation.latitude, "lon": widget.currentLocation.longitude},
        {"lat": widget.destinationLocation.latitude, "lon": widget.destinationLocation.longitude},
      ],
      "costing": "pedestrian",
      "directions_options": {"units": "km"}
    });

    try {
      final response = await http.post(
        Uri.parse(_valhallaUrl),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['trip'] != null && data['trip']['legs'] != null) {
          final encodedPolyline = data['trip']['legs'][0]['shape'];
          final decodedPoints = _decodePolyline(encodedPolyline);
          setState(() {
            _polylinePoints = decodedPoints;
            _isNavigating = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No route found.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch route: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching route: $e';
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    final decoded = PolylineCodec.decode(encoded);
    for (var point in decoded) {
      points.add(LatLng(point[0].toDouble() / 10, point[1].toDouble() / 10)); // Decode polyline
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _polylinePoints.isNotEmpty ? _polylinePoints.first : widget.currentLocation,
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _polylinePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()),  // Show loading spinner
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (_isNavigating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Navigating...'),
            ),
        ],
      ),
    );
  }
}
