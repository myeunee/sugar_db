import 'package:flutter/material.dart';
import 'dart:typed_data';

class DrinkList extends StatelessWidget {
  final List<Map<String, dynamic>> drinks;
  final Future<Uint8List> Function(String) fetchImage;

  DrinkList({required this.drinks, required this.fetchImage});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: drinks.length,
      itemBuilder: (context, index) {
        final drink = drinks[index];
        return ListTile(
          leading: drink['image_url'] != null
              ? FutureBuilder<Uint8List>(
                  future: fetchImage(drink['image_url']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Icon(Icons.error);
                      } else {
                        return Image.memory(snapshot.data!);
                      }
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                )
              : null,
          title: Text(drink['drink_name']),
          subtitle: Text(
              '당: ${drink['sugar_content']}g, 칼로리: ${drink['calories']}kcal'),
        );
      },
    );
  }
}
