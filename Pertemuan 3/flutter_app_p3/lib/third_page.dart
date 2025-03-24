import 'package:flutter/material.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Third Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Halaman Ketiga (Detail)',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) =>  route.isFirst);
              },
              child: Text('Kembali ke Halaman Utama'),
            ),
          ],
        ),
      ),
    );
  }
}