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

class PriceData {
  final int? id;
  int? placeIndex;
  int? categoryIndex;
  double? price;

  PriceData.empty()
      : id = null,
        placeIndex = null,
        categoryIndex = null,
        price = null;

  PriceData(
      {required this.id, this.placeIndex, this.categoryIndex, this.price});
}

class PricesEdit extends StatefulWidget {
  final Database? db;

  const PricesEdit({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => _PricesEditState();
}

class _PricesEditState extends State<PricesEdit> {
  List<_ShortPlaceData>? places;
  List<_ShortCategoryData>? categories;
  PriceData? data = PriceData.empty();
  String? placeName;
  String? categoryName;

  void saveState(BuildContext context) {
    if (data?.id != null) {
      // TODO: `db` in principle can be yet null.
      widget.db!
          .update(
              'Product',
              {
                'store': data!.placeIndex,
                'category': data!.categoryIndex,
                'price': data!.price!, // FIXME: `price` may be null.
              },
              where: "id=?",
              whereArgs: [data!.id])
          .then((c) => {});
    } else {
      widget.db!.insert('Product', {
        'store': data!.placeIndex,
        'category': data!.categoryIndex,
        'price': data!.price!, // FIXME: `price` may be null.
      }).then((c) => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var passedData = ModalRoute.of(context)!.settings.arguments as PriceData;
    if (passedData != data) {
      setState(() {
        data = passedData;
      });
    }
    if (widget.db != null) {
      if (places == null) {
        widget.db!
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
        widget.db!
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

      if (data?.id != null) {
        widget.db!
            .query('Product',
                columns: ['store', 'category', 'price'],
                where: "id=?",
                whereArgs: [data!.id])
            .then((result) => {
                  if (result.isNotEmpty)
                    {
                      setState(() {
                        data!.placeIndex = result[0]['store'] as int;
                        data!.categoryIndex = result[0]['category'] as int;
                        data!.price = result[0]['price'] as double;
                        if (places != null) {
                          placeName = places!.where((r) => r.id == data?.placeIndex).first.name; // TODO: Is `data?` correct here?
                        }
                        if (categories != null) {
                          categoryName = categories!.where((r) => r.id == data?.categoryIndex).first.name; // TODO: Is `data?` correct here?
                        }
                      })
                    }
                });
      }
    }

    var priceTextController =
        TextEditingController(text: data?.price == null ? "" : data!.price.toString());

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
            value: data?.placeIndex,
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
                data!.placeIndex = id; // TODO: Is `!` valid?
              });
            },
          ),
        ]),
        Column(children: [
          const Text("Category*:"),
          DropdownButton<int>(
            value: data?.categoryIndex,
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
                data!.categoryIndex = id; // TODO: Is `!` valid?
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
              data!.price = double.parse(text); // TODO: Is `!` valid?
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
