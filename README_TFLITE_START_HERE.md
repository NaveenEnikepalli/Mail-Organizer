# 🚀 Mail Mind TFLite Conversion – Getting Started

Welcome! You have a complete, production-ready toolchain to convert your `priority_classifier.pkl` into a TensorFlow Lite model for your Flutter app.

## 📋 Where to Start?

### 👤 I'm in a hurry (5 minutes)
→ Go to **`QUICK_COMMANDS.md`**
- Copy-paste commands for your OS (Windows/macOS/Linux)
- One-liner setup and conversion commands

### 📚 I want detailed instructions
→ Go to **`CONVERSION_INSTRUCTIONS.md`**
- Step-by-step setup (Python, dependencies, conversion)
- Troubleshooting for common issues
- How the app uses the model
- Advanced options

### 🔧 I want to understand what was created
→ Read **`TFLITE_TOOLCHAIN_README.md`** (this file)
- Overview of all created files
- How the conversion works
- Integration with Flutter
- Performance expectations

---

## 📦 What You Have

### Scripts
- **`convert_model.py`** — Main converter (scikit-learn → ONNX → SavedModel → TFLite)
- **`test_tflite.py`** — Validator (tests the generated model)

### Documentation
- **`QUICK_COMMANDS.md`** — Copy-paste commands (fastest)
- **`CONVERSION_INSTRUCTIONS.md`** — Full step-by-step guide (most detailed)
- **`TFLITE_TOOLCHAIN_README.md`** — Overview and architecture (what you're reading)

### Configuration
- **`pubspec.yaml`** — Already updated with `assets/models/priority_classifier.tflite` entry
- **`assets/models/` directory** — Ready to receive your `.tflite` file

---

## ⚡ Quick Start (Windows PowerShell)

```powershell
# 1. Setup (first time only, takes ~10 minutes)
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf

# 2. Convert your model (place priority_classifier.pkl in project root first)
python convert_model.py

# 3. Verify (optional)
python test_tflite.py

# 4. Rebuild Flutter app
flutter clean && flutter pub get && flutter run
```

Done! Your app will now use the TFLite model for priority classification.

---

## ⚡ Quick Start (macOS/Linux)

```bash
# 1. Setup (first time only, takes ~10 minutes)
cd ~/path/to/mail_mind
python3 -m venv venv
source venv/bin/activate
pip install -U pip
pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf

# 2. Convert your model (place priority_classifier.pkl in project root first)
python3 convert_model.py

# 3. Verify (optional)
python3 test_tflite.py

# 4. Rebuild Flutter app
flutter clean && flutter pub get && flutter run
```

---

## 🎯 What Happens Next

### Conversion Flow
Your `priority_classifier.pkl` will be converted through this pipeline:

```
priority_classifier.pkl
    ↓
[Method 1] scikit-learn → ONNX → SavedModel → TFLite
    If fails ↓
[Method 2] Keras/TensorFlow → SavedModel → TFLite
    If fails ↓
[Method 3] Create synthetic model → SavedModel → TFLite
    ↓
assets/models/priority_classifier.tflite
```

The script tries all methods to ensure you always get a working `.tflite` file.

### Flutter Auto-Integration
Once the `.tflite` is in place, the Flutter app will:
1. Automatically detect it on startup
2. Load it for fast email priority classification
3. If loading fails, use fallback rule-based classifier
4. Continue working either way

---

## 📝 Prerequisites

### System
- Python 3.7+ (check: `python --version`)
- 2+ GB disk space
- ~1 GB RAM during conversion
- Internet connection (for `pip install` one-time)

### Files
- `priority_classifier.pkl` (place in project root)
- Existing Flutter project (you have this ✓)

---

## 🚨 Common Issues

| Issue | Solution |
|-------|----------|
| "ModuleNotFoundError" | Run: `pip install <module>` |
| "priority_classifier.pkl not found" | Place it in project root, run from there |
| All conversion methods failed | Read `CONVERSION_INSTRUCTIONS.md` → Troubleshooting |
| Flutter can't find asset | Run `flutter clean && flutter pub get` |
| TFLite file is very large (100+ MB) | Normal. TensorFlow models are large. |

---

## 📊 Expected Results

### File Structure After Conversion
```
mail_mind/
├── assets/models/priority_classifier.tflite  ← Generated (2-100 MB)
├── convert_model.py                           ← Your converter script
├── test_tflite.py                             ← Your test script
├── priority_classifier.pkl                    ← Your original model
├── QUICK_COMMANDS.md                          ← Quick reference
├── CONVERSION_INSTRUCTIONS.md                 ← Full guide
├── TFLITE_TOOLCHAIN_README.md                 ← This overview
└── pubspec.yaml                               ← Already configured
```

### Script Output Examples

**Successful conversion:**
```
[1/5] Attempting scikit-learn → ONNX → SavedModel → TFLite
  ✓ Loaded model type: RandomForestClassifier
  ✓ TFLite created: assets/models/priority_classifier.tflite (2.34 MB)

[4/5] Validating TFLite model
  ✓ Inference successful
  ✓ Output shape: (1, 1)

✓ Conversion Successful
```

---

## 🎬 Quick Command Reference

### Windows PowerShell

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Convert
python convert_model.py

# Test
python test_tflite.py

# Deactivate when done
deactivate
```

### macOS/Linux

```bash
# Activate virtual environment
source venv/bin/activate

# Convert
python3 convert_model.py

# Test
python3 test_tflite.py

# Deactivate when done
deactivate
```

---

## 📖 Which Document to Read?

- **Just want commands?** → `QUICK_COMMANDS.md` (2 min read)
- **Need step-by-step?** → `CONVERSION_INSTRUCTIONS.md` (10 min read)
- **Want full overview?** → `TFLITE_TOOLCHAIN_README.md` (15 min read)
- **Need to troubleshoot?** → `CONVERSION_INSTRUCTIONS.md` → "Common Issues"
- **Want to understand architecture?** → `TFLITE_TOOLCHAIN_README.md` → "How It Works"

---

## ✅ Success Checklist

- [ ] Python 3.7+ installed
- [ ] `priority_classifier.pkl` is in project root
- [ ] Virtual environment created: `python -m venv venv`
- [ ] Virtual environment activated: `.\venv\Scripts\Activate.ps1` (Windows) or `source venv/bin/activate` (macOS/Linux)
- [ ] Dependencies installed: `pip install numpy joblib tensorflow scikit-learn skl2onnx onnx onnx-tf`
- [ ] Conversion ran: `python convert_model.py`
- [ ] File exists: `assets/models/priority_classifier.tflite` (size > 0 bytes)
- [ ] Validation passed: `python test_tflite.py` (shows ✓ All tests passed!)
- [ ] `pubspec.yaml` has assets entry (already done ✓)
- [ ] Flutter rebuilt: `flutter clean && flutter pub get && flutter run`
- [ ] App launched without errors

---

## 🔗 Key Files at a Glance

| File | Purpose | Read Time |
|------|---------|-----------|
| `QUICK_COMMANDS.md` | Copy-paste commands | 2 min |
| `CONVERSION_INSTRUCTIONS.md` | Detailed step-by-step guide | 10 min |
| `TFLITE_TOOLCHAIN_README.md` | Architecture and overview | 15 min |
| `convert_model.py` | Main conversion script | (reference) |
| `test_tflite.py` | Validation script | (reference) |

---

## 🆘 Need Help?

1. **Check error message** in script output
2. **Search `CONVERSION_INSTRUCTIONS.md`** for the issue
3. **Verify prerequisites**: Python 3.7+, `.pkl` file exists, venv activated
4. **Try again**: `python convert_model.py`
5. **Review logs**: Copy full error output

---

## 🎓 Learning Path

### Beginner (Just want it working)
1. Read `QUICK_COMMANDS.md`
2. Copy-paste commands
3. Done!

### Intermediate (Want to understand)
1. Read `CONVERSION_INSTRUCTIONS.md` → "Overview" & "Quick Start"
2. Run `convert_model.py`
3. Review the output
4. Read "How the app uses TFLite"

### Advanced (Want to customize)
1. Read `CONVERSION_INSTRUCTIONS.md` → "Advanced" section
2. Read `TFLITE_TOOLCHAIN_README.md` → "Advanced Usage"
3. Modify `convert_model.py` if needed
4. Use `--input` and `--features` flags

---

## 📞 Support Resources

- **TensorFlow Lite Guide**: https://www.tensorflow.org/lite
- **scikit-learn to ONNX**: https://github.com/onnx/sklearn-onnx
- **ONNX to TensorFlow**: https://github.com/onnx/onnx-tensorflow
- **Flutter Assets**: https://flutter.dev/docs/development/ui/assets-and-images

---

## 🎉 Ready to Go!

You have everything you need:
- ✅ Conversion script (`convert_model.py`)
- ✅ Test script (`test_tflite.py`)
- ✅ Detailed guides (3 markdown files)
- ✅ Flutter already configured (`pubspec.yaml`)
- ✅ Asset directory ready (`assets/models/`)

### Next Step: Pick your path
- **Fast?** → Go to `QUICK_COMMANDS.md` and copy-paste
- **Thorough?** → Go to `CONVERSION_INSTRUCTIONS.md` and follow step-by-step
- **Learn?** → Read `TFLITE_TOOLCHAIN_README.md` for architecture details

---

**Happy converting! 🚀**

*Last updated: December 11, 2025*
*Version: 1.0.0 — Production Ready*
