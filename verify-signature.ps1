# Verify Code Signature Script
# Checks if the DLL is properly signed and displays signature information

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$BuildType = "Release"
)

$ErrorActionPreference = "Stop"

$dllPath = "target\$($BuildType.ToLower())\rustlib.dll"

if (-not (Test-Path $dllPath)) {
    Write-Host "ERROR: DLL not found at $dllPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== Verifying Code Signature ===" -ForegroundColor Cyan
Write-Host "File: $dllPath"
Write-Host ""

$signature = Get-AuthenticodeSignature -FilePath $dllPath

# Display status
Write-Host "Status: " -NoNewline
switch ($signature.Status) {
    "Valid" { Write-Host "✓ Valid" -ForegroundColor Green }
    "NotSigned" { Write-Host "✗ Not Signed" -ForegroundColor Red }
    "HashMismatch" { Write-Host "✗ Hash Mismatch (file may be corrupted or tampered)" -ForegroundColor Red }
    "NotTrusted" { Write-Host "⚠ Not Trusted (certificate not in trusted store)" -ForegroundColor Yellow }
    default { Write-Host "⚠ $($signature.Status)" -ForegroundColor Yellow }
}

if ($signature.SignerCertificate) {
    Write-Host ""
    Write-Host "Signer Certificate:" -ForegroundColor Cyan
    Write-Host "  Subject: $($signature.SignerCertificate.Subject)"
    Write-Host "  Issuer: $($signature.SignerCertificate.Issuer)"
    Write-Host "  Serial Number: $($signature.SignerCertificate.SerialNumber)"
    Write-Host "  Thumbprint: $($signature.SignerCertificate.Thumbprint)"
    Write-Host "  Valid From: $($signature.SignerCertificate.NotBefore)"
    Write-Host "  Valid To: $($signature.SignerCertificate.NotAfter)"
    Write-Host "  Algorithm: $($signature.SignerCertificate.SignatureAlgorithm.FriendlyName)"
}

if ($signature.TimeStamperCertificate) {
    Write-Host ""
    Write-Host "Timestamp Certificate:" -ForegroundColor Cyan
    Write-Host "  Subject: $($signature.TimeStamperCertificate.Subject)"
    Write-Host "  Timestamp: $($signature.TimeStamperCertificate.NotBefore)"
}

Write-Host ""
Write-Host "Status Message: $($signature.StatusMessage)"

# Return appropriate exit code
if ($signature.Status -eq "Valid") {
    exit 0
} else {
    exit 1
}
