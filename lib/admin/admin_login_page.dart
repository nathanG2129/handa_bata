import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_home_page.dart';
import 'security/admin_session.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  AdminLoginPageState createState() => AdminLoginPageState();
}

class AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;
  bool _isAuthenticating = false;

  final AuthService _authService = AuthService();

  Future<bool> _validateAdminAccess(String username) async {
    // Check if user has admin role
    return true;
  }

  void _showSecurityAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Alert'),
        content: const Text('Multiple failed login attempts detected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAdminLoginError(dynamic error) {
    setState(() => _isAuthenticating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login error: $error')),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isAuthenticating = true);
      
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final user = await _authService.signInWithUsernameAndPassword(username, password);

        if (!mounted) return;

        if (user != null) {
          final role = await _authService.getUserRole(user.uid);
          
          if (role == 'admin') {
            
            try {
              await AdminSession().startSession();
              
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminHomePage()),
              );
            } catch (sessionError) {
              throw sessionError;
            }
          } else {
            setState(() => _isAuthenticating = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You do not have admin privileges.')),
            );
          }
        } else {
          setState(() => _isAuthenticating = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        _handleAdminLoginError(e);
      }
    }
  }

  void _forgotPassword() {
    // Handle forgot password
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
        ),
        if (_isAuthenticating)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}