class MainPageLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'handaBata': 'Handa Bata',
      'mobile': 'Mobile',
      'joinKladisAndKloud': 'Join Kladis and Kloud as they explore the secrets of staying safe during earthquakes, typhoons and more! Tag along their journey to become preparedness experts and protect their community.',
      'playNow': 'Play Now',
      'playAdventure': 'Play Adventure',
      'playAdventureButton': 'Play Adventure',
      'adventureDescription': 'Embark on an exhilarating quest and put your earthquake and typhoon preparedness knowledge to the test in our engaging stage-based quiz game! Conquer each challenging stage and unlock different kinds of rewards!',
      'playArcade': 'Play Arcade',
      'playArcadeButton': 'Play Arcade',
      'arcadeDescription': 'Expand your preparedness knowledge with our fast-paced quiz games in Arcade! Climb the leaderboards and claim the title of the ultimate preparedness expert!',
      'learnAbout': 'Learn About',
      'preparedness': 'Preparedness',
      'learnMoreDescription': 'Explore our earthquake and typhoon preparedness resources to learn how to safeguard yourself during these calamities! Discover everything from how to secure your home to how to create a family emergency plan. Get prepared and stay safe!',
      'learnMore': 'Learn More',
    },
    'fil': {
      'handaBata': 'Handa Bata',
      'mobile': 'Mobile',
      'joinKladisAndKloud': 'Samahan sina Kladis at Kloud sa pagtuklas ng mga sikreto upang maging ligtas sa panahon ng lindol at bagyo! Sumama sa kanilang paglalakbay upang maging mga eksperto sa kahandaan at tagapag-alaga ng kanilang pamayanan!',
      'playNow': 'Maglaro Na',
      'playAdventure': 'Maglaro ng',
      'playAdventureMode': 'Adventure',
      'playAdventureButton': 'Pumunta sa Adventure',
      'adventureDescription': 'Samahan sina Kladis at Kloud sa pagtuklas ng mga sikreto upang maging ligtas sa panahon ng lindol at bagyo! Sumama sa kanilang paglalakbay upang maging mga eksperto sa kahandaan at tagapag-alaga ng kanilang pamayanan!',
      'playArcade': 'Maglaro ng',
      'playArcadeMode': 'Arcade',
      'playArcadeButton': 'Pumunta sa Arcade',
      'arcadeDescription': 'Samahan sina Kladis at Kloud sa pagtuklas ng mga sikreto upang maging ligtas sa panahon ng lindol at bagyo! Sumama sa kanilang paglalakbay upang maging mga eksperto sa kahandaan at tagapag-alaga ng kanilang pamayanan!',
      'learnAbout': 'Matuto Tungkol',
      'preparedness': 'sa Kahandaan',
      'learnMoreDescription': 'I-explore ang aming mga resource tungkol sa lindol at bagyo upang alamin kung paano protektahan ang iyong sarili sa panahon ng sakuna! Tuklasin ang mga bagay-bagay mula sa kung paano siguruhing ligtas ang iyong tahanan hanggang sa kung paano gumawa ng family emergency plan. Maging handa at manatiling ligtas!',
      'learnMore': 'Tuklasin',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
}