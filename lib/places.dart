import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'dialogs.dart';

class PlacesAdd extends StatefulWidget {
  final Database? db;
  final LatLng? coord;

  const PlacesAdd({super.key, required this.db, required this.coord});

  @override
  State<PlacesAdd> createState() => _PlacesAddState();
}

class PlaceData {
  int? id;
  final String placeId;
  String name;
  String description;
  LatLng? location;
  Uri? icon;

  // TODO: business_status == "OPERATIONAL"

  PlaceData(
      {this.id,
      required this.placeId,
      required this.name,
      required this.description,
      required this.location,
      required this.icon});

  @override
  bool operator ==(other) =>
      other is PlaceData &&
      id == other.id &&
      placeId == other.placeId &&
      name == other.name &&
      description == other.description &&
      location == other.location &&
      icon == other.icon;

  @override
  int get hashCode => placeId.hashCode;
}

class _PlacesAddState extends State<PlacesAdd> {
  List<PlaceData> places = [];
  List<PlaceData> placesSearch = [];
  bool addressInputed = false;
  LatLng? coord;
  String? googleSearchToken;

  void onChoosePlaceImpl(PlaceData place, BuildContext context) {
    // Below warrants `widget.db != null`.
    Navigator.pushNamed(context, '/places/edit', arguments: place)
        .then((value) {});
  }

  void searchPlaces(String text) {
    final mapsPlaces = GoogleMapsPlaces(
        // TODO: Don't call every time.
        apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
    googleSearchToken ??= const Uuid().v4();
    mapsPlaces
        .autocomplete(
          text, sessionToken: googleSearchToken,
          location: Location(lat: coord!.latitude, lng: coord!.longitude),
          // radius: 50000
        )
        .then((result) => setState(() {
              placesSearch = result.predictions
                  .map((r) => PlaceData(
                      placeId: r.placeId!,
                      name: r.description!,
                      description: "",
                      location: null,
                      icon: null))
                  .toList(growable: false);
            }));
  }

  @override
  Widget build(BuildContext context) {
    var passedCoord = ModalRoute.of(context)!.settings.arguments
        as LatLng; // FIXME: It may be null.
    if (passedCoord != coord) {
      setState(() {
        coord = passedCoord;
      });
      // Check for `widget.db != null` to ensure onChoosePlace() is called with `db`.
      if (passedCoord != null) {
        final mapsPlaces = GoogleMapsPlaces(
            // TODO: Don't call every time.
            apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
        mapsPlaces
            .searchNearbyWithRadius(
                Location(
                    lat: passedCoord!.latitude, lng: passedCoord!.longitude),
                2500) // TODO: the number
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
        TextField(
          decoration: const InputDecoration(
            // border: OutlineInputBorder(),
            hintText: 'address',
          ),
          onChanged: (text) {
            setState(() {
              addressInputed = text.isNotEmpty;
              searchPlaces(text);
            });
          },
        ),
        Expanded(
            child: _PlacesList(
                db: widget.db,
                places: addressInputed ? placesSearch : places,
                onChoosePlace: onChoosePlaceImpl)),
      ]),
    );
  }
}

class _PlacesList extends StatelessWidget {
  Database? db;
  final List<PlaceData> places;
  void Function(PlaceData place, BuildContext context) onChoosePlace;

  _PlacesList(
      {required this.db, required this.places, required this.onChoosePlace});

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
            ...places[index].icon == null
                ? []
                : [Image.network(places[index].icon.toString(), scale: 2.0)],
            Text(places[index].name, textScaleFactor: 2.0),
          ])),
    );
  }
}

class _SavedPlacesList extends StatefulWidget {
  final Database? db;
  int counter;

  _SavedPlacesList({required this.db, required this.counter});

  @override
  State<StatefulWidget> createState() => _SavedPlaceListState();
}

class _SavedPlaceListState extends State<_SavedPlacesList> {
  List<PlaceData> places = [];

