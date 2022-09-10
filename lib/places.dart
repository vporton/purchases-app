import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Places extends StatefulWidget {
  const Places({super.key});

  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            child: const Icon(Icons.close),
            onTap: () => Navigator.pop(context)
        ),
        title: const Text("Places"),
      ),
      body: Center(
        child: ListView(children: []),
      ),
    );
  }
}
