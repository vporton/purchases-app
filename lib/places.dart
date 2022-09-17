import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';

class Places extends StatefulWidget {
  final LatLng? coord;

  Places({super.key, required this.coord});

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
        child: ListView(children: []), // FIXME
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/places/add', arguments: widget.coord).then((value) {});
          }),
    );
  }
}

class PlacesAdd extends StatefulWidget {
  final Database? db; // TODO: unneeded.
  final LatLng? coord;

  const PlacesAdd({super.key, required this.db, required this.coord});

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

  // FIXME: hack
  @override
  bool operator ==(other) => other is PlaceData && placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;
}

class _PlacesAddState extends State<PlacesAdd> {
  List<PlaceData> places = [];
  LatLng? coord;

  void onChoosePlaceImpl(PlaceData place, BuildContext context) {
    // Below warrants `widget.db != null`.
    Navigator.pushNamed(context, '/places/edit', arguments: place).then((value) {});
  }

  @override
  Widget build(BuildContext context) {
    var passedCoord = ModalRoute.of(context)!.settings.arguments as LatLng; // FIXME: It may be null.
    if (passedCoord != coord) {
      // Check for `widget.db != null` to ensure onChoosePlace() is called with `db`.
      if (passedCoord != null && widget.db != null) {
        final mapsPlaces = GoogleMapsPlaces(
            // TODO: Don't call every time.
            apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
        mapsPlaces
            .searchNearbyWithRadius(
                Location(
                    lat: passedCoord!.latitude, lng: passedCoord!.longitude),
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
            child:
                _PlacesList(places: places, onChoosePlace: onChoosePlaceImpl)),
      ]),
    );
  }
}

class _PlacesList extends StatelessWidget {
  final List<PlaceData> places;
  void Function(PlaceData place, BuildContext context) onChoosePlace;

  _PlacesList({required this.places, required this.onChoosePlace});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        color: Colors.black45,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) => InkWell(
          onTap: () {
            onChoosePlace(places[index], context);
          },
          child: Row(children: [
            Image.network(places[index].icon.toString(), scale: 2.0),
            Text(places[index].name, textScaleFactor: 2.0),
          ])),
    );
  }
}

class PlacesAddForm extends StatefulWidget {
  final Database? db;

  const PlacesAddForm({super.key, required this.db});

  @override
  State<PlacesAddForm> createState() => _PlacesAddFormState();
}

class _PlacesAddFormState extends State<PlacesAddForm> {
  PlaceData? place;

  @override
  void initState() {
  }

  void saveState(BuildContext context) {
    widget.db!
        .insert(
          'Place',
          {
            'google_id': place!.placeId,
            'name': place!.name,
            'description': place!.description,
            'icon_url': place!.icon.toString(),
            'lat': place!.location.latitude,
            'lng': place!.location.longitude,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        )
        .then((c) => {});

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var newPlace = ModalRoute.of(context)!.settings.arguments as PlaceData;
    setState(() {
      place = newPlace;
    });

    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.arrow_circle_left),
              onTap: () => Navigator.pop(context)),
          title: const Text("Edit Place"),
        ),
        body: Column(children: [
          Column(children: [
            const Text("Place name:*"),
            TextField(
                controller: TextEditingController(text: place!.name),
                onChanged: (value) {
                  place?.name = value;
                })
          ]),
          Column(
            children: [
              const Text("Description:*"),
              TextField(onChanged: (value) {
                place?.description = value;
              })
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ElevatedButton(
              onPressed: () => saveState(context), // passing false
              child: const Text('OK'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              // passing false
              child: const Text('Cancel'),
            ),
          ]),
        ]));
  }
}

class SavedPlaces extends StatefulWidget {
  final Database? db;

  const SavedPlaces({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => _SavedPlacesState();
}

class _SavedPlacesState extends State<SavedPlaces> {
  List<PlaceData> places = [];

  @override
  Widget build(BuildContext context) {
    void onChoosePlaceImpl(PlaceData place, BuildContext context) {
      // Below warrants `widget.db != null`.
      Navigator.pushNamed(context, '/places/edit', arguments: place).then((value) {});
    }

    if (widget.db != null) {
      widget.db!
          .query('Place',
              columns: [
                'google_id',
                'name',
                'description',
                'lat',
                'lng',
                'icon_url',
              ],
              orderBy: 'name')
          .then((result) {
        var newPlaces = result
            .map((row) => PlaceData(
                placeId: row['google_id'] as String,
                name: row['name'] as String,
                description: row['description'] as String,
                location: LatLng(row['lat'] as double, row['lng'] as double),
                icon: Uri.parse(row['icon_url'] as String)))
            .toList(growable: false);
        debugPrint("YYY: ${newPlaces.length}");
        var eq = const ListEquality().equals;
        if (!eq(newPlaces, places)) {
          setState(() {
            places = newPlaces;
          });
        }
      });
    }

    debugPrint("XXX: ${places.length}");
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.arrow_circle_left),
            onTap: () => Navigator.pop(context)),
        title: const Text("Saved Places"),
      ),
      body: _PlacesList(places: places, onChoosePlace: onChoosePlaceImpl),
    );
  }
}
