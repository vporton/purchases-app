import 'dart:io';
import 'dart:isolate';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

Future<_Dummy> _googleMapsReloadAsync() async {
  // TODO
  return _Dummy();
}

void _googleMapsReload(_Dummy n) {
  _googleMapsReloadAsync().then((v) {});
  sleep(const Duration(days: int64MaxValue)); // TODO: This does not work with JS target.
}

void main() async {
  // var receivePort = ReceivePort();
  // var thread = Isolate(receivePort.sendPort);
  var thread = await Isolate.spawn(_googleMapsReload, _Dummy());
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
  thread.kill(priority: Isolate.immediate);
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
    myOpenDatabase().then((db) => setState(() {
          this.db = db;
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
        '/map': (context) => MyHomePage(onMove: onMove),
        '/places/saved': (context) => SavedPlaces(db: db, coord: coord),
        '/places/nearby': (context) => PlacesAdd(db: db, coord: coord),
        '/places/edit': (context) => PlacesAddForm(db: db),
        '/places/prices': (context) => PlacePrices(db: db),
        '/categories': (context) => Categories(db: db),
        '/categories/edit': (context) => CategoriesEdit(db: db),
        '/categories/sub': (context) => CategoriesRel(
            db: db,
            forwardColumn: 'sub',
            backwardColumn: 'super',
            title: 'Edit subcategories',
            relText: 'Subcategories',
            relText2: 'subcategory'),
        '/categories/super': (context) => CategoriesRel(
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
  const MyHomePage({super.key, this.onMove});

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
              title: const Text("Product categories"),
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
      body: Center(
        child: MyMap(onMove: onMoveImpl),
      ),
    );
  }
}
