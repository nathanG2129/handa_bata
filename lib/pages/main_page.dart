import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:handabatamae/pages/play_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MainPage extends StatefulWidget {
  final String selectedLanguage;

  const MainPage({super.key, required this.selectedLanguage});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBreakpoints(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: MaxWidthBox(
          maxWidth: 1200,
          child: ResponsiveScaledBox(
            width: ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 450),
              const Condition.between(start: 800, end: 1100, value: 800),
              const Condition.between(start: 1000, end: 1200, value: 1000),
            ]).value,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Column(
                  children: [
                    HeaderWidget(
                      selectedLanguage: _selectedLanguage,
                      onBack: () {
                        Navigator.pop(context);
                      },
                      onToggleUserProfile: () {
                        // Define the action for toggling user profile if needed
                      },
                      onChangeLanguage: (String newValue) {
                        _changeLanguage(newValue);
                      },
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                const SizedBox(height: 10),
                                Center(
                                  child: Column(
                                    children: [
                                      const TextWithShadow(
                                        text: 'Handa Bata',
                                        fontSize: 85,
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -30),
                                        child: const TextWithShadow(
                                          text: 'Mobile',
                                          fontSize: 85,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Transform.translate(
                                        offset: const Offset(0, -20), // Adjust this offset as needed
                                        child: SvgPicture.asset(
                                          'assets/characters/KladisandKloud.svg',
                                          width: 250,
                                          height: 250,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          'Join Kladis and Kloud as they explore the secrets of staying safe during earthquakes, typhoons and more! Tag along their journey to become preparedness experts and protect their community.',
                                          style: GoogleFonts.rubik(
                                            fontSize: 24,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        width: 200,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF351b61),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => PlayPage(selectedLanguage: _selectedLanguage, title: 'Adventure')),
                                            );
                                          },
                                          child: Text(
                                            'Play Now',
                                            style: GoogleFonts.vt323(
                                              fontSize: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 150),
                                Center(
                                  child: Column(
                                    children: [
                                      const TextWithShadow(
                                        text: 'Play Adventure',
                                        fontSize: 70,
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          'Embark on an exhilarating quest and put your earthquake and typhoon preparedness knowledge to the test in our engaging stage-based quiz game! Conquer each challenging stage and unlock different kinds of rewards!',
                                          style: GoogleFonts.rubik(
                                            fontSize: 24,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CarouselSlider(
                                        options: CarouselOptions(
                                          height: 200.0,
                                          enlargeCenterPage: true,
                                          autoPlay: true,
                                          aspectRatio: 16 / 9,
                                          autoPlayCurve: Curves.fastOutSlowIn,
                                          enableInfiniteScroll: true,
                                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                          viewportFraction: 0.8,
                                        ),
                                        items: [1,2,3,4,5].map((i) {
                                          return Builder(
                                            builder: (BuildContext context) {
                                              return Container(
                                                width: MediaQuery.of(context).size.width,
                                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                decoration: const BoxDecoration(
                                                  color: Colors.amber,
                                                ),
                                                child: Text('Adventure image $i', style: const TextStyle(fontSize: 16.0),)
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        width: 200,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF351b61),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => AdventurePage(selectedLanguage: _selectedLanguage)),
                                            );
                                          },
                                          child: Text(
                                            'Play Adventure',
                                            style: GoogleFonts.vt323(
                                              fontSize: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 150),
                                Center(
                                  child: Column(
                                    children: [
                                      const TextWithShadow(
                                        text: 'Play Arcade',
                                        fontSize: 70,
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          'Expand your preparedness knowledge with our fast-paced quiz games in Arcade! Climb the leaderboards and claim the title of the ultimate preparedness expert!',
                                          style: GoogleFonts.rubik(
                                            fontSize: 24,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CarouselSlider(
                                        options: CarouselOptions(
                                          height: 200.0,
                                          enlargeCenterPage: true,
                                          autoPlay: true,
                                          aspectRatio: 16 / 9,
                                          autoPlayCurve: Curves.fastOutSlowIn,
                                          enableInfiniteScroll: true,
                                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                          viewportFraction: 0.8,
                                        ),
                                        items: [1,2,3,4,5].map((i) {
                                          return Builder(
                                            builder: (BuildContext context) {
                                              return Container(
                                                width: MediaQuery.of(context).size.width,
                                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                decoration: const BoxDecoration(
                                                  color: Colors.amber,
                                                ),
                                                child: Text('Arcade image $i', style: const TextStyle(fontSize: 16.0),)
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        width: 200,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF351b61),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage)),
                                            );
                                          },
                                          child: Text(
                                            'Play Arcade',
                                            style: GoogleFonts.vt323(
                                              fontSize: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 150),
                                Center(
                                  child: Column(
                                    children: [
                                      const TextWithShadow(
                                        text: 'Learn About',
                                        fontSize: 70,
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -30),
                                        child: const TextWithShadow(
                                          text: 'Preparedness',
                                          fontSize: 70,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/characters/KloudLearn.svg',
                                            width: 200,
                                            height: 200,
                                          ),
                                          const SizedBox(width: 20),
                                          SvgPicture.asset(
                                            'assets/characters/KladisLearn.svg',
                                            width: 200,
                                            height: 200,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          'Explore our earthquake and typhoon preparedness resources to learn how to safeguard yourself during these calamities! Discover everything from how to secure your home to how to create a family emergency plan. Get prepared and stay safe!',
                                          style: GoogleFonts.rubik(
                                            fontSize: 24,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: 200,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF351b61),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          onPressed: () {
                                            // Add navigation to Learn About Preparedness page
                                          },
                                          child: Text(
                                            'Learn More',
                                            style: GoogleFonts.vt323(
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 175),
                              ],
                            ),
                          ),
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              children: [
                                Spacer(),
                                FooterWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
