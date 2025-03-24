import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' if (kIsWeb) 'package:flutter/foundation.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: ResponsiveAppBar(scaffoldKey: _scaffoldKey), 
      endDrawer: NavigationDrawer(), 
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return WideScreenLayout();
          } else {
            return NarrowScreenLayout();
          }
        },
      ),
    );
  }
}

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ResponsiveAppBar({required this.scaffoldKey, super.key});

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return AppBar(
      title: const Text('Company Profile'),
      actions: isWideScreen
          ? _buildMenuItems() // Full menu
          : [_buildBurgerMenu()], // Hamburger menu for mobile
    );
  }

  // Desktop Menu Items
  List<Widget> _buildMenuItems() {
    return [
      TextButton(onPressed: () {}, child: const Text('Home', style: TextStyle(color: Colors.red))),
      TextButton(onPressed: () {}, child: const Text('About', style: TextStyle(color: Colors.red))),
      TextButton(onPressed: () {}, child: const Text('Services', style: TextStyle(color: Colors.red))),
      TextButton(onPressed: () {}, child: const Text('Contact', style: TextStyle(color: Colors.red))),
    ];
  }

  // Mobile Burger Menu (Opens Drawer)
  Widget _buildBurgerMenu() {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        scaffoldKey.currentState?.openEndDrawer(); 
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Mobile Drawer Menu
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(title: const Text('Home'), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('About'), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('Services'), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('Contact'), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class WideScreenLayout extends StatelessWidget {
  const WideScreenLayout({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (kIsWeb) {
      return Center(
        child: Container(
          color: Colors.purple,
          width: 600,
          height: 400,
          child: const Center(child: Text('Web Layout', style: TextStyle(color: Colors.white))),
        ),
      );
    }
    
    return Center(
      child: Container(
        color: Platform.isIOS ? Colors.blue : Colors.red,
        width: screenWidth * 0.6,
        height: 400,
        child: Center(
          child: Text(
            'Wide Screen Layout', 
            style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class NarrowScreenLayout extends StatelessWidget {
  const NarrowScreenLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.green,
        width: 300,
        height: 200,
        child: const Center(child: Text('Narrow Screen Layout', style: TextStyle(color: Colors.white))),
      ),
    );
  }
}
