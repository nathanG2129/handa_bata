import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class CharacterPage extends StatefulWidget {
  final VoidCallback onClose;

  const CharacterPage({super.key, required this.onClose});

  @override
  _CharacterPageState createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  late Future<List<Map<String, dynamic>>> _avatarsFuture;

  @override
  void initState() {
    super.initState();
    _avatarsFuture = AvatarService().fetchAvatars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withOpacity(0),
          child: GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight, // Adjust to start below the header
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveValue<double>(
                        context,
                        defaultValue: MediaQuery.of(context).size.width * 0.75,
                        conditionalValues: [
                          Condition.smallerThan(
                            name: MOBILE,
                            value: MediaQuery.of(context).size.width * 0.9,
                          ),
                          Condition.largerThan(
                            name: TABLET,
                            value: MediaQuery.of(context).size.width * 0.5,
                          ),
                        ],
                      ).value!,
                    ),
                    color: const Color(0xFF241242),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _avatarsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No avatars found.'));
                        } else {
                          final avatars = snapshot.data!;
                          return GridView.builder(
                            padding: const EdgeInsets.all(8.0),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: ResponsiveValue<int>(
                                context,
                                defaultValue: 2,
                                conditionalValues: [
                                  const Condition.largerThan(name: TABLET, value: 4),
                                ],
                              ).value,
                              crossAxisSpacing: 0.0,
                              mainAxisSpacing: 0.0,
                            ),
                            itemCount: avatars.length,
                            itemBuilder: (context, index) {
                              final avatar = avatars[index];
                              return Card(
                                color: Colors.transparent, // Make the card background transparent
                                elevation: 0, // Remove the card elevation
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30, // Increase the radius
                                        backgroundColor: Colors.white, // Make the background transparent
                                        child: Container(
                                          width: 35, // Set the width of the container
                                          height: 35, // Set the height of the container
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            image: DecorationImage(
                                              image: AssetImage('assets/avatars/${avatar['img']}'),
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.none, // Apply pixelated effect
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        avatar['title'] ?? 'Avatar',
                                        style: GoogleFonts.vt323(
                                          color: Colors.white, // Use white font color
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
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