Map<String, String> getCategoryText(String categoryName, String selectedLanguage) {
  if (categoryName.contains('Quake')) {
    return {
      'name': 'Shake',
      'description': selectedLanguage == 'fil'
          ? 'Patunayan ang iyong lakas ng loob laban sa makapangyarihang pagyanig ng lupa!'
          : 'Prove your courage against the earth\'s mighty tremors!',
    };
  } else if (categoryName.contains('Storm')) {
    return {
      'name': 'Rumble', 
      'description': selectedLanguage == 'fil'
          ? 'Subukin ang iyong katapangan laban sa galit ng rumaragasang bagyo!'
          : 'Challenge your bravery against the fury of a raging typhoon!',
    };
  } else if (categoryName.contains('Volcano')) {
    return {
      'name': 'Inferno',
      'description': selectedLanguage == 'fil'
          ? 'Harapin ang matinding init ng bulkang nagbabaga!'
          : 'Face the intense heat of an erupting volcano!',
    };
  } else if (categoryName.contains('Drought')) {
    return {
      'name': 'Scorch',
      'description': selectedLanguage == 'fil'
          ? 'Tiisin ang init ng nakakapasong tagtuyot!'
          : 'Endure the scorching heat of a devastating drought!',
    };
  } else if (categoryName.contains('Flood')) {
    return {
      'name': 'Deluge',
      'description': selectedLanguage == 'fil'
          ? 'Labanan ang rumaragasang baha!'
          : 'Battle against the surging floodwaters!',
    };
  } else if (categoryName.contains('Tsunami')) {
    return {
      'name': 'Surge',
      'description': selectedLanguage == 'fil'
          ? 'Makipagsapalaran sa napakalaking alon ng tsunami!'
          : 'Brave the massive waves of a tsunami!',
    };
  } else {
    return {
      'name': categoryName,
      'description': '',
    };
  }
} 