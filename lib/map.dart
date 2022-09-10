import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();

  final location = Location();
  LatLng? userLocation = LatLng(10, 20);

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen(onLocationDataChanged);
    location.getLocation().then(onLocationDataChanged);
  }

  void onLocationDataChanged(LocationData currentLocation) {
    setState(() {
      if(currentLocation.latitude == null || currentLocation.longitude == null) {
        // userLocation = null;
      } else {
        setState(() {
          userLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return userLocation == null
        ? const Center(child: Text("Determining user location"))
        : GoogleMap(
          // onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: userLocation!,
            zoom: 11.0,
          ),
        );
  }
}