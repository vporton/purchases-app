import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';

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
  int? placeIndex;
  int? categoryIndex;
  double? price;

  PriceData.empty()
      : placeIndex = null,
        categoryIndex = null,
        price = null;

  PriceData({this.placeIndex, this.categoryIndex, this.price});
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
  TextEditingController priceTextController = TextEditingController();

  void saveState(BuildContext context) {
    if (data?.placeIndex != null && data?.categoryIndex != null) {
      // TODO: `db` in principle can be yet null.
      widget.db!
          .insert(
              'Product',
              {
                'shop': data!.placeIndex,
                'category': data!.categoryIndex,
                'price': data!.price!,
              },
              conflictAlgorithm: ConflictAlgorithm.replace)
          .then((c) => {});
    }
    Navigator.pop(context);
  }

  // TODO: Passing `TextEditingController` is a hack.
  void updatePrice(TextEditingController priceTextController) {
    // TODO: `db` in principle can be yet null.
    if (data!.placeIndex != null && data!.categoryIndex != null) {
      widget.db!
          .query('Product',
              columns: ['price'],
              where: "shop=? AND category=?",
              whereArgs: [data!.placeIndex, data!.categoryIndex])
          .then((result) {
        priceTextController.text =
            result.isNotEmpty ? (result[0]['price'] as double).toString() : "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var passedData = ModalRoute.of(context)!.settings.arguments as PriceData;
    if (passedData != data) {
      setState(() {
        data = passedData;
      });
      if (data != null && data!.price != null) {
        setState(() {
          priceTextController.text = data!.price.toString();
        });
      }
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
    }

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.close),
            onTap: () => Navigator.pop(context)),
        title: const Text("Edit Price"),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                updatePrice(priceTextController);
              });
            },
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Kind*:"),
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
                updatePrice(priceTextController);
              });
            },
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Price*:"),
          TextField(
            controller: priceTextController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'\d|\.')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return RegExp(r'^(?:|\d+(?:\.\d*)?)$').hasMatch(newValue.text)
                    ? newValue
                    : oldValue;
              })
            ],
            keyboardType: TextInputType.number,
            onChanged: (text) {
              setState(() {
                data!.price = double.parse(text); // TODO: Is `!` valid?
              });
            },
          )
        ]),
        Wrap(spacing: 8, children: [
          ElevatedButton(
            onPressed: data!.placeIndex != null &&
                    data!.categoryIndex != null &&
                    RegExp(r'^\d+(?:\.\d+)?$')
                        .hasMatch(priceTextController.text)
                ? () => saveState(context)
                : null,
            child: const Text('OK'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ...(data!.placeIndex == null || data!.categoryIndex == null
              ? []
              : [
                  OutlinedButton(
                    onPressed: () {
                      // TODO: In principle `widget.db` may be null.
                      widget.db!.delete('Product',
                          where: "shop=? AND category=?",
                          whereArgs: [data!.placeIndex, data!.categoryIndex]);
                      Navigator.pop(context, false);
                    },
                    child: const Text('Delete'),
                  ),
                ]),
        ]),
      ]),
    );
  }
}

class CategoryPrices extends StatefulWidget {
  final Database? db;

  const CategoryPrices({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => CategoryPricesState();
}

// TODO: Rename.
class PriceDataWithPlaceName {
  PriceData priceData;
  String placeName;
  String productName;
  LatLng coord;

  PriceDataWithPlaceName(
      {required this.priceData,
      required this.placeName,
      required this.productName,
      required this.coord});
}

class CategoryPricesState extends State<CategoryPrices> {
  int? categoryId;
  String? categoryName;
  List<PriceDataWithPlaceName>? prices;

  @override
  Widget build(BuildContext context) {
    var passedCategoryId = ModalRoute.of(context)!.settings.arguments as int;
    setState(() {
      categoryId = passedCategoryId;
    });
    if (widget.db != null) {
      widget.db!
          .query('Category',
              columns: ['name'], where: "id=?", whereArgs: [categoryId])
          .then((result) {
        if (result.isNotEmpty) {
          setState(() {
            categoryName = result[0]['name'] as String;
          });
        }
      });
      widget.db!.rawQuery(
          'SELECT Product.category categoryId, product.id, shop, price, place.name name, lat, lng, Category.name productName '
          'FROM Product INNER JOIN Place ON Product.shop=Place.id INNER JOIN Category ON Product.category=Category.id '
          'WHERE categoryId=? '
          'UNION '
          'SELECT Category.id categoryId, CategoryRel.sub id, shop, price, place.name name, lat, lng, Category.name productName FROM Product '
          'INNER JOIN Place ON Product.shop=Place.id '
          'INNER JOIN CategoryRel ON sub=categoryId '
          'INNER JOIN Category ON Product.category=Category.id '
          'WHERE super=? '
          'ORDER BY price ASC, name',
          [
            categoryId,
            categoryId,
          ]).then((result) => setState(() {
            prices = result
                .map((r) => PriceDataWithPlaceName(
                    priceData: PriceData(
                        placeIndex: r['shop'] as int,
                        categoryIndex: passedCategoryId,
                        price: r['price'] as double),
                    coord: LatLng(
                        r['lat'] as double, r['lng'] as double),
                    placeName: r['name'] as String,
                    productName: r['productName'] as String))
                .toList(growable: false);
          }));
    }

    final formatCurrency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.arrow_circle_left),
              onTap: () => Navigator.pop(context)),
          title: const Text("Best prices for kind")),
      body: Column(children: [
        Text("Category: $categoryName"),
        Expanded(
            child: ListView(
          children: prices == null
              ? []
              : prices!
                  .map((r) => InkWell(
                      onTap: () {
                        MapsLauncher.launchCoordinates(
                                r.coord.latitude, r.coord.longitude)
                            .then((v) {});
                      },
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${formatCurrency.format(r.priceData.price)} ${r.placeName}",
                                textScaleFactor: 2.0),
                            Text(r.productName),
                          ])))
                  .toList(growable: false),
        ))
      ]),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/prices/edit',
                    arguments: PriceData(categoryIndex: categoryId))
                .then((value) {});
          }),
    );
  }
}

