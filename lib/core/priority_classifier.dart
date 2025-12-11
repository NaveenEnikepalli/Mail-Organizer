// IMPORTANT: You cannot use .pkl directly in Flutter. Convert priority_classifier.pkl to TF Lite:
//
// Example (Python) conversion steps (developer runs on PC):
//   1) Load sklearn model and export to ONNX (if sklearn):
//      - pip install skl2onnx onnx onnxconverter-common
//      - python:
//           from skl2onnx import convert_sklearn
//           from skl2onnx.common.data_types import FloatTensorType
//           model = joblib.load('priority_classifier.pkl')
//           initial_type = [('input', FloatTensorType([None, N]))]  # N = number of features you design
//           onnx_model = convert_sklearn(model, initial_types=initial_type)
//           with open('priority_classifier.onnx','wb') as f: f.write(onnx_model.SerializeToString())
//   2) Convert ONNX to TensorFlow SavedModel or TFLite via tf2onnx / onnx-tf / or re-train equivalent model in TF Keras.
//   3) Convert SavedModel to TFLite:
//           converter = tf.lite.TFLiteConverter.from_saved_model('saved_model_dir')
//           tflite_model = converter.convert()
//           open('priority_classifier.tflite','wb').write(tflite_model)
//   4) Place 'priority_classifier.tflite' in project assets folder and add to pubspec.yaml assets.
//
// If conversion is not possible, the app will use the built-in fallback classifier automatically.

import 'package:flutter/foundation.dart';
import 'email_metadata.dart';

class PriorityClassifier {
  final String? tfliteAssetPath;
  bool useFallback = false;
  dynamic _interpreter;

  // Configuration
  static const List<String> _highPriorityKeywords = [
    // Urgency indicators
    'deadline',
    'due',
    'submit',
    'by',
    'important',
    'urgent',
    'asap',
    'immediately',
    'now',
    'critical',
    'high priority',
    // Professional/formal
    'interview',
    'offer',
    'job',
    'contract',
    'agreement',
    'approved',
    'rejected',
    'confirmation',
    'alert',
    'action required',
    // Meetings and calls
    'call',
    'meeting',
    'scheduled',
    'appointment',
    'conference',
    'presentation',
    // Financial/Important
    'invoice',
    'receipt',
    'payment',
    'refund',
    'transaction',
    'amount',
    'bill',
    'salary',
    'bonus',
    'promotion',
    // Personal/Urgent
    'emergency',
    'urgent help needed',
    'important news',
  ];

  static const List<String> _lowPriorityKeywords = [
    // Marketing/Promotional
    'newsletter',
    'unsubscribe',
    'promotional',
    'sale',
    'discount',
    'coupon',
    'deal',
    'limited time',
    'click here',
    'offer ends',
    'special offer',
    'save now',
    'exclusive offer',
    // Social/Casual
    'follow us',
    'like us',
    'share this',
    'viral',
    'trending',
    'check this out',
    // Notifications (generic)
    'notification',
    'you have',
    'new message',
    'friend request',
    'comment on your',
    'liked your',
    // Mass emails
    'mass email',
    'sent to many',
    'batch',
    'bulk',
  ];

  static const List<String> _trustedDomains = [
    // Corporate
    'gmail.com',
    'outlook.com',
    'company.com',
    'corporate.com',
    // Educational
    'edu',
    'university.edu',
    'college.edu',
    'school.edu',
    // Government
    'gov',
    'government',
    'official',
    // Major tech companies
    'google.com',
    'microsoft.com',
    'apple.com',
    'amazon.com',
    'facebook.com',
    'linkedin.com',
    // Financial
    'bank.com',
    'icici.com',
    'hdfc.com',
    'sbi.co.in',
    'axis.com',
  ];

  PriorityClassifier({this.tfliteAssetPath});

