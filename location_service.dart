import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String baseUrl = "http://172.16.10.3:8000"; // Your server URL

  // Fetch location data based on search query
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      // Check if the query is empty, if so fetch all locations
      String url = query.isEmpty
          ? '$baseUrl/locations?station_id=1'  // Replace with the actual station_id you want to query
          : '$baseUrl/locations?station_id=1&LocationName=$query';  // Modify URL to pass query as parameter

      final response = await http.get(Uri.parse(url));

      print("Request URL: $url");  // Debugging - Check the URL being requested

      if (response.statusCode == 200) {
        // Parse the JSON response
        var data = json.decode(response.body);

        print("API Response: $data");  // Debugging - Check the response data

        // Check if the 'data' key exists in the response
        if (data is Map && data['data'] != null) {
          List locations = data['data']; // Access the 'data' key
          return locations.map((location) {
            return {
              'LocationName': location['LocationName'],
              'Latitude': location['Latitude'],
              'Longitude': location['Longitude'],
              'Description': location['Description'],
              'PhotoPath': location['PhotoPath'],
              'LocationType': location['LocationType'],
            };
          }).toList();
        } else {
          throw Exception("No 'data' key in the response data");
        }
      } else {
        throw Exception("Failed to fetch locations: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching locations: $e");
    }
  }
}
