# Quick Commands: TFLite Conversion Workflow

## Windows PowerShell

### 1. Set Up (First Time Only)

```powershell
# Navigate to project
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"

# Create Python virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# If you get execution policy error:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install dependencies (takes ~5 min)
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf

# Verify installation
python -c "import tensorflow; print('TensorFlow OK')"
```

### 2. Convert Model (Every Time You Update .pkl)

```powershell
# Make sure you're in venv
# (Look for (venv) in your PowerShell prompt)

# Navigate to project root
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"

# Run conversion
python convert_model.py

# Expected output:
# ✓ Conversion Successful
# TFLite model: assets/models/priority_classifier.tflite
```

### 3. Verify Model (Optional)

```powershell
# Test the TFLite file
python test_tflite.py

# Expected output:
# ✓ All tests passed!
```

### 4. Rebuild Flutter

```powershell
# Navigate to project root (if not already there)
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"

# Clean build artifacts
flutter clean

# Get dependencies and assets
flutter pub get

# Run on device/emulator
flutter run

# Or specify device:
flutter devices  # (to see available devices)
flutter run -d emulator-5554
```

---

## macOS / Linux

### 1. Set Up (First Time Only)

```bash
# Navigate to project
cd ~/path/to/mail_mind

# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies (takes ~5 min)
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf

# Verify installation
python -c "import tensorflow; print('TensorFlow OK')"
```

### 2. Convert Model (Every Time You Update .pkl)

```bash
# Make sure venv is activated
source venv/bin/activate

# Navigate to project root
cd ~/path/to/mail_mind

# Run conversion
python3 convert_model.py

# Expected output:
# ✓ Conversion Successful
# TFLite model: assets/models/priority_classifier.tflite
```

### 3. Verify Model (Optional)

```bash
python3 test_tflite.py

# Expected output:
# ✓ All tests passed!
```

### 4. Rebuild Flutter

```bash
# Navigate to project root
cd ~/path/to/mail_mind

# Clean build artifacts
flutter clean

# Get dependencies and assets
flutter pub get

# Run on device/emulator
flutter run

# Or specify device:
flutter devices  # (to see available devices)
flutter run -d <device-id>
```

---

## Automation: One-Liner Commands

### Convert + Verify + Rebuild (Windows)

```powershell
python convert_model.py; python test_tflite.py; flutter clean; flutter pub get; flutter run
```

### Convert + Verify + Rebuild (macOS/Linux)

```bash
python3 convert_model.py && python3 test_tflite.py && flutter clean && flutter pub get && flutter run
```

---

## Troubleshooting Quick Checks

### Check Python Installation

```powershell
python --version          # Should be 3.7+
python -m pip --version   # Should be 21.0+
```

### Check Virtual Environment

```powershell
# Windows PowerShell
# If activated, you should see (venv) in prompt
.\venv\Scripts\Activate.ps1

# Deactivate when done
deactivate
```

### Check Dependencies

```powershell
pip list | findstr tensorflow
pip list | findstr scikit
pip list | findstr onnx
```

### Check Flutter Installation

```powershell
flutter --version
flutter devices       # Should show at least one device/emulator
```

### Check Assets in pubspec.yaml

```powershell
# Should have this:
# flutter:
#   assets:
#     - assets/models/priority_classifier.tflite

# Edit pubspec.yaml if missing:
# Add under "flutter:" section
```

---

## File Locations

After successful conversion, you should have:

```
mail_mind/
├── assets/
│   └── models/
│       └── priority_classifier.tflite    ← The converted model
├── convert_model.py                      ← Conversion script
├── test_tflite.py                        ← Test script
├── CONVERSION_INSTRUCTIONS.md            ← Full guide (this file)
├── QUICK_COMMANDS.md                     ← Quick reference
├── priority_classifier.pkl               ← Your original model
├── pubspec.yaml                          ← Should have assets entry
└── ...
```

---

## Expected File Sizes

- `priority_classifier.pkl`: 1-50 MB (varies by model)
- `priority_classifier.tflite`: 2-100 MB (usually larger than .pkl due to TF framework)

---

## Success Checklist

- [ ] `priority_classifier.pkl` is in project root
- [ ] Python 3.7+ is installed
- [ ] Virtual environment is activated (if using)
- [ ] Dependencies installed: `pip install ...`
- [ ] Conversion ran: `python convert_model.py`
- [ ] `assets/models/priority_classifier.tflite` exists and > 0 bytes
- [ ] `pubspec.yaml` has assets entry with `.tflite` path
- [ ] `flutter clean && flutter pub get && flutter run` succeeds
- [ ] App launches without errors
- [ ] Check Flutter console: "Loaded TFLite model" or "Using fallback classifier"

---

## One-Time Setup Command (Copy-Paste Ready)

### Windows PowerShell

```powershell
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"; python -m venv venv; .\venv\Scripts\Activate.ps1; pip install -U pip; pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf; echo "Setup complete! Now run: python convert_model.py"
```

### macOS/Linux

```bash
cd ~/path/to/mail_mind && python3 -m venv venv && source venv/bin/activate && pip install -U pip && pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf && echo "Setup complete! Now run: python3 convert_model.py"
```

---

## Still Having Issues?

1. Read `CONVERSION_INSTRUCTIONS.md` for detailed troubleshooting
2. Check the full error output from conversion script
3. Verify `priority_classifier.pkl` is a valid pickle file:
   ```powershell
   python -c "import pickle; pickle.load(open('priority_classifier.pkl', 'rb')); print('Valid pickle')"
   ```
4. Check file permissions (especially on macOS/Linux):
   ```bash
   ls -la assets/models/priority_classifier.tflite
   ```
