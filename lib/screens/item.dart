import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ItemScreen extends StatefulWidget {
  final String itemName;
  final int count;
  final String price;

  const ItemScreen({
    super.key,
    required this.itemName,
    required this.count,
    required this.price,
  });

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Food Inventory System'),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Text(widget.itemName),
            Text(widget.count.toString()),
            Text(widget.price),
          ]
        )
      ),
    );
  }
}