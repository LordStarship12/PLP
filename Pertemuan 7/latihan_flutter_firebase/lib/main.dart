import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_note_page.dart';
import 'firebase_options.dart';

const String myUserId = 'Timothy'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('Using myUserId: $myUserId');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Catatan Liburan",
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');

  List<DocumentSnapshot> _userNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);

    final snapshot = await notes.where('created_by', isEqualTo: myUserId).get();

    setState(() {
      _userNotes = snapshot.docs;
      _loading = false;
    });
  }

  Future<void> _navigateToAddNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNotePage(myUserId: myUserId)),
    );

    if (result == true) {
      await _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Catatan Liburan"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Tambah Catatan",
            onPressed: _navigateToAddNote,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userNotes.isEmpty
              ? const Center(child: Text("Belum ada catatan."))
              : ListView.builder(
                  itemCount: _userNotes.length,
                  itemBuilder: (context, index) {
                    final doc = _userNotes[index];
                    final data = doc.data()! as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data['title'] ?? '-'),
                        subtitle: Text(data['content'] ?? ''),
                        trailing: data['synced'] == true
                            ? const Icon(Icons.cloud_done, color: Colors.green)
                            : const Icon(Icons.cloud_off, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
