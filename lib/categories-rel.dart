import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class CategoriesRel extends StatefulWidget {
  final Database? db;
  final String forwardColumn; // such as "sub"
  final String backwardColumn; // such as "super"
  final String title;
  final String relText; // see ""

  const CategoriesRel(
      {super.key,
      required this.db,
      required this.forwardColumn,
      required this.backwardColumn,
      required this.title,
      required this.relText});

  @override
  State<StatefulWidget> createState() => CategoriesRelState();
}

class CategoriesRelState extends State<CategoriesRel> {
  String? categoryName;

  @override
  Widget build(BuildContext context) {
    var categoryId = ModalRoute.of(context)!.settings.arguments as int;
    if (widget.db != null) {
      widget.db!
          .query('Category', columns: ['name'], where: "id=?", whereArgs: [categoryId])
      .then((result) {
        var categoryName = result[0]['name'] as String;
        if (categoryName != this.categoryName) {
          setState(() {
            this.categoryName = categoryName;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          child: const Icon(Icons.close),
          onTap: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
      ),
      body: Column(children: [
        Text(categoryName != null ? "${widget.relText} of $categoryName:" : ""),
        Expanded(child: _CategoriesRelList(
            db: widget.db,
            forwardColumn: widget.forwardColumn,
            backwardColumn: widget.backwardColumn,
            categoryId: categoryId)
        )
      ]),
    );
  }
}

class _CategoriesRelList extends StatefulWidget {
  final Database? db;
  final String forwardColumn;
  final String backwardColumn;
  final int categoryId;

  const _CategoriesRelList(
      {super.key,
      required this.db,
      required this.forwardColumn,
      required this.backwardColumn,
      required this.categoryId});

  @override
  State<StatefulWidget> createState() => _CategoriesRelListState();
}

class _CategoriesRelListStateValue {
  int categoryId;
  String categoryName;
  bool checked;

  _CategoriesRelListStateValue(
      {required this.categoryId,
      required this.categoryName,
      required this.checked});
}

class _CategoriesRelListStateValue2 {
  int categoryId;
  String categoryName;

  _CategoriesRelListStateValue2(
      {required this.categoryId, required this.categoryName});
}

class _CategoriesRelListState extends State<_CategoriesRelList> {
  List<_CategoriesRelListStateValue> values = [];

  Future<void> readDb() async {
    var result1 = await widget.db!
        .query('Category', columns: ['id', 'name'], orderBy: 'name');
    var result2 = await widget.db!.query('CategoryRel',
        columns: ['id', widget.forwardColumn],
        where: "${widget.backwardColumn}=? AND ${widget.forwardColumn}!=?",
        whereArgs: [widget.categoryId, widget.categoryId]);
    var set = {for (var e in result2) e['id'] as int};
    var ordered = result1.map((value) => _CategoriesRelListStateValue2(
        categoryId: value['id'] as int, categoryName: value['name'] as String));
    var rel2 = {
      for (var e in result1)
        e['id'] as int: _CategoriesRelListStateValue(
            categoryId: e['id'] as int,
            categoryName: e['name'] as String,
            checked: set.contains(e['id'] as int))
    };
    var newValues =
        ordered.map((e) => rel2[e.categoryId]!).toList(growable: false);
    var eq = const ListEquality().equals;
    if (!eq(values, newValues)) {
      setState(() {
        values = newValues;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    readDb().then((value) {});

    return ListView(
      children: values
          .map((value) => CheckboxListTile(
                title: Text(value.categoryName),
                value: value.checked,
                onChanged: (checked) {},
              ))
          .toList(growable: false),
    );
  }
}
