import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.purple[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centers everything vertically
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Image.asset(
                  'img/Sticker.png',
                  width: constraints.maxWidth * 0.9, 
                  height: constraints.maxWidth * 0.3, 
                  fit: BoxFit.contain, // Prevents the image from being cropped
                );
              },
            ),
            const Text(
              'This is a Home Screen',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            )
          ],
        ),
      ),
    );
  }
}