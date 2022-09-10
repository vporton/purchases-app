import 'package:flutter/material.dart';
import 'package:purchases/map.dart';
import 'package:purchases/places.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Database? db;

  @override
  void initState() {
    super.initState();
    myOpenDatabase().then((db) => setState(() { this.db = db; }));
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
        '/': (context) => const MyHomePage(title: 'Purchases App'),
        '/places': (context) => const Places(),
      },
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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
        child: MyMap(),
      ),
    );
  }
}
