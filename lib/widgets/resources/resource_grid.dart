import 'package:flutter/material.dart';
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
          thumbnailPath: 'assets/resources/thumbnails/alam_mo_ba_lindol.jpg',
        ),
        const ResourceData(
          title: 'DOST BLTB Series Lindol',
          src: 'your_video_id',
          reference: 'From the Department of Science and Technology',
          thumbnailPath: 'assets/resources/thumbnails/dost_bltb.jpg',
        ),
      ];
    } else {
      return [
        const ResourceData(
          title: 'Earthquake!!! Are You Prepared?',
          src: 'assets/resources/infographics/earthquake_prepared.jpg',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: 'assets/resources/thumbnails/earthquake_prepared.jpg',
        ),
        const ResourceData(
          title: 'Lindol... Handa ka na ba?',
          src: 'assets/resources/infographics/lindol_handa.jpg',
          reference: 'From the Philippine Institute of Volcanology and Seismology',
          thumbnailPath: 'assets/resources/thumbnails/lindol_handa.jpg',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = getResources();
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1200 
              ? 4 
              : screenWidth > 800 
                  ? 3 
                  : screenWidth > 450 
                      ? 2 
                      : 1,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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