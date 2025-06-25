// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making API calls
import 'dart:convert';
import 'dart:async'; // Add this for TimeoutException
import '../config/app_config.dart';
import 'package:quickhire/screens/login.dart'; // For JSON parsing

class VerifyOtp extends StatefulWidget {
  static const String id = 'verify_otp'; // Define a unique route ID for this screen
  const VerifyOtp({super.key});

  @override
  State<VerifyOtp> createState() => _VerifyOtpState();
}

class _VerifyOtpState extends State<VerifyOtp> {
  final _emailController = TextEditingController(); // Email input controller
  final _otpController = TextEditingController(); // OTP input controller
  final _formKey = GlobalKey<FormState>(); // For form validation
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely extract arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _emailController.text = args['email'] ?? '';
      print("Received email: ${_emailController.text}");
    }
  }

  // Function to show dialogs for messages or errors
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
                  Navigator.pop(context); // Close the dialog
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

  // Function to handle OTP verification
  Future<void> _verifyOtp() async {
    const String apiUrl = "${AppConfig.authEndpoint}/verify-email";

    try {
      setState(() {
        _isLoading = true;
      });

      final Map<String, dynamic> requestBody = {
        "email": _emailController.text.trim(),
        "otp": _otpController.text.trim(),
      };

      print("Attempting OTP verification to: $apiUrl");
      print("With request body: ${json.encode(requestBody)}");
      
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: AppConfig.connectionTimeout ~/ 1000),
        onTimeout: () {
          print("OTP verification request timed out");
          throw TimeoutException("The connection has timed out, please try again!");
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Show success message
        _showDialog('OTP verified successfully! You can now log in.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushNamed(context, Login.id); // Navigate back to login
        });
      } else {
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          final String errorMessage = errorResponse['error'] ?? errorResponse['message'] ?? 'Unknown error occurred';
          _showDialog('Error: $errorMessage');
        } catch (e) {
          _showDialog('Error: Server returned status code ${response.statusCode}. Response: ${response.body}');
        }
      }
    } catch (error) {
      print("OTP verification error: $error");
      _showDialog('An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    const String apiUrl = "${AppConfig.authEndpoint}/resend-otp";

    try {
      setState(() {
        _isLoading = true;
      });

      final Map<String, dynamic> requestBody = {
        "email": _emailController.text.trim(),
      };

      print("Attempting to resend OTP to: $apiUrl");
      print("With request body: ${json.encode(requestBody)}");
      
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: AppConfig.connectionTimeout ~/ 1000),
        onTimeout: () {
          print("Resend OTP request timed out");
          throw TimeoutException("The connection has timed out, please try again!");
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Show success message
        _showDialog('OTP has been resent to your email.');
      } else {
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          final String errorMessage = errorResponse['error'] ?? errorResponse['message'] ?? 'Unknown error occurred';
          _showDialog('Error: $errorMessage');
        } catch (e) {
          _showDialog('Error: Server returned status code ${response.statusCode}. Response: ${response.body}');
        }
      }
    } catch (error) {
      print("Resend OTP error: $error");
      _showDialog('An error occurred: $error');
    } finally {
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
                        'Verify OTP',
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
                        controller: _otpController,
                        keyboardType: TextInputType.number, // Numeric keyboard for OTP
                        decoration: InputDecoration(
                          labelText: 'OTP',
                          hintText: 'Enter the OTP sent to your email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the OTP';
                          }
                          if (value.length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() == true) {
                              _verifyOtp(); // Trigger OTP verification
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (_emailController.text.isEmpty) {
                              _showDialog('Please enter your email address first.');
                            } else {
                              _resendOtp(); // Call the new resend OTP function
                            }
                          },
                          child: const Text(
                            'Resend OTP?',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
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