class PlacePrices extends StatefulWidget {
  final Database? db;

  const PlacePrices({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => PlacePricesState();
}

class PriceDataWithCategoryName {
  PriceData priceData;
  String categoryName;
  String productName;

  PriceDataWithCategoryName(
      {required this.priceData,
      required this.categoryName,
      required this.productName});
}

enum _PlacePricesMenuOp { edit, delete }

class _PlacePricesMenuData {
  final _PlacePricesMenuOp op;
  final int index;

  const _PlacePricesMenuData({required this.op, required this.index});
}

class PlacePricesState extends State<PlacePrices> {
  int? placeId;
  String? placeName;
  List<PriceDataWithCategoryName>? prices;

  void onMenuClicked(_PlacePricesMenuData item, BuildContext context) {
    switch (item.op) {
      case _PlacePricesMenuOp.edit:
        Navigator.pushNamed(context, '/prices/edit',
                arguments: prices![item.index].priceData) // TODO: `!`?
            .then((value) {});
        break;
      case _PlacePricesMenuOp.delete:
        var data = prices![item.index].priceData;
        widget.db!.delete('Product',
            where: "shop=? AND category=?",
            whereArgs: [data.placeIndex, data.categoryIndex]).then((value) {});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var passedPlaceId = ModalRoute.of(context)!.settings.arguments as int?;
    setState(() {
      placeId = passedPlaceId;
    });
    if (widget.db != null) {
      widget.db!
          .query('Place',
              columns: ['name'], where: "id=?", whereArgs: [placeId])
          .then((result) {
        if (result.isNotEmpty) {
          setState(() {
            placeName = result[0]['name'] as String;
          });
        }
      });
      widget.db!.rawQuery(
          'SELECT category, price, name FROM Product INNER JOIN Category ON Product.category=Category.id WHERE shop=?'
          ' ORDER BY price ASC, name',
          [
            placeId
          ]).then((result) => setState(() {
            prices = result
                .map((r) => PriceDataWithCategoryName(
                    priceData: PriceData(
                        categoryIndex: r['category'] as int,
                        placeIndex: passedPlaceId,
                        price: r['price'] as double),
                    productName: "", // TODO: hack
                    categoryName: r['name'] as String))
                .toList(growable: false);
          }));
    }

    final formatCurrency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.arrow_circle_left),
              onTap: () => Navigator.pop(context)),
          title: const Text("Prices in Shop")),
      body: Column(children: [
        Text("Shop: $placeName"),
        Expanded(
            child: ListView(
          children: prices == null
              ? []
              : prices!
                  .mapIndexed((index, r) => Row(children: [
                        PopupMenuButton(
                            onSelected: (item) {
                              onMenuClicked(item, context);
                            },
                            itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                      value: _PlacePricesMenuData(
                                          op: _PlacePricesMenuOp.edit,
                                          index: index),
                                      child: const Text("Edit")),
                                  PopupMenuItem(
                                    value: _PlacePricesMenuData(
                                        op: _PlacePricesMenuOp.delete,
                                        index: index),
                                    child: const Text('Delete'),
                                  ),
                                ]),
                        Text(
                            "${formatCurrency.format(r.priceData.price)} ${r.categoryName}",
                            textScaleFactor: 2.0)
                      ]))
                  .toList(growable: false),
        ))
      ]),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(context, '/prices/edit',
                    arguments: PriceData(placeIndex: placeId))
                .then((value) {});
          }),
    );
  }
}
