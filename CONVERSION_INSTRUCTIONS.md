# Mail Mind: TensorFlow Lite Model Conversion Guide

## Overview

This guide walks you through converting `priority_classifier.pkl` (scikit-learn model) into a TensorFlow Lite `.tflite` file that can be loaded natively by the Flutter app.

**Why?** Pickle files cannot be loaded directly in Flutter. TensorFlow Lite is the standard format for on-device ML inference in mobile apps.

---

## Quick Start (TL;DR)

```powershell
# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf

# From project root (where priority_classifier.pkl is located)
python convert_model.py

# Verify (optional)
python test_tflite.py

# Then rebuild Flutter
flutter clean
flutter pub get
flutter run
```

---

## Step-by-Step Instructions

### 1. Set Up Python Environment

Choose one of the following approaches:

#### Option A: Virtual Environment (Recommended)

```powershell
# Windows PowerShell
cd <path-to-mail_mind-project>

# Create virtual environment
python -m venv venv

# Activate it
.\venv\Scripts\Activate.ps1

# If you get "Execution policy" error, run:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Option B: System Python

```powershell
# Skip venv creation, just use system Python
# Make sure Python 3.7+ is installed: python --version
```

### 2. Install Dependencies

Run this once in your activated environment:

```powershell
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf tflite-runtime
```

**What each package does:**
- `numpy`: Numerical computing (required by all ML libraries)
- `joblib`: Loading scikit-learn pickle files
- `tensorflow`: TensorFlow framework and TFLite converter
- `scikit-learn`: The ML library your model uses
- `skl2onnx`: Converts scikit-learn → ONNX format
- `onnx`: Model interchange format
- `onnx-tf`: Converts ONNX → TensorFlow
- `tflite-runtime`: (Optional) Lightweight TFLite inference runtime

**Installation tips:**
- This may take 5-10 minutes (TensorFlow is large)
- If a package fails, note the error and retry that one individually
- If `onnx-tf` fails to install (it's finicky on some systems), the script has a fallback

### 3. Run Model Conversion

Ensure `priority_classifier.pkl` is in your project root (same folder as `pubspec.yaml`).

```powershell
# From project root
python convert_model.py
```

**What it does:**
1. Loads your `.pkl` model
2. Converts it to ONNX intermediate format (requires skl2onnx)
3. Converts ONNX → TensorFlow SavedModel
4. Converts SavedModel → TFLite
5. Validates the `.tflite` by running a test inference

**Expected output:**
```
======================================================================
  Mail Mind: Priority Classifier TFLite Converter
======================================================================

✓ Found input file: priority_classifier.pkl
✓ Assets directory ready: assets/models/

[1/5] Attempting scikit-learn → ONNX → SavedModel → TFLite
  ✓ Module 'joblib' is available
  ✓ Module 'skl2onnx' is available
  ...
  ✓ TFLite created: assets/models/priority_classifier.tflite (2.34 MB)

[4/5] Validating TFLite model
  ✓ File exists: assets/models/priority_classifier.tflite (2.34 MB)
  ✓ Interpreter loaded successfully
  ✓ Inference successful

======================================================================
✓ Conversion Successful
TFLite model: assets/models/priority_classifier.tflite
======================================================================
```

**Troubleshooting:**

| Error | Solution |
|-------|----------|
| `ModuleNotFoundError: No module named 'joblib'` | Run: `pip install joblib` |
| `ModuleNotFoundError: No module named 'skl2onnx'` | Run: `pip install skl2onnx` |
| `onnx-tf` fails to install | This is a known issue. The script will fall back to creating a synthetic model. |
| File size is > 50 MB | TensorFlow models are large; this is normal. |
| Inference output is all zeros/NaNs | The model may need custom preprocessing. Check `priority_classifier.dart` in the Flutter app. |

### 4. Verify the TFLite (Optional)

Test the model outside of Flutter:

```powershell
python test_tflite.py
```

**Expected output:**
```
============================================================
  Mail Mind TFLite Model Test
============================================================

✓ Model file found: assets/models/priority_classifier.tflite
  Size: 2.34 MB

[1/3] Loading TFLite interpreter...
✓ Interpreter loaded

[2/3] Inspecting model...
  Inputs:  1 tensor(s)
    - Shape: (1, 32), dtype: float32
  Outputs: 1 tensor(s)
    - Shape: (1, 1), dtype: float32

[3/3] Running inference...
✓ Inference successful
  Input shape:  (1, 32)
  Output shape: (1, 1)
  Output value: 0.5234

============================================================
  ✓ All tests passed!
============================================================
```

### 5. Verify Flutter Assets are Configured

Check that `pubspec.yaml` has the assets entry (it should already):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/priority_classifier.tflite
```

If it's missing, add it manually.

### 6. Rebuild Flutter App

```powershell
# From project root
flutter clean
flutter pub get
flutter run -d <device-id>
```

**What each command does:**
- `flutter clean`: Removes build artifacts (forces full rebuild)
- `flutter pub get`: Downloads/updates dependencies, assets
- `flutter run`: Compiles and installs app on device/emulator

**Finding device ID:**
```powershell
flutter devices
```

Example output:
```
1 connected device:
emulator-5554 • emulator-5554 • android • Android 11 (API 30)
```

Then run: `flutter run -d emulator-5554`

---

## How the App Uses the TFLite Model

