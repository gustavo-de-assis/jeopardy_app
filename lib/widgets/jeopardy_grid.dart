import 'package:flutter/material.dart';
import 'category_column.dart';

class JeopardyGrid extends StatelessWidget {
  const JeopardyGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        // color: Colors.black, // Dark background behind the grid removed for global gradient
        padding: const EdgeInsets.all(8),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CategoryColumn(categoryName: "Category 1"),
            CategoryColumn(categoryName: "Category 2"),
            CategoryColumn(categoryName: "Category 3"),
            CategoryColumn(categoryName: "Category 4"),
            CategoryColumn(categoryName: "Category 5"),
          ],
        ),
      ),
    );
  }
}
