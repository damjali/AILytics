import 'package:ailytics/services/auth_service.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ailytics/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/custom_icons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.resetPassword(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isEmailSent = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width <= 640;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: 20,
          ),
          constraints: const BoxConstraints(maxWidth: 412),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Icon(
                    CustomIcons.arrowLeft,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Title
                          Text(
                            'Oops!',
                            style: TextStyle(
                              fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Forgot your password?',
                            style: TextStyle(
                              fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                              fontSize: isSmallScreen ? 20 : 24,
                              color: const Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Icon container
                          SizedBox(
                            width: 80,
                            height: 60,
                            child: Stack(
                              children: [
                                // Lock icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CustomIcons.lock,
                                      size: 28,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ),

                                // Key icon
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CustomIcons.key,
                                        size: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Message
                          Text(
                            'We\'ll send you a link to your email.\nFollow the instructions to recover\nyour password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                              fontSize: isSmallScreen ? 14 : 16,
                              color: const Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Form
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? double.infinity : 320,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Form label
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Email input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                      fontSize: 16,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                    fontSize: 16,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!EmailValidator.validate(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Send button
                                SizedBox(
                                  width: double.infinity,
                                  child: _isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                    onPressed: _isEmailSent ? null : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                                    ),
                                    child: Text(
                                      'Send',
                                      style: TextStyle(
                                        fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Success message
                                if (_isEmailSent)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Password reset email sent! Check your inbox for instructions.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),

                          // Signup prompt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                  color: const Color(0xFF666666),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                    fontFamily: isSmallScreen ? 'Poppins' : 'Inter',
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}