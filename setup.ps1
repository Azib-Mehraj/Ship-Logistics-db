$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was not found. Install it, reopen PowerShell, and run this script again."
    }
}

Write-Host "Checking required tools..." -ForegroundColor Cyan
Require-Command "git"
Require-Command "cmake"

$ProjectRoot = $PSScriptRoot
$PresetFile = Join-Path $ProjectRoot "CMakePresets.json"
$ManifestFile = Join-Path $ProjectRoot "vcpkg.json"

if (-not (Test-Path $PresetFile)) {
    throw "CMakePresets.json was not found in $ProjectRoot"
}
if (-not (Test-Path $ManifestFile)) {
    throw "vcpkg.json was not found in $ProjectRoot"
}

# Use the teammate's existing vcpkg installation when VCPKG_ROOT is set.
# Otherwise, install vcpkg in their home folder.
$VcpkgRoot = $env:VCPKG_ROOT
if ([string]::IsNullOrWhiteSpace($VcpkgRoot)) {
    $VcpkgRoot = Join-Path $HOME "vcpkg"
}

$VcpkgExe = Join-Path $VcpkgRoot "vcpkg.exe"

if (-not (Test-Path $VcpkgExe)) {
    if (Test-Path $VcpkgRoot) {
        throw "The folder '$VcpkgRoot' exists but vcpkg.exe was not found there. Set VCPKG_ROOT to a valid vcpkg folder or rename/remove this incomplete folder."
    }

    Write-Host "Downloading vcpkg into $VcpkgRoot ..." -ForegroundColor Cyan
    git clone https://github.com/microsoft/vcpkg.git $VcpkgRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Could not clone the vcpkg repository."
    }

    Write-Host "Bootstrapping vcpkg..." -ForegroundColor Cyan
    & (Join-Path $VcpkgRoot "bootstrap-vcpkg.bat") -disableMetrics
    if ($LASTEXITCODE -ne 0) {
        throw "vcpkg bootstrap failed."
    }
}

# Make VCPKG_ROOT available to this PowerShell session and future sessions.
$env:VCPKG_ROOT = $VcpkgRoot
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VcpkgRoot, "User")

Write-Host "Configuring the project. vcpkg will install the libraries listed in vcpkg.json..." -ForegroundColor Cyan
Push-Location $ProjectRoot
try {
    cmake --preset msvc-vcpkg
    if ($LASTEXITCODE -ne 0) {
        throw "CMake configuration failed. Check the messages above; Visual Studio with the C++ workload may be missing."
    }

    Write-Host "Building the project..." -ForegroundColor Cyan
    cmake --build build --config Debug
    if ($LASTEXITCODE -ne 0) {
        throw "The dependencies were configured, but the project build failed. Check the compiler errors above."
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Setup and build completed successfully." -ForegroundColor Green
Write-Host "To run the program, first make sure MySQL is running and your local .env file is configured."
