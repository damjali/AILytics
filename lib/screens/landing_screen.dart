import 'package:ailytics/screens/login_screen.dart';
import 'package:ailytics/screens/signup_screen.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 640;
    final isTablet = screenWidth <= 991 && screenWidth > 640;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: isMobile
              ? const DecorationImage(
            image: NetworkImage(
              'https://cdn.builder.io/api/v1/image/assets%2Fc1b70a3ade1841a0955962a05969ef37%2Fcb2930c1db7e45dd96c87e2f1a31d515',
            ),
            fit: BoxFit.cover,
          )
              : null,
          gradient: isMobile
              ? null
              : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                margin: isMobile
                    ? const EdgeInsets.only(top: 83.0, left: 20.0)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _buildHeadingText(isMobile, isTablet),
                    const SizedBox(height: 40),
                    _buildButtonSection(isMobile, context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadingText(bool isMobile, bool isTablet) {
    final TextStyle baseStyle = TextStyle(
      fontFamily: 'Poppins', // Using Poppins exclusively
      fontWeight: FontWeight.w900,
      color: Colors.black,
      fontSize: isMobile
          ? 40
          : isTablet
          ? 40
          : 48,
      height: isMobile ? 1.25 : 1.2,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 0),
          blurRadius: 0.5,
        ),
      ],
    );

    return Column(
      crossAxisAlignment:
      isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Kickstart',
          style: baseStyle,
        ),
        Text(
          'your grind.',
          style: baseStyle,
        ),
        Text(
          'Insights',
          style: baseStyle.copyWith(
            height: isMobile ? 1.85 : 1.2,
          ),
        ),
        Text(
          'all-in-one.',
          style: baseStyle,
        ),
      ],
    );
  }

  Widget _buildButtonSection(bool isMobile, BuildContext context) {
    return SizedBox(
      height: isMobile ? 171 : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? MediaQuery.of(context).size.width * 0.59 : double.infinity,
            margin: isMobile
                ? const EdgeInsets.only(top: 66, bottom: 9)
                : EdgeInsets.zero,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: isMobile
                    ? const EdgeInsets.symmetric(vertical: 14, horizontal: 24)
                    : const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: const Text(
                'Register',
                style: TextStyle(
                  fontFamily: 'Poppins', // Using Poppins exclusively
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: const Text(
              'I already have an account',
              style: TextStyle(
                fontFamily: 'Poppins', // Using Poppins exclusively
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}