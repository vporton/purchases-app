import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

class _ShortPlaceData {
  int id;
  String name;

  _ShortPlaceData({required this.id, required this.name});
}

class _ShortCategoryData {
  int id;
  String name;

  _ShortCategoryData({required this.id, required this.name});
}

class PricesEdit extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PricesEditState();
}

class _PricesEditState extends State<PricesEdit> {
  Database? db;
  List<_ShortPlaceData>? places;
  List<_ShortCategoryData>? categories;

  @override
  Widget build(BuildContext context) {
    if (db != null) {
      if (places == null) {
        db!.query(
            'Place', columns: ['id', 'name'], orderBy: 'name')
            .then((result) {
          var newPlaces = result.map((r) =>
              _ShortPlaceData(id: r['id'] as int, name: r['name'] as String))
              .toList(growable: false);
          setState(() {
            places = newPlaces;
          });
        });
      }
      if (categories == null) {
        db!.query(
            'Category', columns: ['id', 'name'], orderBy: 'name')
            .then((result) {
          var newCategories = result.map((r) =>
              _ShortCategoryData(id: r['id'] as int, name: r['name'] as String))
              .toList(growable: false);
          setState(() {
            categories = newCategories;
          });
        });
      }
    }

    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.close),
              onTap: () => Navigator.pop(context)),
          title: const Text("Edit Price"),
        ),
        body: Column(children: [
          Column(children: [
            const Text("Shop (place)*:"),
            DropdownButton<int>(
              items: places == null ? [] : places!.map((value) {
                return DropdownMenuItem<int>(
                  value: value.id,
                  child: Text(value.name),
                );
              }).toList(),
              onChanged: (id) {},
            ),
          ]),
          Column(children: [
            const Text("Category*:"),
            DropdownButton<int>(
              items: categories == null ? [] : categories!.map((value) {
                return DropdownMenuItem<int>(
                  value: value.id,
                  child: Text(value.name),
                );
              }).toList(),
              onChanged: (id) {},
            ),
          ]),
          Column(children: [
            const Text("Price*:"),
            TextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
            )
          ]),
        ])
    );
  }

}