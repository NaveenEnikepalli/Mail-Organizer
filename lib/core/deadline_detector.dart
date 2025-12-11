import 'package:flutter/foundation.dart';

class DeadlineDetectionResult {
  final bool hasDeadline;
  final List<DateTime> deadlines;
  final DateTime? primaryDeadline;
  final String? primaryDeadlineText;
  final int daysUntilPrimary;
  final Map<String, int> remainingTime;
  final int urgencyScore;
  final Map<String, dynamic>? reminder;

  const DeadlineDetectionResult({
    required this.hasDeadline,
    required this.deadlines,
    this.primaryDeadline,
    this.primaryDeadlineText,
    required this.daysUntilPrimary,
    required this.remainingTime,
    required this.urgencyScore,
    this.reminder,
  });

  /// Convert to JSON-like map for storage
  Map<String, dynamic> toMap() {
    return {
      'hasDeadline': hasDeadline,
      'deadlines': deadlines.map((d) => d.toIso8601String()).toList(),
      'primaryDeadline': primaryDeadline?.toIso8601String(),
      'primaryDeadlineText': primaryDeadlineText,
      'daysUntilPrimary': daysUntilPrimary,
      'urgencyScore': urgencyScore,
      'reminder': reminder,
    };
  }

  /// Create from stored map
  factory DeadlineDetectionResult.fromMap(Map<String, dynamic> map) {
    try {
      final deadlines =
          (map['deadlines'] as List?)
              ?.map((d) {
                try {
                  return DateTime.parse(d.toString());
                } catch (e) {
                  return null;
                }
              })
              .whereType<DateTime>()
              .toList() ??
          [];

      final primaryDeadline = map['primaryDeadline'] != null
          ? DateTime.tryParse(map['primaryDeadline'].toString())
          : null;

      return DeadlineDetectionResult(
        hasDeadline: map['hasDeadline'] as bool? ?? false,
        deadlines: deadlines,
        primaryDeadline: primaryDeadline,
        primaryDeadlineText: map['primaryDeadlineText'] as String?,
        daysUntilPrimary: map['daysUntilPrimary'] as int? ?? 9999,
        remainingTime: Map<String, int>.from(
          (map['remainingTime'] as Map?) ??
              {'days': 0, 'hours': 0, 'minutes': 0, 'total_hours': 0},
        ),
        urgencyScore: map['urgencyScore'] as int? ?? 0,
        reminder: map['reminder'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Error parsing DeadlineDetectionResult: $e');
      return DeadlineDetectionResult(
        hasDeadline: false,
        deadlines: [],
        daysUntilPrimary: 9999,
        remainingTime: {'days': 0, 'hours': 0, 'minutes': 0, 'total_hours': 0},
        urgencyScore: 0,
      );
    }
  }
}

class DeadlineDetectorDart {
  // Month names for date parsing
  static const Map<String, int> _monthNames = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  // Regex patterns for deadline detection
  static final RegExp _deadlineKeywordPattern = RegExp(
    r'\b(deadline|due|due\s+by|due\s+date|submit\s+by|submit\s+before|must\s+be\s+done|complete\s+by|finish\s+by|by\s+\d|expires?|expiration\s+date|final\s+date|last\s+date)\b',
    caseSensitive: false,
  );

  static final RegExp _datePattern1 = RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b',
  );

  static final RegExp _datePattern2 = RegExp(
    r'\b([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})\b',
  );

  static final RegExp _datePattern3 = RegExp(r'\b([A-Za-z]+)\s+(\d{1,2})\b');

  static final RegExp _urgencyKeywordPattern = RegExp(
    r'\b(urgent|asap|critical|immediately|high\s+priority|important|crucial|emergency|rush|today|tonight|tomorrow)\b',
    caseSensitive: false,
  );

  static final RegExp _actionVerbPattern = RegExp(
    r'\b(submit|send|complete|finish|deliver|provide|prepare|review|approve|sign|confirm)\b',
    caseSensitive: false,
  );

  DeadlineDetectorDart();

  /// Main method: detect all deadlines in text
  DeadlineDetectionResult detectDeadlines(String text) {
    try {
      if (text.isEmpty) {
        return DeadlineDetectionResult(
          hasDeadline: false,
          deadlines: [],
          daysUntilPrimary: 9999,
          remainingTime: {
            'days': 0,
            'hours': 0,
            'minutes': 0,
            'total_hours': 0,
          },
          urgencyScore: 0,
        );
      }

      final lowerText = text.toLowerCase();

      // Check if text contains deadline keywords
      final hasKeywords = _deadlineKeywordPattern.hasMatch(lowerText);

      // Extract dates
      final allDates = _extractDates(text);

      debugPrint(
        '      🔍 Deadline detection: hasKeywords=$hasKeywords, foundDates=${allDates.length}',
      );
      if (allDates.isNotEmpty) {
        for (int i = 0; i < (allDates.length < 3 ? allDates.length : 3); i++) {
          debugPrint('        - Date $i: ${allDates[i]}');
        }
      }

      // If no keywords found and no dates found, definitely not a deadline
      if (!hasKeywords && allDates.isEmpty) {
        return DeadlineDetectionResult(
          hasDeadline: false,
          deadlines: [],
          daysUntilPrimary: 9999,
          remainingTime: {
            'days': 0,
            'hours': 0,
            'minutes': 0,
            'total_hours': 0,
          },
          urgencyScore: 0,
        );
      }

      // If we have keywords but no dates, check for action verbs (more lenient)
      if (hasKeywords && allDates.isEmpty) {
        final hasActionVerbs = _actionVerbPattern.hasMatch(lowerText);
        if (!hasActionVerbs) {
          return DeadlineDetectionResult(
            hasDeadline: false,
            deadlines: [],
            daysUntilPrimary: 9999,
            remainingTime: {
              'days': 0,
              'hours': 0,
              'minutes': 0,
              'total_hours': 0,
            },
            urgencyScore: 0,
          );
        }
      }

      // If we have no keywords but we found dates, treat it as potential deadline
      // This is lenient mode - any date in the future could be a deadline
      if (!hasKeywords && allDates.isNotEmpty) {
        // Filter for future dates only
        final now = DateTime.now();
        final futureDates = allDates.where((d) => d.isAfter(now)).toList();

        // If we have future dates with no keyword, treat as low-confidence deadline
        if (futureDates.isNotEmpty) {
          final primaryDeadline = futureDates.reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
          final daysUntil = primaryDeadline.difference(now).inDays;

          // Only treat as deadline if it's within 90 days (not distant events)
          if (daysUntil <= 90) {
            debugPrint(
              '        ⚠️  LOW-CONFIDENCE DEADLINE: date without keywords, daysUntil=$daysUntil',
            );
          } else {
            return DeadlineDetectionResult(
              hasDeadline: false,
              deadlines: [],
              daysUntilPrimary: 9999,
              remainingTime: {
                'days': 0,
                'hours': 0,
                'minutes': 0,
                'total_hours': 0,
              },
              urgencyScore: 0,
            );
          }
        } else {
          return DeadlineDetectionResult(
            hasDeadline: false,
            deadlines: [],
            daysUntilPrimary: 9999,
            remainingTime: {
              'days': 0,
              'hours': 0,
              'minutes': 0,
              'total_hours': 0,
            },
            urgencyScore: 0,
          );
        }
      }

      if (allDates.isEmpty) {
        return DeadlineDetectionResult(
          hasDeadline: false,
          deadlines: [],
          daysUntilPrimary: 9999,
          remainingTime: {
            'days': 0,
            'hours': 0,
            'minutes': 0,
            'total_hours': 0,
          },
          urgencyScore: 0,
        );
      }

      // Find primary deadline (earliest future date)
      final now = DateTime.now();
      DateTime? primaryDeadline;
      String? primaryDeadlineText;

      for (final date in allDates) {
        if (date.isAfter(now)) {
          if (primaryDeadline == null || date.isBefore(primaryDeadline)) {
            primaryDeadline = date;
          }
        }
      }

      // If no future date, use earliest overall
      if (primaryDeadline == null && allDates.isNotEmpty) {
        primaryDeadline = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
        // Extract the text representation
        primaryDeadlineText = _findDeadlineText(text, primaryDeadline);
      } else {
        primaryDeadlineText = _findDeadlineText(text, primaryDeadline);
      }

      final daysUntil = primaryDeadline != null
          ? primaryDeadline.difference(now).inDays
          : 9999;

      final remainingTime = primaryDeadline != null
          ? calculateRemainingTime(primaryDeadline)
          : {'days': 0, 'hours': 0, 'minutes': 0, 'total_hours': 0};

      final urgency = calculateUrgency(text, primaryDeadline);
      final reminderMap = primaryDeadline != null
          ? generateReminder(primaryDeadline, primaryDeadlineText ?? 'Deadline')
          : null;

      return DeadlineDetectionResult(
        hasDeadline: true,
        deadlines: allDates,
        primaryDeadline: primaryDeadline,
        primaryDeadlineText: primaryDeadlineText,
        daysUntilPrimary: daysUntil,
        remainingTime: remainingTime,
        urgencyScore: urgency,
        reminder: reminderMap,
      );
    } catch (e) {
      debugPrint('Error in detectDeadlines: $e');
      return DeadlineDetectionResult(
        hasDeadline: false,
        deadlines: [],
        daysUntilPrimary: 9999,
        remainingTime: {'days': 0, 'hours': 0, 'minutes': 0, 'total_hours': 0},
        urgencyScore: 0,
      );
    }
  }

  /// Extract all dates from text
  List<DateTime> _extractDates(String text) {
    final dates = <DateTime>[];

    try {
      // Pattern 1: DD/MM/YYYY or DD-MM-YYYY
      for (final match in _datePattern1.allMatches(text)) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);

          // Try DD/MM/YYYY first
          if (day <= 31 && month <= 12) {
            final date = DateTime(year, month, day);
            dates.add(date);
          } else if (day <= 12 && month <= 31) {
            // Try MM/DD/YYYY
            final date = DateTime(year, day, month);
            dates.add(date);
          }
        } catch (e) {
          // Skip invalid date
        }
      }

