from pathlib import Path
import xml.etree.ElementTree as ET

MANIFEST = Path('android/app/src/main/AndroidManifest.xml')
DEVICE_FILTER = Path('android/app/src/main/res/xml/device_filter.xml')
ANDROID_NS = 'http://schemas.android.com/apk/res/android'

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

DEVICE_FILTER_XML = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <usb-device vendor-id="1027" />
    <usb-device vendor-id="1659" />
    <usb-device vendor-id="6790" />
    <usb-device vendor-id="4292" />
</resources>
'''

PERMISSION_NAMES = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.FOREGROUND_SERVICE',
]


def _q(tag: str) -> str:
    return f'{{{ANDROID_NS}}}{tag}'


def configure_manifest() -> None:
    if not MANIFEST.exists():
        return

    ET.register_namespace('android', ANDROID_NS)
    tree = ET.parse(MANIFEST)
    root = tree.getroot()

    existing_perms = {
        elem.get(f'{{{ANDROID_NS}}}name')
        for elem in root.findall('uses-permission')
    }
    for name in PERMISSION_NAMES:
        if name not in existing_perms:
            ET.SubElement(root, 'uses-permission', {f'{{{ANDROID_NS}}}name': name})

    if root.find(f'uses-feature[@{_q("name")}="android.hardware.usb.host"]') is None:
        ET.SubElement(
            root,
            'uses-feature',
            {f'{{{ANDROID_NS}}}name': 'android.hardware.usb.host'},
        )

    application = root.find('application')
    if application is None:
        return

    activity = None
    for candidate in application.findall('activity'):
        if candidate.get(f'{{{ANDROID_NS}}}name', '').endswith('MainActivity'):
            activity = candidate
            break
    if activity is None:
        activity = application.find('activity')

    if activity is not None:
        has_usb = False
        for intent_filter in activity.findall('intent-filter'):
            for action in intent_filter.findall('action'):
                if action.get(f'{{{ANDROID_NS}}}name') == 'android.hardware.usb.action.USB_DEVICE_ATTACHED':
                    has_usb = True
        if not has_usb:
            intent_filter = ET.SubElement(activity, 'intent-filter')
            ET.SubElement(
                intent_filter,
                'action',
                {f'{{{ANDROID_NS}}}name': 'android.hardware.usb.action.USB_DEVICE_ATTACHED'},
            )
            ET.SubElement(
                activity,
                'meta-data',
                {
                    f'{{{ANDROID_NS}}}name': 'android.hardware.usb.action.USB_DEVICE_ATTACHED',
                    f'{{{ANDROID_NS}}}resource': '@xml/device_filter',
                },
            )

    tree.write(MANIFEST, encoding='utf-8', xml_declaration=True)


def configure_build_kts(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    if 'KEYSTORE_FILE' not in text:
        text = text.replace('android {\n', f'android {{{KTS_SIGNING_SNIPPET}', 1)
    if 'abiFilters' not in text:
        text = text.replace(
            '        versionName = flutter.versionName\n',
            f'        versionName = flutter.versionName\n{KTS_DEFAULT_CONFIG_ABI}',
            1,
        )
    if 'releaseSigning' not in text:
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