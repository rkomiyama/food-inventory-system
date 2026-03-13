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
  final headings = [
    "Item name",
    "Quantity",
    "Price",
    "Last date ordered"
  ];
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Food Inventory System'),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('inventory').get(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show a loading indicator
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}'); // Show an error message
                  } else if (snapshot.hasData) {
                    // Data has been successfully received, access via snapshot.data!.docs
                    final List<DocumentSnapshot> documents = snapshot.data!.docs;
                    return ShadTable(
                      columnCount: headings.length,
                      rowCount: documents.length,
                      header: (context, column) {
                        return ShadTableCell.header(
                          child: Text(headings[column]),
                        );
                      },
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
                          Navigator.push(
                            context,
                            CupertinoPageRoute<void>(
                              builder: (context) => ItemScreen(
                                itemName: id,
                                count: data['count'],
                                price: formatCurrency.format(data['price']),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, index) {
                        // Access data for a specific document
                        var id = documents[index.row].id;
                        var data = documents[index.row].data() as Map<String, dynamic>;
                        if (index.column == 0) {
                          return ShadTableCell(
                            child: Text(id)
                          );
                        }
                        if (index.column == 1) {
                          return ShadTableCell(
                            child: Text(data['count'].toString())
                          );
                        }
                        if (index.column == 2) {
                          return ShadTableCell(
                            child: Text(formatCurrency.format(data['price']))
                          );
                        }
                        else {
                          return ShadTableCell(
                            child: Text('Null')
                          );
                        }
                      },
                    );
                  } else {
                    return Text('No data found');
                  }
                },
              )
            )
          ),
        ]
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadIconButton(
            onPressed: () => print('Add'),
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