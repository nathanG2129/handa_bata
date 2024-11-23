import 'package:flutter/material.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/resources/resource_preview.dart';

class ResourceGrid extends StatelessWidget {
  final String category;
  final String selectedLanguage;

  const ResourceGrid({
    super.key,
    required this.category,
    required this.selectedLanguage,
  });

  List<ResourceData> getResources() {
    if (category == 'Videos') {
      return [
        const ResourceData(
          title: 'Alam mo ba? Lindol',
          src: 'zXLyMMFGbhM',
          reference: 'From the Philippine Information Agency',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'DOST BLTB Series Lindol',
          src: 'ZKdAH9uf1WE',
          reference: 'From the Department of Science and Technology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Earthquake Epicenter',
          src: 'nnHzsX11ofI',
          reference: 'From the Department of Education',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Earthquake and Its Hazards',
          src: 'Py9k7dacoKo',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Mga Dapat Malaman sa Big One',
          src: 'T-WoRReLpKY',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Duck, Cover, and Hold',
          src: 'XUoYj1fN2Cs',
          reference: 'From Rappler',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Earthquake Drill',
          src: 'EKAhY84FPbs',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'When is the time to evacuate?',
          src: 'zplJvqDQrVw',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Are you ready for it?',
          src: 'lpe_0P8sUZg',
          reference: 'From the Philippine Information Agency',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Alam mo ba? Bagyo',
          src: 'uz9sclC3nBE',
          reference: 'From the Philippine Information Agency',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Typhoon',
          src: 'eSxN7e6uCbo',
          reference: 'From the Department of Science and Technology',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'DOST BLTB Series Bagyo',
          src: 'nXfj-Id_La0',
          reference: 'From the Philippine Atmospheric, Geophysical and Astronomical Services Administration',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Modified Tropical Cyclone Warning Signal System',
          src: 'ke2drZ-2YfU',
          reference: 'From the Philippine Atmospheric, Geophysical and Astronomical Services Administration',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Tropical Cyclone Wind Signals, Explained',
          src: 'KyOnxOhnMaM',
          reference: 'From GMA Integrated News',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Heavy Rainfall and Thunderstorm Warning System',
          src: 'l0hsjostU_g',
          reference: 'From the Philippine Atmospheric, Geophysical and Astronomical Services Administration',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Ano-ano ang yellow, orange at red rainfall warning?',
          src: 'uys9waXWW3M',
          reference: 'From GMA Integrated News',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Mga Hakbang sa Pagbuo ng Community Based DRRMP',
          src: 'zddS3dJupno',
          reference: 'From the Department of Education',
          thumbnailPath: '',
        ),
        const ResourceData(
          title: 'Emergency Go Bag',
          src: 'm9whRKDsEAA',
          reference: 'From the Office of Civil Defense Region XII - SOCCSKSARGEN',
          thumbnailPath: '',
        ),
      ];
    } else {
      return [
        const ResourceData(
          title: 'Community and Family Earthquake Safety Guide',
          src: 'assets/images/infographics/CommunityAndFamilyEarthquakeSafetyGuide.png',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/CommunityAndFamilyEarthquakeSafetyGuide.png',
        ),
        const ResourceData(
          title: 'Earthquake: Are You Prepared?',
          src: 'assets/images/infographics/EarthquakeAreYouPrepared.jpg',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/EarthquakeAreYouPrepared.jpg',
        ),
        const ResourceData(
          title: 'Emergency Go Bag',
          src: 'assets/images/infographics/EmergencyGoBag.jfif',
          reference: 'From NDRRMC',
          thumbnailPath: 'assets/images/infographics/previews/EmergencyGoBag.jfif',
        ),
        const ResourceData(
          title: 'Gabay sa mga Abiso, Klasipikasyon, at Sukat ng Ulan',
          src: 'assets/images/infographics/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg',
          reference: 'From PAGASA',
          thumbnailPath: 'assets/images/infographics/previews/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg',
        ),
        const ResourceData(
          title: 'Heavy Rainfall Warnings',
          src: 'assets/images/infographics/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg',
          reference: 'From Philippine Information Agency',
          thumbnailPath: 'assets/images/infographics/previews/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg',
        ),
        const ResourceData(
          title: 'Lindol... Handa Ka Na Ba?',
          src: 'assets/images/infographics/LindolHandaKaNaBa.jpg',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/LindolHandaKaNaBa.jpg',
        ),
        const ResourceData(
          title: 'May Naramdamang Lindol: Gabay sa Pag-uulat ng Lindol',
          src: 'assets/images/infographics/MayNaramdamangLindolGabaySaPag-uulatNgLindol.png',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/MayNaramdamangLindolGabaySaPag-uulatNgLindol.png',
        ),
        const ResourceData(
          title: 'Mga Uri ng Bagyo',
          src: 'assets/images/infographics/MgaUriNgBagyoPhilippineInformationAgency.jpg',
          reference: 'From Philippine Information Agency',
          thumbnailPath: 'assets/images/infographics/previews/MgaUriNgBagyoPhilippineInformationAgency.jpg',
        ),
        const ResourceData(
          title: 'PHIVOLCS Earthquake Intensity Scale',
          src: 'assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/PHIVOLCSEarthquakeIntensityScale.jpg',
        ),
        const ResourceData(
          title: 'Rainfall Warning System',
          src: 'assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg',
          reference: 'From PAGASA',
          thumbnailPath: 'assets/images/infographics/previews/RainfallWarningSystemPayongPAGASA.jpeg',
        ),
        const ResourceData(
          title: 'Tropical Cyclone Warning System',
          src: 'assets/images/infographics/TropicalCycloneWarningSystemPayongPAGASA.jpeg',
          reference: 'From PAGASA',
          thumbnailPath: 'assets/images/infographics/previews/TropicalCycloneWarningSystemPayongPAGASA.jpeg',
        ),
        const ResourceData(
          title: 'Tropical Cyclone Wind Signal',
          src: 'assets/images/infographics/TropicalCycloneWindSignalPhilippineInformationAgency.jpg',
          reference: 'From Philippine Information Agency',
          thumbnailPath: 'assets/images/infographics/previews/TropicalCycloneWindSignalPhilippineInformationAgency.jpg',
        ),
        const ResourceData(
          title: 'Volcanic Eruption Safety Guide',
          src: 'assets/images/infographics/VolcanicEruption.jpg',
          reference: 'From Philippine Red Cross',
          thumbnailPath: 'assets/images/infographics/previews/VolcanicEruption.jpg',
        ),
        const ResourceData(
          title: 'Drought Preparedness Guide',
          src: 'assets/images/infographics/Drought_Preparedness.jpeg',
          reference: 'From NDRRMC',
          thumbnailPath: 'assets/images/infographics/previews/Drought_Preparedness.jpeg',
        ),
        const ResourceData(
          title: 'Earthquake Preparedness',
          src: 'assets/images/infographics/EarthquakePreparedness.jpg',
          reference: 'From PHIVOLCS',
          thumbnailPath: 'assets/images/infographics/previews/EarthquakePreparedness.jpg',
        ),
        const ResourceData(
          title: 'First Aid Guide',
          src: 'assets/images/infographics/First Aid.jpg',
          reference: 'From Philippine Red Cross',
          thumbnailPath: 'assets/images/infographics/previews/FirstAid.jpg',
        ),
        const ResourceData(
          title: 'Flood Preparedness Guide',
          src: 'assets/images/infographics/Flood_Preparedness.jpeg',
          reference: 'From NDRRMC',
          thumbnailPath: 'assets/images/infographics/previews/Flood_Preparedness.jpeg',
        ),
        const ResourceData(
          title: 'Typhoon Preparedness Guide',
          src: 'assets/images/infographics/TyphoonPreparedness.jpeg',
          reference: 'From PAGASA',
          thumbnailPath: 'assets/images/infographics/previews/TyphoonPreparedness.jpeg',
        ),
        const ResourceData(
          title: 'What To Do During Volcanic Eruption',
          src: 'assets/images/infographics/WhatToDoVolcanicEruption.jpg',
          reference: 'From Philippine Red Cross',
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
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    // Adjust aspect ratio to give more height for content
    final childAspectRatio = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 0.8,
      tablet: 0.7,  // Made taller for tablet to accommodate text
      desktop: 0.8,
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
          mobile: 50,
          tablet: 30,  // Reduced padding for tablet to use more space
          desktop: 50,
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