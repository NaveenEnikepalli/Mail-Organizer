import 'package:flutter/foundation.dart';

class Summarizer {
  static const List<String> _importantKeywords = [
    'deadline',
    'due',
    'submit',
    'by',
    'important',
    'urgent',
    'asap',
    'action',
    'required',
    'approved',
    'rejected',
    'confirmation',
    'alert',
    'meeting',
    'call',
    'interview',
    'offer',
    'amount',
    'total',
    'price',
  ];

  /// Extracts a simple extractive summary from text.
  /// Splits into sentences and scores each based on keyword presence.
  /// Returns the top [maxSentences] sentences as a summary.
  static String summarize(String text, {int maxSentences = 2}) {
    try {
      if (text.isEmpty) return '';

      // Split into sentences (simple heuristic)
      final sentences = _splitSentences(text);
      if (sentences.isEmpty) {
        return text.substring(0, (200).clamp(0, text.length));
      }

      // Score sentences
      final scoredSentences = <(String, double)>[];
      for (final sentence in sentences) {
        final score = _scoreSentence(sentence);
        scoredSentences.add((sentence, score));
      }

      // Sort by score and take top maxSentences
      scoredSentences.sort((a, b) => b.$2.compareTo(a.$2));
      final topSentences = scoredSentences
          .take(maxSentences)
          .map((e) => e.$1)
          .toList();

      // Re-order by original position
      final result = _reorderByOriginal(sentences, topSentences);
      return result.join(' ').trim();
    } catch (e) {
      debugPrint('Error in summarize: $e');
      return text.substring(0, (200).clamp(0, text.length));
    }
  }

  static List<String> _splitSentences(String text) {
    // Simple sentence splitting on . ! ?
    final sentences = text.split(RegExp(r'[.!?]+'));
    return sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 5)
        .toList();
  }

  static double _scoreSentence(String sentence) {
    double score = 0;
    final lower = sentence.toLowerCase();

    // Count keyword occurrences
    for (final keyword in _importantKeywords) {
      if (lower.contains(keyword)) {
        score += 1.0;
      }
    }

    // Bonus for length (sentences with more info)
    if (sentence.split(' ').length > 10) {
      score += 0.5;
    }

    // Bonus for numbers (dates, amounts)
    if (RegExp(r'\d').hasMatch(sentence)) {
      score += 0.5;
    }

    return score;
  }

  static List<String> _reorderByOriginal(
    List<String> originalSentences,
    List<String> selectedSentences,
  ) {
    final result = <String>[];
    for (final orig in originalSentences) {
      if (selectedSentences.contains(orig)) {
        result.add(orig);
      }
    }
    return result;
  }
}
