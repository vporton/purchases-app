import 'package:flutter/material.dart';
import 'package:purchases/map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchases App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Purchases App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: MapSample(), /*Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Sample"),
            // MapSample(),
          ],
        ),*/
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
