import 'package:flutter/material.dart';
import 'package:ailytics/pages/home_page.dart';
import 'package:ailytics/pages/upload_page.dart';
import 'package:ailytics/pages/dashboard_page.dart';
import 'package:ailytics/pages/chatbot_page.dart';
import 'package:ailytics/pages/prediction_page.dart';
import 'package:ailytics/pages/recommendation_page.dart';
import 'package:provider/provider.dart';
import 'package:ailytics/providers/data_provider.dart';

// Global key to access navigation state
final GlobalKey<AppNavigationState> navigationKey = GlobalKey<AppNavigationState>();

class AppNavigation extends StatefulWidget {
  final Map<String, dynamic>? initialArguments;

  const AppNavigation({
    super.key,
    this.initialArguments,
  });

  @override
  State<AppNavigation> createState() => AppNavigationState();
}

class AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Check if we need to navigate to dashboard
    if (widget.initialArguments != null) {
      // Use Provider to update the data after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final dataProvider = Provider.of<DataProvider>(context, listen: false);
          dataProvider.setData(
            widget.initialArguments!['processedData'],
            widget.initialArguments!['fileName'],
          );
        }
      });

      // If flag is set to navigate to dashboard, set selected index to dashboard (2)
      if (widget.initialArguments!['navigateToDashboard'] == true) {
        _selectedIndex = 2; // Index for dashboard
      }
    }
  }

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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