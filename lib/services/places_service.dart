import 'dart:convert';

import 'package:flutter_map/model/Place.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PlacesService {
  PlacesService._();

  static final PlacesService instance = PlacesService._();

  Future<PlacesResponse> getPlaces(String input) async {
    String url = 'https://places.googleapis.com/v1/places:autocomplete';
    print('URL: $url');
    http.Response response = await http.post(Uri.parse(url),
        headers: {'X-Goog-Api-Key': googleApiKey}, body: {'input': input});
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      print('Response: $jsonData');
      return PlacesResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch places');
    }
  }
}
