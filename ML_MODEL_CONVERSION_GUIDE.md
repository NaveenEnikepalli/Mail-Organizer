"""
ML Model Conversion Guide for mail_mind Priority Classifier
============================================================

This document provides step-by-step instructions to convert the priority_classifier.pkl
(scikit-learn model) to TensorFlow Lite (.tflite) format for on-device inference in Flutter.

PREREQUISITES:
- Python 3.7+
- pip install tensorflow>=2.11.0
- pip install scikit-learn
- pip install skl2onnx
- pip install onnx
- pip install onnxconverter-common
- pip install onnx-tf (optional, for ONNX to SavedModel conversion)

STEP 1: Load and Convert sklearn model to ONNX
================================================

import joblib
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

# Load the sklearn model
model = joblib.load('priority_classifier.pkl')

# Determine number of features (inspect your model)
# Typically from feature extraction: subject tokens + snippet tokens + sender features
# For example: 128 features
num_features = 128

# Define input type for ONNX
initial_type = [('input', FloatTensorType([None, num_features]))]

# Convert to ONNX
onnx_model = convert_sklearn(model, initial_types=initial_type)

# Save ONNX model
with open('priority_classifier.onnx', 'wb') as f:
    f.write(onnx_model.SerializeToString())

print("✓ ONNX model saved: priority_classifier.onnx")


STEP 2: Convert ONNX to TensorFlow SavedModel
==============================================

Option A: Using tf2onnx (if model is TensorFlow originally):
pip install tf2onnx

Option B: Using onnx-tf (for pure ONNX -> SavedModel):
pip install onnx-tf

import onnx
from onnxruntime import inference_session
import tensorflow as tf
import onnx_tf.backend

# Load ONNX model
onnx_model = onnx.load('priority_classifier.onnx')

# Convert to TensorFlow
tf_rep = onnx_tf.backend.prepare(onnx_model)

# Save as SavedModel
tf_rep.export_graph('priority_classifier_savedmodel')

print("✓ SavedModel saved: priority_classifier_savedmodel/")


STEP 3: Convert SavedModel to TFLite
====================================

import tensorflow as tf

# Load SavedModel
converter = tf.lite.TFLiteConverter.from_saved_model('priority_classifier_savedmodel')

# Optional: Enable optimizations
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS,
]

# Convert to TFLite
tflite_model = converter.convert()

# Save TFLite model
with open('priority_classifier.tflite', 'wb') as f:
    f.write(tflite_model)

print("✓ TFLite model saved: priority_classifier.tflite")


STEP 4: Copy TFLite to Flutter Project
======================================

1. Create assets/models directory in your Flutter project (if not exists):
   mkdir -p assets/models

2. Copy the .tflite file:
   cp priority_classifier.tflite /path/to/mail_mind/assets/models/

3. Update pubspec.yaml:
   assets:
     - assets/models/priority_classifier.tflite

4. Rebuild Flutter app:
   flutter clean
   flutter pub get
   flutter run


ALTERNATIVE: If Model Conversion Fails
======================================

If you encounter issues during conversion, the fallback classifier will activate:
- The app will automatically use the built-in deterministic classifier
- Priority classification will still work offline
- No model file required for basic functionality

To debug:
1. Check priority_classifier.dart logs for initialization errors
2. Verify .tflite file exists at assets/models/priority_classifier.tflite
3. Ensure pubspec.yaml includes the assets entry


INTEGRATION IN FLUTTER
======================

The PriorityClassifier class in lib/core/priority_classifier.dart will:
1. Attempt to load priority_classifier.tflite from assets
2. Fall back to deterministic classifier if loading fails
3. Use the classifier for email priority scoring


PERFORMANCE NOTES
=================

TFLite Model Advantages:
- Faster inference than fallback classifier
- More accurate predictions
- Lightweight (typically 1-5MB)
- Works completely offline

Fallback Classifier:
- Works without any model file
- Keyword and rule-based (no ML)
- Instant results
- Sufficient for basic priority classification


TROUBLESHOOTING
===============

Issue: "Only one file in the asset directory"
Solution: Ensure assets/ directory exists and pubspec.yaml is updated

Issue: Model too large (>20MB)
Solution: Enable TFLite quantization in Step 3:
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]

Issue: ONNX conversion fails
Solution: Check sklearn model compatibility and ensure correct feature count


FEATURE EXTRACTION (For TFLite Input)
====================================

The TFLite model expects a fixed-size vector. In priority_classifier.dart,
implement feature extraction similar to this:

List<double> extractFeatures(EmailMetadata email) {
  // Example: bag-of-words with fixed vocabulary
  final text = '${email.subject} ${email.snippet}'.toLowerCase();
  final vocab = ['deadline', 'urgent', 'meeting', ...]; // Fixed vocab
  
  final features = <double>[];
  for (final word in vocab) {
    features.add(text.contains(word) ? 1.0 : 0.0);
  }
  
  // Ensure fixed size (pad or truncate)
  while (features.length < 128) features.add(0.0);
  return features.sublist(0, 128);
}

# Then run inference:
final features = extractFeatures(email);
final input = [features]; // Batch size 1
final output = interpreter.run(input);
final priority = output[0][0] as double; // Assuming single output


NEXT STEPS
==========

1. Run conversion steps 1-3 above
2. Copy priority_classifier.tflite to assets/models/
3. Update pubspec.yaml with assets entry
4. Run: flutter clean && flutter pub get && flutter run
5. App will auto-detect and load the TFLite model on next startup

For more info on TFLite in Flutter, see:
https://github.com/google/flutter-tflite

"""

print(__doc__)
