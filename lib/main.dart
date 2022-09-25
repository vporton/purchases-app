import 'dart:io';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:purchases/map.dart';
import 'package:purchases/places.dart';
import 'package:purchases/prices.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'categories-rel.dart';
import 'db.dart';
import 'categories.dart';

class _Dummy {
  _Dummy();
}

Future<_Dummy> _googleMapsReload(Database db) async {
  const waitPeriod = Duration(days: 20);
  for (;;) {
    var result = await db.query(
        'Place', columns: ['id', 'google_id', 'updated'],
        orderBy: 'updated',
        limit: 1);
    if (!result.isEmpty) {
      final mapsPlaces = GoogleMapsPlaces(
        // TODO: Don't call every time.
          apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']);
      // FIXME: Handle errors.
      var response = await mapsPlaces.getDetailsByPlaceId(
          result[0]['google_id'] as String,
          // fields: ['place_id', 'geometry/location', 'icon'] // TODO: Bug in Flutter's GooglePlaces
      );
      if (response.hasNoResults) {
        await db.delete('Place', where: 'id=?', whereArgs: [result[0]['id'] as int]);
        await Future.delayed(waitPeriod);
      } else {
        final DateFormat dateFormatter = DateFormat('yyyy-MM-dd hh:mm:ss');
        var updated = dateFormatter.parse(result[0]['updated'] as String);
        await Future.delayed(updated.add(waitPeriod).difference(DateTime.now()));
        await db.update('Place', {
          'updated': dateFormatter.format(DateTime.now()),
          'google_id': response.result.placeId,
          'lat': response.result.geometry!.location.lat,
          'lng': response.result.geometry!.location.lng,
          'icon_url': response.result.icon,
        }, where: "id=?", whereArgs: [result[0]['id'] as int]);
      }
    } else {
      await Future.delayed(waitPeriod);
    }
  }
  return _Dummy();
}

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Database? db;
  LatLng? coord;

  @override
  void initState() {
    super.initState();
    myOpenDatabase().then((db) =>
        setState(() {
          this.db = db;
          _googleMapsReload(db).then((v) {});
        }));
  }

  void onMove(LatLng coord) {
    if (coord != this.coord) {
      setState(() {
        this.coord = coord;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchases App',
      initialRoute: '/map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/map': (context) => MyHomePage(db: db, onMove: onMove),
        '/places/saved': (context) => SavedPlaces(db: db, coord: coord),
        '/places/nearby': (context) => PlacesAdd(db: db, coord: coord),
        '/places/edit': (context) => PlacesAddForm(db: db),
        '/places/prices': (context) => PlacePrices(db: db),
        '/categories': (context) => Categories(db: db),
        '/categories/edit': (context) => CategoriesEdit(db: db),
        '/categories/sub': (context) =>
            CategoriesRel(
                db: db,
                forwardColumn: 'sub',
                backwardColumn: 'super',
                title: 'Edit subcategories',
                relText: 'Subcategories',
                relText2: 'subcategory'),
        '/categories/super': (context) =>
            CategoriesRel(
              db: db,
              forwardColumn: 'super',
              backwardColumn: 'sub',
              title: 'Edit supercategories',
              relText: 'Supercategories',
              relText2: 'supercategory',
            ),
        '/categories/prices': (context) => CategoryPrices(db: db),
        '/prices/edit': (context) => PricesEdit(db: db),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Database? db;
  const MyHomePage({super.key, required this.db, this.onMove});

  final Function(LatLng)? onMove;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? coord;

  void onMoveImpl(LatLng coord) {
    if (coord != this.coord) {
      setState(() {
        this.coord = coord;
      });
    }
    if (widget.onMove != null) {
      widget.onMove!(coord);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading:
        title: const Text("Prices app"),
      ),
      drawer: Drawer(
        child: ListView(children: [
          ListTile(
              leading: const Icon(Icons.place),
              title: const Text("Nearby places"),
              onTap: () {
                Navigator.pushNamed(context, '/places/nearby', arguments: coord)
                    .then((value) {});
              }),
          ListTile(
              leading: const Icon(Icons.save),
              title: const Text("Saved places"),
              onTap: () {
                Navigator.pushNamed(context, '/places/saved').then((value) {});
              }),
          ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Product kinds"),
              onTap: () {
                Navigator.pushNamed(context, '/categories').then((value) {});
              }),
          ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Prices"),
              onTap: () {
                Navigator.pushNamed(context, '/prices/edit',
                    arguments: PriceData.empty())
                    .then((value) {});
              }),
        ]),
      ),
      body: MyMap(db: widget.db, onMove: onMoveImpl),
    );
  }
}
