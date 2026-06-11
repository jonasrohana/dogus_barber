import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/cupertino.dart';
import '../utils/models.dart';

class GooglePlacesApiCaller {

  String language = "";

  Debouncer debouncer = Debouncer<String>(initialValue: "", const Duration(milliseconds: 1000));
  final apiKey = "AIzaSyAxNsboz--MNS3mZaTCNsbstwRsOERKO84";
  bool locationChanged = false;
  String? sessionToken;
  Place? selectedPlace;

  TextEditingController streetTf = TextEditingController();
  FocusNode locationFocus = FocusNode();
  TextEditingController plzTf = TextEditingController();
  TextEditingController cityCountryTf = TextEditingController();

  late Function() reload;

  GooglePlacesApiCaller(this.reload) {
    streetTf.addListener(() => debouncer.value = streetTf.text);
    debouncer.values.listen((search) {

      if(streetTf.text != selectedPlace?.street) {
        selectedPlace = null;
      }

      // starting to type again => searching for new place
      sessionToken ??= const Uuid().v4();
      getSuggestion(streetTf.text);
      reload();
    });
    locationFocus.addListener(() => reload());
  }

  Future<List<dynamic>> getSuggestion(String input) async {
    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request = '$baseURL?input=$input&key=$apiKey&sessiontoken=$sessionToken&language=$language';
    var response = await get(Uri.parse(request));
    if (response.statusCode == 200) {
      return json.decode(response.body)['predictions'];
    } else {
      if (kDebugMode) print('Failed to load predictions');
      return [];
    }
  }

  Future<void> getPlaceDetailFromId(String placeId) async {
    final request = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields='
        'geometry,address_component&key=$apiKey&sessiontoken=$sessionToken&language=$language';
    final response = await get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final place = Place();

        // Extract latitude and longitude from the 'geometry' field
        final geometry = result['result']['geometry'];
        place.latitude = geometry['location']['lat'];
        place.longitude = geometry['location']['lng'];

        // Extract detailed address information from the 'address_components' field
        final components = result['result']['address_components'] as List<dynamic>;
        for (var c in components) {
          final List types = c['types'];
          if (types.contains('route')) {
            place.street = (place.street != null) ? '${c['long_name']} ${place.street}' : c['long_name'];
          }
          if (types.contains('street_number')) {
            place.street = (place.street != null) ? '${place.street} ${c['long_name']}' : c['long_name'];
          }
          if (types.contains('locality')) {
            place.city = c['long_name'];
          }
          if (types.contains('postal_code')) {
            place.plz = c['long_name'];
          }
          if (types.contains('country')) {
            place.country = c['long_name'];
          }
          if (types.contains('administrative_area_level_1')) {
            place.state = c['short_name'];
          }
        }

        if(!place.isValid) {
          streetTf.text = "";
          plzTf.text = "";
          cityCountryTf.text = "";
          selectedPlace = null;
          reload();
        }
        else {
          // Update the streetTf TextEditingController with the full address
          streetTf.text = "${place.street}";
          plzTf.text = place.plz ?? "";
          cityCountryTf.text = "${place.city}, ${place.country}";
          locationChanged = true;
          selectedPlace = place;
          reload();
        }
      }
    } else {
      throw Exception('Failed to fetch place details');
    }
  }

  void prefill(Place place) {
    streetTf.text = "${place.street}";
    plzTf.text = place.plz ?? "";
    cityCountryTf.text = "${place.city}, ${place.country}";
    selectedPlace = place;
  }

}