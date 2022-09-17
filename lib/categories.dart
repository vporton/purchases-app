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

  const Categories({super.key, required this.db});

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
          .query('Category',
              columns: ['id', 'name', 'description'], orderBy: 'name')
          .then((result) => setState(() {
                list = result
                    .map((r) => CategoryData(
                        id: r['id'] as int,
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
        itemBuilder: (context, index) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(list[index].name, textScaleFactor: 2.0),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Supercategories", style: TextStyle(color: Colors.blue)),
            const Text("Subcategories", style: TextStyle(color: Colors.blue)),
            InkWell(
                child: const Text("Edit", style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.pushNamed(context, '/categories/edit',
                          arguments: list[index])
                      .then((value) {});
                }),
            const Text("Delete", style: TextStyle(color: Colors.blue)),
          ])
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Below warrants `widget.db != null`.
            Navigator.pushNamed(context, '/categories/edit', arguments: null)
                .then((value) {});
          }),
    );
  }
}

class CategoriesEdit extends StatefulWidget {
  Database? db;

  CategoriesEdit({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => CategoriesEditState();
}

class CategoriesEditState extends State<CategoriesEdit> {
  CategoryData? category;
  TextEditingController nameTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();

  void saveState(BuildContext context) {
    if (category!.id != null) {
      widget.db!
          .update(
              'Category',
              {
                'name': category!.name,
                'description': category!.description,
              },
              where: "id=?",
              whereArgs: [category!.id])
          .then((c) => {});
    } else {
      widget.db!.insert('Category', {
        'name': category!.name,
        'description': category!.description,
      }).then((c) => {});
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      var newCategory = ModalRoute
          .of(context)!
          .settings
          .arguments as CategoryData? ??
          CategoryData(name: "", description: "");
      setState(() {
        category = newCategory;
      });
      nameTextController.text = category!.name;
      descriptionTextController.text = category!.description;
    }

    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.arrow_circle_left),
              onTap: () => Navigator.pop(context)),
          title: const Text("Edit Category"),
        ),
        body: Column(children: [
          Column(children: [
            const Text("Category name:*"),
            TextField(
                controller: nameTextController,
                onChanged: (value) {
                  category!.name = value;
                })
          ]),
          Column(children: [
            const Text("Description:"),
            TextField(
                controller: descriptionTextController,
                onChanged: (value) {
                  category!.description = value;
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
  }
}
