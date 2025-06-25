// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Add this for TimeoutException
import 'js_dashboard.dart';
import 'dart:convert';
import 'decision_screen.dart';
import 'emp_dashboard.dart';
import 'forgot_password.dart';
import '../config/app_config.dart';

class Login extends StatefulWidget {
  static const String id = 'login';
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController(); // Controller for email input
  final _passwordController = TextEditingController(); // Controller for password input
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();

    // Trigger a test notification on initialization
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1, // Unique ID for this notification
        channelKey: 'basic_channel', // Use the channel defined in main.dart
        title: 'Notification Testing',
        body: 'Welcome to QuickHire!',
        notificationLayout: NotificationLayout.Default, // Default notification style
      ),
    );
  }

  // Function to show dialog for errors or messages
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to handle login logic
  Future<void> _login() async {
    const String apiUrl = AppConfig.loginEndpoint;

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final Map<String, dynamic> requestBody = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      print("Attempting login to: $apiUrl");
      print("With request body: ${json.encode(requestBody)}");
      
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: AppConfig.connectionTimeout ~/ 1000),
        onTimeout: () {
          print("Login request timed out");
          throw TimeoutException("The connection has timed out, please try again!");
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        print("Parsed response data: $responseData");
        
        if (responseData['token'] == null) {
          _showDialog('Error: Authentication token is missing in the response');
          return;
        }
        
        final String token = responseData['token'];
        
        // Check if user data exists in the response
        if (responseData['user'] == null) {
          _showDialog('Error: User data is missing in the response');
          return;
        }
        
        final String role = responseData['user']['role'];

        // Save token to shared preferences for future API calls
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', role);

        // Show success message
        _showDialog('Login successful! Redirecting to dashboard...');

        // Navigate to the MainWrapper
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/main');
        });
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          final String errorMessage = errorResponse['error'] ?? errorResponse['message'] ?? 'Unknown error occurred';
          _showDialog('Error: $errorMessage');
        } catch (e) {
          // If response body is not valid JSON
          _showDialog('Error: Server returned status code ${response.statusCode}. Response: ${response.body}');
        }
      }
    } catch (error) {
      print("Login error: $error");
      _showDialog('An error occurred during login: ${error.toString()}');
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                Center(
                  child: Image.asset(
                    'assets/quickhirelogo.png', // Replace with your actual logo path
                    height: 180,
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to QuickHire',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter Your Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter Your Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, ForgotPassword.id); // Add ForgotPassword screen route
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading 
                            ? null // Disable button when loading
                            : () {
                                if (_formKey.currentState?.validate() == true) {
                                  _login(); // Trigger login
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, DecisionScreen.id);
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.black54, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
