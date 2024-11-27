import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/email_verification_dialog.dart';
import 'package:handabatamae/pages/login_page.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../helpers/validation_helpers.dart';
import '../helpers/widget_helpers.dart';
import '../helpers/date_helpers.dart';
import '../widgets/privacy_policy_error.dart';
import '../styles/input_styles.dart';
import '../widgets/text_with_shadow.dart';
import '../localization/register/localization.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../constants/breakpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class RegistrationPage extends StatefulWidget {
  final String selectedLanguage; // Add this line
  const RegistrationPage({super.key, required this.selectedLanguage});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPrivacyPolicyAccepted = false;
  bool _showPrivacyPolicyError = false;
  bool _isPasswordLengthValid = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _isPasswordFieldTouched = false;

  String _selectedLanguage = 'en'; // Add language selection

  bool _isRegistering = false; // Add state variable

  late AnimationController _dialogAnimationController;
  late Animation<Offset> _dialogSlideAnimation;

  // Add state variables for both password fields
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
    _checkUserStatus();
    _dialogAnimationController = AnimationController(
      vsync: this as TickerProvider,
      duration: const Duration(milliseconds: 350),
    );
    _dialogSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _dialogAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _dialogAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String? role = await AuthService().getUserRole(currentUser.uid);
        
        // If user is already registered (not a guest), redirect to main page
        if (role != 'guest') {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainPage(selectedLanguage: _selectedLanguage),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDialogClose() async {
    await _dialogAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _register() async {
    setState(() {
      _showPrivacyPolicyError = !_isPrivacyPolicyAccepted;
      _isRegistering = true;
    });

    if (_formKey.currentState!.validate() && _isPrivacyPolicyAccepted) {
      try {
        // Check if username is taken first
        bool isUsernameTaken = await AuthService().isUsernameTaken(_usernameController.text);
        
        if (isUsernameTaken) {
          setState(() => _isRegistering = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  RegisterLocalization.translate('username_taken', _selectedLanguage),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _isRegistering = false);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => EmailVerificationDialog(
              email: _emailController.text,
              selectedLanguage: _selectedLanguage,
              username: _usernameController.text,
              password: _passwordController.text,
              birthday: _birthdayController.text,
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        }
      } catch (e) {
        setState(() => _isRegistering = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isRegistering = false);
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<bool> _validateRegistrationData() async {
    if (!_formKey.currentState!.validate()) return false;
    if (!_isPrivacyPolicyAccepted) {
      setState(() => _showPrivacyPolicyError = true);
      return false;
    }
    return true;
  }

  Future<bool> _checkRateLimit() async {
    // Implement rate limiting logic
    return true;
  }

  void _handleRegistrationError(dynamic error) {
    setState(() => _isRegistering = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration error: $error')),
    );
  }

  void _cleanupFailedRegistration() {
    setState(() => _isRegistering = false);
  }

  void _showPrivacyPolicy() {
    _dialogAnimationController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return _buildPolicyDialog(
          title: RegisterLocalization.translate('privacy_policy_title', _selectedLanguage),
          content: _getPrivacyPolicyContent(),
        );
      },
    ).then((_) {
      // Reset animation controller when dialog is fully closed
      if (mounted) {
        _dialogAnimationController.reset();
      }
    });
  }

  void _showTermsOfService() {
    _dialogAnimationController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return _buildPolicyDialog(
          title: RegisterLocalization.translate('terms_of_service_title', _selectedLanguage),
          content: _getTermsOfServiceContent(),
        );
      },
    ).then((_) {
      // Reset animation controller when dialog is fully closed
      if (mounted) {
        _dialogAnimationController.reset();
      }
    });
  }

  String _getPrivacyPolicyContent() {
    if (_selectedLanguage == 'en') {
      return '''
Information Collected/Privacy Rights

Handa Bata expresses their commitment to providing their users with privacy protection and security. We will only use your information for the purposes it was collected, and we will not share your personal information with any third parties without your consent.

To access our full features service, you must create an account by providing your personal information. Handa Bata will use this information to process your data and to provide you with the services requested. We may also use your information to improve our services, and we will contact you to verify your identity for security purposes. Handa Bata implements security measures to safeguard your personal data against unauthorized access and disclosure. You can access our website using the same information and update them anytime.

Third-Party Vendors

We use a variety of third-party APIs and Firebase services to provide features and functionality on our website. These third-party vendors may collect your personal information, such as your email address.

We have carefully reviewed the third-party APIs and Firebase (Firebase services) we used, and we only share your personal information with them to an extent to provide you with the necessary features and functionality of our website. Handa Bata does not sell your personal information to these third-party vendors.

Data Security

We are committed to taking your data security seriously and have implemented encryption to protect your sensitive information from data loss and attacks. Handa Bata respects your rights to security and privacy, so we limit our access to your data.

As a registered user, you are also responsible for keeping your account credentials confidential. We are not responsible for keeping your information safe from unauthorized access by individuals you know.

Use of Cookies

Cookies are small fragments of data stored within the website to be retrieved when using our services. We use cookies to improve your browsing experience and website functionality. Handa Bata only stores the necessary information to provide you with the best possible experience. We also use cookies to store how users perform in our game.

User Rights

Handa Bata respects your rights to the following:
• Creating your Account - Users have the right to create their own account and gain full access to the features of our website.
• Access to your Account and Information - Users have the right to access their account and the information provided by our website.
• Updating your Account - Users have the ability to update their account information on our website.
• Deleting your Account - Users have the ability to delete their account permanently on our website.
• Recover your Account - Users have the ability to recover their account when they forget their password.
''';
    } else {
      return '''
Impormasyong Nakolekta / Mga Karapatan sa Privacy

Pinapangako ng Handa Bata na mabigyang-proteksiyon at seguridad ang privacy ng mga gagamit nito. Ang iyong mga personal na impormasyon na makokolekta ay gagamitin lamang base sa layunin kung saan ito nauukol, at hindi ibabahagi sa anumang mga third party nang wala ang iyong pahintulot.

Upang makuha ang aming buong serbisyo, kinakailangan ninyong gumawa ng account sa pamamagitan ng pagbibigay ng iyong personal na impormasyon. Gagamitin ng Handa Bata ang iyong mga impormasyon sa pagproseso ng iyong data at ibahagi ang iyong mga kahilingan na serbisyo. Maaari rin namin gamitin ang iyong impormasyon sa pagpapabuti ng aming mga serbisyo at kami ay makikipag-ugnayan sa inyo upang patunayan ang iyong pagkakakilanlan para sa mga layuning pang-seguridad. Isinasagawa ang Handa Bata nang may hakbang pang-seguridad upang mapangalagaan ang iyong personal na data laban sa mga hindi awtorisadong pag-access. Maaari mong ma-access ang aming website gamit ang iyong impormasyon at i-update ang mga ito sa anumang oras.

Mga Third-Party na Vendor

Gumagamit kami ng iba't ibang mga third party na API Firebase na nagbibigay ng mga feature at functionality sa aming website. Maaring kolektahin ng mga third-party na vendor na ito ang iyong personal na impormasyon kagaya ng iyong email address.

Maingat naming sinusubaybayan ang mga ginamit namin na API at Firebase, at ibinahagi lamang namin sa mga nasabing third-party vendor ang iyong personal na impormasyon upang mabigay namin sa inyo ang mga feature at functionality ng website. Hindi ibebenta ng Handa Bata ang iyong personal na impormasyon sa mga nasabing third-party na vendor.

Seguridad ng Data

Nakatuon kami na pangalagaan ang seguridad ng iyong data at isinagawa namin ang encryption upang pangalagaan ang iyong sensitibong impormasyon mula sa data loss at attacks. Nirerespeto ng Handa Bata ang iyong mga karapatan sa seguridad at privacy habang tinatakda din nila ang pag-access nito sa iyong data.

Bilang rehistradong gumagamit, responsable ka rin na panatilihing kumpidensyal ang mga kredensyal ng iyong account. Hindi kami responsable na mapanatiling ligtas sa iyong impormasyon mula sa hindi awtorisadong pag-access ng mga indibidwal na kilala mo.

Paggamit ng Cookies

Ang cookies ay maliliit na piraso ng data na nakaimbak sa loob ng website na kinukuha kapag ginagamit ang aming mga serbisyo. Gumagamit kami ng cookies upang mapabuti ang iyong karanasan sa pagba-browse at sa paggamit ng aming website. Ang Handa Bata ay nag-iimbak lamang ng kinakailangang impormasyon upang mabigyan kayo ng maayos na karanasan. Gumagamit din kami ng cookies upang mag-imbak kung paano gumaganap ang mga maglalaro sa aming mga laro.

Mga Karapatan ng Gumagamit

Nirerespeto ng Handa Bata ang iyong sumusunod na karapatan:
• Paglikha ng iyong Account - May karapatan ang mga user na gumawa ng kanilang sariling account at makakuha ng buong access sa features ng aming website.
• Pag-access sa iyong Account at Impormasyon - May karapatan ang mga user na i-access ang kanilang account at ang impormasyong ibinigay ng aming website.
• Pag-update ng iyong Account - May kakayahan ang mga user na i-update ang impormasyon sa kanilang account sa aming website.
• Pagtanggal ng iyong Account - May kakayahan ang mga gumagamit na tuluyan nang tanggalin ang kanilang account sa aming website.
• Pag-recover ng iyong Account - May kakayahan ang mga user na ma-recover ang kanilang account kapag nakalimutan nila ang kanilang password.
''';
    }
  }

  String _getTermsOfServiceContent() {
    if (_selectedLanguage == 'en') {
      return '''
Eligibility

To be eligible to create an account on our website, you must be of Junior High School age, specifically between the ages of 11 and 16. Handa Bata aims to provide general information and preparedness measures on earthquakes and typhoons in the Philippines. The content on this website is intended for educational purposes only. The provided information does not intend to replace professional advice or guidance from experts in disaster preparedness.

By creating an account, you agree to our Terms of Service.

User Account and Responsibilities

To use our full feature services, you must create a user account. By creating an account, you consent to providing your credential information in our system. As a registered user, you are always responsible for keeping your account confidential. Any activities under your account will be subject to your control, and you will be responsible for them.

Intellectual Property

We own all intellectual property rights to the Service and its content, including trademarks and copyrights. You are granted the permission to use the Service for your personal, non-commercial use only. You may not reproduce, distribute, modify, transmit, display, create derivative works of, or sell any part of the Service or its content unless you have written permission from us.

Disclaimer

The educational information on this website is primarily from the public domain, specifically government agencies in the Philippines, such as the National Disaster Risk Reduction and Management Council (NDRRMC), the Philippine Institute of Volcanology and Seismology (PHIVOLCS), the Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA), and the Department of Education (DepEd). The photos, infographics, and videos used on the website are from Unsplash, Getty Images and official government sources.

We have used public domain information in good faith but do not guarantee its accuracy or completeness. While we take responsibility for validating the information we put on our website, we encourage you to read other sources, such as textbooks, scholarly articles, and government publications, to learn more about earthquakes and typhoons.

Additionally, the music tracks and sound effects we use on our website are from websites that offer royalty-free music tracks and sound effects.
''';
    } else {
      return '''
Mga Karapat-dapat

Upang maging karapat-dapat na gumawa ng account sa aming website, dapat ay nasa edad ka ng Junior High School, partikular sa pagitan ng edad na 11 at 16. Ang Handa Bata ay naglalayong magbigay ng pangkalahatang impormasyon at mga hakbang sa paghahanda sa mga lindol at bagyo sa Pilipinas. Ang nilalaman ng website na ito ay para sa layuning pang-edukasyon lamang. Ang ibinigay na impormasyon ay hindi naglalayong palitan ang propesyonal na payo o gabay mula sa mga espesyalista sa pamamahala ng eksperto sa paghahanda sa sakuna.

Sa pamamagitan ng paggawa ng isang account, sumasang-ayon ka sa aming Mga Tuntunin ng Serbisyo.

Account ng User at Responsabilidad

Upang magamit ang aming buong serbisyo, dapat kang gumawa ng isang user account. Sa pamamagitan ng paggawa ng account, sumasang-ayon ka na ibigay ang iyong kredensyal na impormasyon sa aming system.

Bilang isang rehistradong user, palagi kang responsable sa pagpapanatili na kumpidensyal ang iyong account. Ang anumang aktibidad sa ilalim ng iyong account ay sumasailalim sa iyong kontrol, at ikaw ang mananagot para sa mga ito.

Intelektwal na Pag-aari

Kami ay nagmamay-ari ng lahat ng mga karapatan sa intelektwal na pag-aari sa Serbisyo at sa nilalaman nito, kabilang ang mga trademark at copyright. Binibigyan ka ng pahintulot na gamitin ang Serbisyo para sa iyong personal, hindi pangkomersyal na paggamit lamang. Hindi mo maaaring kopyahin, ipamahagi, baguhin, ipadala, ipakita, lumikha ng mga hinangong gawa ng, o ibenta ang anumang bahagi ng Serbisyo o nilalaman nito maliban kung mayroon kang nakasulat na pahintulot galing sa amin.

Disclaimer

Ang impormasyong pang-edukasyon sa website na ito ay pangunahing mula sa mga public domain, partikular sa mga ahensya ng gobyerno sa Pilipinas, tulad ng National Disaster Risk Reduction and Management Council (NDRRMC), Philippine Institute of Volcanology and Seismology (PHIVOLCS), Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA), at Department of Education (DepEd). Ang mga larawan, infographics, at bidyo na ginamit sa website ay mula sa Unsplash, Getty Images at mga opisyal na mapagkukunan sa pamahalaan.

Gumamit kami ng impormasyon mula sa public domain nang may magandang hangarin, ngunit hindi namin sinisigurado ang kawastuhan o pagkakumpleto nito. Bagama't tinitiyak namin na wasto ang impormasyong inilalagay namin sa aming website, hinihikayat namin kayo na magbasa ng iba pang mga mapagkukunan, tulad ng mga aklat-aralin, mga artikulong pang-akademiko, at mga publikasyon ng pamahalaan, para sa karagdagang kaalaman tungkol sa mga lindol at bagyo.

Bukod dito, ang mga music track at sound effects na ginagamit namin sa aming website ay mula sa mga website na nagbibigay ng royalty-free na mga music tracks at sound effects.
''';
    }
  }

  Widget _buildPolicyDialog({required String title, required String content}) {
    return WillPopScope(
      onWillPop: () async {
        await _handleDialogClose();
        return false;
      },
      child: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          final dialogWidth = ResponsiveUtils.valueByDevice<double>(
            context: context,
            mobile: MediaQuery.of(context).size.width * 0.9,
            tablet: 450,
            desktop: 500,
          );

          final titleFontSize = ResponsiveUtils.valueByDevice<double>(
            context: context,
            mobile: 32,
            tablet: 36,
            desktop: 32,
          );

          final contentPadding = ResponsiveUtils.valueByDevice<double>(
            context: context,
            mobile: 16,
            tablet: 20,
            desktop: 24,
          );

          final screenWidth = MediaQuery.of(context).size.width;
          final bool isMobileSmall = screenWidth <= 375;
          final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375;
          final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
            child: SlideTransition(
              position: _dialogSlideAnimation,
              child: Dialog(
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.zero,
                ),
                backgroundColor: Colors.white,
                child: Container(
                  width: dialogWidth,
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                title,
                                style: GoogleFonts.vt323(
                                  fontSize: isMobileSmall ? 24 :
                                           isMobileLarge ? 28 :
                                           isMobileExtraLarge ? 32 : titleFontSize,
                                  color: const Color(0xFF351B61),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: contentPadding,
                              vertical: contentPadding * 0.5,
                            ),
                            child: _buildFormattedContent(content),
                          ),
                        ),
                      ),
                      Container(
                        color: const Color(0xFF241242),
                        padding: EdgeInsets.all(contentPadding * 0.75),
                        child: Center(
                          child: TextButton(
                            onPressed: _handleDialogClose,
                            child: Text(
                              'OK',
                              style: GoogleFonts.vt323(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final List<String> paragraphs = content.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) {
          return const SizedBox(height: 8);
        }

        // Handle bullet points
        if (paragraph.trim().startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    paragraph.substring(1).trim(),
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Handle section headings (standalone words without periods)
        if (!paragraph.contains('.') && !paragraph.contains(':')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              paragraph,
              style: GoogleFonts.rubik(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF351B61),
              ),
            ),
          );
        }

        // Handle regular paragraphs
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph,
            style: GoogleFonts.rubik(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(selectedLanguage: _selectedLanguage),
          ),
        );
        return false;
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          breakpoints: AppBreakpoints.screenBreakpoints,
          builder: (context, sizingInformation) {
            // Get responsive dimensions
            final handaBataFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 55,
              tablet: 60,
              desktop: 100,
            );

            final mobileFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 45,
              tablet: 55,
              desktop: 90,
            );

            final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 40,
              tablet: 60,
            );

            return Stack(
              children: [
                // Background
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                
                // Main Content
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Language Selector Container
                      Container(
                        padding: EdgeInsets.only(
                          top: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 40.0,
                            tablet: 50.0,
                            desktop: 60.0,
                          ),
                          right: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 25.0,
                            tablet: 30.0,
                            desktop: 35.0,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        child: _buildLanguageSelector(),
                      ),
                      
                      // Main Form Content
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 20, // Reduced from 40 since we have the language selector above
                            ),
                            child: Column(
                              children: [
                                // Title Section
                                _buildTitleSection(handaBataFontSize, mobileFontSize),
                                
                                // Form Section
                                _buildForm(sizingInformation),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading Overlay
                if (_isRegistering)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(double handaBataFontSize, double mobileFontSize) {
    return Column(
      children: [
        TextWithShadow(text: 'Handa Bata', fontSize: handaBataFontSize),
        Transform.translate(
          offset: const Offset(0, -20.0),
          child: Column(
            children: [
              TextWithShadow(text: 'Mobile', fontSize: mobileFontSize),
              const SizedBox(height: 0),
              Text(
                RegisterLocalization.translate('title', _selectedLanguage),
                style: GoogleFonts.vt323(
                  fontSize: 30,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 3.0),
                      blurRadius: 0.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(SizingInformation sizingInformation) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          _buildInputFields(),
          const SizedBox(height: 20),
          _buildButtons(sizingInformation),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('username', _selectedLanguage),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) => validateUsername(value, _selectedLanguage),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('email', _selectedLanguage)
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) => validateEmail(value, _selectedLanguage),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _birthdayController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('birthday', _selectedLanguage)
          ),
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          onTap: () => selectDate(context, _birthdayController),
          validator: (value) => validateBirthday(value, _selectedLanguage),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('password', _selectedLanguage)
          ).copyWith(
            suffixIcon: IconButton(
              icon: SvgPicture.string(
                _obscurePassword ? '''
                  <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                    <path d="M8 6h8v2H8V6zm-4 4V8h4v2H4zm-2 2v-2h2v2H2zm0 2v-2H0v2h2zm2 2H2v-2h2v2zm4 2H4v-2h4v2zm8 0v2H8v-2h8zm4-2v2h-4v-2h4zm2-2v2h-2v-2h2zm0-2h2v2h-2v-2zm-2-2h2v2h-2v-2zm0 0V8h-4v2h4zm-10 1h4v4h-4v-4z" fill="currentColor"/>
                  </svg>
                ''' : '''
                  <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                    <path d="M0 7h2v2H0V7zm4 4H2V9h2v2zm4 2v-2H4v2H2v2h2v-2h4zm8 0H8v2H6v2h2v-2h8v2h2v-2h-2v-2zm4-2h-4v2h4v2h2v-2h-2v-2zm2-2v2h-2V9h2zm0 0V7h2v2h-2z" fill="currentColor"/>
                  </svg>
                ''',
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: const TextStyle(color: Colors.white),
          obscureText: _obscurePassword,
          validator: (value) => passwordValidator(value, _isPasswordLengthValid, _hasUppercase, _hasNumber, _hasSymbol, _selectedLanguage),
          onChanged: (value) {
            setState(() {
              _isPasswordFieldTouched = true;
            });
            validatePassword(value, (isPasswordLengthValid, hasUppercase, hasNumber, hasSymbol) {
              setState(() {
                _isPasswordLengthValid = isPasswordLengthValid;
                _hasUppercase = hasUppercase;
                _hasNumber = hasNumber;
                _hasSymbol = hasSymbol;
              });
            });
          },
        ),
        if (_isPasswordFieldTouched) ...[
          const SizedBox(height: 10),
          buildPasswordRequirement(
            text: RegisterLocalization.translate('password_requirement_1', _selectedLanguage),
            isValid: _isPasswordLengthValid,
          ),
          buildPasswordRequirement(
            text: RegisterLocalization.translate('password_requirement_2', _selectedLanguage),
            isValid: _hasUppercase,
          ),
          buildPasswordRequirement(
            text: RegisterLocalization.translate('password_requirement_3', _selectedLanguage),
            isValid: _hasNumber,
          ),
          buildPasswordRequirement(
            text: RegisterLocalization.translate('password_requirement_4', _selectedLanguage),
            isValid: _hasSymbol,
          ),
        ],
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('confirm_password', _selectedLanguage)
          ).copyWith(
            suffixIcon: IconButton(
              icon: SvgPicture.string(
                _obscureConfirmPassword ? '''
                  <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                    <path d="M8 6h8v2H8V6zm-4 4V8h4v2H4zm-2 2v-2h2v2H2zm0 2v-2H0v2h2zm2 2H2v-2h2v2zm4 2H4v-2h4v2zm8 0v2H8v-2h8zm4-2v2h-4v-2h4zm2-2v2h-2v-2h2zm0-2h2v2h-2v-2zm-2-2h2v2h-2v-2zm0 0V8h-4v2h4zm-10 1h4v4h-4v-4z" fill="currentColor"/>
                  </svg>
                ''' : '''
                  <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                    <path d="M0 7h2v2H0V7zm4 4H2V9h2v2zm4 2v-2H4v2H2v2h2v-2h4zm8 0H8v2H6v2h2v-2h8v2h2v-2h-2v-2zm4-2h-4v2h4v2h2v-2h-2v-2zm2-2v2h-2V9h2zm0 0V7h2v2h-2z" fill="currentColor"/>
                  </svg>
                ''',
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          style: const TextStyle(color: Colors.white),
          obscureText: _obscureConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return _selectedLanguage == 'en' ? 'Please confirm your password.' : 'I-type muli ang iyong password.';
            }
            if (value != _passwordController.text) {
              return _selectedLanguage == 'en' ? 'Passwords do not match.' : 'Hindi magkatugma ang mga password.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _isPrivacyPolicyAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isPrivacyPolicyAccepted = value!;
                  if (_isPrivacyPolicyAccepted) {
                    _showPrivacyPolicyError = false;
                  }
                });
              },
              fillColor: WidgetStateProperty.all(Colors.white),
              checkColor: Colors.black,
            ),
            Flexible(
              child: Wrap(
                children: [
                  Text(
                    RegisterLocalization.translate('privacy_policy_start', _selectedLanguage),
                    style: const TextStyle(color: Colors.white),
                  ),
                  InkWell(
                    onTap: _showPrivacyPolicy,
                    child: Text(
                      RegisterLocalization.translate('privacy_policy_link', _selectedLanguage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    RegisterLocalization.translate('privacy_policy_middle', _selectedLanguage),
                    style: const TextStyle(color: Colors.white),
                  ),
                  InkWell(
                    onTap: _showTermsOfService,
                    child: Text(
                      RegisterLocalization.translate('terms_of_service_link', _selectedLanguage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showPrivacyPolicyError)
          PrivacyPolicyError(showError: _showPrivacyPolicyError, selectedLanguage: _selectedLanguage),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final iconSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 32.0,
          tablet: 36.0,
          desktop: 40.0,
        );
        
        final menuTextSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 18.0,
        );

        return PopupMenuButton<String>(
          icon: SvgPicture.asset(
            'assets/icons/language_switcher.svg',
            width: iconSize,
            height: iconSize,
            color: Colors.white,
          ),
          padding: EdgeInsets.zero,
          offset: const Offset(0, 30),
          color: const Color(0xFF241242),
          onSelected: (String newValue) {
            _changeLanguage(newValue);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedLanguage == 'en' ? 'English' : 'Ingles',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'en') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'fil',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filipino',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'fil') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildButtons(SizingInformation sizingInformation) {
    final buttonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.8,
      tablet: 400, // Fixed width on tablet
    );

    // final buttonHeight = ResponsiveUtils.valueByDevice<double>(
    //   context: context,
    //   mobile: 45,
    //   tablet: 55,
    // );

    return Column(
      children: [
        Button3D(
          width: buttonWidth,
          backgroundColor: const Color(0xFF351B61),
          borderColor: const Color(0xFF1A0D30),  // Darker purple for 3D effect
          onPressed: _register,
          child: Text(
            RegisterLocalization.translate('register_button', _selectedLanguage),
            style: GoogleFonts.vt323(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Button3D(
          width: buttonWidth,
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFCCCCCC),  // Light gray for white button
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(selectedLanguage: _selectedLanguage),
              ),
            );
          },
          child: Text(
            RegisterLocalization.translate('login_instead', _selectedLanguage),
            style: GoogleFonts.vt323(
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}