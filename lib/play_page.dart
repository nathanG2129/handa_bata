import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String title;

  const HomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  appBar: AppBar(
		title: Text(title),
	  ),
	  body: Center(
		child: Column(
		  mainAxisAlignment: MainAxisAlignment.center,
		  children: <Widget>[
			ElevatedButton(
			  onPressed: () {
				// Navigate to Adventure mode
			  },
			  style: ElevatedButton.styleFrom(
				padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 100),
				textStyle: const TextStyle(fontSize: 24),
			  ),
			  child: const Text('Adventure'),
			),
			const SizedBox(height: 20),
			ElevatedButton(
			  onPressed: () {
				// Navigate to Arcade mode
			  },
			  style: ElevatedButton.styleFrom(
				padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 100),
				textStyle: const TextStyle(fontSize: 24),
			  ),
			  child: const Text('Arcade'),
			),
		  ],
		),
	  ),
	);
  }
}