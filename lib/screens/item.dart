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
  final headings = [
    "Last ordered date",
    "Quantity ordered",
    "Total order price",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Food Inventory System'),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 10,
          ),
          ShadCard(
            title: Text(widget.itemName),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Count: ' + widget.count.toString()),
                Text('Price: ' + widget.price),
              ]
            )
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: ShadTable(
              columnCount: 3,
              rowCount: 5,
              columnSpanExtent: (index) {
                if (index == 0) return const FixedTableSpanExtent(250);
                if (index == headings.length - 1) {
                  return const MaxTableSpanExtent(
                    FixedTableSpanExtent(120),
                    RemainingTableSpanExtent(),
                  );
                }
                return null;
              },
              header: (context, column) {
                return ShadTableCell.header(
                  child: Text(headings[column]),
                );
              },
              builder: (context, index) {
                return ShadTableCell(
                  child: Text('Null')
                );
              }
            )
          )
        ]
      ),
      floatingActionButton: ShadIconButton(
        onPressed: () => print('Add'),
        icon: const Icon(LucideIcons.plus),
      ),
    );
  }
}