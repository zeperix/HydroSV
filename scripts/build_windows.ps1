# PowerShell script for automated build process
# Run as Administrator

# Error handling
$ErrorActionPreference = "Stop"

function DownloadAndExtract {
    param (
        [string]$Uri,
        [string]$OutFile
    )

    $maxRetries = 5
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "Downloading $Uri to $OutFile, attempt $retryCount of $maxRetries"
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile
            $success = $true
        }
        catch {
            Write-Host "Attempt $retryCount of $maxRetries failed with error: $($_.Exception.Message). Retrying..."
            Start-Sleep -Seconds 5
        }
    }

    if (-not $success) {
        Write-Host "Failed to download the file after $maxRetries attempts."
        exit 1
    }

    # Extract the zip file
    Expand-Archive -Path $OutFile -DestinationPath ([System.IO.Path]::GetFileNameWithoutExtension($OutFile)) -Force
}

# Install MSYS2
Write-Host "Installing MSYS2..."
$msys2Installer = "msys2-x86_64-latest.exe"
Invoke-WebRequest -Uri "https://github.com/msys2/msys2-installer/releases/latest/download/$msys2Installer" -OutFile $msys2Installer
Start-Process -FilePath ".\$msys2Installer" -ArgumentList @('install', '--confirm-command', '--accept-messages', '--root', 'C:/msys64') -Wait
Remove-Item $msys2Installer

# Add MSYS2 to PATH
$env:Path = "C:\msys64\usr\bin;C:\msys64\mingw64\bin;" + $env:Path

# Install dependencies using pacman
Write-Host "Installing dependencies..."
$dependencies = @(
    "git",
    "wget",
    "mingw-w64-ucrt-x86_64-cmake",
    "mingw-w64-ucrt-x86_64-cppwinrt",
    "mingw-w64-ucrt-x86_64-curl-winssl",
    "mingw-w64-ucrt-x86_64-graphviz",
    "mingw-w64-ucrt-x86_64-MinHook",
    "mingw-w64-ucrt-x86_64-miniupnpc",
    "mingw-w64-ucrt-x86_64-nlohmann-json",
    "mingw-w64-ucrt-x86_64-nodejs",
    "mingw-w64-ucrt-x86_64-nsis",
    "mingw-w64-ucrt-x86_64-onevpl",
    "mingw-w64-ucrt-x86_64-openssl",
    "mingw-w64-ucrt-x86_64-opus",
    "mingw-w64-ucrt-x86_64-toolchain"
)

# Update MSYS2
bash -lc 'pacman -Syu --noconfirm'

# Install dependencies
foreach ($dep in $dependencies) {
    bash -lc "pacman -S --noconfirm $dep"
}

# Install specific GCC version
$gcc_version = "14.2.0-3"
$broken_deps = @(
    "mingw-w64-ucrt-x86_64-gcc",
    "mingw-w64-ucrt-x86_64-gcc-libs"
)

foreach ($dep in $broken_deps) {
    $tarball = "${dep}-${gcc_version}-any.pkg.tar.zst"
    bash -lc "wget https://repo.msys2.org/mingw/ucrt64/${tarball}"
    bash -lc "pacman -U --noconfirm ${tarball}"
}

# Install Doxygen
Write-Host "Installing Doxygen..."
$DOXYGEN_VERSION = "1.11.0"
$_doxy_ver = $DOXYGEN_VERSION.Replace(".", "_")
$doxygenUrl = "https://github.com/doxygen/doxygen/releases/download/Release_${_doxy_ver}/doxygen-${DOXYGEN_VERSION}-setup.exe"
Invoke-WebRequest -Uri $doxygenUrl -OutFile "doxygen-setup.exe"
Start-Process -FilePath ".\doxygen-setup.exe" -ArgumentList '/VERYSILENT' -Wait -NoNewWindow
Remove-Item -Path "doxygen-setup.exe"

# Install Python
Write-Host "Installing Python..."
winget install Python.Python.3.11

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Clone and Build
Write-Host "Building project..."
if (!(Test-Path "build")) {
    New-Item -ItemType Directory -Path "build"
}

# Extract third-party dependencies
if (Test-Path "third-party/pack.zip") {
    Expand-Archive -Path "third-party/pack.zip" -DestinationPath "third-party/" -Force
}

# Build using CMake
bash -lc @'
    cmake -B build -G Ninja -S . \
        -DBUILD_WERROR=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DAQUA_ASSETS_DIR=assets \
        -DAQUA_PUBLISHER_NAME="LocalBuild" \
        -DAQUA_PUBLISHER_WEBSITE="https://app.lizardbyte.dev" \
        -DAQUA_PUBLISHER_ISSUE_URL="https://app.lizardbyte.dev/support"
    
    ninja -C build
'@

# Package
Write-Host "Packaging..."
Push-Location build
bash -lc @'
    mkdir -p artifacts
    cpack -G NSIS
    cpack -G ZIP
    mv ./cpack_artifacts/Sunshine.exe ../artifacts/sunshine-windows-installer.exe
    mv ./cpack_artifacts/Sunshine.zip ../artifacts/sunshine-windows-portable.zip
'@
Pop-Location

Write-Host "Build completed successfully!"
Write-Host "Installer: artifacts/sunshine-windows-installer.exe"
Write-Host "Portable: artifacts/sunshine-windows-portable.zip"
