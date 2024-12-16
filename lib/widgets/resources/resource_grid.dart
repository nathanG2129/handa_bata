import 'package:flutter/material.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/resources/resource_preview.dart';
import 'package:handabatamae/services/resource_service.dart';
import '../../localization/resources/localization.dart';

class ResourceGrid extends StatefulWidget {
  final String category;
  final String selectedLanguage;

  const ResourceGrid({
    super.key,
    required this.category,
    required this.selectedLanguage,
  });

  @override
  State<ResourceGrid> createState() => _ResourceGridState();
}

class _ResourceGridState extends State<ResourceGrid> {
  final ResourceService _resourceService = ResourceService();
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final resources = await _resourceService.fetchResources();
      
      if (mounted) {
        setState(() {
          _resources = resources.where((r) => 
            r['type'] == (widget.category == 'Videos' ? 'video' : 'infographic')
          ).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _buildReference(String organization) {
    final thePrefix = ResourcesLocalization.translate('the', widget.selectedLanguage);
    final fromPrefix = ResourcesLocalization.translate('from', widget.selectedLanguage);
    
    final cleanOrg = organization.startsWith('the ') 
      ? organization.substring(4)
      : organization;
      
    return '$fromPrefix ${thePrefix}$cleanOrg';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadResources,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    final gridSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 40.0,
      tablet: 40.0,
      desktop: 24.0,
    );

    final childAspectRatio = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.0,
      desktop: 1.0,
    );

    final crossAxisCount = screenWidth > 1200 
        ? 4 
        : screenWidth > 800 
            ? 2
            : screenWidth > 450 
                ? 2 
                : 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 0,
          tablet: 0,
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
        itemCount: _resources.length,
        itemBuilder: (context, index) {
          final resource = _resources[index];
          final resourceData = ResourceData(
            title: resource['title'],
            src: resource['src'],
            reference: _buildReference(resource['reference']),
            thumbnailPath: resource['thumbnailPath'] ?? '',
          );
          return ResourcePreview(
            data: resourceData,
            category: widget.category,
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