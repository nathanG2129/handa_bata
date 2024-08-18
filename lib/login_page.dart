import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;

  void _login() {
	if (_formKey.currentState!.validate()) {
	  // Perform login
	}
  }

  void _forgotPassword() {
	showDialog(
	  context: context,
	  builder: (BuildContext context) {
		return AlertDialog(
		  title: const Text('Forgot Password'),
		  content: const Text('Password reset instructions will be sent to your email.'),
		  actions: <Widget>[
			TextButton(
			  onPressed: () {
				Navigator.of(context).pop(); // Close the dialog
			  },
			  child: const Text('OK'),
			),
		  ],
		);
	  },
	);
  }

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  appBar: AppBar(
		title: const Text('Login'),
	  ),
	  body: Padding(
		padding: const EdgeInsets.all(40.0),
		child: Form(
		  key: _formKey,
		  child: Column(
			mainAxisAlignment: MainAxisAlignment.center,
			children: <Widget>[
			  const Text(
				'Handa Bata',
				style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.black),
			  ),
			  const Text(
				'Mobile App Edition',
				style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
			  ),
			  const SizedBox(height: 75),
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
			  const SizedBox(height: 10), // Space between the login button and the register button
			  ElevatedButton(
				onPressed: () {
				  // Navigate to the registration page
				  Navigator.push(
					context,
					MaterialPageRoute(builder: (context) => const RegistrationPage()),
				  );
				},
				child: const Text('Register'),
			  ),
			],
		  ),
		),
	  ),
	);
  }
}