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
  PlaceData? currentPlaceData; // for editing place
  CategoryData? currentCategoryData; // for editing category

  @override
  void initState() {
    super.initState();
    myOpenDatabase().then((db) => setState(() { this.db = db; }));
  }

  void onMove(LatLng coord) {
    if (coord != this.coord) {
      setState(() {
        this.coord = coord;
      });
    }
  }

  void onChoosePlace(PlaceData place) {
    currentPlaceData = place;
  }

  void onChooseCategory(CategoryData? cat) {
    currentCategoryData = cat;
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
        '/places/saved': (context) => SavedPlaces(db: db, onChoosePlace: onChoosePlace),
        '/places/add': (context) => PlacesAdd(coord: coord, db: db, onChoosePlace: onChoosePlace),
        '/places/edit': (context) => PlacesAddForm(db: db, place: currentPlaceData),
        '/categories': (context) => Categories(db: db, onChooseCategory: onChooseCategory),
        '/categories/edit': (context) => CategoriesEdit(db: db, category: currentCategoryData),
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
            ListTile(leading: const Icon(Icons.place), title: const Text("Nearby places"), onTap: () { Navigator.pushNamed(context, '/places').then((value) {}); }),
            ListTile(leading: const Icon(Icons.place), title: const Text("Saved Places"), onTap: () { Navigator.pushNamed(context, '/places/saved').then((value) {}); }),
            ListTile(leading: const Icon(Icons.shopping_cart), title: const Text("Products")),
            ListTile(leading: const Icon(Icons.category), title: const Text("Product categories"), onTap: () { Navigator.pushNamed(context, '/categories').then((value) {}); }),
          ]),
      ),
      body: Center(
        child: MyMap(onMove: widget.onMoveImpl),
      ),
    );
  }
}
