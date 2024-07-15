import 'package:flutter/material.dart';

class DrinkList extends StatefulWidget {
  final List<Map<String, dynamic>> drinks;
  final Future<void> Function(int) onFavoritePressed;
  final Future<void> Function(int) onConsumePressed;
  final Set<int> favoriteDrinkIds;
  final Set<int> consumedDrinkIds;

  DrinkList({
    required this.drinks,
    required this.onFavoritePressed,
    required this.onConsumePressed,
    required this.favoriteDrinkIds,
    required this.consumedDrinkIds,
  });

  @override
  _DrinkListState createState() => _DrinkListState();
}

class _DrinkListState extends State<DrinkList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.drinks.length,
      itemBuilder: (context, index) {
        final drink = widget.drinks[index];
        final isFavorite = widget.favoriteDrinkIds.contains(drink['drink_id']);
        final isConsumed = widget.consumedDrinkIds.contains(drink['drink_id']);

        return ListTile(
          leading: Image.asset('assets/images/default_drink.png'),
          title: Text(drink['drink_name']),
          subtitle: Text(
              '당: ${drink['sugar_content']}g, 칼로리: ${drink['calories']}kcal, 용량: ${drink['volume']}ml'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  await widget.onFavoritePressed(drink['drink_id']);
                  setState(() {
                    if (isFavorite) {
                      widget.favoriteDrinkIds.remove(drink['drink_id']);
                    } else {
                      widget.favoriteDrinkIds.add(drink['drink_id']);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.local_cafe,
                  color: isConsumed ? Colors.brown : Colors.grey,
                ),
                onPressed: isConsumed
                    ? null
                    : () async {
                        await widget.onConsumePressed(drink['drink_id']);
                        setState(() {
                          widget.consumedDrinkIds.add(drink['drink_id']);
                        });
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
