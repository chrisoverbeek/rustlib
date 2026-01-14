# Code Signing Script for Rust Library
# This script signs the compiled DLL with Authenticode

param(
    [Parameter(Mandatory=$false)]
    [string]$CertificateThumbprint,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePassword,
    
    [Parameter(Mandatory=$false)]
    [string]$TimestampServer = "http://timestamp.digicert.com",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Rust Library Code Signing Script ===" -ForegroundColor Cyan

# Find the DLL to sign
$dllPath = "target\$($BuildType.ToLower())\rustlib.dll"

if (-not (Test-Path $dllPath)) {
    Write-Host "ERROR: DLL not found at $dllPath" -ForegroundColor Red
    Write-Host "Please build the project first with: cargo build --release" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found DLL: $dllPath" -ForegroundColor Green

# Determine which signing method to use
if ($CertificateThumbprint) {
    Write-Host "Using certificate from Windows certificate store" -ForegroundColor Cyan
    Write-Host "Thumbprint: $CertificateThumbprint"
    
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
    if (-not $cert) {
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
    }
    
    if (-not $cert) {
        Write-Host "ERROR: Certificate with thumbprint $CertificateThumbprint not found" -ForegroundColor Red
        exit 1
    }
    
    # Sign using certificate from store
    Set-AuthenticodeSignature -FilePath $dllPath `
        -Certificate $cert `
        -TimestampServer $TimestampServer `
        -HashAlgorithm SHA256
        
} elseif ($CertificatePath) {
    Write-Host "Using certificate file: $CertificatePath" -ForegroundColor Cyan
    
    if (-not (Test-Path $CertificatePath)) {
        Write-Host "ERROR: Certificate file not found: $CertificatePath" -ForegroundColor Red
        exit 1
    }
    
    # Load PFX certificate
    if ($CertificatePassword) {
        $securePassword = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath, $securePassword)
    } else {
        Write-Host "Enter certificate password:" -ForegroundColor Yellow
        $securePassword = Read-Host -AsSecureString
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath, $securePassword)
    }
    
    # Sign using PFX certificate
    Set-AuthenticodeSignature -FilePath $dllPath `
        -Certificate $cert `
        -TimestampServer $TimestampServer `
        -HashAlgorithm SHA256
        
} else {
    Write-Host "ERROR: No certificate specified!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage options:" -ForegroundColor Yellow
    Write-Host "  1. Use certificate from Windows store:"
    Write-Host "     .\sign.ps1 -CertificateThumbprint <thumbprint>"
    Write-Host ""
    Write-Host "  2. Use PFX file:"
    Write-Host "     .\sign.ps1 -CertificatePath <path> -CertificatePassword <password>"
    Write-Host ""
    Write-Host "To list available certificates in your store, run:"
    Write-Host "     Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert"
    Write-Host ""
    Write-Host "To create a self-signed certificate for testing (not for production):"
    Write-Host "     New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=Dev Certificate' -CertStoreLocation Cert:\CurrentUser\My"
    exit 1
}

Write-Host ""
Write-Host "=== Verifying Signature ===" -ForegroundColor Cyan
$signature = Get-AuthenticodeSignature -FilePath $dllPath

if ($signature.Status -eq "Valid") {
    Write-Host "[SUCCESS] DLL successfully signed!" -ForegroundColor Green
    Write-Host "  Status: $($signature.Status)"
    Write-Host "  Signer: $($signature.SignerCertificate.Subject)"
    Write-Host "  Timestamp: $($signature.TimeStamperCertificate.Subject)"
} else {
    Write-Host "WARNING: Signature status: $($signature.Status)" -ForegroundColor Yellow
    Write-Host "  Status Message: $($signature.StatusMessage)"
}
