import 'package:flutter/material.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/resources/resource_preview.dart';
import '../../localization/resources/localization.dart';

class ResourceGrid extends StatelessWidget {
  final String category;
  final String selectedLanguage;

  const ResourceGrid({
    super.key,
    required this.category,
    required this.selectedLanguage,
  });

  List<ResourceData> getResources() {
    // Helper function to build reference string
    String buildReference(String organization) {
      // Add 'the' prefix based on language
      final thePrefix = ResourcesLocalization.translate('the', selectedLanguage);
      final fromPrefix = ResourcesLocalization.translate('from', selectedLanguage);
      
      // If organization starts with 'the', remove it and let translation handle it
      final cleanOrg = organization.startsWith('the ') 
        ? organization.substring(4)  // Remove 'the ' from the start
        : organization;
        
      return '$fromPrefix ${thePrefix}$cleanOrg';
    }

    if (category == 'Videos') {
      return [
        ResourceData(
          title: 'Alam mo ba? Lindol',
          src: 'zXLyMMFGbhM',
          reference: buildReference('the Philippine Information Agency'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'DOST BLTB Series Lindol',
          src: 'ZKdAH9uf1WE',
          reference: buildReference('the Department of Science and Technology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Earthquake Epicenter',
          src: 'nnHzsX11ofI',
          reference: buildReference('the Department of Education'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Earthquake and Its Hazards',
          src: 'Py9k7dacoKo',
          reference: buildReference('the Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Mga Dapat Malaman sa Big One',
          src: 'T-WoRReLpKY',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Duck, Cover, and Hold',
          src: 'XUoYj1fN2Cs',
          reference: buildReference('Rappler'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Earthquake Drill',
          src: 'EKAhY84FPbs',
          reference: buildReference('the Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'When is the time to evacuate?',
          src: 'zplJvqDQrVw',
          reference: buildReference('the Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Are you ready for it?',
          src: 'lpe_0P8sUZg',
          reference: buildReference('the Philippine Information Agency'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Alam mo ba? Bagyo',
          src: 'uz9sclC3nBE',
          reference: buildReference('the Philippine Information Agency'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Typhoon',
          src: 'eSxN7e6uCbo',
          reference: buildReference('the Department of Science and Technology'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'DOST BLTB Series Bagyo',
          src: 'nXfj-Id_La0',
          reference: buildReference('the Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Modified Tropical Cyclone Warning Signal System',
          src: 'ke2drZ-2YfU',
          reference: buildReference('the Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Tropical Cyclone Wind Signals, Explained',
          src: 'KyOnxOhnMaM',
          reference: buildReference('GMA Integrated News'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Heavy Rainfall and Thunderstorm Warning System',
          src: 'l0hsjostU_g',
          reference: buildReference('the Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Ano-ano ang yellow, orange at red rainfall warning?',
          src: 'uys9waXWW3M',
          reference: buildReference('GMA Integrated News'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Mga Hakbang sa Pagbuo ng Community Based DRRMP',
          src: 'zddS3dJupno',
          reference: buildReference('the Department of Education'),
          thumbnailPath: '',
        ),
        ResourceData(
          title: 'Emergency Go Bag',
          src: 'm9whRKDsEAA',
          reference: buildReference('the Office of Civil Defense Region XII - SOCCSKSARGEN'),
          thumbnailPath: '',
        ),
      ];
    } else {
      return [
        ResourceData(
          title: 'Community and Family Earthquake Safety Guide',
          src: 'assets/images/infographics/CommunityAndFamilyEarthquakeSafetyGuide.png',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/CommunityAndFamilyEarthquakeSafetyGuide.png',
        ),
        ResourceData(
          title: 'Earthquake: Are You Prepared?',
          src: 'assets/images/infographics/EarthquakeAreYouPrepared.jpg',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/EarthquakeAreYouPrepared.jpg',
        ),
        ResourceData(
          title: 'Emergency Go Bag',
          src: 'assets/images/infographics/EmergencyGoBag.jfif',
          reference: buildReference('National Disaster Risk Reduction and Management Council'),
          thumbnailPath: 'assets/images/infographics/previews/EmergencyGoBag.jfif',
        ),
        ResourceData(
          title: 'Gabay sa mga Abiso, Klasipikasyon, at Sukat ng Ulan',
          src: 'assets/images/infographics/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg',
          reference: buildReference('Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: 'assets/images/infographics/previews/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg',
        ),
        ResourceData(
          title: 'Heavy Rainfall Warnings',
          src: 'assets/images/infographics/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg',
          reference: buildReference('Philippine Information Agency'),
          thumbnailPath: 'assets/images/infographics/previews/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg',
        ),
        ResourceData(
          title: 'Lindol... Handa Ka Na Ba?',
          src: 'assets/images/infographics/LindolHandaKaNaBa.jpg',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/LindolHandaKaNaBa.jpg',
        ),
        ResourceData(
          title: 'May Naramdamang Lindol: Gabay sa Pag-uulat ng Lindol',
          src: 'assets/images/infographics/MayNaramdamangLindolGabaySaPag-uulatNgLindol.png',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/MayNaramdamangLindolGabaySaPag-uulatNgLindol.png',
        ),
        ResourceData(
          title: 'Mga Uri ng Bagyo',
          src: 'assets/images/infographics/MgaUriNgBagyoPhilippineInformationAgency.jpg',
          reference: buildReference('Philippine Information Agency'),
          thumbnailPath: 'assets/images/infographics/previews/MgaUriNgBagyoPhilippineInformationAgency.jpg',
        ),
        ResourceData(
          title: 'PHIVOLCS Earthquake Intensity Scale',
          src: 'assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/PHIVOLCSEarthquakeIntensityScale.jpg',
        ),
        ResourceData(
          title: 'Rainfall Warning System',
          src: 'assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg',
          reference: buildReference('Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: 'assets/images/infographics/previews/RainfallWarningSystemPayongPAGASA.jpeg',
        ),
        ResourceData(
          title: 'Tropical Cyclone Warning System',
          src: 'assets/images/infographics/TropicalCycloneWarningSystemPayongPAGASA.jpeg',
          reference: buildReference('Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: 'assets/images/infographics/previews/TropicalCycloneWarningSystemPayongPAGASA.jpeg',
        ),
        ResourceData(
          title: 'Tropical Cyclone Wind Signal',
          src: 'assets/images/infographics/TropicalCycloneWindSignalPhilippineInformationAgency.jpg',
          reference: buildReference('Philippine Information Agency'),
          thumbnailPath: 'assets/images/infographics/previews/TropicalCycloneWindSignalPhilippineInformationAgency.jpg',
        ),
        ResourceData(
          title: 'Volcanic Eruption Safety Guide',
          src: 'assets/images/infographics/VolcanicEruption.jpg',
          reference: buildReference('Philippine Red Cross'),
          thumbnailPath: 'assets/images/infographics/previews/VolcanicEruption.jpg',
        ),
        ResourceData(
          title: 'Drought Preparedness Guide',
          src: 'assets/images/infographics/Drought_Preparedness.jpeg',
          reference: buildReference('National Disaster Risk Reduction and Management Council'),
          thumbnailPath: 'assets/images/infographics/previews/Drought_Preparedness.jpeg',
        ),
        ResourceData(
          title: 'Earthquake Preparedness',
          src: 'assets/images/infographics/EarthquakePreparedness.jpg',
          reference: buildReference('Philippine Institute of Volcanology and Seismology'),
          thumbnailPath: 'assets/images/infographics/previews/EarthquakePreparedness.jpg',
        ),
        ResourceData(
          title: 'First Aid Guide',
          src: 'assets/images/infographics/FirstAid.jpg',
          reference: buildReference('Philippine Red Cross'),
          thumbnailPath: 'assets/images/infographics/previews/FirstAid.jpg',
        ),
        ResourceData(
          title: 'Flood Preparedness Guide',
          src: 'assets/images/infographics/Flood_Preparedness.jpeg',
          reference: buildReference('National Disaster Risk Reduction and Management Council'),
          thumbnailPath: 'assets/images/infographics/previews/Flood_Preparedness.jpeg',
        ),
        ResourceData(
          title: 'Typhoon Preparedness Guide',
          src: 'assets/images/infographics/TyphoonPreparedness.jpeg',
          reference: buildReference('Philippine Atmospheric, Geophysical and Astronomical Services Administration'),
          thumbnailPath: 'assets/images/infographics/previews/TyphoonPreparedness.jpeg',
        ),
        ResourceData(
          title: 'What To Do During Volcanic Eruption',
          src: 'assets/images/infographics/WhatToDoVolcanicEruption.jpg',
          reference: buildReference('Philippine Red Cross'),
          thumbnailPath: 'assets/images/infographics/previews/WhatToDoVolcanicEruption.jpg',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = getResources();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust grid spacing and aspect ratio based on screen size
    final gridSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 40.0,
      tablet: 40.0,
      desktop: 24.0,
    );

    // Adjust aspect ratio to give more height for content
    final childAspectRatio = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.0,  // Made taller for tablet to accommodate text
      desktop: 1.0,
    );

    // Adjust number of columns based on screen width
    final crossAxisCount = screenWidth > 1200 
        ? 4 
        : screenWidth > 800 
            ? 2  // Changed from 3 to 2 for tablet to give more width
            : screenWidth > 450 
                ? 2 
                : 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 0,
          tablet: 0,  // Reduced padding for tablet to use more space
          desktop: 0,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: gridSpacing,
          mainAxisSpacing: gridSpacing,
        ),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final resource = resources[index];
          return ResourcePreview(
            data: resource,
            category: category,
          );
        },
      ),
    );
  }
}

class ResourceData {
  final String title;
  final String src;
  final String reference;
  final String thumbnailPath;

  const ResourceData({
    required this.title,
    required this.src,
    required this.reference,
    required this.thumbnailPath,
  });
} 