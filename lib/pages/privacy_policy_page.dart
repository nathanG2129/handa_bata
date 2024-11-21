import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:handabatamae/pages/main/main_page.dart';

class PrivacyPolicyPage extends StatefulWidget {
  final String selectedLanguage;

  const PrivacyPolicyPage({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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

  Widget _buildSection(String title, String description, [List<String>? bulletPoints]) {
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
        if (bulletPoints != null) ...[
          const SizedBox(height: 8),
          ...bulletPoints.map((point) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    point,
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
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
                                                ? 'Privacy Policy'
                                                : 'Patakaran sa Privacy',
                                            style: GoogleFonts.rubik(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          if (_currentLanguage == 'en') ...[
                                            _buildSection(
                                              'Information Collected/Privacy Rights',
                                              'Handa Bata expresses their commitment to providing their users with privacy protection and security. We will only use your information for the purposes it was collected, and we will not share your personal information with any third parties without your consent.\n\nTo access our full features service, you must create an account by providing your personal information. Handa Bata will use this information to process your data and to provide you with the services requested. We may also use your information to improve our services, and we will contact you to verify your identity for security purposes. Handa Bata implements security measures to safeguard your personal data against unauthorized access and disclosure. You can access our website using the same information and update them anytime.\n\nBy creating an account, you agree to the terms of this Privacy Policy.',
                                            ),
                                            _buildSection(
                                              'Third-Party Vendors',
                                              'We use a variety of third-party APIs and Firebase services to provide features and functionality on our website. These third-party vendors may collect your personal information, such as your email address\n\nWe have carefully reviewed the third-party APIs and Firebase (Firebase services) we used, and we only share your personal information with them to an extent to provide you with the necessary features and functionality of our website. Handa Bata does not sell your personal information to these third-party vendors.',
                                            ),
                                            _buildSection(
                                              'Data Security',
                                              'We are committed to taking your data security seriously and have implemented encryption to protect your sensitive information from data loss and attacks. Handa Bata respects your rights to security and privacy, so we limit our access to your data.\n\nAs a registered user, you are also responsible for keeping your account credentials confidential. We are not responsible for keeping your information safe from unauthorized access by individuals you know.',
                                            ),
                                            _buildSection(
                                              'Use of Cookies',
                                              'Cookies are small fragments of data stored within the website to be retrieved when using our services. We use cookies to improve your browsing experience and website functionality. Handa Bata only stores the necessary information to provide you with the best possible experience. We also use cookies to store how users perform in our game.',
                                            ),
                                            _buildSection(
                                              'User Rights',
                                              'Handa Bata respects your rights to the following:',
                                              [
                                                'Creating your Account - Users have the right to create their own account and gain full access to the features of our website.',
                                                'Access to your Account and Information - Users have the right to access their account and the information provided by our website.',
                                                'Updating your Account - Users have the ability to update their account information on our website.',
                                                'Deleting your Account - Users have the ability to delete their account permanently on our website.',
                                                'Recover your Account - Users have the ability to recover their account when they forget their password.',
                                              ],
                                            ),
                                            _buildSection(
                                              'Questions and Concerns',
                                              'For any questions or concerns about our privacy policy, please email us at handabata.official@gmail.com.\n\nWe will do our best to respond quickly to your questions and concerns.',
                                            ),
                                          ] else ...[
                                            _buildSection(
                                              'Impormasyong Nakolekta / Mga Karapatan sa Privacy',
                                              'Pinapangako ng Handa Bata na mabigyang-proteksiyon at seguridad ang privacy ng mga gagamit nito. Ang iyong mga personal na impormasyon na makokolekta ay gagamitin lamang base sa layunin kung saan ito nauukol, at hindi ibabahagi sa anumang mga third party nang wala ang iyong pahintulot.\n\nUpang makuha ang aming buong serbisyo, kinakailangan ninyong gumawa ng account sa pamamagitan ng pagbibigay ng iyong personal na impormasyon. Gagamitin ng Handa Bata ang iyong mga impormasyon sa pagproseso ng iyong data at ibahagi ang iyong mga kahilingan na serbisyo. Maaari rin namin gamitin ang iyong impormasyon sa pagpapabuti ng aming mga serbisyo at kami ay makikipag-ugnayan sa inyo upang patunayan ang iyong pagkakakilanlan para sa mga layuning pang-seguridad. Isinasagawa ang Handa Bata nang may hakbang pang-seguridad upang mapangalagaan ang iyong personal na data laban sa mga hindi awtorisadong pag-access. Maaari mong ma-access ang aming website gamit ang iyong impormasyon at i-update ang mga ito sa anumang oras.\n\nSa paggawa ng account, kinakailangan mong sumang-ayon sa tuntunin ng Private Policy.',
                                            ),
                                            _buildSection(
                                              'Mga Third-Party na Vendor',
                                              'Gumagamit kami ng iba\'t ibang mga third party na API Firebase na nagbibigay ng mga feature at functionality sa aming website. Maaring kolektahin ng mga third-party na vendor na ito ang iyong personal na impormasyon kagaya ng iyong email address.\n\nMaingat naming sinusubaybayan ang mga ginamit namin na API at Firebase, at ibinahagi lamang namin sa mga nasabing third-party vendor ang iyong personal na impormasyon upang mabigay namin sa inyo ang mga feature at functionality ng website. Hindi ibebenta ng Handa Bata ang iyong personal na impormasyon sa mga nasabing third-party na vendor.',
                                            ),
                                            _buildSection(
                                              'Seguridad ng Data',
                                              'Nakatuon kami na pangalagaan ang seguridad ng iyong data at isinagawa namin ang encryption upang pangalagaan ang iyong sensitibong impormasyon mula sa data loss at attacks. Nirerespeto ng Handa Bata ang iyong mga karapatan sa seguridad at privacy habang tinatakda din nila ang pag-access nito sa iyong data.\n\nBilang rehistradong gumagamit, responsable ka rin na panatilihing kumpidensyal ang mga kredensyal ng iyong account. Hindi kami responsable na mapanatiling ligtas sa iyong impormasyon mula sa hindi awtorisadong pag-access ng mga indibidwal na kilala mo.',
                                            ),
                                            _buildSection(
                                              'Paggamit ng Cookies',
                                              'Ang cookies ay maliliit na piraso ng data na nakaimbak sa loob ng website na kinukuha kapag ginagamit ang aming mga serbisyo. Gumagamit kami ng cookies upang mapabuti ang iyong karanasan sa pagba-browse at sa paggamit ng aming website. Ang Handa Bata ay nag-iimbak lamang ng kinakailangang impormasyon upang mabigyan kayo ng maayos na karanasan. Gumagamit din kami ng cookies upang mag-imbak kung paano gumaganap ang mga maglalaro sa aming mga laro.',
                                            ),
                                            _buildSection(
                                              'Mga Karapatan ng Gumagamit',
                                              'Nirerespeto ng Handa Bata ang iyong sumusunod na karapatan:',
                                              [
                                                'Paglikha ng iyong Account - May karapatan ang mga user na gumawa ng kanilang sariling account at makakuha ng buong access sa features ng aming website.',
                                                'Pag-access sa iyong Account at Impormasyon - May karapatan ang mga user na i-access ang kanilang account at ang impormasyong ibinigay ng aming website.',
                                                'Pag-update ng iyong Account - May kakayahan ang mga user na i-update ang impormasyon sa kanilang account sa aming website.',
                                                'Pagtanggal ng iyong Account - May kakayahan ang mga gumagamit na tuluyan nang tanggalin ang kanilang account sa aming website.',
                                                'Pag-recover ng iyong Account - May kakayahan ang mga user na ma-recover ang kanilang account kapag nakalimutan nila ang kanilang password.',
                                              ],
                                            ),
                                            _buildSection(
                                              'Mga Tanong at Alalahanin',
                                              'Para sa anumang mga katanungan o alalahanin tungkol sa aming patakaran sa privacy, maaari kayong mag-email sa handabata.official@gmail.com.\n\nPagsisikapan naming tumugon nang mabilis at lubusan sa iyong katanungan at mga alalahanin.',
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