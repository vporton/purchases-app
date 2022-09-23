import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:marker_icon/marker_icon.dart';
import 'package:sqflite/sqflite.dart';

class MyMap extends StatefulWidget {
  Database? db;
  final Function(LatLng)? onMove;

  MyMap({super.key, required this.db, this.onMove});

  @override
  State<MyMap> createState() => MyMapState();
}

class _PlaceInfo {
  int id;
  final String googleId;
  final String name;
  final String iconUrl;
  final double lat;
  final double lng;

  _PlaceInfo(
      {required this.id,
      required this.googleId,
      required this.name,
      required this.iconUrl,
      required this.lat,
      required this.lng});

  bool operator ==(Object other) {
    return other is _PlaceInfo &&
        googleId == other.googleId; // TODO: Need to compare the rest fields?
  }
}

class MyMapState extends State<MyMap> {
  final Completer<GoogleMapController> _controller = Completer();

  final location = Location();
  LatLng? userLocation;
  List<_PlaceInfo> places =
      []; // only to check equality with the previous value
  Set<Marker> markers = {}; // only to check equality with the previous value

  @override
  void initState() {
    super.initState();
    location.onLocationChanged.listen(onLocationDataChanged);
    location.getLocation().then(onLocationDataChanged);
  }

  void onLocationDataChanged(LocationData currentLocation) {
    if (currentLocation.latitude == null || currentLocation.longitude == null) {
      // userLocation = null;
    } else {
      var loc = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      if (loc != userLocation) {
        setState(() {
          userLocation = loc;
        });
        if (widget.onMove != null) {
          widget.onMove!(loc);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return const Center(child: Text("Determining user location"));
    }

    if (widget.db != null) {
      widget.db!.query('Place',
          // TODO: Is 'name' really needed?
          columns: [
            'id',
            'google_id',
            'name',
            'icon_url',
            'lat',
            'lng',
            'updated'
          ]).then((results) {
        final newPlaces = results
            .map((r) => _PlaceInfo(
                id: r['id'] as int,
                googleId: r['google_id'] as String,
                name: r['name'] as String,
                iconUrl: r['icon_url'] as String,
                lat: r['lat'] as double,
                lng: r['lng'] as double))
            .toList(growable: false);
        var eq = const ListEquality().equals;
        if (!eq(places, newPlaces)) {
          MarkerIcon.pictureAsset(
                  width: 100, height: 100, assetPath: 'media/marker.png')
              .then((icon) {
            setState(() {
              places = newPlaces;
              markers = newPlaces
                  .map((v) => Marker(
                        markerId: MarkerId(v.googleId),
                        consumeTapEvents: true,
                        icon: icon,
                        anchor: const Offset(0.5, 0.5),
                        // infoWindow: TODO,
                        position: LatLng(v.lat, v.lng),
                        zIndex: 1000001,
                        onTap: () {
                          Navigator.pushNamed(context, '/places/prices',
                                  arguments: v.id)
                              .then((value) {});
                        },
                      ))
                  .toSet();
            });
          });
        }
      });
    }

    var map = GoogleMap(
      // onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: userLocation!,
        zoom: 11.0,
      ),
      markers: markers,
    );

    return map;
  }
}
