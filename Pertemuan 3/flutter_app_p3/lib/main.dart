import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'second_page.dart';
import 'spoke_one_page.dart';
import 'spoke_two_page.dart';
import 'spoke_three_page.dart';

void main() {
  runApp(MyApp());
}

// {{Hierarchical Navigation + Stateless Widget}}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Latihan StatefulWidget',
//       home: MainScreen(),
//     );
//   }
// }

// class MainScreen extends StatelessWidget {
//   const MainScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Main Screen'),
//         backgroundColor: Colors.purple[100],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const HomeScreen()),
//                 );
//               },
//               child: const Text('Go to Home Screen'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ProfileScreen()),
//                 );
//               },
//               child: const Text('Go to Profile Screen'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// {Hierarchical Navigation}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hierarchical Navigation',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: HomePage(),
//     );
//   }
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home Page'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Halaman Utama',
//               style: TextStyle(fontSize: 24),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SecondPage()),
//                 );
//               },
//               child: Text('Pergi ke Halaman Kedua'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// {{Flat Navigation}}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Latihan StatefulWidget',
//       home: MainScreen(),
//     );
//   } 
// }

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   _MainScreenState createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = [
//     HomeScreen(),
//     ProfileScreen()
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_currentIndex], // Menampilkan halaman sesuai indeks
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//         currentIndex: _currentIndex,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index; // Ubah indeks halaman
//           });
//         },
//       ),
//     );
//   }
// }

// {{Sequential Navigation}}
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sequential Navigation',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: OnboardingScreen(),
//     );
//   }
// }

// class OnboardingScreen extends StatefulWidget {
//   @override
//   _OnboardingScreenState createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController =
//     PageController();
//   int _currentPage = 0;

//   final List<String> _titles = [
//     "Welcome to MyApp!",
//     "Track Your Progress",
//     "Stay Connected"
//   ];

//   final List<String> _descriptions = [
//     "This app will help you organize your tasks efficiently.",
//     "Monitor your achievements and stay productive.",
//     "Connect with friends and work together on your goals."
//   ];

//   void _nextPage() {
//     if (_currentPage < 2) {
//       _pageController.nextPage(
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void _previousPage() {
//     if (_currentPage > 0) {
//       _pageController.previousPage(
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView.builder(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             _currentPage = index;
//           });
//         },
//         itemCount: _titles.length,
//         itemBuilder: (context, index) {
//           return _buildPage(
//             _titles[index],
//             _descriptions[index],
//             index == _titles.length - 1,
//           );
//         },
//       ),
//       bottomNavigationBar: _buildBottomNavigation(),
//     );
//   }

//   Widget _buildPage(String title, String description, bool isLastPage) {
//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 20),
//           Text(
//             description,
//             style: TextStyle(fontSize: 18),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 40),
//           isLastPage
//             ? ElevatedButton(
//               onPressed: () {
//                 print("Onboarding Selesai!");
//               },
//               child: Text("Get Started"),
//             )
//             : SizedBox.shrink(),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigation() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _currentPage > 0
//             ? TextButton(
//               onPressed: _previousPage,
//               child: Text("Previous"),
//             )
//             : SizedBox.shrink(),
//           Row(
//             children: List.generate(
//               _titles.length,
//               (index) => Container(
//                 margin: EdgeInsets.symmetric(horizontal: 4),
//                 width: 10,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: _currentPage == index ? Colors.blue : Colors.grey,
//                 ),
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed: _nextPage,
//             child: Text(_currentPage == _titles.length - 1 ? "Finish" : "Next"),
//           ),
//         ],
//       ),
//     );
//   }
// }

// {{Spoke and Hub Navigation}}
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hub and Spoke Navigation',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: HubPage(),
//     );
//   }
// }

// class HubPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Hub Page - Main Menu'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Hub - Halaman Utama',
//               style: TextStyle(fontSize: 24),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SpokeOnePage()),
//                 );
//               },
//               child: Text('Pergi ke Fitur 1'),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SpokeTwoPage()),
//                 );
//               },
//               child: Text('Pergi ke Fitur 2'),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => SpokeThreePage()),
//                 );
//               },
//               child: Text('Pergi ke Fitur 3'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// {{Modal Navigation}}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Modal Navigation Example",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  void _showSimpleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                print('Aksi dilanjutkan.');
              },
              child: Text('Lanjut'),
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Pilih Aksi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Data'),
                onTap: () {
                  Navigator.pop(context);
                  print('Edit data dipilih');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Hapus Data'),
                onTap: () {
                  Navigator.pop(context);
                  print('Hapus data dipilih');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modal Navigation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _showSimpleDialog(context);
              },
              child: Text('Tampikan Dialog Konfirmasi'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showBottomSheet(context);
              },
              child: Text('Tampilkan Bottom Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}