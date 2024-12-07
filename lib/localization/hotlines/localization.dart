class HotlinesLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'emergency_hotlines': 'EMERGENCY HOTLINES',
      'emergency_hotlines_description': 'Earthquakes, typhoons and volcanic eruptions are some of the most common and destructive natural disasters in the Philippines. Here are some important emergency numbers you should keep in mind in case of an earthquake or typhoon.',
      'national_emergency_hotline': 'NATIONAL EMERGENCY HOTLINE',
      'ndrrmc_name': 'National Disaster Risk Reduction and Management Council',
      'prc_name': 'Philippine Red Cross',
      'phivolcs_name': 'Philippine Institute of Volcanology and Seismology',
      'pagasa_name': 'Philippine Atmospheric, Geophysical and Astronomical Services Administration',
      'pcg_name': 'Philippine Coast Guard',
      'doh_name': 'Department of Health',
    },
    'fil': {
      'emergency_hotlines': 'MGA EMERGENCY HOTLINE',
      'emergency_hotlines_description': 'Ang mga lindol, bagyo at pagputok ng bulkan ay ilan sa pinakakaraniwan at mapanirang natural na kalamidad sa Pilipinas. Narito ang ilang mahahalagang emergency numbers na dapat mong tandaan kung sakaling magkaroon ng lindol o bagyo.',
      'national_emergency_hotline': 'PAMBANSANG EMERGENCY HOTLINE',
      'ndrrmc_name': 'National Disaster Risk Reduction and Management Council',
      'prc_name': 'Philippine Red Cross',
      'phivolcs_name': 'Philippine Institute of Volcanology and Seismology',
      'pagasa_name': 'Philippine Atmospheric, Geophysical and Astronomical Services Administration',
      'pcg_name': 'Philippine Coast Guard',
      'doh_name': 'Department of Health',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 