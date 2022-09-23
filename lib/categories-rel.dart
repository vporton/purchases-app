import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class CategoriesRel extends StatefulWidget {
  final Database? db;
  final String forwardColumn; // such as "sub"
  final String backwardColumn; // such as "super"
  final String title;
  final String relText;
  final String relText2;

  const CategoriesRel(
      {super.key,
      required this.db,
      required this.forwardColumn,
      required this.backwardColumn,
      required this.title,
      required this.relText,
      required this.relText2});

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
          .query('Category',
              columns: ['name'], where: "id=?", whereArgs: [categoryId])
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
        Expanded(
            child: _CategoriesRelList(
                db: widget.db,
                forwardColumn: widget.forwardColumn,
                backwardColumn: widget.backwardColumn,
                categoryId: categoryId,
                relText2: widget.relText2))
      ]),
    );
  }
}

class _CategoriesRelList extends StatefulWidget {
  final Database? db;
  final String forwardColumn;
  final String backwardColumn;
  final int categoryId;
  final String relText2;

  const _CategoriesRelList(
      {super.key,
      required this.db,
      required this.forwardColumn,
      required this.backwardColumn,
      required this.categoryId,
      required this.relText2});

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
        columns: [widget.forwardColumn],
        where: "${widget.backwardColumn}=? AND ${widget.forwardColumn}!=?",
        whereArgs: [widget.categoryId, widget.categoryId]);
    var set = {for (var e in result2) e[widget.forwardColumn] as int};
    var ordered = result1
        .where((value) => value['id'] as int != widget.categoryId)
        .map((value) => _CategoriesRelListStateValue2(
            categoryId: value['id'] as int,
            categoryName: value['name'] as String));
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

  Future<void> check(int forwardCategory, BuildContext context) async {
    var resultReverse = await widget.db!.query('CategoryRel',
        columns: ['id'],
        where: "${widget.backwardColumn}=? AND ${widget.forwardColumn}=?",
        whereArgs: [forwardCategory, widget.categoryId]);
    if (resultReverse.isNotEmpty) {
      var r1 = await widget.db!.query('Category',
          columns: ['name'], where: "id=?", whereArgs: [widget.categoryId]);
      var r2 = await widget.db!.query('Category',
          columns: ['name'], where: "id=?", whereArgs: [forwardCategory]);
      var backwardCategoryName = r1[0]['name'] as String;
      var forwardCategoryName = r2[0]['name'] as String;

      final removeDialogResponse = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Remove the reverse relation?'),
          content: Text(
              '$backwardCategoryName is ${widget.relText2} of $forwardCategoryName. Remove this relation?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (removeDialogResponse != true) {
        return;
      }

      await widget.db!.delete('CategoryRel',
          where:
              '${widget.backwardColumn}=? AND (${widget.forwardColumn}=? OR EXISTS(SELECT * FROM CategoryRel WHERE ${widget.forwardColumn}=?))',
          whereArgs: [forwardCategory, widget.categoryId]);
    }

    // transitive closure
    var resultChecked = await widget.db!.rawQuery(
      "SELECT DISTINCT c1.name name1, c2.name name2, c1.id bc, c2.id fc FROM Category c1 INNER JOIN Category c2 ON "
      "(EXISTS(SELECT * FROM CategoryRel WHERE ${widget.backwardColumn}=bc AND ${widget.forwardColumn}=?) OR bc=?) AND "
      "(EXISTS(SELECT * FROM CategoryRel WHERE ${widget.backwardColumn}=? AND ${widget.forwardColumn}=fc) OR fc=?) "
      "WHERE c1.id!=c2.id AND NOT(EXISTS(SELECT * FROM CategoryRel WHERE ${widget.backwardColumn}=bc AND ${widget.forwardColumn}=fc))",
      [widget.categoryId, widget.categoryId, forwardCategory, forwardCategory],
    );
    if (resultChecked.length > 1) {
      final relationsStr = resultChecked
          .map((r) => "${r['name1'] as String} -> ${r['name2'] as String}")
          .join("\n");
      final addDialogResponse = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Add relations?'),
          content: Text(
              "Add the following subcategory relations:\n$relationsStr"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (addDialogResponse != true) {
        return;
      }
    }
    Batch batch = widget.db!.batch();
    for (var e in resultChecked) {
      widget.db!.insert('CategoryRel', {
        widget.backwardColumn: e['bc'] as int,
        widget.forwardColumn: e['fc'] as int,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> uncheck(int forwardCategory, BuildContext context) async {
    widget.db!.delete('CategoryRel',
        where: "${widget.backwardColumn}=? AND ${widget.forwardColumn}=?",
        whereArgs: [widget.categoryId, forwardCategory]);
  }

  @override
  Widget build(BuildContext context) {
    readDb().then((value) {});

    return ListView(
      children: values
          .map((value) => CheckboxListTile(
                title: Text(value.categoryName),
                value: value.checked,
                onChanged: (checked) {
                  // TODO: It may be in principle `widget.db == null`.
                  if (checked!) {
                    check(value.categoryId, context).then((value) => readDb());
                  } else {
                    uncheck(value.categoryId, context)
                        .then((value) => readDb());
                  }
                },
              ))
          .toList(growable: false),
    );
  }
}
