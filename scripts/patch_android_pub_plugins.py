#!/usr/bin/env python3
"""Patch third-party Android Gradle files in pub-cache for CI compatibility."""
from pathlib import Path
import os


def pub_cache_root() -> Path:
    return Path(os.environ.get('PUB_CACHE', Path.home() / '.pub-cache'))


COMPILE_SDK_TARGET = '35'


def bump_compile_sdk(text: str) -> str:
    """Raise plugin compileSdk so AAR metadata checks pass on CI runners."""
    updated = text
    for old in ('28', '29', '30', '31', '32', '33', '34'):
        updated = updated.replace(f'compileSdkVersion {old}', f'compileSdkVersion {COMPILE_SDK_TARGET}')
        updated = updated.replace(f'compileSdk {old}', f'compileSdk {COMPILE_SDK_TARGET}')
    updated = updated.replace(
        'compileSdk = flutter.compileSdkVersion',
        f'compileSdk = {COMPILE_SDK_TARGET}',
    )
    updated = updated.replace(
        'compileSdk flutter.compileSdkVersion',
        f'compileSdk {COMPILE_SDK_TARGET}',
    )
    return updated


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding='utf-8')
    updated = text.replace('jcenter()', 'mavenCentral()')
    updated = bump_compile_sdk(updated)
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
        'android.suppressUnsupportedCompileSdk': COMPILE_SDK_TARGET,
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
        for build_gradle in hosted.glob('*/android/build.gradle'):
            patch_file(build_gradle)
        for build_gradle in hosted.glob('*/android/build.gradle.kts'):
            patch_file(build_gradle)

    ensure_gradle_properties(Path('android'))
    patch_root_build_gradle()


if __name__ == '__main__':
    main()