  Future<void> init() async {
    try {
      if (tfliteAssetPath != null && tfliteAssetPath!.isNotEmpty) {
        // Try to load TFLite model (stub - will be enhanced when tflite_flutter is integrated)
        debugPrint('TFLite model path: $tfliteAssetPath');
        // TODO: Implement TFLite loading when tflite_flutter is available
        // For now, use fallback
        useFallback = true;
      } else {
        useFallback = true;
        debugPrint('Using fallback priority classifier (no TFLite model)');
      }
    } catch (e) {
      debugPrint(
        'Failed to initialize TFLite model: $e. Using fallback classifier.',
      );
      useFallback = true;
    }
  }

  Future<int> predictPriority(EmailMetadata email) async {
    try {
      if (useFallback) {
        return _fallbackClassifier(email);
      }
      // TFLite inference would go here
      return _fallbackClassifier(email);
    } catch (e) {
      debugPrint('Error in predictPriority: $e');
      return 50; // Default medium priority
    }
  }

  Future<String> predictLabel(EmailMetadata email) async {
    final score = await predictPriority(email);
    if (score >= 70) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  int _fallbackClassifier(EmailMetadata email) {
    int score = 50; // Start at medium

    final combinedText = '${email.subject} ${email.snippet}'.toLowerCase();

    // Check for important label
    if (email.labels.any(
      (label) =>
          label.toUpperCase() == 'IMPORTANT' ||
          label.toUpperCase() == 'STARRED',
    )) {
      score += 35;
    }

    // Check sender reputation
    final senderDomain = _extractDomain(email.from);
    if (_isTrustedDomain(senderDomain)) {
      score += 20;
    }

    // Check for high-priority keywords
    for (final keyword in _highPriorityKeywords) {
      if (combinedText.contains(keyword)) {
        score += 20;
      }
    }

    // Check for low-priority keywords (deduct points)
    for (final keyword in _lowPriorityKeywords) {
      if (combinedText.contains(keyword)) {
        score -= 15;
      }
    }

    // Check for dates/times (simple heuristic)
    if (combinedText.contains(RegExp(r'\d{1,2}[/-]\d{1,2}')) ||
        combinedText.contains(RegExp(r'tomorrow|today|next week'))) {
      score += 15;
    }

    // Normalize to 0-100
    return (score).clamp(0, 100);
  }

  Map<String, dynamic> explainPrediction(EmailMetadata email) {
    final score = _fallbackClassifier(email);
    final label = score >= 70 ? 'High' : (score >= 40 ? 'Medium' : 'Low');
    final reasons = <String>[];

    final combinedText = '${email.subject} ${email.snippet}'.toLowerCase();

    if (email.labels.any(
      (label) =>
          label.toUpperCase() == 'IMPORTANT' ||
          label.toUpperCase() == 'STARRED',
    )) {
      reasons.add('Marked as IMPORTANT or STARRED (+35)');
    }

    final senderDomain = _extractDomain(email.from);
    if (_isTrustedDomain(senderDomain)) {
      reasons.add('From trusted domain: $senderDomain (+20)');
    }

    for (final keyword in _highPriorityKeywords) {
      if (combinedText.contains(keyword)) {
        reasons.add('Contains "$keyword" (+20)');
      }
    }

    for (final keyword in _lowPriorityKeywords) {
      if (combinedText.contains(keyword)) {
        reasons.add('Contains promotional keyword "$keyword" (-15)');
      }
    }

    if (combinedText.contains(RegExp(r'\d{1,2}[/-]\d{1,2}')) ||
        combinedText.contains(RegExp(r'tomorrow|today|next week'))) {
      reasons.add('Contains date/time reference (+15)');
    }

    if (reasons.isEmpty) {
      reasons.add('Standard email');
    }

    return {'score': score, 'label': label, 'reasons': reasons};
  }

  String _extractDomain(String email) {
    try {
      if (email.contains('@')) {
        return email.split('@')[1].split('>')[0].toLowerCase();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  bool _isTrustedDomain(String domain) {
    for (final trusted in _trustedDomains) {
      if (domain.contains(trusted)) {
        return true;
      }
    }
    return false;
  }

  Future<void> dispose() async {
    try {
      if (_interpreter != null) {
        // TODO: Dispose TFLite interpreter when implemented
      }
    } catch (e) {
      debugPrint('Error disposing classifier: $e');
    }
  }
}
