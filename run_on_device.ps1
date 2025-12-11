# ╔════════════════════════════════════════════════════════════════════════════╗
# ║         Mail Mind — Android Device Deployment Tool (PowerShell)             ║
# ║                                                                              ║
# ║  This script detects connected Android devices and runs the Flutter app     ║
# ║  automatically on the first available device (USB or WiFi debugging).       ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    .\run_on_device.ps1                    (run in debug mode)               ║
# ║    .\run_on_device.ps1 -Release           (run in release mode)             ║
# ║    .\run_on_device.ps1 -Verbose           (show detailed output)            ║
# ║                                                                              ║
# ╚════════════════════════════════════════════════════════════════════════════╝

param(
    [switch]$Release = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$projectRoot = $scriptDir
$buildMode = if ($Release) { "release" } else { "debug" }

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Mail Mind — Android Device Deployment Tool            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Detect devices
Write-Host "[1/4] Detecting Android devices..." -ForegroundColor Yellow
Write-Host ""

try {
    $devicesOutput = & flutter devices 2>&1 | Out-String
} catch {
    Write-Host "❌ ERROR: Could not run 'flutter devices'" -ForegroundColor Red
    Write-Host "Make sure Flutter is installed and added to PATH" -ForegroundColor Red
    exit 1
}

if ($Verbose) {
    Write-Host $devicesOutput
}

# Extract device IDs (lines containing 'android' and 'connected')
$lines = $devicesOutput -split "`n"
$androidDevices = @()

foreach ($line in $lines) {
    if ($line -match '^\S+' -and $line -match 'android' -and $line -match 'connected') {
        $deviceId = ($line -split '\s+')[0]
        if ($deviceId) {
            $androidDevices += $deviceId
        }
    }
}

if ($androidDevices.Count -eq 0) {
    Write-Host "❌ ERROR: No connected Android device detected." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Connect Android phone via USB cable"
    Write-Host "  2. Enable USB debugging on the phone:"
    Write-Host "     Settings → Developer Options → USB Debugging (enabled)"
    Write-Host "  3. Allow USB debugging permission when prompted on phone"
    Write-Host "  4. Try again: .\run_on_device.ps1"
    Write-Host ""
    Write-Host "Alternative: WiFi Debugging" -ForegroundColor Yellow
    Write-Host "  1. Enable Developer Options on phone"
    Write-Host "  2. Enable 'Wireless Debugging'"
    Write-Host "  3. Run: adb connect <phone-ip>:5555"
    Write-Host "  4. Try again: .\run_on_device.ps1"
    Write-Host ""
    exit 1
}

$deviceId = $androidDevices[0]
Write-Host "✓ Device detected: $deviceId" -ForegroundColor Green
Write-Host ""

# Step 2: Build
Write-Host "[2/4] Building Flutter app (mode: $buildMode)..." -ForegroundColor Yellow
Write-Host ""

try {
    if ($buildMode -eq "release") {
        $output = & flutter build apk --release 2>&1 | Out-String
    } else {
        $output = & flutter build apk 2>&1 | Out-String
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed." -ForegroundColor Red
        if ($Verbose) {
            Write-Host $output
        } else {
            Write-Host "Run with -Verbose for details: .\run_on_device.ps1 -Verbose"
        }
        exit 1
    }
    
    Write-Host "✓ Build successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Build failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Install
Write-Host "[3/4] Installing APK on device..." -ForegroundColor Yellow
Write-Host ""

try {
    $output = & flutter install -d $deviceId 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ Installation encountered an issue, trying to uninstall first..." -ForegroundColor Yellow
        & flutter uninstall -d $deviceId 2>&1 | Out-Null
        $output = & flutter install -d $deviceId 2>&1 | Out-String
    }
    
    Write-Host "✓ Installation successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Installation failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Run
Write-Host "[4/4] Launching app..." -ForegroundColor Yellow
Write-Host ""

try {
    & flutter run -d $deviceId
} catch {
    Write-Host "❌ Failed to launch app: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    ✓ Deployment Complete                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
