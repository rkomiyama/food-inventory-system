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
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'en_US');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _inventoryStream;

  @override
  void initState() {
    super.initState();

    _inventoryStream = FirebaseFirestore.instance.collection('inventory').snapshots();
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
                Navigator.push(
                  context,
                  CupertinoPageRoute<void>(
                    builder: (context) => ItemScreen(
                      itemName: id,
                      count: data['count'],
                      price: formatCurrency.format(data['price']),
                      lastOrderedDate: DateFormat('MM/dd/yyyy, hh:mm a').format(ts.toDate()),
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
                return ShadTableCell(
                  child: Text(DateFormat('MM/dd/yyyy, hh:mm a').format(ts.toDate())),
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