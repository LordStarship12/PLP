import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNotePage extends StatefulWidget {
  final String myUserId;

  const AddNotePage({super.key, required this.myUserId});
  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('notes').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'created_at': Timestamp.now(),
        'synced': false,
        'created_by': widget.myUserId, // ✅ Always "Timothy"
      });

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Catatan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Judul"),
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: "Isi Catatan"),
                validator: (value) =>
                    value!.isEmpty ? 'Isi tidak boleh kosong' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveNote,
                child: Text('Simpan Catatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
