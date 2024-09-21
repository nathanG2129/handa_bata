import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;

  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      // Fetch the email associated with the username from Firestore
      final email = await _authService.getEmailByUsername(username);

      if (email != null) {
        // Sign in with email and password using Firebase Auth
        final user = await _authService.signInWithEmailAndPassword(email, password);

        if (user != null) {
          // Check if the user has admin privileges
          final role = await _authService.getUserRole(user.uid);
          if (role == 'admin') {
            // Navigate to AdminHomePage after successful login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          } else {
            // Show error message if the user is not an admin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You do not have admin privileges.')),
            );
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } else {
        // Show error message if username is not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username not found. Please try again.')),
        );
      }
    }
  }

  void _forgotPassword() {
    // Handle forgot password
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 75),
                SizedBox(
                  width: 400, // Set the desired width
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0), // Oblong shape
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0), // Oblong shape
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10), // Space between password field and the row of buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: _staySignedIn,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _staySignedIn = value!;
                                  });
                                },
                              ),
                              const Text('Stay signed in'),
                            ],
                          ),
                          TextButton(
                            onPressed: _forgotPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Space between the row of buttons and the login button
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}