      // Pattern 2: "January 5, 2024" or "Jan 5 2024"
      for (final match in _datePattern2.allMatches(text)) {
        try {
          final monthStr = match.group(1)!.toLowerCase();
          final month = _monthNames[monthStr];
          if (month != null) {
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            if (day >= 1 && day <= 31) {
              final date = DateTime(year, month, day);
              dates.add(date);
            }
          }
        } catch (e) {
          // Skip
        }
      }

      // Pattern 3: "January 5" (assume current or next year)
      for (final match in _datePattern3.allMatches(text)) {
        try {
          final monthStr = match.group(1)!.toLowerCase();
          final month = _monthNames[monthStr];
          if (month != null) {
            final day = int.parse(match.group(2)!);
            if (day >= 1 && day <= 31) {
              final now = DateTime.now();
              var year = now.year;
              var date = DateTime(year, month, day);

              // If date is in the past, assume next year
              if (date.isBefore(now)) {
                year++;
                date = DateTime(year, month, day);
              }
              dates.add(date);
            }
          }
        } catch (e) {
          // Skip
        }
      }

      return dates;
    } catch (e) {
      debugPrint('Error extracting dates: $e');
      return [];
    }
  }

  /// Find the actual deadline text in the original text
  String? _findDeadlineText(String text, DateTime? deadline) {
    if (deadline == null) return null;

    try {
      // Look for date patterns near deadline keywords
      final lowerText = text.toLowerCase();
      final keywords = _deadlineKeywordPattern.allMatches(lowerText);

      for (final keywordMatch in keywords) {
        final start = (keywordMatch.start - 50).clamp(0, text.length);
        final end = (keywordMatch.end + 100).clamp(0, text.length);
        final snippet = text.substring(start, end);

        // Check if deadline date appears in this snippet
        if (snippet.contains(deadline.day.toString()) &&
            (snippet.contains(
                  _monthNames.entries
                      .firstWhere((e) => e.value == deadline.month)
                      .key,
                ) ||
                snippet.contains(deadline.month.toString()))) {
          return snippet.trim();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate remaining time from deadline to now
  Map<String, int> calculateRemainingTime(DateTime deadline) {
    try {
      final now = DateTime.now();
      final diff = deadline.difference(now);
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final totalHours = diff.inHours;
      final isOverdue = diff.isNegative;

      return {
        'days': isOverdue ? -(days.abs()) : days,
        'hours': hours,
        'minutes': minutes,
        'total_hours': isOverdue ? -(totalHours.abs()) : totalHours,
        'is_overdue': isOverdue ? 1 : 0,
      };
    } catch (e) {
      return {
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'total_hours': 0,
        'is_overdue': 0,
      };
    }
  }

  /// Calculate urgency score (0-10 scale)
  int calculateUrgency(String text, [DateTime? deadlineDate]) {
    try {
      int score = 0;

      // Check urgency keywords (each adds 1 point, max 3)
      final urgencyMatches = _urgencyKeywordPattern.allMatches(
        text.toLowerCase(),
      );
      score += (urgencyMatches.length * 1).clamp(0, 3);

      // Check action verbs (each adds 1 point, max 2)
      final actionMatches = _actionVerbPattern.allMatches(text.toLowerCase());
      score += (actionMatches.length * 1).clamp(0, 2);

      // Days until deadline scoring
      if (deadlineDate != null) {
        final now = DateTime.now();
        final daysUntil = deadlineDate.difference(now).inDays;

        if (daysUntil < 0) {
          score += 3; // Overdue
        } else if (daysUntil <= 1) {
          score += 3; // Tomorrow or today
        } else if (daysUntil <= 3) {
          score += 2; // This week
        } else if (daysUntil <= 7) {
          score += 1; // Next week
        }
      }

      return score.clamp(0, 10);
    } catch (e) {
      return 0;
    }
  }

  /// Generate reminder metadata
  Map<String, dynamic> generateReminder(
    DateTime deadlineDate,
    String deadlineText,
  ) {
    try {
      final remaining = calculateRemainingTime(deadlineDate);
      final daysUntil = remaining['days'] ?? 0;
      final totalHours = remaining['total_hours'] ?? 0;
      final isOverdue = daysUntil < 0;

      String reminderMessage = '';
      String reminderType = 'info';
      int priority = 3;

      if (isOverdue) {
        reminderType = 'critical';
        priority = 1;
        reminderMessage =
            'OVERDUE: This deadline was ${daysUntil.abs()} days ago. Immediate action required!';
      } else if (daysUntil == 0) {
        reminderType = 'critical';
        priority = 1;
        reminderMessage =
            'TODAY: Deadline is today. $totalHours hours remaining.';
      } else if (daysUntil == 1) {
        reminderType = 'urgent';
        priority = 2;
        reminderMessage =
            'TOMORROW: Deadline is tomorrow. Less than 24 hours remaining.';
      } else if (daysUntil <= 3) {
        reminderType = 'warning';
        priority = 2;
        reminderMessage =
            'COMING UP: Deadline in $daysUntil days. ${remaining['hours']} hours remaining.';
      } else {
        reminderType = 'info';
        priority = 3;
        reminderMessage = 'Upcoming deadline in $daysUntil days.';
      }

      return {
        'should_remind': daysUntil <= 3,
        'reminder_type': reminderType,
        'message': reminderMessage,
        'priority': priority,
        'remaining': remaining,
      };
    } catch (e) {
      return {
        'should_remind': false,
        'reminder_type': 'info',
        'message': 'Deadline reminder',
        'priority': 3,
        'remaining': {'days': 0, 'hours': 0, 'minutes': 0},
      };
    }
  }
}
