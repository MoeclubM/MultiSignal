#!/usr/bin/env python3
"""Patch third-party Android Gradle files in pub-cache for CI compatibility."""
from pathlib import Path
import os


def pub_cache_root() -> Path:
    return Path(os.environ.get('PUB_CACHE', Path.home() / '.pub-cache'))


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding='utf-8')
    updated = text.replace('jcenter()', 'mavenCentral()')
    if 'compileSdkVersion' in updated and 'compileSdkVersion 36' not in updated:
        updated = updated.replace('compileSdkVersion 28', 'compileSdkVersion 34')
        updated = updated.replace('compileSdkVersion 29', 'compileSdkVersion 34')
        updated = updated.replace('compileSdkVersion 30', 'compileSdkVersion 34')
        updated = updated.replace('compileSdkVersion 31', 'compileSdkVersion 34')
        updated = updated.replace('compileSdkVersion 33', 'compileSdkVersion 34')
    if updated == text:
        return False
    path.write_text(updated, encoding='utf-8')
    print(f'Patched {path}')
    return True


def ensure_gradle_properties(project_android: Path) -> None:
    props = project_android / 'gradle.properties'
    lines = []
    if props.exists():
        lines = props.read_text(encoding='utf-8').splitlines()
    wanted = {
        'android.newDsl': 'false',
        'android.suppressUnsupportedCompileSdk': '36',
    }
    existing = {line.split('=')[0].strip(): line for line in lines if '=' in line}
    for key, value in wanted.items():
        if key not in existing:
            lines.append(f'{key}={value}')
    props.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'Updated {props}')


def patch_root_build_gradle() -> None:
    """Skip desktop-only serialport plugin tasks on Android CI builds."""
    for name in ('build.gradle.kts', 'build.gradle'):
        root = Path('android') / name
        if not root.exists():
            continue
        text = root.read_text(encoding='utf-8')
        marker = 'multisignal_skip_libserialport_android'
        if marker in text:
            return
        if name.endswith('.kts'):
            injection = '''

// multisignal_skip_libserialport_android
subprojects {
    if (name == "flutter_libserialport") {
        tasks.configureEach { enabled = false }
    }
}
'''
        else:
            injection = '''

// multisignal_skip_libserialport_android
subprojects { project ->
    if (project.name == "flutter_libserialport") {
        project.tasks.configureEach { task -> task.enabled = false }
    }
}
'''
        root.write_text(text + injection, encoding='utf-8')
        print(f'Updated {root}')


def main() -> None:
    hosted = pub_cache_root() / 'hosted' / 'pub.dev'
    if hosted.is_dir():
        for pattern in (
            'flutter_libserialport-*/android/build.gradle',
            'usb_serial-*/android/build.gradle',
            'file_picker-*/android/build.gradle',
        ):
            for build_gradle in hosted.glob(pattern):
                patch_file(build_gradle)

    ensure_gradle_properties(Path('android'))
    patch_root_build_gradle()


if __name__ == '__main__':
    main()