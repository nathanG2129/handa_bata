// lib/utils/profanity_filter.dart

class ProfanityFilter {
  static final List<String> filipinoBadWords = [
    "amputa", "animal ka", "bilat", "binibrocha", "bobo", "bogo", "boto",
    "brocha", "burat", "bwesit", "bwisit", "demonyo ka", "engot", "etits",
    "gaga", "gagi", "gago", "habal", "hayop ka", "hayup", "hinampak",
    "hinayupak", "hindot", "hindutan", "hudas", "iniyot", "inutel", "inutil",
    "iyot", "kagaguhan", "kagang", "kantot", "kantotan", "kantut", "kantutan",
    "kaululan", "kayat", "kiki", "kikinginamo", "kingina", "kupal", "leche",
    "leching", "lechugas", "lintik", "nakakaburat", "nimal", "ogag", "olok",
    "pakingshet", "pakshet", "pakyu", "pesteng yawa", "poke", "poki", "pokpok",
    "poyet", "pu'keng", "pucha", "puchanggala", "puchangina", "puke", "puki",
    "pukinangina", "puking", "punyeta", "puta", "putang", "putang ina",
    "putangina", "putanginamo", "putaragis", "putragis", "puyet", "ratbu",
    "shunga", "sira ulo", "siraulo", "suso", "susu", "tae", "taena", "tamod",
    "tanga", "tangina", "taragis", "tarantado", "tete", "teti", "timang",
    "tinil", "tite", "titi", "tungaw", "ulol", "ulul", "ungas"
  ];

  static final List<String> englishBadWords = [
    "ass", "asshole", "bastard", "bitch", "crap", "cunt", "damn", "dick",
    "douche", "douchebag", "fuck", "fucking", "fucker", "motherfucker",
    "nigger", "piss", "pussy", "shit", "slut", "whore"
  ];

  static bool containsProfanity(String text) {
    final String lowerText = text.toLowerCase();
    
    // Check for exact matches
    if (filipinoBadWords.contains(lowerText) || englishBadWords.contains(lowerText)) {
      return true;
    }

    // Check if any bad word is contained within the text
    for (final word in filipinoBadWords) {
      if (lowerText.contains(word.toLowerCase())) {
        return true;
      }
    }

    for (final word in englishBadWords) {
      if (lowerText.contains(word.toLowerCase())) {
        return true;
      }
    }

    // Check for common variations and concatenations
    final RegExp variations = RegExp(
      r'(pu?t?a?(ng)?[^a-z]*i[^a-z]*n[^a-z]*a|' // putangina variations
      r'ta[^a-z]*ng[^a-z]*i[^a-z]*na|' // tangina variations
      r'f+[^a-z]*u+[^a-z]*c+[^a-z]*k+|' // fuck variations
      r'b+[^a-z]*i+[^a-z]*t+[^a-z]*c+[^a-z]*h+)', // bitch variations
      caseSensitive: false
    );

    return variations.hasMatch(lowerText);
  }

  static String? validateText(String? value, String language) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (containsProfanity(value)) {
      return language.toLowerCase().contains('fil') 
          ? 'Bawal gumamit ng masamang salita.'
          : 'Profanity is not allowed.';
    }

    return null;
  }
} 