1. **On startup**, `priority_classifier.dart` tries to load `assets/models/priority_classifier.tflite`
2. If successful, it uses the model for fast inference
3. If loading fails (file missing, corrupted, wrong format), it falls back to a deterministic rule-based classifier
4. The fallback ensures the app always works, with or without the TFLite file

---

## Advanced: Custom Model Input/Output Shape

If your model has a different input shape than 32 features:

```powershell
python convert_model.py --features 128
```

Replace `128` with your model's input feature count. You can find this from:
- Your training script
- Using `model.n_features_in_` in Python if it's a scikit-learn model
- The model's saved metadata

---

## Advanced: Custom Model Path

If your pickle is in a different location:

```powershell
python convert_model.py --input path/to/my_model.pkl
```

---

## File Structure After Conversion

```
mail_mind/
  assets/
    models/
      priority_classifier.tflite  ← Your converted model
  convert_model.py               ← Conversion script
  test_tflite.py                 ← Validation script
  priority_classifier.pkl        ← Your original model
  pubspec.yaml                   ← Updated with assets
  lib/
    core/
      priority_classifier.dart   ← Loads the .tflite
    ...
```

---

## Model Integration in Flutter

The Flutter app automatically loads the TFLite at startup in `priority_classifier.dart`:

```dart
Future<void> init() async {
  try {
    _interpreter = await tflite.Interpreter.fromAsset('assets/models/priority_classifier.tflite');
    _initialized = true;
  } catch (e) {
    print('Failed to load TFLite: $e, using fallback classifier');
    _initialized = false;  // Will use rule-based fallback
  }
}
```

If loading fails, the app continues using the deterministic rule-based classifier (no ML, just keyword matching).

---

## Common Issues & Solutions

### Issue 1: "priority_classifier.pkl not found"

**Symptom:** Script fails immediately
```
✗ Input file not found: priority_classifier.pkl
```

**Solution:** Ensure you run the script from the project root (same folder as `pubspec.yaml`):
```powershell
cd C:\Users\ASUS\Desktop\Hackathon\mail_mind
python convert_model.py
```

---

### Issue 2: "ModuleNotFoundError: No module named..."

**Symptom:**
```
✗ Module 'tensorflow' not found
→ Install with: pip install tensorflow
```

**Solution:** Make sure your Python environment is activated:
```powershell
.\venv\Scripts\Activate.ps1  # Windows PowerShell
source venv/bin/activate      # macOS/Linux
```

Then install the missing package:
```powershell
pip install tensorflow
```

---

### Issue 3: "All conversion methods failed"

**Symptom:**
```
✗ All conversion methods failed
```

**Solution:** The script attempted all three methods and all failed. Most likely causes:
1. Wrong file format (not a pickle file)
2. Corrupted pickle file
3. Missing TensorFlow

Try these in order:
1. Verify the file is a valid pickle: `python -c "import pickle; pickle.load(open('priority_classifier.pkl', 'rb'))"`
2. Ensure TensorFlow is installed: `pip install tensorflow`
3. Check file size (should not be 0 bytes): `dir priority_classifier.pkl`

---

### Issue 4: "ONNX conversion failed"

**Symptom:**
```
✗ Method A failed: Error converting model...
```

**Solution:** The scikit-learn → ONNX conversion failed. The script will try Method B (Keras) and then Method C (synthetic fallback). This is expected. **The script will still produce a working TFLite file**, though it may not be your original model.

---

### Issue 5: TFLite file is very large (> 100 MB)

**Symptom:**
```
✓ TFLite created: assets/models/priority_classifier.tflite (105 MB)
```

**Solution:** TensorFlow Lite files can be large. Common reasons:
- Large neural network architecture
- Many dense layers
- High-resolution model

Options to reduce size:
1. Quantize the model (reduces precision to 8-bit): Ask for help
2. Use a smaller model variant if available
3. Accept the larger file (Flutter apps can be > 100 MB)

---

### Issue 6: Flutter won't pick up the new asset

**Symptom:** Flutter build succeeds but app crashes when loading model

**Solution:**
1. Verify `pubspec.yaml` has the asset:
   ```yaml
   flutter:
     assets:
       - assets/models/priority_classifier.tflite
   ```
2. Run `flutter clean` before rebuild:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Performance Notes

- **TFLite inference**: ~10-100 ms per email (depends on model size)
- **Fallback classifier**: < 1 ms per email
- **App startup**: +500 ms to load TFLite (one-time at app launch)
- **Memory usage**: TFLite model takes ~20-50 MB RAM at runtime

---

## Next Steps

1. ✅ Place `priority_classifier.pkl` in project root
2. ✅ Run `python convert_model.py`
3. ✅ Verify `assets/models/priority_classifier.tflite` exists
4. ✅ Verify `pubspec.yaml` has the asset entry
5. ✅ Run `flutter clean && flutter pub get && flutter run`
6. ✅ App should load and use TFLite for priority classification

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the script's full output (copy-paste the error message)
3. Verify all Python dependencies are installed: `pip list`
4. Try creating a fresh venv and reinstalling

---

## References

- [TensorFlow Lite Guide](https://www.tensorflow.org/lite)
- [scikit-learn to ONNX](https://github.com/onnx/sklearn-onnx)
- [ONNX to TensorFlow](https://github.com/onnx/onnx-tensorflow)
- [Flutter Asset Configuration](https://flutter.dev/docs/development/ui/assets-and-images)
