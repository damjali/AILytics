// lib/navigation/app_navigation.dart

import 'package:flutter/material.dart';
import 'package:ailytics/pages/home_page.dart';
import 'package:ailytics/pages/upload_page.dart';
import 'package:ailytics/pages/dashboard_page.dart';
import 'package:ailytics/pages/chatbot_page.dart';
import 'package:ailytics/pages/prediction_page.dart';
import 'package:ailytics/pages/recommendation_page.dart';

// Create a global key to access navigation state
final GlobalKey<AppNavigationState> navigationKey = GlobalKey<AppNavigationState>();

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => AppNavigationState();
}

class AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const UploadPage(),
    const DashboardPage(),
    const ChatbotPage(),
    const PredictionPage(),
    const RecommendationPage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Needed for more than 3 items
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Predict',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Recommend',
          ),
        ],
      ),
    );
  }
}