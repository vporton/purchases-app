import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  const PlacesAdd({super.key});

  @override
  State<PlacesAdd> createState() => _PlacesAddState();
}

class _PlacesAddState extends State<PlacesAdd> {
  List<String> places = [];

  @override
  Widget build(BuildContext context) {
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
        Expanded(child: // TODO: Is Expanded correct here?
          ListView(children: places.map((e) => Text(e)).toList(growable: false)),
        ),
      ]),
    );
  }
}
