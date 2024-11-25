class AboutPageLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'about': 'About',
      'theProject': 'The Project',
      'projectDescription': 'Handa Bata is a game-based learning website and mobile application that aims to empower Filipino children in junior high school with the knowledge they need to prepare for, respond to, and recover from earthquakes and typhoons. It was developed in 2023 by four Information Technology students from the University of Santo Tomas in Manila, Philippines. In 2024, the mobile application was developed by a new team of students from the same university.\n\nWe believe that every child should have the opportunity to be safe and resilient during times of disaster, and that technology can be a powerful tool to make this happen. That\'s why we created Handa Bata.',
      'meetTheTeam': 'Meet the Team',
      'handaBataMobile': 'Handa Bata Mobile',
      'handaBataWeb': 'Handa Bata Web',
      'contactUs': 'Contact Us',
      'contactDescription': 'For any questions or concerns about Handa Bata, you can email us at handabata.official@gmail.com.',
    },
    'fil': {
      'about': 'Tungkol',
      'theProject': 'sa Proyekto',
      'projectDescription': 'Ang Handa Bata ay isang game-based learning website at mobile application na naglalayong bigyang-kalakasan ang mga Pilipinong junior high school sa pamamagitan ng kaalamang kakailanganin nila para sa paghahanda, pagtugon, at pagbangon mula sa mga lindol at bagyo. Ito ay binuo noong 2023 ng apat na mag-aaral ng Information Technology mula sa Unibersidad ng Santo Tomas sa Maynila, Pilipinas.</p><p>Naniniwala kami na ang bawat bata ay dapat magkaroon ng pagkakataon na maging ligtas at matatag sa panahon ng sakuna, at ang teknolohiya ay maaaring maging isang makapangyarihang kasangkapan upang maisagawa ito. Iyon ang dahilan kung bakit namin nilikha ang Handa Bata.',
      'meetTheTeam': 'Kilalanin ang Team',
      'handaBataMobile': 'Handa Bata Mobile',
      'handaBataWeb': 'Handa Bata Web',
      'contactUs': 'Makipag-ugnayan',
      'contactDescription': 'Para sa anumang mga katanungan o alalahanin tungkol sa Handa Bata, maaari kayong mag-email sa amin sa handabata.official@gmail.com.',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 