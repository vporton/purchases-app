import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Places extends StatefulWidget {
  const Places({super.key});

  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.close),
            onTap: () => Navigator.pop(context)),
        title: const Text("Places"),
      ),
      body: Center(
        child: ListView(children: []),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/places/add').then((value) {});
          }),
    );
  }
}

class PlacesAdd extends StatefulWidget {
  Database? db; // TODO: unneeded.
  LatLng? coord;
  final void Function(PlaceData) onChoosePlace;

  PlacesAdd(
      {super.key,
      required this.db,
      required this.coord,
      required this.onChoosePlace});

  @override
  State<PlacesAdd> createState() => _PlacesAddState();
}

class PlaceData {
  final String placeId;
  String name;
  String description;
  final LatLng location;
  final Uri icon;

  // TODO: business_status == "OPERATIONAL"

  PlaceData(
      {required this.placeId,
      required this.name,
      required this.description,
      required this.location,
      required this.icon});
}

class _PlacesAddState extends State<PlacesAdd> {
  LatLng? coord;
  List<PlaceData> places = [];

  @override
  void initState() {
    super.initState();
  }

  // FIXME: Don't insert on simple tap.
  void Function() onChoosePlaceImpl(PlaceData place, BuildContext context) {
    return () {
      // Below warrants `widget.db != null`.
      widget.onChoosePlace(place);
      Navigator.pushNamed(context, '/places/add/form').then((value) {});
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coord != coord) {
      setState(() {
        coord = widget.coord;
      });

      // Check for `widget.db != null` to ensure onChoosePlace() is called with `db`.
      if (widget.coord != null && widget.db != null) {
        final mapsPlaces = GoogleMapsPlaces(
            // TODO: Don't call every time.
            apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
        mapsPlaces
            .searchNearbyWithRadius(
                Location(
                    lat: widget.coord!.latitude, lng: widget.coord!.longitude),
                2500)
            .then((PlacesSearchResponse response) {
          var results = response.results
              .map((r) => PlaceData(
                    placeId: r.placeId,
                    name: r.name,
                    description: "",
                    location: LatLng(r.geometry?.location.lat as double,
                        r.geometry?.location.lng as double),
                    icon: Uri.parse(r.icon!),
                  ))
              .toList(growable: false);
          setState(() {
            places = results;
          });
        }).catchError((e) {
          debugPrint("Error reading Google: $e");
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.arrow_circle_left),
            onTap: () => Navigator.pop(context)),
        title: const Text("Add Place"),
      ),
      body: Column(children: [
        const TextField(
          decoration: InputDecoration(
            // border: OutlineInputBorder(),
            hintText: 'address',
          ),
        ),
        Expanded(
          // TODO: Is Expanded correct here?
          child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(
              color: Colors.black45,
            ),
            itemCount: places.length,
            itemBuilder: (context, index) => InkWell(
                onTap: onChoosePlaceImpl(places[index], context),
                child: Row(children: [
                  Image.network(places[index].icon.toString(), scale: 2.0),
                  Text(places[index].name, textScaleFactor: 2.0)
                ])),
          ),
        )
      ]),
    );
  }
}

class PlacesAddForm extends StatefulWidget {
  final Database? db;
  final PlaceData? place;

  const PlacesAddForm({super.key, required this.db, required this.place});

  @override
  State<PlacesAddForm> createState() => _PlacesAddFormState();
}

class _PlacesAddFormState extends State<PlacesAddForm> {
  PlaceData? place;

  void saveState(BuildContext context) {
    widget.db!.insert('Place', {
      'google_id': place!.placeId,
      'name': place!.name,
      'description': place!.description,
      'uri_icon': place!.icon.toString(),
      'lat': place!.location.latitude,
      'lng': place!.location.longitude,
    }).then((c) => {});

    Navigator.pushNamed(context, '/').then((value) {}); // TODO: to where navigate?
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      place = widget.place;
    });

    return Column(children: [
      Column(children: [
        const Text("Place name:*"),
        TextField(onChanged: (value) {
          setState(() {
            place?.name = value;
          });
        })
      ]),
      Column(
        children: [
          const Text("Description:*"),
          TextField(onChanged: (value) {
            setState(() {
              place?.description = value;
            });
          })
        ],
      ),
      Row(
        children: [
          ElevatedButton(
            onPressed: () => saveState(context), // passing false
            child: const Text('OK'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false), // passing false
            child: const Text('Cancel'),
          ),
        ]
      ),
    ]);
  }
}
