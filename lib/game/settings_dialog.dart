import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package

class SettingsDialog extends StatefulWidget {
  final bool isTextToSpeechEnabled;
  final ValueChanged<bool> onTextToSpeechChanged;
  final String selectedVoice;
  final ValueChanged<String?> onVoiceChanged;
  final double speed;
  final ValueChanged<double> onSpeedChanged;
  final double ttsVolume;
  final ValueChanged<double> onTtsVolumeChanged;
  final List<dynamic> availableVoices; // Add this line

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
    required this.availableVoices, // Add this line
  });

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> {
  late bool _isTextToSpeechEnabled;
  late String _selectedVoice;
  late double _visualSpeed;
  late double _visualVolume;

  @override
  void initState() {
    super.initState();
    _isTextToSpeechEnabled = widget.isTextToSpeechEnabled;
    _selectedVoice = widget.selectedVoice;
    _visualSpeed = widget.speed + 0.5; // Convert actual speed to visual speed
    _visualVolume = widget.ttsVolume * 100; // Convert actual volume to visual volume
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF351B61),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: Colors.black),
      ),
      title: const Text('Settings', style: TextStyle(color: Colors.white)),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog box
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Text-to-Speech', style: GoogleFonts.vt323(fontSize: 28, color: Colors.white)),
                Switch(
                  value: _isTextToSpeechEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isTextToSpeechEnabled = value;
                    });
                    widget.onTextToSpeechChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Voice', style: GoogleFonts.vt323(fontSize: 28, color: Colors.white)),
            Container(
              width: double.infinity, // Make the dropdown button take full width
              child: DropdownButton<String>(
                value: _selectedVoice,
                dropdownColor: const Color(0xFF241242),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVoice = newValue!;
                  });
                  widget.onVoiceChanged(newValue);
                },
                items: widget.availableVoices
                    .map<DropdownMenuItem<String>>((dynamic voice) {
                  String displayName;
                  if (voice['name'] == 'en-us-x-tpd-local') {
                    displayName = 'John';
                  } else if (voice['name'] == 'en-us-x-log-local') {
                    displayName = 'Jane';
                  } else {
                    displayName = voice['name'];
                  }
                  return DropdownMenuItem<String>(
                    value: voice['name'],
                    child: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20)), // Increase font size
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Speed', style: GoogleFonts.vt323(fontSize: 28, color: Colors.white)),
                Text('${_visualSpeed.toStringAsFixed(2)}', style: GoogleFonts.vt323(fontSize: 24, color: Colors.white)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.0, // Make the slider bar thicker
              ),
              child: Slider(
                value: _visualSpeed,
                onChanged: (double value) {
                  setState(() {
                    _visualSpeed = value;
                  });
                  widget.onSpeedChanged(value - 0.5); // Convert visual speed to actual speed
                },
                min: 0.0,
                max: 2.0,
                divisions: 8,
                activeColor: const Color(0xFFF1B33A),
                inactiveColor: const Color(0xFF241242),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TTS Volume', style: GoogleFonts.vt323(fontSize: 28, color: Colors.white)),
                Text('${_visualVolume.round()}', style: GoogleFonts.vt323(fontSize: 24, color: Colors.white)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.0, // Make the slider bar thicker
              ),
              child: Slider(
                value: _visualVolume,
                onChanged: (double value) {
                  setState(() {
                    _visualVolume = value;
                  });
                  widget.onTtsVolumeChanged(value / 100); // Convert visual volume to actual volume
                },
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: const Color(0xFFF1B33A),
                inactiveColor: const Color(0xFF241242),
              ),
            ),
            const SizedBox(height: 16), // Add larger top margin
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, // Text color
                  backgroundColor: const Color(0xFFF1B33A), // Background color
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                  ),
                  side: const BorderSide(
                    color: Color(0xFF8B5A00), // Much darker border color
                    width: 4, // Thicker border width
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () {
                  // Handle quit game action
                },
                child: const Text('Quit Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}