import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'dialogs.dart';

class CategoryData {
  int? id;
  String name;
  String description;

  CategoryData({this.id, required this.name, required this.description});

  @override
  bool operator ==(other) =>
      other is CategoryData &&
      id == other.id &&
      name == other.name &&
      description == other.description;
}

class Categories extends StatefulWidget {
  final Database? db;

  const Categories({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => _CategoriesState();
}

enum _CategoriesMenuOp { prices, supercategories, subcategories, edit, delete }

class _CategoriesMenuData {
  final _CategoriesMenuOp op;
  final int index;

  const _CategoriesMenuData({required this.op, required this.index});
}

class _CategoriesState extends State<Categories> {
  List<CategoryData> list;

  _CategoriesState() : list = [];

  void onMenuClicked(_CategoriesMenuData item, BuildContext context) {
    switch (item.op) {
      case _CategoriesMenuOp.prices:
        Navigator.pushNamed(context, '/categories/prices',
                arguments: list[item.index].id)
            .then((value) {});
        break;
      case _CategoriesMenuOp.supercategories:
        Navigator.pushNamed(context, '/categories/super',
                arguments: list[item.index].id)
            .then((value) {});
        break;
      case _CategoriesMenuOp.subcategories:
        Navigator.pushNamed(context, '/categories/sub',
                arguments: list[item.index].id)
            .then((value) {});
        break;
      case _CategoriesMenuOp.edit:
        Navigator.pushNamed(context, '/categories/edit',
                arguments: list[item.index])
            .then((value) {
          updateData();
        });
        break;
      case _CategoriesMenuOp.delete:
        // FIXME: Update kinds list on delete.
        askDeletePermission(context).then((reply) {
          if (reply) {
            widget.db!.delete('Category',
                where: 'id=?', whereArgs: [list[item.index].id])
            .then((s) => updateData());
          }
        });
        break;
    }
  }

  void updateData() {
    if (widget.db != null) {
      widget.db!
          .query('Category',
          columns: ['id', 'name', 'description'], orderBy: 'name')
          .then((result) {
        var newList = result
            .map((r) => CategoryData(
            id: r['id'] as int,
            name: r['name'] as String,
            description: r['description'] as String))
            .toList(growable: false);
        var eq = const ListEquality().equals;
        if (!eq(newList, list)) {
          setState(() {
            list = newList;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    updateData();

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          child: const Icon(Icons.close),
          onTap: () => Navigator.pop(context),
        ),
        title: const Text("Product Kinds"),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(
          color: Colors.black45,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) => Row(children: [
          PopupMenuButton(
              onSelected: (item) => onMenuClicked(item, context),
              itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: _CategoriesMenuData(
                          op: _CategoriesMenuOp.prices, index: index),
                      child: Text('Best prices'),
                    ),
                    PopupMenuItem(
                      value: _CategoriesMenuData(
                          op: _CategoriesMenuOp.supercategories, index: index),
                      child: Text('Supercategories'),
                    ),
                    PopupMenuItem(
                      value: _CategoriesMenuData(
                          op: _CategoriesMenuOp.subcategories, index: index),
                      child: Text('Subcategories'),
                    ),
                    PopupMenuItem(
                        value: _CategoriesMenuData(
                            op: _CategoriesMenuOp.edit, index: index),
                        child: Text("Edit")),
                    PopupMenuItem(
                      value: _CategoriesMenuData(
                          op: _CategoriesMenuOp.delete, index: index),
                      child: Text('Delete'),
                    ),
                  ]),
          Text(list[index].name, textScaleFactor: 2.0),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Below warrants `widget.db != null`.
            Navigator.pushNamed(context, '/categories/edit', arguments: null)
                .then((value) {
              updateData();
            });
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
          .then((c) {});
    } else {
      widget.db!.insert('Category', {
        'name': category!.name,
        'description': category!.description,
      }).then((c) {});
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      var newCategory =
          ModalRoute.of(context)!.settings.arguments as CategoryData? ??
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
          title: const Text("Edit Kind"),
        ),
        body: Column(children: [
          Column(children: [
            const Text("Product kind name:*"),
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
