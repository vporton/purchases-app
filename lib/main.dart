import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:purchases/map.dart';
import 'package:purchases/places.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'db.dart';

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
    myOpenDatabase().then((db) => setState(() { this.db = db; }));
  }

  void onMove(LatLng coord) {
    setState(() {
      this.coord = coord;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchases App',
      initialRoute: '/',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => MyHomePage(
            title: 'Purchases App',
            onMove: onMove),
        '/places': (context) => const Places(),
        '/places/add': (context) => PlacesAdd(coord: coord),
      },
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.onMove});

  final String title;
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading:
        title: Text(widget.title),
      ),
      drawer: Drawer(
          child: ListView(children: [
            ListTile(leading: const Icon(Icons.place), title: Text("Places"), onTap: () { Navigator.pushNamed(context, '/places').then((value) {}); }),
            ListTile(leading: const Icon(Icons.shopping_cart), title: Text("Products")),
            ListTile(leading: const Icon(Icons.category), title: Text("Product categories")),
          ]),
      ),
      body: Center(
        child: MyMap(onMove: widget.onMoveImpl),
      ),
    );
  }
}
