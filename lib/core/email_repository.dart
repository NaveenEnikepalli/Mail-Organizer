import 'package:flutter/foundation.dart';
import 'gmail_api_service.dart';
import 'email_local_storage.dart';
import 'email_metadata.dart';
import 'priority_classifier.dart';
import 'priority_store.dart';
import 'deadline_detector.dart';
import 'deadline_store.dart';

class EmailWithPriority {
  final EmailMetadata email;
  final int score;
  final String label;
  final bool manualOverride;
  final String? manualLabel;
  final DateTime? storedAt;

  EmailWithPriority({
    required this.email,
    required this.score,
    required this.label,
    this.manualOverride = false,
    this.manualLabel,
    this.storedAt,
  });

  // For display, use manual label if overridden
  String get displayLabel => manualOverride ? (manualLabel ?? label) : label;
  int get displayScore => score;
  bool get isHighPriority => displayLabel == 'High';
  bool get isMediumPriority => displayLabel == 'Medium';
  bool get isLowPriority => displayLabel == 'Low';
}

class EmailRepository {
  final GmailApiService gmailApiService;
  final EmailLocalStorage localStorage;

  EmailRepository({required this.gmailApiService, required this.localStorage});

  Future<List<EmailMetadata>> loadEmailsFromLocal() async {
    try {
      return await localStorage.loadEmails();
    } catch (e) {
      debugPrint('Error loading emails from local storage: $e');
      return [];
    }
  }

  Future<List<EmailMetadata>> syncEmailsFromRemote(
    Map<String, String> authHeaders,
  ) async {
    try {
      final emails = await gmailApiService.fetchInboxEmails(authHeaders);
      await localStorage.saveEmails(emails);
      return emails;
    } catch (e) {
      debugPrint('Error syncing emails from remote: $e');
      rethrow;
    }
  }

  Future<List<EmailMetadata>> syncSpamFromRemote(
    Map<String, String> authHeaders, {
    int maxResults = 50,
  }) async {
    try {
      debugPrint('🚨 Fetching spam from Gmail API...');
      final fetchedSpam = await gmailApiService.fetchSpamEmails(
        authHeaders,
        maxResults: maxResults,
      );
      debugPrint('🚨 Got ${fetchedSpam.length} spam emails from API');
      for (
        var i = 0;
        i < (fetchedSpam.length < 3 ? fetchedSpam.length : 3);
        i++
      ) {
        debugPrint(
          '  Email ${i + 1}: ${fetchedSpam[i].subject}, labels=${fetchedSpam[i].labels}',
        );
      }

      // Load existing emails to preserve them
      final existing = await localStorage.loadEmails();

      // Create a map to deduplicate and merge
      final byId = <String, EmailMetadata>{for (var e in existing) e.id: e};

      // Add/overwrite with fetched spam emails
      for (var spamEmail in fetchedSpam) {
        byId[spamEmail.id] = spamEmail;
      }

      // Save merged list
      await localStorage.saveEmails(byId.values.toList());
      debugPrint('🚨 Saved ${byId.length} total emails to storage');

      return fetchedSpam;
    } catch (e) {
      debugPrint('Error syncing spam from remote: $e');
      rethrow;
    }
  }

  Future<List<EmailMetadata>> loadSpamFromLocal() async {
    try {
      final allEmails = await localStorage.loadEmails();
      debugPrint(
        '🚨 Loading spam from local - total emails: ${allEmails.length}',
      );
      // Filter for emails with SPAM label
      final spamEmails = allEmails.where((email) {
        final hasSpam = email.labels.any(
          (label) => label.toUpperCase() == 'SPAM',
        );
        if (!hasSpam && allEmails.indexOf(email) < 3) {
          // Show first 3 emails' labels for debugging
          debugPrint('  ${email.subject}: labels=${email.labels}');
        }
        if (hasSpam) {
          debugPrint('  ✓ ${email.subject} has SPAM label');
        }
        return hasSpam;
      }).toList();
      debugPrint('🚨 Found ${spamEmails.length} spam emails');
      return spamEmails;
    } catch (e) {
      debugPrint('Error loading spam from local storage: $e');
      return [];
    }
  }

  Future<List<EmailWithPriority>> computeAndStorePriorities(
    List<EmailMetadata> emails,
    PriorityClassifier classifier,
    PriorityStore store,
  ) async {
    try {
      final result = <EmailWithPriority>[];

      for (final email in emails) {
        try {
          // Check if there's a stored manual override
          final storedPriority = await store.loadPriority(email.id);

          if (storedPriority != null &&
              storedPriority['manualOverride'] == true) {
            // Use manual override
            final score = storedPriority['score'] as int? ?? 50;
            final label = storedPriority['manualLabel'] as String? ?? 'Medium';
            result.add(
              EmailWithPriority(
                email: email,
                score: score,
                label: label,
                manualOverride: true,
                manualLabel: label,
                storedAt: storedPriority['timestamp'] != null
                    ? DateTime.tryParse(storedPriority['timestamp'] as String)
                    : null,
              ),
            );
          } else {
            // Compute priority using classifier
            final score = await classifier.predictPriority(email);
            final label = await classifier.predictLabel(email);

            // Save to store
            await store.savePriority(email.id, score, label);

            result.add(
              EmailWithPriority(
                email: email,
                score: score,
                label: label,
                manualOverride: false,
                storedAt: DateTime.now(),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error computing priority for email ${email.id}: $e');
          // Default to medium priority
          result.add(
            EmailWithPriority(
              email: email,
              score: 50,
              label: 'Medium',
              manualOverride: false,
            ),
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error in computeAndStorePriorities: $e');
      return emails
          .map((e) => EmailWithPriority(email: e, score: 50, label: 'Medium'))
          .toList();
    }
  }

  /// Analyze emails for deadlines and store metadata
  Future<List<String>> analyzeAndStoreDeadlinesForEmails(
    List<EmailMetadata> emails,
    DeadlineDetectorDart detector,
    DeadlineStore store,
  ) async {
    try {
      debugPrint('🔍 Starting deadline analysis for ${emails.length} emails');
      final deadlineMessageIds = <String>[];

      for (final email in emails) {
        try {
          // Combine subject and snippet for analysis
          final textToAnalyze = '${email.subject}\n${email.snippet}';

          // Detect deadlines
          final detection = detector.detectDeadlines(textToAnalyze);
          final preview = textToAnalyze.substring(
            0,
            (textToAnalyze.length < 80 ? textToAnalyze.length : 80),
          );
          debugPrint('  Subject: ${email.subject}');
          debugPrint(
            '    hasDeadline: ${detection.hasDeadline}, preview: $preview...',
          );

          // Save metadata
          await store.saveDeadlineMetadata(email.id, detection);

          if (detection.hasDeadline) {
            deadlineMessageIds.add(email.id);
          }
        } catch (e) {
          debugPrint('Error analyzing deadline for email ${email.id}: $e');
        }
      }

      return deadlineMessageIds;
    } catch (e) {
      debugPrint('Error in analyzeAndStoreDeadlinesForEmails: $e');
      return [];
    }
  }
}
