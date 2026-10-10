import 'package:flutter/material.dart';

class ExpenseCategoryTags extends StatelessWidget {
  const ExpenseCategoryTags({required this.categories, super.key});
  final List<String> categories;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final category in categories)
          Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E8),
                      border: Border.all(color: const Color(0xFFFFA54B)),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(category,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFD97818))))),
      ]));
}
