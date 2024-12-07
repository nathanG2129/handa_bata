import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import Flutter TTS package
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/localization/settings/localization.dart';

class SettingsDialog extends StatefulWidget {
  final bool isTextToSpeechEnabled;
  final ValueChanged<bool> onTextToSpeechChanged;
  final String selectedVoice;
  final ValueChanged<String?> onVoiceChanged;
  final double speed;
  final ValueChanged<double> onSpeedChanged;
  final double ttsVolume;
  final ValueChanged<double> onTtsVolumeChanged;
  final List<dynamic> availableVoices;
  final FlutterTts flutterTts; // Add this line
  final double musicVolume; // Add this line
  final ValueChanged<double> onMusicVolumeChanged; // Add this line
  final double sfxVolume; // Add this line
  final ValueChanged<double> onSfxVolumeChanged; // Add this line
  final Future<void> Function() onQuitGame;
  final bool isLastQuestion;
  final String language;

  const SettingsDialog({
    super.key,
    required this.isTextToSpeechEnabled,
    required this.onTextToSpeechChanged,
    required this.selectedVoice,
    required this.onVoiceChanged,
    required this.speed,
    required this.onSpeedChanged,
    required this.ttsVolume,
    required this.onTtsVolumeChanged,
    required this.availableVoices,
    required this.flutterTts, // Add this line
    required this.musicVolume, // Add this line
    required this.onMusicVolumeChanged, // Add this line
    required this.sfxVolume, // Add this line
    required this.onSfxVolumeChanged, // Add this line
    required this.onQuitGame,
    required this.isLastQuestion,
    required this.language,
  });

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> with TickerProviderStateMixin {
  late bool _isTextToSpeechEnabled;
  late String _selectedVoice;
  late double _visualSpeed;
  late double _visualVolume;
  late double _visualMusicVolume; // Add this line
  late double _visualSfxVolume; // Add this line

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _isTextToSpeechEnabled = widget.isTextToSpeechEnabled;
    _selectedVoice = widget.selectedVoice;
    _visualSpeed = (widget.speed * 2); // Convert actual speed to visual speed
    _visualVolume = widget.ttsVolume * 100; // Convert actual volume to visual volume
    _visualMusicVolume = widget.musicVolume * 100; // Convert actual volume to visual volume
    _visualSfxVolume = widget.sfxVolume * 100; // Convert actual volume to visual volume

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTextToSpeechEnabled', _isTextToSpeechEnabled);
    await prefs.setString('selectedVoice', _selectedVoice);
    await prefs.setDouble('speed', _visualSpeed / 2); // Save actual speed
    await prefs.setDouble('ttsVolume', _visualVolume / 100); // Save actual volume
    await prefs.setDouble('musicVolume', _visualMusicVolume / 100); // Save actual volume
    await prefs.setDouble('sfxVolume', _visualSfxVolume / 100); // Save actual volume
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _visualSfxVolume = (prefs.getDouble('sfxVolume') ?? 1.0) * 100;
    });
  }

  Future<void> _showQuitConfirmationDialog() async {
    final bool? shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: AlertDialog(
            backgroundColor: const Color(0xFF351B61),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
              side: const BorderSide(color: Colors.black),
            ),
            title: Text(
              SettingsLocalization.translate('quitGame', widget.language),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            content: Text(
              SettingsLocalization.translate('quitMessage', widget.language),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  SettingsLocalization.translate('back', widget.language),
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              Button3D(
                backgroundColor: const Color(0xFFF1B33A),
                borderColor: const Color(0xFF8B5A00),
                width: 120,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  SettingsLocalization.translate('quitGame', widget.language),
                  style: GoogleFonts.vt323(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldQuit == true) {
      if (mounted) {
        Navigator.of(context).pop();
        await widget.onQuitGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double dialogWidth = isTablet ? 450 : 300;
    final double maxDialogHeight = screenSize.height * 0.8; // 80% of screen height

    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: GestureDetector(
        onTap: _closeDialog,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevents tap from propagating
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: dialogWidth,
                      constraints: BoxConstraints(
                        maxHeight: maxDialogHeight,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40.0 : 20.0,
                        vertical: 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF351B61),
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                SettingsLocalization.translate('settings', widget.language),
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: isTablet ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                          // Content - Now in Expanded with SingleChildScrollView
                          Flexible(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24.0 : 20.0,
                                  vertical: isTablet ? 12.0 : 10.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          SettingsLocalization.translate('musicVolume', widget.language),
                                          style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                        ),
                                        Text(
                                          '${_visualMusicVolume.round()}',
                                          style: GoogleFonts.vt323(fontSize: 20, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 8.0, // Make the slider bar thicker
                                      ),
                                      child: Slider(
                                        value: _visualMusicVolume,
                                        onChanged: (double value) {
                                          setState(() {
                                            _visualMusicVolume = value;
                                          });
                                          widget.onMusicVolumeChanged(value / 100); // Convert visual volume to actual volume
                                          _saveSettings(); // Save settings
                                        },
                                        min: 0,
                                        max: 100,
                                        divisions: 100,
                                        activeColor: const Color(0xFFF1B33A),
                                        inactiveColor: const Color(0xFF241242),
                                      ),
                                    ),
                                    const SizedBox(height: 16), // Add larger top margin
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          SettingsLocalization.translate('sfxVolume', widget.language),
                                          style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                        ),
                                        Text(
                                          '${_visualSfxVolume.round()}',
                                          style: GoogleFonts.vt323(fontSize: 20, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 8.0, // Make the slider bar thicker
                                      ),
                                      child: Slider(
                                        value: _visualSfxVolume,
                                        onChanged: (double value) {
                                          setState(() {
                                            _visualSfxVolume = value;
                                          });
                                          widget.onSfxVolumeChanged(value / 100); // Convert visual volume to actual volume
                                          _saveSettings(); // Save settings
                                        },
                                        min: 0,
                                        max: 100,
                                        divisions: 100,
                                        activeColor: const Color(0xFFF1B33A),
                                        inactiveColor: const Color(0xFF241242),
                                      ),
                                    ),
                                    const SizedBox(height: 16), // Add larger top margin
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          SettingsLocalization.translate('textToSpeech', widget.language),
                                          style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                        ),
                                        Switch(
                                          value: _isTextToSpeechEnabled,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _isTextToSpeechEnabled = value;
                                            });
                                            widget.onTextToSpeechChanged(value);
                                            if (!value) {
                                              widget.flutterTts.stop(); // Stop TTS immediately when toggled off
                                            }
                                            _saveSettings(); // Save settings
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16), // Add spacing before Voice section
                                    const SizedBox(height: 8),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: Text(
                                        SettingsLocalization.translate('language', widget.language),
                                        style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF241242),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: ButtonTheme(
                                            alignedDropdown: true, // This helps align the dropdown items
                                            child: DropdownButton<String>(
                                              value: _selectedVoice,
                                              isExpanded: true, // Make dropdown take full width
                                              icon: const Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white,
                                              ),
                                              dropdownColor: const Color(0xFF241242),
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              onChanged: _isTextToSpeechEnabled 
                                                ? (String? newValue) {
                                                    setState(() {
                                                      _selectedVoice = newValue!;
                                                    });
                                                    widget.onVoiceChanged(newValue);
                                                    _saveSettings();
                                                  }
                                                : null,
                                              items: widget.availableVoices
                                                  .map<DropdownMenuItem<String>>((dynamic voice) {
                                                String displayName;
                                                if (voice['name'] == 'en-us-x-tpd-local') {
                                                  displayName = 'John';
                                                } else if (voice['name'] == 'en-us-x-log-local') {
                                                  displayName = 'Jane';
                                                } else if (voice['name'] == 'fil-ph-x-fie-local') {
                                                  displayName = 'Juan';
                                                } else if (voice['name'] == 'fil-PH-language') {
                                                  displayName = 'Maria';
                                                } else {
                                                  displayName = voice['name'];
                                                }
                                                return DropdownMenuItem<String>(
                                                  value: voice['name'],
                                                  child: Text(
                                                    displayName,
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            SettingsLocalization.translate('speed', widget.language),
                                            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                          ),
                                          Text(
                                            _visualSpeed.toStringAsFixed(2), 
                                            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 8.0,
                                        ),
                                        child: Slider(
                                          value: _visualSpeed,
                                          onChanged: _isTextToSpeechEnabled 
                                            ? (double value) {
                                                setState(() {
                                                  _visualSpeed = value;
                                                });
                                                widget.onSpeedChanged(value / 2);
                                                _saveSettings();
                                              }
                                            : null, // Disable slider when TTS is off
                                          min: 0.0,
                                          max: 2.0,
                                          divisions: 8,
                                          activeColor: const Color(0xFFF1B33A),
                                          inactiveColor: const Color(0xFF241242),
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            SettingsLocalization.translate('ttsVolume', widget.language),
                                            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)
                                          ),
                                          Text(
                                            '${_visualVolume.round()}', 
                                            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Opacity(
                                      opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 8.0,
                                        ),
                                        child: Slider(
                                          value: _visualVolume,
                                          onChanged: _isTextToSpeechEnabled 
                                            ? (double value) {
                                                setState(() {
                                                  _visualVolume = value;
                                                });
                                                widget.onTtsVolumeChanged(value / 100);
                                                _saveSettings();
                                              }
                                            : null, // Disable slider when TTS is off
                                          min: 0,
                                          max: 100,
                                          divisions: 100,
                                          activeColor: const Color(0xFFF1B33A),
                                          inactiveColor: const Color(0xFF241242),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16), // Add larger top margin
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Actions - Always at bottom
                          Container(
                            width: double.infinity,
                            color: const Color(0xFF241242),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _closeDialog,
                                  child: Text(
                                    SettingsLocalization.translate('back', widget.language),
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Opacity(
                                  opacity: widget.isLastQuestion ? 0.5 : 1.0,
                                  child: Button3D(
                                    backgroundColor: const Color(0xFFF1B33A),
                                    borderColor: const Color(0xFF8B5A00),
                                    width: 120,
                                    onPressed: () {
                                      if (widget.isLastQuestion) return;
                                      _showQuitConfirmationDialog();
                                    },
                                    child: Text(
                                      SettingsLocalization.translate('quitGame', widget.language),
                                      style: GoogleFonts.vt323(
                                        color: Colors.black,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}