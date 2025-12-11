# 🚀 Mail Mind — Quick Android Deployment Commands

## ONE-COMMAND DEPLOY

### Windows PowerShell
```powershell
cd "C:\Users\ASUS\Desktop\Hackathon\mail_mind"
.\run_on_device.ps1
```

### macOS / Linux
```bash
cd ~/path/to/mail_mind
chmod +x run_on_device.sh
./run_on_device.sh
```

---

## MANUAL COMMANDS

### 1. Detect Connected Devices
```bash
flutter devices
```
**Output example:**
```
ASUS Android Device  • 192.168.1.100:5555 • android • Android 12 (API 31)
```

### 2. Run on Device (Build + Install + Run)
```bash
flutter run -d ASUS\ Android\ Device
```

Replace `ASUS\ Android\ Device` with your actual device ID.

### 3. Run in Release Mode
```bash
flutter run -d <deviceId> --release
```

### 4. Build APK Only (Debug)
```bash
flutter build apk
```

### 5. Build APK Only (Release)
```bash
flutter build apk --release
```

### 6. Install Only (After Building)
```bash
flutter install -d <deviceId>
```

### 7. View Live Logs
```bash
flutter logs -d <deviceId>
```

### 8. Uninstall App
```bash
flutter uninstall -d <deviceId>
```

### 9. Clear App Data
```bash
adb shell pm clear com.example.mail_mind
```

---

## OPTIONS & VARIATIONS

### Debug + Verbose Logs
```bash
./run_on_device.sh --verbose
```

### Release Mode
```bash
./run_on_device.sh --release
```

### Release + Verbose
```bash
./run_on_device.sh --release --verbose
```

---

## TROUBLESHOOTING QUICK FIXES

### No Device Detected
```bash
# Check USB connection
adb devices

# If device shows but not in flutter devices:
adb kill-server
adb start-server
flutter devices
```

### Clear Build Cache
```bash
flutter clean
flutter pub get
flutter run -d <deviceId>
```

### Rebuild from Scratch
```bash
flutter clean
flutter pub get
flutter build apk
flutter install -d <deviceId>
```

---

## SCRIPT OPTIONS (PowerShell)

```powershell
# Debug mode (default)
.\run_on_device.ps1

# Release mode
.\run_on_device.ps1 -Release

# Verbose logging
.\run_on_device.ps1 -Verbose

# Release + verbose
.\run_on_device.ps1 -Release -Verbose
```

---

## SCRIPT OPTIONS (Bash)

```bash
# Debug mode (default)
./run_on_device.sh

# Release mode
./run_on_device.sh --release

# Verbose logging
./run_on_device.sh --verbose

# Release + verbose
./run_on_device.sh --release --verbose
```

---

## USB DEBUGGING SETUP

1. Phone: Settings → About Phone → Tap "Build Number" 7 times
2. Phone: Settings → System → Developer Options → USB Debugging (ON)
3. Connect phone via USB
4. Allow permission when prompted
5. Run: `flutter devices` (should show phone)
6. Deploy: `./run_on_device.sh` or `.\run_on_device.ps1`

---

## DEVICE ID FORMAT

**From:** `flutter devices`
```
ASUS Android Device  • 192.168.1.100:5555 • android • Android 12 (API 31)
│
└─ Device ID (use this in commands)
```

**Example commands:**
```bash
flutter run -d "ASUS Android Device"
flutter install -d "ASUS Android Device"
flutter logs -d "ASUS Android Device"
```

---

## APK LOCATIONS

After building:
- **Debug APK:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK:** `build/app/outputs/flutter-apk/app-release.apk`

---

## REFERENCE

| Task | Command |
|------|---------|
| List devices | `flutter devices` |
| Run app | `flutter run -d <deviceId>` |
| Run (release) | `flutter run -d <deviceId> --release` |
| Build APK | `flutter build apk` |
| Build APK (release) | `flutter build apk --release` |
| Install APK | `flutter install -d <deviceId>` |
| Uninstall | `flutter uninstall -d <deviceId>` |
| View logs | `flutter logs -d <deviceId>` |
| Clear cache | `flutter clean` |
| Reset device | `adb shell pm clear com.example.mail_mind` |

---

**Status:** ✅ Ready to Deploy

**Last Updated:** December 11, 2025
