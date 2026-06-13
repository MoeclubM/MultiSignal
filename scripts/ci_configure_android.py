from pathlib import Path

MANIFEST = Path('android/app/src/main/AndroidManifest.xml')
DEVICE_FILTER = Path('android/app/src/main/res/xml/device_filter.xml')

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
    <usb-device vendor-id="1027" />
    <usb-device vendor-id="1659" />
    <usb-device vendor-id="6790" />
    <usb-device vendor-id="4292" />
</resources>
'''

KTS_SIGNING_SNIPPET = '''
    val abiFilter = System.getenv("ABI_FILTER") ?: ""

    signingConfigs {
        create("release") {
            val keystoreFilePath = System.getenv("KEYSTORE_FILE") ?: ""
            if (keystoreFilePath.isNotEmpty() && file(keystoreFilePath).exists()) {
                storeFile = file(keystoreFilePath)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS") ?: "multisignal"
                keyPassword = System.getenv("KEYSTORE_PASSWORD")
            }
        }
    }
'''

KTS_DEFAULT_CONFIG_ABI = '''
        val filter = abiFilter
        if (filter.isNotEmpty()) {
            ndk {
                abiFilters += listOf(filter)
            }
        }
'''

KTS_RELEASE_SIGNING = '''
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = if (releaseSigning?.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
'''

GROOVY_SIGNING_SNIPPET = '''
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

GROOVY_DEFAULT_CONFIG_ABI = '''
        if (abiFilter != "") {
            ndk {
                abiFilters abiFilter
            }
        }
'''

GROOVY_RELEASE_SIGNING = '''
            if (signingConfigs.release.storeFile != null) {
                signingConfig signingConfigs.release
            } else {
                signingConfig signingConfigs.debug
            }
'''


def configure_build_kts(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    if 'KEYSTORE_FILE' not in text:
        text = text.replace('android {\n', f'android {{{KTS_SIGNING_SNIPPET}', 1)
    if 'abiFilter' not in text:
        marker = 'defaultConfig {'
        if marker in text and 'abiFilters' not in text:
            text = text.replace(
                '        versionName = flutter.versionName\n',
                f'        versionName = flutter.versionName\n{KTS_DEFAULT_CONFIG_ABI}',
                1,
            )
    if 'releaseSigning' not in text and 'buildTypes {' in text:
        text = text.replace(
            '        release {\n',
            f'        release {{{KTS_RELEASE_SIGNING}',
            1,
        )
    path.write_text(text, encoding='utf-8')


def configure_build_groovy(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    if 'KEYSTORE_FILE' not in text:
        text = text.replace('android {\n', f'android {{{GROOVY_SIGNING_SNIPPET}', 1)
    if 'abiFilters abiFilter' not in text:
        text = text.replace(
            '        versionName = flutter.versionName\n',
            f'        versionName = flutter.versionName\n{GROOVY_DEFAULT_CONFIG_ABI}',
            1,
        )
    if 'signingConfigs.release.storeFile' not in text:
        text = text.replace('        release {\n', f'        release {{{GROOVY_RELEASE_SIGNING}', 1)
    path.write_text(text, encoding='utf-8')


def configure_manifest() -> None:
    if not MANIFEST.exists():
        return
    text = MANIFEST.read_text(encoding='utf-8')
    if 'android.hardware.usb.host' not in text:
        text = text.replace(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
            f'<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n{PERMISSIONS}',
            1,
        )
    if 'android.hardware.usb.action.USB_DEVICE_ATTACHED' not in text:
        text = text.replace(
            'android:exported="true"',
            f'android:exported="true"\n{USB_METADATA}',
            1,
        )
    MANIFEST.write_text(text, encoding='utf-8')


def write_device_filter() -> None:
    DEVICE_FILTER.parent.mkdir(parents=True, exist_ok=True)
    DEVICE_FILTER.write_text(DEVICE_FILTER_XML, encoding='utf-8')


def configure_android_build() -> None:
    kts = Path('android/app/build.gradle.kts')
    groovy = Path('android/app/build.gradle')
    if kts.exists():
        configure_build_kts(kts)
    elif groovy.exists():
        configure_build_groovy(groovy)
    else:
        raise FileNotFoundError('No android/app/build.gradle(.kts) found. Run flutter create first.')


if __name__ == '__main__':
    configure_android_build()
    configure_manifest()
    write_device_filter()