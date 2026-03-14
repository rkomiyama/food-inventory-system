import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemScreen extends StatefulWidget {
  final String itemName;
  final String lastOrderedDate;
  final int count;
  final String price;

  const ItemScreen({
    super.key,
    required this.itemName,
    required this.lastOrderedDate,
    required this.count,
    required this.price,
  });

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final headings = [
    "Order date",
    "Quantity ordered",
    "Total order price",
  ];

  final orderQuantityController = TextEditingController();
  final orderPriceController = TextEditingController();
  final itemNameController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _itemOrdersStream;
  String _lastOrderedDate = '';
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'en_US');

  @override
  void initState() {
    super.initState();

    _itemOrdersStream = 
      FirebaseFirestore.instance
        .collection('inventory')
        .doc(widget.itemName)
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots();
    _lastOrderedDate = widget.lastOrderedDate;
  }

  void addOrder (quantity, price) async {
    try {
      var now = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(widget.itemName)
          .set({
              'lastOrderedDate': now,
            },
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 10));
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(widget.itemName)
          .collection('orders')
          .add({
            'orderDate': now,
            'orderQuantity': double.tryParse(orderQuantityController.text),
            'orderPrice': double.tryParse(orderPriceController.text),
          })
          .timeout(const Duration(seconds: 10));
      setState(() {
        _lastOrderedDate = DateFormat('MM/dd/yyyy, hh:mm a').format(now.toDate());
      });
      print('WRITE succeeded');
    } catch (e, st) {
      print('WRITE failed: $e');
      print(st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Food Inventory System'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _itemOrdersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return Row(
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
                      Text('Last ordered: ' + _lastOrderedDate),
                      Text('Count: ' + widget.count.toString()),
                      Text('Price: ' + widget.price),
                    ]
                  )
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: const Center(child: Text('orders collection is empty'))
                ),
              ]
            );
          }

          return Row(
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
                    Text('Last ordered: ' + _lastOrderedDate),
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
                  columnCount: headings.length,
                  rowCount: documents.length,
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
                  onRowTap: (row) {
                    if (row > 0) {
                      var data = documents[row - 1].data() as Map<String, dynamic>;
                      showShadDialog(
                        context: context,
                        builder: (context) => ShadDialog(
                          title: const Text('Add inventory item'),
                          actions: [ShadButton(
                            child: Text('Add item'),
                            onPressed: () {
                              // addInventoryItem(itemNameController.text);
                              Navigator.of(context).pop(true);
                            }
                          )],
                          child: Container(
                            width: 375,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 16,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Item name',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 3,
                                      child: ShadInput(controller: itemNameController),
                                    ),
                                  ]
                                )
                              ],
                            ),
                          )
                        )
                      );
                    }
                  },
                  header: (context, column) {
                    return ShadTableCell.header(
                      child: Text(headings[column]),
                    );
                  },
                  builder: (context, index) {
                    final doc = documents[index.row];
                    final data = doc.data();
                    
                    if (index.column == 0) {
                      return ShadTableCell(
                        child: Text(DateFormat('MM/dd/yyyy, hh:mm a').format(data['orderDate'].toDate()))
                      );
                    }
                    if (index.column == 1) {
                      return ShadTableCell(
                        child: Text(data['orderQuantity'].toString())
                      );
                    }
                    if (index.column == 2) {
                      return ShadTableCell(
                        child: Text(formatCurrency.format(data['orderPrice'] ?? 0))
                      );
                    }
                    else {
                      return ShadTableCell(
                        child: Text('Null')
                      );
                    }
                  }
                )
              )
            ]
          );
        }
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadIconButton(
            onPressed: () {
              showShadDialog(
                context: context,
                builder: (context) => ShadDialog(
                  title: const Text('Order item'),
                  actions: [ShadButton(
                    child: Text('Order item'),
                    onPressed: () {
                      addOrder(orderQuantityController.text, orderPriceController.text);
                      Navigator.of(context).pop(true);
                    }
                  )],
                  child: Container(
                    width: 375,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 16,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order quantity',
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: ShadInput(controller: orderQuantityController),
                            ),
                          ]
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order price',
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: ShadInput(controller: orderPriceController),
                            ),
                          ]
                        ),
                      ],
                    ),
                  )
                )
              );
            },
            icon: const Icon(LucideIcons.plus),
          ),
          SizedBox(
            width: 10,
          ),
          ShadIconButton(
            onPressed: () => print('Minus'),
            icon: const Icon(LucideIcons.minus),
          ),
          SizedBox(
            width: 10,
          ),
          ShadIconButton.destructive(
            onPressed: () => print('Delete'),
            icon: const Icon(LucideIcons.trash),
          ),
        ]
      ),
    );
  }
}