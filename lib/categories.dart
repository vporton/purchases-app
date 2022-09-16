import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

class Categories extends StatefulWidget {
  final Database? db;

  const Categories({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  List<String> list;

  CategoriesState() : list = [];

  @override
  Widget build(BuildContext context) {
    if (widget.db != null) {
      widget.db!
          .query('Category', columns: ['name'], orderBy: 'name')
          .then((result) => setState(() {
                list = result
                    .map((e) => e['name'] as String)
                    .toList(growable: false);
              }));
    }
    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
            child: const Icon(Icons.close),
            onTap: () => Navigator.pop(context),
          ),
          title: const Text("Product Categories"),
        ),
        body: ListView(
            children: list
                .map(
                  (c) => Row(children: [
                    Text(c, textScaleFactor: 2.0),
                    Column(children: const [
                      Text("Supercategories"),
                      Text("Subcategories"),
                      Text("Edit"),
                      Text("Delete"),
                    ])
                  ]),
                )
                .toList(growable: false)
        )
    );
  }
}
