class MoodAnalyzer {
  static const Map<String, List<String>> _moodKeywords = {
    "Happy 😊": [
      "happy", "joy", "wonderful", "great", "excellent", "amazing", "love", "excited",
      "blessed", "grateful", "smile", "laugh", "fun", "good", "positive", "victory",
      "success", "awesome", "fantastic", "yay", "hurray", "achievement"
    ],
    "Sad 😢": [
      "sad", "lonely", "depressed", "unhappy", "cry", "tears", "pain", "hurt", "grief",
      "sorrow", "regret", "miss", "lost", "broken", "empty", "miserable", "tough",
      "hard", "failure", "bad", "negative", "hopeless", "tear"
    ],
    "Angry 😠": [
      "angry", "mad", "furious", "hate", "annoyed", "irritated", "frustrated", "rage",
      "upset", "bitter", "revenge", "stupid", "worst", "unbearable", "offensive",
      "argument", "fight", "screaming", "yelling"
    ],
    "Calm 🌿": [
      "calm", "peace", "quiet", "relax", "serene", "chill", "steady", "soft", "gentle",
      "meditation", "breath", "balanced", "stable", "smooth", "cozy", "resting",
      "flow", "simple", "still"
    ],
    "Excited ⚡": [
      "excited", "dynamic", "energetic", "rush", "adventure", "thrill", "hype",
      "wow", "unbelievable", "fast", "active", "passionate", "powerful", "wild",
      "vibrant", "spark", "fire", "bright", "party"
    ],
  };

  static String analyzeMood(String content) {
    if (content.trim().isEmpty || content.length < 5) {
      return "Calm 🌿";
    }

    final words = content.toLowerCase().split(RegExp(r'\W+'));
    final Map<String, int> scores = {
      "Happy 😊": 0,
      "Sad 😢": 0,
      "Angry 😠": 0,
      "Calm 🌿": 0,
      "Excited ⚡": 0,
    };

    for (var word in words) {
      _moodKeywords.forEach((mood, keywords) {
        if (keywords.contains(word)) {
          scores[mood] = (scores[mood] ?? 0) + 1;
        }
      });
    }

    // Find the mood with the highest score
    String detectedMood = "Calm 🌿";
    int highestScore = 0;

    scores.forEach((mood, score) {
      if (score > highestScore) {
        highestScore = score;
        detectedMood = mood;
      }
    });

    return detectedMood;
  }
}
