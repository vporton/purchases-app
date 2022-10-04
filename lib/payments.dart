import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

class Payments extends StatefulWidget {
  Database? db;

  Payments({super.key, required this.db});

  @override
  State<StatefulWidget> createState() => PaymentsState();
}

class PaymentsState extends State<Payments> {
  double? credits;

  static Future<String> getInstallationId(Database db) async {
    final rows = await db.query('Global', columns: ['installation']);
    final bytes = rows[0]['installation'] as Uint8List;
    return bytes.map((b) => b.toRadixString(16)).join();
  }

  Future<void> updateCredits() async {
    if (widget.db != null) {
      final account = await getInstallationId(widget.db!);
      debugPrint(
          'UUUU: ${"${dotenv.env['GOOGLE_PROXY_PREFIX']!}balance/${account}"}');
      final resp = await http.get(
          Uri.parse("${dotenv.env['GOOGLE_PROXY_PREFIX']!}balance/${account}"));
      final newCredits = double.parse(resp.body);
      if (newCredits != credits) {
        setState(() {
          credits = newCredits;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    updateCredits().then((v) {});

    return Scaffold(
        appBar: AppBar(
          leading: InkWell(
              child: const Icon(Icons.close),
              onTap: () => Navigator.pop(context)),
          title: const Text("Credits"),
        ),
        body: Column(children: [
          Text(
              credits == null
                  ? "Credits: Loading..."
                  : "Credits: \$${credits.toString()}",
              textScaleFactor: 2.0),
          TextButton(
              onPressed: () async {
              },
              child: Text('pay')),
        ]));
  }
}
