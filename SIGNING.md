# Code Signing Guide for rustlib

This document explains how to securely sign your Rust library to make it trustworthy.

## Overview

Code signing provides:
- **Authenticity**: Verifies the software publisher's identity
- **Integrity**: Ensures the code hasn't been tampered with
- **Trust**: Allows users to verify the software comes from a trusted source

## Prerequisites

### For Production Signing

You need a code signing certificate from a trusted Certificate Authority (CA):
- **DigiCert** (recommended)
- **Sectigo** (formerly Comodo)
- **GlobalSign**
- **Entrust**

Certificates typically cost $100-$500/year. For organizations, you may need an EV (Extended Validation) certificate.

### For Testing/Development

You can create a self-signed certificate (not trusted by default, only for testing):

```powershell
New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=CollectionTeam, O=Lakeside Software LLC, C=US" `
    -CertStoreLocation Cert:\CurrentUser\My `
    -NotAfter (Get-Date).AddYears(5)
```

## Signing Methods

### Method 1: Using Certificate from Windows Store

1. Install your certificate in the Windows certificate store
2. Get the certificate thumbprint:
   ```powershell
   Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
   ```
3. Build and sign:
   ```powershell
   .\build-and-sign.ps1 -CertificateThumbprint "1C18BF498CAA0192AF747765F31BA821E7286E52"
   ```

### Method 2: Using PFX File

1. Export your certificate to a PFX file (if not already in that format)
2. Build and sign:
   ```powershell
   .\build-and-sign.ps1 -CertificatePath "path\to\cert.pfx" -CertificatePassword "password"
   ```

## Available Scripts

### build-and-sign.ps1
Builds the project and signs the DLL in one step:
```powershell
# Using certificate from store
.\build-and-sign.ps1 -BuildType Release -CertificateThumbprint "THUMBPRINT"

# Using PFX file
.\build-and-sign.ps1 -BuildType Release -CertificatePath "cert.pfx" -CertificatePassword "pass"
```

### sign.ps1
Signs an already-built DLL:
```powershell
# Build first
cargo build --release

# Then sign
.\sign.ps1 -CertificateThumbprint "THUMBPRINT"
```

### verify-signature.ps1
Verifies the signature of the built DLL:
```powershell
.\verify-signature.ps1 -BuildType Release
```

## Timestamping

All signing operations include timestamping via DigiCert's timestamp server. This ensures:
- The signature remains valid even after your certificate expires
- Users can verify when the code was signed

The default timestamp server is `http://timestamp.digicert.com`. You can change this with the `-TimestampServer` parameter.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Sign

on: [push]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      
      - name: Import Certificate
        run: |
          $cert = [Convert]::FromBase64String("${{ secrets.CERTIFICATE_BASE64 }}")
          [IO.File]::WriteAllBytes("cert.pfx", $cert)
      
      - name: Build and Sign
        run: |
          .\build-and-sign.ps1 -CertificatePath "cert.pfx" `
            -CertificatePassword "${{ secrets.CERT_PASSWORD }}"
      
      - name: Verify Signature
        run: .\verify-signature.ps1
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: signed-dll
          path: target/release/rustlib.dll
```

## Git Commit Signing (Additional Security)

To sign your Git commits for source code integrity:

### 1. Generate GPG Key
```powershell
gpg --full-generate-key
```

### 2. Configure Git
```powershell
gpg --list-secret-keys --keyid-format LONG
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

### 3. Add GPG Key to GitHub
```powershell
gpg --armor --export YOUR_KEY_ID
```
Copy the output and add it to GitHub Settings → SSH and GPG keys.

## Security Best Practices

1. **Protect Private Keys**: Never commit certificates or private keys to source control
2. **Use Hardware Security Modules (HSM)**: For production, store keys in HSM or USB token
3. **Secure Storage**: Use environment variables or Azure Key Vault for CI/CD
4. **Rotate Certificates**: Renew before expiration
5. **Verify After Signing**: Always run `verify-signature.ps1` after signing
6. **Sign All Releases**: Make signing part of your release process

## Troubleshooting

### "Certificate not found"
- Verify certificate is installed: `Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert`
- Check if certificate has Code Signing purpose
- Try `Cert:\LocalMachine\My` instead

### "NotTrusted" signature status
- Self-signed certificates won't be trusted by default
- Install root CA certificate in Trusted Root store
- For production, use CA-issued certificate

### "HashMismatch" error
- File was modified after signing
- Rebuild and sign again

## Additional Resources

- [Microsoft Code Signing Documentation](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [DigiCert Code Signing Guide](https://www.digicert.com/signing/code-signing-certificate)
- [Rust Security Policy](https://www.rust-lang.org/policies/security)
