import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

class CategoryData {
  int? id;
  String name;
  String description;

  CategoryData({this.id, required this.name, required this.description});
}

class Categories extends StatefulWidget {
  final Database? db;
  final Function(CategoryData?) onChooseCategory;

  const Categories(
      {super.key, required this.db, required this.onChooseCategory});

  @override
  State<StatefulWidget> createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  List<CategoryData> list;

  CategoriesState() : list = [];

  @override
  Widget build(BuildContext context) {
    if (widget.db != null) {
      widget.db!
          .query('Category', columns: ['name', 'description'], orderBy: 'name')
          .then((result) => setState(() {
                list = result
                    .map((r) => CategoryData(
                        name: r['name'] as String,
                        description: r['description'] as String))
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
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          color: Colors.black45,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) => Column(children: [
          Text(list[index].name, textScaleFactor: 2.0),
          Row(children: const [
            Text("Supercategories"),
            Text("Subcategories"),
            Text("Edit"),
            Text("Delete"),
          ])
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Below warrants `widget.db != null`.
            widget.onChooseCategory(null);
            Navigator.pushNamed(context, '/categories/edit').then((value) {});
          }),
    );
  }
}

class CategoriesEdit extends StatefulWidget {
  Database? db;
  CategoryData? category;

  CategoriesEdit({super.key, required this.db, required this.category});

  @override
  State<StatefulWidget> createState() => CategoriesEditState();
}

class CategoriesEditState extends State<CategoriesEdit> {
  CategoryData? category;
  // Database? db;
  TextEditingController nametextController =  TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  void saveState(BuildContext context) {
    // ...
  }

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      setState(() {
        category = widget.category ?? CategoryData(name: "", description: "");
      });


    }
    nametextController.text = category!.name??"";
    descriptionTextController.text = category!.description??"";



    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.arrow_circle_left),
              onTap: () => Navigator.pop(context)),
          title: const Text("Edit Category"),
        ),
        body: Column(children: [
          Column(key: const Key('name'), children: [
            const Text("Category name:*"),
            TextField(
                controller: nametextController,
                onChanged: (value) {
                  setState(() {
                    category!.name = value;
                  });
                })
          ]),
          Column(key: const Key('description'), children: [
            const Text("Description:"),
            TextField(
                controller: descriptionTextController,
                onChanged: (value) {
                  setState(() {
                    category!.description = value;
                  });
                })
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            ElevatedButton(
              onPressed: () => saveState(context), // passing false
              child: const Text('OK'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              // passing false
              child: const Text('Cancel'),
            ),
          ]),
        ]));
  }}
