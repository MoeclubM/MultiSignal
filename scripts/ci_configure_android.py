from pathlib import Path

BUILD_GRADLE = Path('android/app/build.gradle')
MANIFEST = Path('android/app/src/main/AndroidManifest.xml')
DEVICE_FILTER = Path('android/app/src/main/res/xml/device_filter.xml')

SIGNING_BLOCK = '''
    def abiFilter = System.getenv("ABI_FILTER") ?: ""

    signingConfigs {
        release {
            def keystoreFilePath = System.getenv("KEYSTORE_FILE") ?: ""
            if (keystoreFilePath != "" && file(keystoreFilePath).exists()) {
                storeFile file(keystoreFilePath)
                storePassword System.getenv("KEYSTORE_PASSWORD")
                keyAlias System.getenv("KEY_ALIAS") ?: "multisignal"
                keyPassword System.getenv("KEYSTORE_PASSWORD")
            }
        }
    }
'''

ABI_DEFAULT_CONFIG = '''
        if (abiFilter != "") {
            ndk {
                abiFilters abiFilter
            }
        }
'''

RELEASE_SIGNING = '''
            if (signingConfigs.release.storeFile != null) {
                signingConfig signingConfigs.release
            } else {
                signingConfig signingConfigs.debug
            }
'''

PERMISSIONS = '''
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-feature android:name="android.hardware.usb.host" />
'''

USB_METADATA = '''
            <intent-filter>
                <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
            </intent-filter>
            <meta-data
                android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
                android:resource="@xml/device_filter" />
'''

DEVICE_FILTER_XML = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- FTDI FT232/FT2232/FT4232 -->
    <usb-device vendor-id="1027" />
    <!-- Prolific PL2303 -->
    <usb-device vendor-id="1659" />
    <!-- QinHeng CH340/CH341 -->
    <usb-device vendor-id="6790" />
    <!-- Silicon Labs CP210x -->
    <usb-device vendor-id="4292" />
    <!-- CDC ACM examples: keep broad filtering in app-side discovery as well. -->
</resources>
'''


def configure_build_gradle() -> None:
    text = BUILD_GRADLE.read_text(encoding='utf-8')
    if 'System.getenv("KEYSTORE_FILE")' not in text:
        text = text.replace('android {\n', f'android {{\n{SIGNING_BLOCK}', 1)
    if 'ABI_FILTER' not in text:
        text = text.replace('android {\n', 'android {\n    def abiFilter = System.getenv("ABI_FILTER") ?: ""\n', 1)
    if 'abiFilters abiFilter' not in text:
        text = text.replace('        versionName = flutter.versionName\n', f'        versionName = flutter.versionName\n{ABI_DEFAULT_CONFIG}', 1)
    if 'signingConfigs.release.storeFile' not in text:
        text = text.replace('        release {\n', f'        release {{\n{RELEASE_SIGNING}', 1)
    BUILD_GRADLE.write_text(text, encoding='utf-8')


def configure_manifest() -> None:
    text = MANIFEST.read_text(encoding='utf-8')
    if 'android.hardware.usb.host' not in text:
        text = text.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', f'<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n{PERMISSIONS}', 1)
    if 'android.hardware.usb.action.USB_DEVICE_ATTACHED' not in text:
        text = text.replace('android:exported="true"', f'android:exported="true"\n{USB_METADATA}', 1)
    MANIFEST.write_text(text, encoding='utf-8')


def write_device_filter() -> None:
    DEVICE_FILTER.parent.mkdir(parents=True, exist_ok=True)
    DEVICE_FILTER.write_text(DEVICE_FILTER_XML, encoding='utf-8')


if __name__ == '__main__':
    configure_build_gradle()
    configure_manifest()
    write_device_filter()
