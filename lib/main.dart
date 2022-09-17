import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:purchases/map.dart';
import 'package:purchases/places.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'db.dart';
import 'categories.dart';

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
        '/places/nearby': (context) => Places(coord: coord),
        '/places/saved': (context) =>
            SavedPlaces(db: db),
        '/places/nearby/add': (context) =>
            PlacesAdd(db: db, coord: coord),
        '/places/edit': (context) =>
            PlacesAddForm(db: db),
        '/categories': (context) =>
            Categories(db: db),
        '/categories/edit': (context) =>
            CategoriesEdit(db: db),
        // '/prices/edit': (context) => PricesEdit(db: db),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.onMove});

  final Function(LatLng)? onMove;

  void onMoveImpl(LatLng coord) {
    if(onMove != null) {
      onMove!(coord);
    }
  }

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
                Navigator.pushNamed(context, '/places/nearby').then((value) {});
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
              title: const Text("Prices")),
        ]),
      ),
      body: Center(
        child: MyMap(onMove: widget.onMoveImpl),
      ),
    );
  }
}
