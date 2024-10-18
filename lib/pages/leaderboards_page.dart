import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/services/stage_service.dart'; // Import StageService

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  _LeaderboardsPageState createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final StageService _stageService = StageService();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories('en'); // Assuming 'en' as the language
    setState(() {
      _categories = categories;
      _tabController = TabController(length: _categories.length, vsync: this);
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData(String categoryId) async {
    List<Map<String, dynamic>> leaderboardData = [];
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('User').get();

    for (var userDoc in userSnapshot.docs) {
      DocumentSnapshot gameSaveDataDoc = await userDoc.reference.collection('GameSaveData').doc(categoryId).get();
      if (gameSaveDataDoc.exists) {
        Map<String, dynamic> gameSaveData = gameSaveDataDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> stageData = gameSaveData['stageData'] as Map<String, dynamic>;

        for (var stageKey in stageData.keys) {
          if (stageKey.contains('Arcade')) {
            int bestRecord = stageData[stageKey]['bestRecord'] as int;
            int crntRecord = stageData[stageKey]['crntRecord'] as int;

            if (bestRecord != -1 && crntRecord != -1) {
              DocumentSnapshot profileDoc = await userDoc.reference.collection('ProfileData').doc(userDoc.id).get();
              if (profileDoc.exists) {
                Map<String, dynamic> profileData = profileDoc.data() as Map<String, dynamic>;
                leaderboardData.add({
                  'nickname': profileData['nickname'],
                  'crntRecord': crntRecord,
                });
              }
            }
          }
        }
      }
    }

    leaderboardData.sort((a, b) => a['crntRecord'].compareTo(b['crntRecord']));
    return leaderboardData;
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/backgrounds/background.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const TextWithShadow(
                  text: 'Leaderboards',
                  fontSize: 48,
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _categories.map((category) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _tabController?.index = _categories.indexOf(category);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _tabController?.index == _categories.indexOf(category) ? Colors.white : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Text(
                            category['name'],
                            style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                if (_tabController != null)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _categories.map((category) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchLeaderboardData(category['id']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('No data available'));
                            } else {
                              List<Map<String, dynamic>> leaderboardData = snapshot.data!;
                              return ListView.builder(
                                itemCount: leaderboardData.length,
                                itemBuilder: (context, index) {
                                  Color containerColor;
                                  if (index == 0) {
                                    containerColor = const Color(0xFFF1B33A); // Gold
                                  } else if (index == 1) {
                                    containerColor = Colors.grey; // Silver
                                  } else if (index == 2) {
                                    containerColor = const Color(0xFFCD7F32); // Bronze
                                  } else {
                                    containerColor = const Color(0xFF241242); // Default
                                  }
                                
                                  return Container(
                                    color: containerColor,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 50,
                                            color: const Color(0xFF4d278f), // Rank container color
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 60.0), // Add padding to the left to make space for the rank container
                                          child: ListTile(
                                            title: Text(
                                              leaderboardData[index]['nickname'],
                                              style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            trailing: Text(
                                              formatTime(leaderboardData[index]['crntRecord']),
                                              style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}