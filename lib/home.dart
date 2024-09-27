import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/model/Place.dart';
import 'package:flutter_map/services/geocoding_service.dart';
import 'package:flutter_map/services/places_service.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'constants.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const LatLng source = LatLng(37.43296265331129, -122.08832357078792);
  LatLng destination = LatLng(37.33, -122.076);
  final Completer<GoogleMapController> _controller = Completer();
  LocationData? currentLocation;
  List<LatLng> polylineCoordinates = [];
  final TextEditingController _placeController = TextEditingController();
  List<Suggestions> _list = [];

  initState() {
    super.initState();
    getCurrentLocation();
  }

  void getPlaces() async {
    PlacesService.instance.getPlaces(_placeController.value.text).then(
      (response) {
        response.suggestions!.forEach(
          (element) => print(element.placePrediction!.text!.text),
        );
        setState(() {
          _list = response.suggestions!;
        });
      },
    );
  }

  Future<void> getPolylinePoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineRequest polylineRequest = PolylineRequest(
      origin:
          PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      destination: PointLatLng(destination.latitude, destination.longitude),
      mode: TravelMode.driving,
    );
    PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: googleApiKey, request: polylineRequest);

    if (polylineResult.points.isNotEmpty) {
      polylineResult.points.forEach((point) {
        print('Point: ${point.latitude}, ${point.longitude}');
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();
    // Check if location services are enabled
    if (!await location.serviceEnabled()) {
      await location.requestService();
    }
    // Check if location permission is granted
    PermissionStatus permission = await location.hasPermission();
    if (permission != PermissionStatus.granted) {
      permission = await location.requestPermission();
    }

    if (permission != PermissionStatus.granted) {
      return;
    }
    location.getLocation().then(
      (location) {
        setState(() {
          currentLocation = location;
          // _controller.future.then(
          //   (controller) {
          //     controller.animateCamera(CameraUpdate.newLatLngZoom(
          //         LatLng(
          //             currentLocation!.latitude!, currentLocation!.longitude!),
          //         11));
          //   },
          // );
        });
      },
    );

    location.onLocationChanged.listen(
      (location) {
        setState(() {
          currentLocation = location;
          // _controller.future.then(
          //   (controller) {
          //     controller.animateCamera(CameraUpdate.newLatLngZoom(
          //         LatLng(
          //             currentLocation!.latitude!, currentLocation!.longitude!),
          //         11));
          //   },
          // );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: Text('Loading...'))
          : SafeArea(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: LatLng(currentLocation!.latitude!,
                            currentLocation!.longitude!),
                        zoom: 11),
                    onMapCreated: (controller) {
                      _controller.complete(controller);
                    },
                    onTap: (locationDestination) {
                      setState(() {
                        destination = locationDestination;
                      });
                    },
                    compassEnabled: true,
                    polylines: {
                      Polyline(
                        polylineId: PolylineId("Polyline"),
                        color: Colors.blue,
                        points: polylineCoordinates,
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: MarkerId("Current Location"),
                        position: LatLng(currentLocation!.latitude!,
                            currentLocation!.longitude!),
                      ),
                      Marker(
                        markerId: MarkerId("Destination"),
                        position: destination,
                        onTap: () async => await getPolylinePoints(),
                      ),
                    },
                  ),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _placeController,
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              hintText: 'Search for place...',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                getPlaces();
                              }
                            },
                          ),
                          if (_list.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              color: Colors.white,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _list.length,
                                separatorBuilder: (context, index) => Divider(),
                                itemBuilder: (context, index) => ListTile(
                                  title: Text(_list[index]
                                      .placePrediction!
                                      .text!
                                      .text!),
                                  leading: Icon(Icons.location_on),
                                  onTap: () {
                                    setState(() {
                                      getPlaceOnMap(_list[index]
                                          .placePrediction
                                          ?.text!
                                          .text);
                                    });
                                  },
                                ),
                              ),
                            )
                          else if (_placeController.text.isNotEmpty)
                            Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 40,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              child: const Text(
                                'No plces found',
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      )),
                ],
              ),
            ),
    );
  }

  void getPlaceOnMap(String? address) {
    _placeController.clear;
    _list.clear();
    GeocodingService.instance.getLatLng(address!).then((value) {
      print('Destination: $value');
      setState(() {
        if (value != null) {
          destination = value;
          // currentLocation = LocationData.fromMap(
          //     {"latitude": value.latitude, "longitude": value.longitude});
          _controller.future.then(
            (controller) {
              controller.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(value.latitude, value.longitude), 11));
            },
          );
        }
      });
    });
  }
}