  void updateData() {
    if (widget.db != null) {
      widget.db!
          .query('Place',
              columns: [
                'id',
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
                id: row['id'] as int,
                placeId: row['google_id'] as String,
                name: row['name'] as String,
                description: row['description'] as String,
                location: LatLng(row['lat'] as double, row['lng'] as double),
                icon: Uri.parse(row['icon_url'] as String)))
            .toList(growable: false);
        var eq = const ListEquality().equals;
        debugPrint("AAA: ${newPlaces.length}");
        if (!eq(newPlaces, places)) {
          setState(() {
            debugPrint("BBB");
            places = newPlaces;
          });
        }
      });
    }
  }

  void onMenuClicked(_PlacesMenuData item, BuildContext context) {
    switch (item.op) {
      case _PlacesMenuOp.prices:
        Navigator.pushNamed(context, '/places/prices',
                arguments: places[item.index].id)
            .then((value) {});
        break;
      case _PlacesMenuOp.edit:
        Navigator.pushNamed(context, '/places/edit',
                arguments: places[item.index])
            .then((s) => updateData());
        break;
      case _PlacesMenuOp.delete:
        askDeletePermission(context).then((reply) {
          if (reply) {
            widget.db!.delete('Place',
                where: 'id=?',
                whereArgs: [places[item.index].id]).then((s) => updateData());
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    updateData();

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        color: Colors.black45,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) => Row(children: [
        PopupMenuButton(
            onSelected: (item) {
              onMenuClicked(item, context);
            },
            itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value:
                        _PlacesMenuData(op: _PlacesMenuOp.prices, index: index),
                    child: Text('Prices'),
                  ),
                  PopupMenuItem(
                      value:
                          _PlacesMenuData(op: _PlacesMenuOp.edit, index: index),
                      child: Text("Edit")),
                  PopupMenuItem(
                    value:
                        _PlacesMenuData(op: _PlacesMenuOp.delete, index: index),
                    child: Text('Delete'),
                  ),
                ]),
        Image.network(places[index].icon.toString(), scale: 2.0),
        Text(places[index].name, textScaleFactor: 2.0),
      ]),
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
  void initState() {}

  Future<void> _insertPlace() async {
    await widget.db!.insert(
      'Place',
      {
        ...place!.id != null ? {'id': place!.id} : {},
        'google_id': place!.placeId,
        'name': place!.name,
        'description': place!.description,
        'icon_url': place!.icon.toString(),
        'lat': place!.location!.latitude,
        'lng': place!.location!.longitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void saveState(BuildContext context) {
    if (place!.location == null) {
      // TODO: Check for errors.
      var mapsPlaces = GoogleMapsPlaces(
          // TODO: Don't call every time.
          apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
      mapsPlaces.getDetailsByPlaceId(place!.placeId).then((response) {
        var loc = response.result.geometry!.location;
        place!.location = LatLng(loc.lat, loc.lng);
        place!.icon = Uri.parse(response.result.icon!);
      }).then((c) => _insertPlace());
    } else {
      _insertPlace().then((c) => {});
    }

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
  final LatLng? coord;

  const SavedPlaces({super.key, required this.db, required this.coord});

  @override
  State<StatefulWidget> createState() => _SavedPlacesState();
}

class _SavedPlacesState extends State<SavedPlaces> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.arrow_circle_left),
            onTap: () => Navigator.pop(context)),
        title: const Text("Saved Places"),
      ),
      body: _SavedPlacesList(db: widget.db, counter: counter),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/places/nearby',
                    arguments: widget.coord)
                .then((value) {
              setState(() {
                ++counter; // hack
              });
            });
          }),
    );
  }
}

enum _PlacesMenuOp { prices, edit, delete }

class _PlacesMenuData {
  final _PlacesMenuOp op;
  final int index;

  const _PlacesMenuData({required this.op, required this.index});
}
