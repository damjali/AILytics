import 'package:ailytics/screens/splash_screen.dart';
import 'package:ailytics/services/auth_service.dart';
import 'package:ailytics/pages/upload_page.dart';
import 'package:ailytics/pages/data_result_page.dart';
import 'package:ailytics/navigation/app_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ailytics/providers/data_provider.dart'; // Adjusted the path based on standard convention
import 'firebase_options.dart';

// Define a navigator key for routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DataProvider()), // Added DataProvider
      ],
      child: MaterialApp(
        title: 'AIltytics',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Fixed navigatorKey type
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Poppins',
          visualDensity: VisualDensity.adaptivePlatformDensity, // Added from suggestion
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => AppNavigation(
                initialArguments: settings.arguments as Map<String, dynamic>?,
              ),
            );
          } else if (settings.name == '/dataResult') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => DataResultPage(
                processedData: args['processedData'],
                fileName: args['fileName'],
              ),
            );
          } else if (settings.name == '/upload') {
            // Add the upload page route
            return MaterialPageRoute(
              builder: (context) => const UploadPage(),
            );
          }
          // Handle other routes if needed
          return null;
        },
        onUnknownRoute: (settings) {
          // Handle unknown routes
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Page not found!'),
              ),
            ),
          );
        },
      ),
    );
  }
}