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
  final int? productId;

  const PricesEdit({super.key, required this.productId});

  @override
  State<StatefulWidget> createState() => _PricesEditState();
}

class _PricesEditState extends State<PricesEdit> {
  Database? db;
  List<_ShortPlaceData>? places;
  List<_ShortCategoryData>? categories;
  int? placeIndex;
  int? categoryIndex;
  String? placeName;
  String? categoryName;
  double? price;

  _PricesEditState({required this.db, required this.price});

  void saveState(BuildContext context) {
    if (widget.productId != null) {
      // TODO: `db` in principle can be yet null.
      db!
          .update(
              'Product',
              {
                'store': placeIndex,
                'category': categoryIndex,
                'price': price!, // FIXME: `price` may be null.
              },
              where: "id=?",
              whereArgs: [widget.productId])
          .then((c) => {});
    } else {
      db!.insert('Product', {
        'store': placeIndex,
        'category': categoryIndex,
        'price': price!, // FIXME: `price` may be null.
      }).then((c) => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (db != null) {
      if (places == null) {
        db!
            .query('Place', columns: ['id', 'name'], orderBy: 'name')
            .then((result) {
          var newPlaces = result
              .map((r) => _ShortPlaceData(
                  id: r['id'] as int, name: r['name'] as String))
              .toList(growable: false);
          setState(() {
            places = newPlaces;
          });
        });
      }
      if (categories == null) {
        db!
            .query('Category', columns: ['id', 'name'], orderBy: 'name')
            .then((result) {
          var newCategories = result
              .map((r) => _ShortCategoryData(
                  id: r['id'] as int, name: r['name'] as String))
              .toList(growable: false);
          setState(() {
            categories = newCategories;
          });
        });
      }

      if (widget.productId != null) {
        db!
            .query('Product',
                columns: ['store', 'category', 'price'],
                where: "id=?",
                whereArgs: [widget.productId])
            .then((result) => {
                  if (result.isNotEmpty)
                    {
                      setState(() {
                        placeIndex = result[0]['store'] as int;
                        categoryIndex = result[0]['category'] as int;
                        price = result[0]['price'] as double;
                        // if (places != null) {
                        //   placeName = places!.where((r) => r.id == placeIndex).first.name;
                        // }
                        // if (categories != null) {
                        //   categoryName = categories!.where((r) => r.id == categoryIndex).first.name;
                        // }
                      })
                    }
                });
      }
    }

    var priceTextController =
        TextEditingController(text: price == null ? "" : price.toString());

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
            value: placeIndex,
            items: places == null
                ? []
                : places!.map((value) {
                    return DropdownMenuItem<int>(
                      value: value.id,
                      child: Text(value.name),
                    );
                  }).toList(),
            onChanged: (id) {
              setState(() {
                placeIndex = id;
              });
            },
          ),
        ]),
        Column(children: [
          const Text("Category*:"),
          DropdownButton<int>(
            value: categoryIndex,
            items: categories == null
                ? []
                : categories!.map((value) {
                    return DropdownMenuItem<int>(
                      value: value.id,
                      child: Text(value.name),
                    );
                  }).toList(),
            onChanged: (id) {
              setState(() {
                categoryIndex = id;
              });
            },
          ),
        ]),
        Column(children: [
          const Text("Price*:"),
          TextField(
            controller: priceTextController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            onChanged: (text) {
              price = double.parse(text);
            },
          )
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ElevatedButton(
            onPressed: () => saveState(context),
            child: const Text('OK'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ]),
      ]),
    );
  }
}
