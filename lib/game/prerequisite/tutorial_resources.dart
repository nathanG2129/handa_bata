/// Data class to hold resource information for a specific stage
class TutorialResourceData {
  final String? videoId;
  final String? videoTitle;
  final String? infographicPath;
  final String? infographicTitle;

  const TutorialResourceData({
    this.videoId,
    this.videoTitle,
    this.infographicPath,
    this.infographicTitle,
  });
}

/// Class to manage all tutorial resources
class TutorialResources {
  /// Gets the resource data for a specific category and stage
  static TutorialResourceData getResourceData({
    required String categoryId,
    required int stageNumber,
    required String language,
  }) {
    // Get the resources for the category
    final categoryResources = _resourceMap[categoryId];
    if (categoryResources == null) return const TutorialResourceData();

    // Get stage-specific resources or arcade resources
    final resources = stageNumber == -1 
        ? categoryResources['arcade'] 
        : categoryResources[stageNumber];
    
    return resources ?? const TutorialResourceData();
  }

  /// Resource mapping for all categories and stages
  static const Map<String, Map<dynamic, TutorialResourceData>> _resourceMap = {
    'Quake': {
      // Arcade mode resources
      'arcade': TutorialResourceData(
        videoId: 'zXLyMMFGbhM',  // Alam mo ba? Lindol
        videoTitle: 'Alam mo ba? Lindol',
        infographicPath: 'assets/images/infographics/LindolHandaKaNaBa.jpg',
        infographicTitle: 'Lindol... Handa Ka Na Ba?',
      ),
      // Stage-specific resources
      1: TutorialResourceData(
        videoId: 'Py9k7dacoKo',  // Earthquake and Its Hazards
        videoTitle: 'Earthquake and Its Hazards',
        infographicPath: 'assets/images/infographics/EarthquakePreparedness.jpg',
        infographicTitle: 'Earthquake Preparedness',
      ),
      2: TutorialResourceData(
        videoId: 'XUoYj1fN2Cs',  // Duck, Cover, and Hold
        videoTitle: 'Duck, Cover, and Hold',
        infographicPath: 'assets/images/infographics/CommunityAndFamilyEarthquakeSafetyGuide.png',
        infographicTitle: 'Community and Family Earthquake Safety Guide',
      ),
      3: TutorialResourceData(
        videoId: 'EKAhY84FPbs',  // Earthquake Drill
        videoTitle: 'Earthquake Drill',
        infographicPath: 'assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg',
        infographicTitle: 'PHIVOLCS Earthquake Intensity Scale',
      ),
      4: TutorialResourceData(
        videoId: 'T-WoRReLpKY',  // Mga Dapat Malaman sa Big One
        videoTitle: 'Mga Dapat Malaman sa Big One',
        infographicPath: 'assets/images/infographics/EarthquakeAreYouPrepared.jpg',
        infographicTitle: 'Earthquake: Are You Prepared?',
      ),
    },
    'Storm': {
      'arcade': TutorialResourceData(
        videoId: 'uz9sclC3nBE',  // Alam mo ba? Bagyo
        videoTitle: 'Alam mo ba? Bagyo',
        infographicPath: 'assets/images/infographics/TropicalCycloneWindSignalPhilippineInformationAgency.jpg',
        infographicTitle: 'Tropical Cyclone Wind Signal',
      ),
      1: TutorialResourceData(
        videoId: 'eSxN7e6uCbo',  // Typhoon
        videoTitle: 'Typhoon',
        infographicPath: 'assets/images/infographics/MgaUriNgBagyoPhilippineInformationAgency.jpg',
        infographicTitle: 'Mga Uri ng Bagyo',
      ),
      2: TutorialResourceData(
        videoId: 'nXfj-Id_La0',  // DOST BLTB Series Bagyo
        videoTitle: 'DOST BLTB Series Bagyo',
        infographicPath: 'assets/images/infographics/TropicalCycloneWarningSystemPayongPAGASA.jpeg',
        infographicTitle: 'Tropical Cyclone Warning System',
      ),
      3: TutorialResourceData(
        videoId: 'ke2drZ-2YfU',  // Modified Tropical Cyclone Warning Signal System
        videoTitle: 'Modified Tropical Cyclone Warning Signal System',
        infographicPath: 'assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg',
        infographicTitle: 'Rainfall Warning System',
      ),
      4: TutorialResourceData(
        videoId: 'KyOnxOhnMaM',  // Tropical Cyclone Wind Signals, Explained
        videoTitle: 'Tropical Cyclone Wind Signals, Explained',
        infographicPath: 'assets/images/infographics/TyphoonPreparedness.jpeg',
        infographicTitle: 'Typhoon Preparedness Guide',
      ),
    },
    'Flood': {
      'arcade': TutorialResourceData(
        videoId: 'l0hsjostU_g',  // Heavy Rainfall and Thunderstorm Warning System
        videoTitle: 'Heavy Rainfall and Thunderstorm Warning System',
        infographicPath: 'assets/images/infographics/Flood_Preparedness.jpeg',
        infographicTitle: 'Flood Preparedness Guide',
      ),
      1: TutorialResourceData(
        videoId: 'uys9waXWW3M',  // Ano-ano ang yellow, orange at red rainfall warning?
        videoTitle: 'Ano-ano ang yellow, orange at red rainfall warning?',
        infographicPath: 'assets/images/infographics/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg',
        infographicTitle: 'Gabay sa mga Abiso, Klasipikasyon, at Sukat ng Ulan',
      ),
      2: TutorialResourceData(
        videoId: 'l0hsjostU_g',  // Heavy Rainfall and Thunderstorm Warning System
        videoTitle: 'Heavy Rainfall and Thunderstorm Warning System',
        infographicPath: 'assets/images/infographics/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg',
        infographicTitle: 'Heavy Rainfall Warnings',
      ),
      3: TutorialResourceData(
        videoId: 'zddS3dJupno',  // Mga Hakbang sa Pagbuo ng Community Based DRRMP
        videoTitle: 'Mga Hakbang sa Pagbuo ng Community Based DRRMP',
        infographicPath: 'assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg',
        infographicTitle: 'Rainfall Warning System',
      ),
      4: TutorialResourceData(
        videoId: 'm9whRKDsEAA',  // Emergency Go Bag
        videoTitle: 'Emergency Go Bag',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
    },
    'Tsunami': {
      'arcade': TutorialResourceData(
        videoId: 'Py9k7dacoKo',  // Using earthquake video as tsunami often follows
        videoTitle: 'Earthquake and Its Hazards',
        infographicPath: 'assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg',
        infographicTitle: 'PHIVOLCS Earthquake Intensity Scale',
      ),
      1: TutorialResourceData(
        videoId: 'nnHzsX11ofI',  // Earthquake Epicenter
        videoTitle: 'Earthquake Epicenter',
        infographicPath: 'assets/images/infographics/EarthquakePreparedness.jpg',
        infographicTitle: 'Earthquake Preparedness',
      ),
      2: TutorialResourceData(
        videoId: 'XUoYj1fN2Cs',  // Duck, Cover, and Hold
        videoTitle: 'Duck, Cover, and Hold',
        infographicPath: 'assets/images/infographics/CommunityAndFamilyEarthquakeSafetyGuide.png',
        infographicTitle: 'Community and Family Earthquake Safety Guide',
      ),
      3: TutorialResourceData(
        videoId: 'zplJvqDQrVw',  // When is the time to evacuate?
        videoTitle: 'When is the time to evacuate?',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
      4: TutorialResourceData(
        videoId: 'lpe_0P8sUZg',  // Are you ready for it?
        videoTitle: 'Are you ready for it?',
        infographicPath: 'assets/images/infographics/FirstAid.jpg',
        infographicTitle: 'First Aid Guide',
      ),
    },
    'Volcanic': {
      'arcade': TutorialResourceData(
        videoId: 'ZKdAH9uf1WE',  // DOST BLTB Series
        videoTitle: 'DOST BLTB Series',
        infographicPath: 'assets/images/infographics/VolcanicEruption.jpg',
        infographicTitle: 'Volcanic Eruption Safety Guide',
      ),
      1: TutorialResourceData(
        videoId: 'Py9k7dacoKo',  // Using earthquake video as volcanic activity often relates
        videoTitle: 'Earthquake and Its Hazards',
        infographicPath: 'assets/images/infographics/VolcanicEruption.jpg',
        infographicTitle: 'Volcanic Eruption Safety Guide',
      ),
      2: TutorialResourceData(
        videoId: 'zplJvqDQrVw',  // When is the time to evacuate?
        videoTitle: 'When is the time to evacuate?',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
      3: TutorialResourceData(
        videoId: 'm9whRKDsEAA',  // Emergency Go Bag
        videoTitle: 'Emergency Go Bag',
        infographicPath: 'assets/images/infographics/FirstAid.jpg',
        infographicTitle: 'First Aid Guide',
      ),
      4: TutorialResourceData(
        videoId: 'lpe_0P8sUZg',  // Are you ready for it?
        videoTitle: 'Are you ready for it?',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
    },
    'Drought': {
      'arcade': TutorialResourceData(
        videoId: 'ZKdAH9uf1WE',  // DOST BLTB Series
        videoTitle: 'DOST BLTB Series',
        infographicPath: 'assets/images/infographics/Drought_Preparedness.jpeg',
        infographicTitle: 'Drought Preparedness Guide',
      ),
      1: TutorialResourceData(
        videoId: 'zddS3dJupno',  // Mga Hakbang sa Pagbuo ng Community Based DRRMP
        videoTitle: 'Mga Hakbang sa Pagbuo ng Community Based DRRMP',
        infographicPath: 'assets/images/infographics/Drought_Preparedness.jpeg',
        infographicTitle: 'Drought Preparedness Guide',
      ),
      2: TutorialResourceData(
        videoId: 'm9whRKDsEAA',  // Emergency Go Bag
        videoTitle: 'Emergency Go Bag',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
      3: TutorialResourceData(
        videoId: 'lpe_0P8sUZg',  // Are you ready for it?
        videoTitle: 'Are you ready for it?',
        infographicPath: 'assets/images/infographics/FirstAid.jpg',
        infographicTitle: 'First Aid Guide',
      ),
      4: TutorialResourceData(
        videoId: 'zplJvqDQrVw',  // When is the time to evacuate?
        videoTitle: 'When is the time to evacuate?',
        infographicPath: 'assets/images/infographics/EmergencyGoBag.jfif',
        infographicTitle: 'Emergency Go Bag',
      ),
    },
  };

  /// Gets the localized title for resource types
  static String getResourceTypeTitle(String type, String language) {
    final Map<String, Map<String, String>> titles = {
      'video': {
        'en': 'Watch this Video',
        'fil': 'Panoorin ang Video na Ito',
      },
      'infographic': {
        'en': 'Read this Infographic',
        'fil': 'Basahin ang Infographic na Ito',
      },
    };

    return titles[type]?[language] ?? titles[type]?['en'] ?? 'Resource';
  }
} 