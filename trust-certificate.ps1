# Trust Self-Signed Certificate Script
# This script adds the self-signed certificate to the Trusted Root store

param(
    [Parameter(Mandatory=$true)]
    [string]$CertificateThumbprint
)

$ErrorActionPreference = "Stop"

Write-Host "=== Trust Self-Signed Certificate ===" -ForegroundColor Cyan
Write-Host "Thumbprint: $CertificateThumbprint"
Write-Host ""

# Find the certificate
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
if (-not $cert) {
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
}

if (-not $cert) {
    Write-Host "ERROR: Certificate not found with thumbprint: $CertificateThumbprint" -ForegroundColor Red
    exit 1
}

Write-Host "Found certificate:"
Write-Host "  Subject: $($cert.Subject)"
Write-Host "  Issuer: $($cert.Issuer)"
Write-Host ""

# Check if it's self-signed
if ($cert.Subject -eq $cert.Issuer) {
    Write-Host "This is a self-signed certificate." -ForegroundColor Yellow
    Write-Host ""
}

# Check if already trusted
$trustedCert = Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
if ($trustedCert) {
    Write-Host "Certificate is already in Trusted Root store." -ForegroundColor Green
    exit 0
}

Write-Host "WARNING: This will add the certificate to your Trusted Root Certificate Authorities store." -ForegroundColor Yellow
Write-Host "This means Windows will trust any code signed with this certificate." -ForegroundColor Yellow
Write-Host ""
Write-Host "Do you want to continue? (Y/N): " -NoNewline -ForegroundColor Cyan
$response = Read-Host

if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Adding certificate to Trusted Root store..." -ForegroundColor Cyan

try {
    # Export and import to Trusted Root
    $certPath = "$env:TEMP\cert_$CertificateThumbprint.cer"
    Export-Certificate -Cert $cert -FilePath $certPath | Out-Null
    Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
    Remove-Item $certPath -Force
    
    Write-Host ""
    Write-Host "[SUCCESS] Certificate added to Trusted Root store!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your signed DLL will now be trusted by Windows." -ForegroundColor Green
    Write-Host ""
    Write-Host "Run verify-signature.ps1 again to confirm the signature is now Valid."
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to add certificate to Trusted Root store." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You may need to run this script as Administrator." -ForegroundColor Yellow
    exit 1
}
