import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import Flutter TTS package
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:handabatamae/widgets/buttons/button_3d.dart';

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

  @override
  Widget build(BuildContext context) {
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
                  child: AlertDialog(
                    backgroundColor: const Color(0xFF351B61),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                      side: const BorderSide(color: Colors.black),
                    ),
                    title: Center(
                      child: Text(
                        'Settings', 
                        style: GoogleFonts.vt323(
                          color: Colors.white,
                          fontSize: 24,
                        )
                      ),
                    ),
                    content: SingleChildScrollView( // Wrap the content in SingleChildScrollView
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog box
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Music Volume', style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                                Text('${_visualMusicVolume.round()}', style: GoogleFonts.vt323(fontSize: 16, color: Colors.white)),
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
                                Text('SFX Volume', style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                                Text('${_visualSfxVolume.round()}', style: GoogleFonts.vt323(fontSize: 16, color: Colors.white)),
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
                                Text('Text-to-Speech', 
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
                              child: Text('Voice', style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                            ),
                            Opacity(
                              opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                              child: SizedBox(
                                width: double.infinity,
                                child: DropdownButton<String>(
                                  value: _selectedVoice,
                                  dropdownColor: const Color(0xFF241242),
                                  onChanged: _isTextToSpeechEnabled 
                                    ? (String? newValue) {
                                        setState(() {
                                          _selectedVoice = newValue!;
                                        });
                                        widget.onVoiceChanged(newValue);
                                        _saveSettings();
                                      }
                                    : null, // Disable dropdown when TTS is off
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
                                      child: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16)), // Increase font size
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _isTextToSpeechEnabled ? 1.0 : 0.5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Speed', style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                                  Text('${_visualSpeed.toStringAsFixed(2)}', 
                                    style: GoogleFonts.vt323(fontSize: 16, color: Colors.white)),
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
                                  Text('TTS Volume', style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                                  Text('${_visualVolume.round()}', 
                                    style: GoogleFonts.vt323(fontSize: 16, color: Colors.white)),
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
                            Center(
                              child: Button3D(
                                backgroundColor: const Color(0xFFF1B33A),
                                borderColor: const Color(0xFF8B5A00),
                                width: 200, // Set a fixed width for the button
                                onPressed: () async {
                                  print('🎮 Quit Game button pressed');
                                  Navigator.of(context).pop();
                                  print('🎮 Dialog closed, calling onQuitGame');
                                  try {
                                    await widget.onQuitGame();
                                    print('🎮 onQuitGame completed successfully');
                                  } catch (e) {
                                    print('❌ Error in onQuitGame: $e');
                                  }
                                },
                                child: Text(
                                  'Quit Game',
                                  style: GoogleFonts.rubik(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
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
      ),
    );
  }
}