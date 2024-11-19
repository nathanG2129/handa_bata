import 'dart:convert';
import 'package:flutter/services.dart';

class LearnLocalization {
  static Map<String, dynamic>? _enContent;
  static Map<String, dynamic>? _filContent;

  static Future<void> initialize() async {
    try {
      print('🔄 Initializing Learn content...');
      
      // Load both language files from assets
      final String enJson = await rootBundle.loadString('assets/localization/learn/en.json');
      final String filJson = await rootBundle.loadString('assets/localization/learn/fil.json');
      
      print('📝 Parsing JSON content...');
      _enContent = json.decode(enJson);
      _filContent = json.decode(filJson);
      
      print('✅ Learn content loaded successfully');
      print('📚 EN categories: ${_enContent?.keys.toList()}');
      print('📚 FIL categories: ${_filContent?.keys.toList()}');
    } catch (e, stackTrace) {
      print('❌ Error loading learn content: $e');
      print('Stack trace: $stackTrace');
    }
  }

  static Map<String, dynamic>? getContent(String category, String title, String language) {
    try {
      print('🔍 Getting content for $category/$title in $language');
      final content = language == 'en' ? _enContent : _filContent;
      
      if (content == null) {
        print('⚠️ No content loaded for $language');
        return null;
      }
      
      if (!content.containsKey(category)) {
        print('⚠️ Category $category not found');
        return null;
      }
      
      if (!content[category].containsKey(title)) {
        print('⚠️ Title $title not found in $category');
        return null;
      }
      
      print('✅ Content found');
      return content[category][title];
    } catch (e) {
      print('❌ Error getting content: $e');
      return null;
    }
  }

  static List<String> getCategories() {
    return (_enContent?.keys.where((key) => key != 'References') ?? []).toList();
  }

  static List<String> getTopicsForCategory(String category) {
    try {
      return (_enContent?[category]?.keys ?? []).toList();
    } catch (e) {
      print('Error getting topics: $e');
      return [];
    }
  }

  // Helper method to handle HTML-like content
  static String cleanHtmlContent(String content) {
    // Remove HTML tags but preserve links
    return content
        .replaceAll(RegExp(r'<(?!a\s|/a)[^>]+>', multiLine: true), '')
        .replaceAll('</p>', '\n')
        .replaceAll('<p>', '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  // Helper method to extract links from content
  static List<Map<String, String>> extractLinks(String content) {
    // Fixed RegExp pattern
    final regex = RegExp('<a href="([^"]*)"[^>]*>(.*?)</a>');
    final matches = regex.allMatches(content);
    
    return matches.map((match) => {
      'url': match.group(1) ?? '',
      'text': match.group(2) ?? '',
    }).toList();
  }
}