import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:handabatamae/pages/main/main_page.dart';

class TermsOfServicePage extends StatefulWidget {
  final String selectedLanguage;

  const TermsOfServicePage({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
  }

  void _handleLanguageChange(String newLanguage) {
    setState(() {
      _currentLanguage = newLanguage;
    });
  }

  void _handleBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(selectedLanguage: _currentLanguage),
      ),
    );
  }

  Widget _buildSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF351B61),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.rubik(
            fontSize: 18,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBack(context);
        return false;
      },
      child: Scaffold(
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
                        selectedLanguage: _currentLanguage,
                        onBack: () => _handleBack(context),
                        onChangeLanguage: _handleLanguageChange,
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate([
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _currentLanguage == 'en'
                                                ? 'Terms of Service'
                                                : 'Mga Tuntunin ng Serbisyo',
                                            style: GoogleFonts.rubik(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          Text(
                                            _currentLanguage == 'en'
                                                ? 'These Terms of Service serve as the rules that govern your use of the Handa Bata website and all its related services. By using our Service, you agree to constitute these Terms. If you do not agree to these Terms, we understand that our Service may not be suitable for you.'
                                                : 'Ang mga Tuntunin ng Serbisyong ito ay nagsisilbing mga tuntunin na namamahala sa iyong paggamit sa website ng Handa Bata at lahat ng kaugnay na serbisyo nito. Sa paggamit ng aming Serbisyo, sumasang-ayon ka na sundin ang mga Tuntunin na ito. Kung hindi ka sumasang-ayon sa mga Tuntuning ito, nauunawaan namin na ang Serbisyo ay maaaring hindi angkop para sa iyo.',
                                            style: GoogleFonts.rubik(
                                              fontSize: 18,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          if (_currentLanguage == 'en') ...[
                                            _buildSection(
                                              'Eligibility',
                                              'To be eligible to create an account on our website, you must be of Junior High School age, specifically between the ages of 11 and 16. Handa Bata aims to provide general information and preparedness measures on earthquakes and typhoons in the Philippines. The content on this website is intended for educational purposes only. The provided information does not intend to replace professional advice or guidance from experts in disaster preparedness.\n\nBy creating an account, you agree to our Terms of Service.',
                                            ),
                                            _buildSection(
                                              'User Account and Responsibilities',
                                              'To use our full feature services, you must create a user account. By creating an account, you consent to providing your credential information in our system. As a registered user, you are always responsible for keeping your account confidential. Any activities under your account will be subject to your control, and you will be responsible for them.',
                                            ),
                                            _buildSection(
                                              'Intellectual Property',
                                              'We own all intellectual property rights to the Service and its content, including trademarks and copyrights. You are granted the permission to use the Service for your personal, non-commercial use only. You may not reproduce, distribute, modify, transmit, display, create derivative works of, or sell any part of the Service or its content unless you have written permission from us.',
                                            ),
                                            _buildSection(
                                              'Disclaimer',
                                              'The educational information on this website is primarily from the public domain, specifically government agencies in the Philippines, such as the National Disaster Risk Reduction and Management Council (NDRRMC), the Philippine Institute of Volcanology and Seismology (PHIVOLCS), the Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA), and the Department of Education (DepEd). The photos, infographics, and videos used on the website are from Unsplash, Getty Images and official government sources.\n\nWe have used public domain information in good faith but do not guarantee its accuracy or completeness. While we take responsibility for validating the information we put on our website, we encourage you to read other sources, such as textbooks, scholarly articles, and government publications, to learn more about earthquakes and typhoons.\n\nAdditionally, the music tracks and sound effects we use on our website are from websites that offer royalty-free music tracks and sound effects.',
                                            ),
                                            _buildSection(
                                              'Questions and Concerns',
                                              'For any questions or concerns about our terms of service, please email us at handabata.official@gmail.com.\n\nWe will do our best to respond quickly to your questions and concerns.',
                                            ),
                                          ] else ...[
                                            _buildSection(
                                              'Mga Karapat-dapat',
                                              'Upang maging karapat-dapat na gumawa ng account sa aming website, dapat ay nasa edad ka ng Junior High School, partikular sa pagitan ng edad na 11 at 16. Ang Handa Bata ay naglalayong magbigay ng pangkalahatang impormasyon at mga hakbang sa paghahanda sa mga lindol at bagyo sa Pilipinas. Ang nilalaman ng website na ito ay para sa layuning pang-edukasyon lamang. Ang ibinigay na impormasyon ay hindi naglalayong palitan ang propesyonal na payo o gabay mula sa mga espesyalista sa pamamahala ng eksperto sa paghahanda sa sakuna.\n\nSa pamamagitan ng paggawa ng isang account, sumasang-ayon ka sa aming Mga Tuntunin ng Serbisyo.',
                                            ),
                                            _buildSection(
                                              'Account ng User at Responsabilidad',
                                              'Upang magamit ang aming buong serbisyo, dapat kang gumawa ng isang user account. Sa pamamagitan ng paggawa ng account, sumasang-ayon ka na ibigay ang iyong kredensyal na impormasyon sa aming system.\n\nBilang isang rehistradong user, palagi kang responsable sa pagpapanatili na kumpidensyal ang iyong account. Ang anumang aktibidad sa ilalim ng iyong account ay sumasailalim sa iyong kontrol, at ikaw ang mananagot para sa mga ito.',
                                            ),
                                            _buildSection(
                                              'Intelektwal na Pag-aari',
                                              'Kami ay nagmamay-ari ng lahat ng mga karapatan sa intelektwal na pag-aari sa Serbisyo at sa nilalaman nito, kabilang ang mga trademark at copyright. Binibigyan ka ng pahintulot na gamitin ang Serbisyo para sa iyong personal, hindi pangkomersyal na paggamit lamang. Hindi mo maaaring kopyahin, ipamahagi, baguhin, ipadala, ipakita, lumikha ng mga hinangong gawa ng, o ibenta ang anumang bahagi ng Serbisyo o nilalaman nito maliban kung mayroon kang nakasulat na pahintulot galing sa amin.',
                                            ),
                                            _buildSection(
                                              'Disclaimer',
                                              'Ang impormasyong pang-edukasyon sa website na ito ay pangunahing mula sa mga public domain, partikular sa mga ahensya ng gobyerno sa Pilipinas, tulad ng National Disaster Risk Reduction and Management Council (NDRRMC), Philippine Institute of Volcanology and Seismology (PHIVOLCS), Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA), at Department of Education (DepEd). Ang mga larawan, infographics, at bidyo na ginamit sa website ay mula sa Unsplash, Getty Images at mga opisyal na mapagkukunan sa pamahalaan.\n\nGumamit kami ng impormasyon mula sa public domain nang may magandang hangarin, ngunit hindi namin sinisigurado ang kawastuhan o pagkakumpleto nito. Bagama\'t tinitiyak namin na wasto ang impormasyong inilalagay namin sa aming website, hinihikayat namin kayo na magbasa ng iba pang mga mapagkukunan, tulad ng mga aklat-aralin, mga artikulong pang-akademiko, at mga publikasyon ng pamahalaan, para sa karagdagang kaalaman tungkol sa mga lindol at bagyo.\n\nBukod dito, ang mga music track at sound effects na ginagamit namin sa aming website ay mula sa mga website na nagbibigay ng royalty-free na mga music tracks at sound effects.',
                                            ),
                                            _buildSection(
                                              'Mga Tanong at Alalahanin',
                                              'Para sa anumang mga katanungan o alalahanin tungkol sa aming mga tuntunin sa serbisyo, maaari kayong mag-email sa handabata.official@gmail.com.\n\nGagawin namin ang lahat ng aming makakaya upang agad na matugunan ang iyong mga katanungan at alalahanin.',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ]),
                            ),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  const Spacer(),
                                  FooterWidget(selectedLanguage: _currentLanguage),
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
      ),
    );
  }
} 