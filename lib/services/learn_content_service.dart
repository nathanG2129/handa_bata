import 'package:handabatamae/localization/learn/localization.dart';

class LearnContentService {
  static final LearnContentService _instance = LearnContentService._internal();
  factory LearnContentService() => _instance;
  LearnContentService._internal();

  Future<Map<String, dynamic>> getContent(String category, String title, String language) async {
    // Map the display title to the JSON key if needed
    String jsonTitle = title;
    if (category == 'Other Information') {
      switch (title) {
        case 'Earthquake Intensity Scale':
        case 'Rainfall Warning System':
        case 'Tropical Cyclone Warning Systems':
          jsonTitle = title;
          break;
      }
    }

    final content = LearnLocalization.getContent(category, jsonTitle, language);
    if (content == null) {
      return {
        'title': 'Content Not Found',
        'content': [],
        'references': []
      };
    }

    // Process content to handle HTML and links
    if (content['content'] is List) {
      for (var item in content['content']) {
        // Process description
        if (item['description'] != null) {
          item['description'] = LearnLocalization.cleanHtmlContent(item['description']);
          item['links'] = LearnLocalization.extractLinks(item['description']);
        }

        // Process list items
        if (item['list'] is List) {
          for (var listItem in item['list']) {
            if (listItem is String) {
              listItem = LearnLocalization.cleanHtmlContent(listItem);
            } else if (listItem is Map) {
              if (listItem['description'] != null) {
                listItem['description'] = LearnLocalization.cleanHtmlContent(listItem['description']);
              }
              if (listItem['text'] != null) {
                listItem['text'] = LearnLocalization.cleanHtmlContent(listItem['text']);
              }
              // Process sublist
              if (listItem['sublist'] is List) {
                listItem['sublist'] = listItem['sublist'].map((subItem) {
                  return LearnLocalization.cleanHtmlContent(subItem.toString());
                }).toList();
              }
            }
          }
        }

        // Process table content
        if (item['table'] != null) {
          var table = item['table'];
          if (table['rows'] is List) {
            for (var row in table['rows']) {
              if (row['Description'] is List) {
                row['Description'] = row['Description'].map((desc) {
                  return LearnLocalization.cleanHtmlContent(desc.toString());
                }).toList();
              }
            }
          }
        }
      }
    }

    return content;
  }

  Future<List<Map<String, String>>> getCategories() async {
    return LearnLocalization.getCategories()
        .map((category) => {
              'id': category,
              'name': category,
            })
        .toList();
  }

  Future<List<Map<String, String>>> getTopicsForCategory(String category) async {
    return LearnLocalization.getTopicsForCategory(category)
        .map((title) => {
              'id': title,
              'name': title,
            })
        .toList();
  }
} 