class TutorialLocalization {
  static final Map<String, Map<String, Map<String, Map<String, String>>>> _localizedValues = {
    'en': {
      'adventure': {
        'multiple_choice': {
          'title': 'Multiple Choice',
          'description': 'Read the question carefully and choose the correct answer. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
        },
        'identification': {
          'title': 'Identification',
          'description': 'Select a letter one at a time to form an answer. Your answer will be checked instantly once you fill in the last tile. Answer carefully to prevent Kladis and Kloud\'s health bar from going down.',
        },
        'matching_type': {
          'title': 'Matching Type',
          'description': 'Select a number on the left and an item on the right to create a pair. Your answers will be checked after you pair the last number to an item. Kladis and Kloud\'s health bars will decrease for every incorrect pair, so choose wisely.',
        },
        'fill_in_blanks': {
          'title': 'Fill in the Blanks',
          'description': 'Drag an option into the blank to complete the sentence. Kladis and Kloud\'s health bars will decrease for every incorrect answer, so answer carefully.',
        },
      },
      'arcade': {
        'multiple_choice': {
          'title': 'Multiple Choice',
          'description': 'Read the question carefully and choose the correct answer to decrease the time on your stopwatch. If you choose an incorrect answer, time will be added to your stopwatch.',
        },
        'identification': {
          'title': 'Identification',
          'description': 'Select a letter one at a time to form an answer. Your answer will be checked instantly once you fill in the last tile. Answer carefully to prevent your stopwatch from increasing in time.',
        },
        'matching_type': {
          'title': 'Matching Type',
          'description': 'Select a number on the left and an item on the right to create a pair. Your answers will be checked after you pair the last number to an item. Time will be added to your stopwatch for every incorrect pair, so choose wisely.',
        },
        'fill_in_blanks': {
          'title': 'Fill in the Blanks',
          'description': 'Drag an option into the blank to complete the sentence. Time will be added to your stopwatch for every incorrect answer, so answer carefully.',
        },
      },
      'ui': {
        'buttons': {
          'next': 'Next',
          'back': 'Back',
          'start_game': 'Start Game',
        },
        'headers': {
          'how_to_play': 'How to Play',
        },
      },
    },
    'fil': {
      'adventure': {
        'multiple_choice': {
          'title': 'Multiple Choice',
          'description': 'Basahing mabuti ang tanong at piliin ang tamang sagot. Iwasan ang mga maling sagot, o mababawasan ang health bar nina Kladis at Kloud.',
        },
        'identification': {
          'title': 'Identification',
          'description': 'Pumili ng paisa-isang letra upang makabuo ng sagot. Machecheck agad ang iyong sagot sa sandaling mapunan ang huling tile. Sumagot nang mabuti para maiwasan ang pagbaba ng health bar nina Kladis at Kloud.',
        },
        'matching_type': {
          'title': 'Matching Type',
          'description': 'Pumili ng numero sa kaliwa at isang aytem sa kanan para gumawa ng pares. Ang iyong mga sagot ay susuriin pagkatapos mong ipares ang huling numero sa isang aytem. Mababawasan ang health bar nina Kladis at Kloud kada maling pares, kaya mamili nang mabuti.',
        },
        'fill_in_blanks': {
          'title': 'Fill in the Blanks',
          'description': 'Mag-drag ng opsyon sa blangko upang makumpleto ang pangungusap. Mababawasan ang health bar nina Kladis at Kloud kada maling sagot, kaya magsagot nang mabuti.',
        },
      },
      'arcade': {
        'multiple_choice': {
          'title': 'Multiple Choice',
          'description': 'Basahing mabuti ang tanong at piliin ang tamang sagot para mapababa ang oras sa iyong stopwatch. Kung pumili ka ng maling sagot, madadagdagan ng oras ang iyong stopwatch.',
        },
        'identification': {
          'title': 'Identification',
          'description': 'Pumili ng paisa-isang letra upang makabuo ng sagot. Machecheck agad ang iyong sagot sa sandaling mapunan ang huling tile. Sumagot nang mabuti para maiwasan ang pagtaas ng oras ng iyong stopwatch.',
        },
        'matching_type': {
          'title': 'Matching Type',
          'description': 'Pumili ng numero sa kaliwa at isang aytem sa kanan para gumawa ng pares. Ang iyong mga sagot ay susuriin pagkatapos mong ipares ang huling numero sa isang aytem. Madadagdagan ng oras ang iyong stopwatch kada maling pares, kaya mamili nang mabuti.',
        },
        'fill_in_blanks': {
          'title': 'Fill in the Blanks',
          'description': 'Mag-drag ng opsyon sa blangko upang makumpleto ang pangungusap. Madadagdagan ng oras ang iyong stopwatch kada maling sagot, kaya magsagot nang mabuti.',
        },
      },
      'ui': {
        'buttons': {
          'next': 'Susunod',
          'back': 'Bumalik',
          'start_game': 'Simulan ang Laro',
        },
        'headers': {
          'how_to_play': 'Paano Laruin Ang',
        },
      },
    },
  };

  static String getTitle(String mode, String type, String language) {
    return _localizedValues[language]?[mode]?[type]?['title'] ?? 'Unknown Type';
  }

  static String getDescription(String mode, String type, String language) {
    return _localizedValues[language]?[mode]?[type]?['description'] ?? 'No description available.';
  }

  static String getUIText(String section, String key, String language) {
    return _localizedValues[language]?['ui']?[section]?[key] ?? key;
  }
} 