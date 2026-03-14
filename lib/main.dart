import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'screens/item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized(); // Ensure initialization
  FullScreen.setFullScreen(true); // enable fullscreen
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      themeMode: ThemeMode.dark,
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      appBuilder: (context) {
        return CupertinoApp(
          theme: CupertinoTheme.of(context),
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: const MainPage(),
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final headings = ["Item name", "Quantity", "Price", "Last ordered date"];
  final newItemAttr = [
    (title: 'Item name', value: ''),
  ];
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'en_US');
  final itemNameController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _inventoryStream;

  @override
  void initState() {
    super.initState();

    _inventoryStream = FirebaseFirestore.instance.collection('inventory').snapshots();
  }

  void addInventoryItem(itemName) async {
    try {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(itemName)
          .set({
            'count': 0,
            'price': 0,
            'lastOrderedDate': '',
          })
          .timeout(const Duration(seconds: 10));
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
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Food Inventory System'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _inventoryStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(child: Text('inventory collection is empty'));
          }

          return ShadTable(
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
                var id = documents[row - 1].id;
                var data = documents[row - 1].data() as Map<String, dynamic>;
                final ts = data['lastOrderedDate'];
                var formattedDate;
                if (ts != Null && ts != '') {
                  formattedDate = DateFormat('MM/dd/yyyy, hh:mm a').format(ts.toDate());
                } else {
                  formattedDate = 'No orders made';
                }
                Navigator.push(
                  context,
                  CupertinoPageRoute<void>(
                    builder: (context) => ItemScreen(
                      itemName: id,
                      count: data['count'],
                      price: formatCurrency.format(data['price']),
                      lastOrderedDate: formattedDate,
                    ),
                  ),
                );
              }
            },
            header: (context, column) => ShadTableCell.header(
              child: Text(headings[column]),
            ),
            builder: (context, index) {
              final doc = documents[index.row];
              final data = doc.data();

              if (index.column == 0) {
                return ShadTableCell(child: Text(doc.id));
              }
              if (index.column == 1) {
                return ShadTableCell(child: Text('${data['count']}'));
              }
              if (index.column == 2) {
                return ShadTableCell(
                  child: Text(formatCurrency.format(data['price'])),
                );
              }
              if (index.column == 3) {
                final ts = data['lastOrderedDate'];
                if (ts != Null && ts != '') {
                  return ShadTableCell(
                    child: Text(DateFormat('MM/dd/yyyy, hh:mm a').format(ts.toDate())),
                  );
                }
                else return ShadTableCell(
                  child: Text('No orders made'),
                );
              }
              return const ShadTableCell(child: Text(''));
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadIconButton(
            onPressed: () {
              showShadDialog(
                context: context,
                builder: (context) => ShadDialog(
                  title: const Text('Add inventory item'),
                  actions: [ShadButton(
                    child: Text('Add item'),
                    onPressed: () {
                      addInventoryItem(itemNameController.text);
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
                                // style: theme.textTheme.small,
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
        ]
      ),
    );
  }
}