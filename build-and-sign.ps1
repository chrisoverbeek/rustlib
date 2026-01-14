# Build and Sign Script
# Builds the Rust library and automatically signs it

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$CertificateThumbprint,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePassword
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building Rust Library ===" -ForegroundColor Cyan

# Build the project
if ($BuildType -eq "Release") {
    cargo build --release
} else {
    cargo build
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "=== Signing DLL ===" -ForegroundColor Cyan

# Prepare signing parameters
$signParams = @{
    BuildType = $BuildType
}

if ($CertificateThumbprint) {
    $signParams.CertificateThumbprint = $CertificateThumbprint
} elseif ($CertificatePath) {
    $signParams.CertificatePath = $CertificatePath
    if ($CertificatePassword) {
        $signParams.CertificatePassword = $CertificatePassword
    }
}

# Sign the DLL
& .\sign.ps1 @signParams

Write-Host ""
Write-Host "=== Build and Sign Complete ===" -ForegroundColor Green
