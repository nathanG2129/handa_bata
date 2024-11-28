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
          ? 'Ipakita ang iyong tapang laban sa matinding pagputok ng bulkan!'
          : 'Demonstrate your valor against the fierce volcanic eruption!',
    };
  } else if (categoryName.contains('Drought')) {
    return {
      'name': 'Scorch',
      'description': selectedLanguage == 'fil'
          ? 'Subukan ang iyong katatagan laban sa walang tigil na init ng tagtuyot!'
          : 'Test your resilience against the relentless heat of drought!',
    };
  } else if (categoryName.contains('Flood')) {
    return {
      'name': 'Deluge',
      'description': selectedLanguage == 'fil'
          ? 'Ipakita ang iyong lakas laban sa mapanirang puwersa ng baha!'
          : 'Show your strength against the devastating force of floods!',
    };
  } else if (categoryName.contains('Tsunami')) {
    return {
      'name': 'Surge',
      'description': selectedLanguage == 'fil'
          ? 'Patunayan ang iyong kagitingan laban sa napakalaking lakas ng tsunami!'
          : 'Prove your strength against the overwhelming power of tsunamis!',
    };
  } else {
    return {
      'name': categoryName,
      'description': '',
    };
  }
} 