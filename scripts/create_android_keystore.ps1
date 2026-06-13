# Creates android/app/release-key.jks for CI signing (not committed).
$ErrorActionPreference = 'Stop'
$Password = '0d000721'
$Alias = 'multisignal'
$Dname = 'CN=MultiSignal, OU=CI, O=MultiSignal, L=Local, ST=Local, C=CN'
$OutDir = Join-Path $PSScriptRoot '..\android\app'
$Keystore = Join-Path $OutDir 'release-key.jks'

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if (Test-Path $Keystore) {
    Write-Host "Keystore already exists: $Keystore"
    exit 0
}

keytool -genkeypair -v `
    -keystore $Keystore `
    -alias $Alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $Password `
    -keypass $Password `
    -dname $Dname

Write-Host "Created $Keystore (alias=$Alias)"