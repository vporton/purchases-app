import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:path/path.dart';

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
  LatLng? coord;

  PlacesAdd({super.key, required this.coord});

  @override
  State<PlacesAdd> createState() => _PlacesAddState();
}

class _PlaceData {
  final String placeId;
  final String name;
  final LatLng location;
  final Uri icon;

  // TODO: business_status == "OPERATIONAL"

  _PlaceData(
      {required this.placeId,
      required this.name,
      required this.location,
      required this.icon});
}

class _PlacesAddState extends State<PlacesAdd> {
  LatLng? coord;
  List<_PlaceData> places = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coord != coord) {
      setState(() {
        coord = widget.coord;
      });

      if (widget.coord != null) {
        final mapsPlaces = GoogleMapsPlaces(
            // TODO: Don't call every time.
            apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
        mapsPlaces
            .searchNearbyWithRadius(
                Location(lat: coord!.latitude, lng: coord!.longitude), 2500)
            .then((PlacesSearchResponse response) {
          var results = response.results
              .map((r) => _PlaceData(
                    placeId: r.placeId,
                    name: r.name,
                    location: LatLng(
                        r.geometry?.location.lat as double, r.geometry?.location.lng as double),
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
            itemBuilder: (context, index) => Row(children: [
              Image.network(places[index].icon.toString(), scale: 2.0),
              Text(places[index].name, textScaleFactor: 2.0)
            ]),
          ),
        )
      ]),
    );
  }
}
