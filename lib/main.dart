import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlAppwrite Realtime Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> items = [];
  final TextEditingController _nameController = TextEditingController();
  RealtimeSubscription? subscription;
  late final Client client;
  final database = 'coombsDb'; // your database id
  final itemsCollection = '671a9f67002f9d396300'; // your collection id
  late final Databases databases;

  @override
  initState() {
    super.initState();
    client = Client().setProject('delete'); // your project id
    databases = Databases(client);
    loadItems();
    subscribe();
  }

  loadItems() async {
    try {
      final res = await databases.listDocuments(
        databaseId: database,
        collectionId: itemsCollection,
      );
      setState(() {
        items =
            List<Map<String, dynamic>>.from(res.documents.map((e) => e.data));
      });
    } on AppwriteException catch (e) {
      print(e.message);
    }
  }

  void subscribe() {
    final realtime = Realtime(client);

    subscription = realtime.subscribe([
      'documents' // subscribe to all documents in every database and collection
    ]);

    // listen to changes
    subscription!.stream.listen((data) {
      // data will consist of `events` and a `payload`
      final event = data.events.first;
      if (data.payload.isNotEmpty) {
        if (event.endsWith('.create')) {
          var item = data.payload;
          items.add(item);
          setState(() {});
        } else if (event.endsWith('.delete')) {
          var item = data.payload;
          items.removeWhere((it) => it['\$id'] == item['\$id']);
          setState(() {});
        }
      }
    });
  }

  @override
  dispose() {
    subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlAppwrite Realtime Demo'),
      ),
      body: ListView(children: [
        ...items.map((item) => ListTile(
              title: Text(item['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await databases.deleteDocument(
                    databaseId: database,
                    collectionId: itemsCollection,
                    documentId: item['\$id'],
                  );
                },
              ),
            )),
      ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // dialog to add new item
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add new item'),
              content: TextField(
                controller: _nameController,
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    // add new item
                    final name = _nameController.text;
                    if (name.isNotEmpty) {
                      _nameController.clear();
                      _addItem(name);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addItem(String name) async {
    try {
      await databases.createDocument(
        databaseId: database,
        collectionId: itemsCollection,
        documentId: ID.unique(),
        data: {'name': name},
      );
    } on AppwriteException catch (e) {
      print(e.message);
    }
  }
}

