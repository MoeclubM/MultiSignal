#!/usr/bin/env python3
"""Patch third-party Android Gradle files in pub-cache for CI compatibility."""
from pathlib import Path
import os


def pub_cache_root() -> Path:
    return Path(os.environ.get('PUB_CACHE', Path.home() / '.pub-cache'))


COMPILE_SDK_TARGET = '36'
MARKER_FORCE_KOTLIN = 'multisignal_force_kotlin'


def bump_compile_sdk(text: str, *, kts: bool) -> str:
    """Raise plugin compileSdk so AAR metadata checks pass on CI runners."""
    compile_sdk = f'compileSdk = {COMPILE_SDK_TARGET}' if kts else f'compileSdk {COMPILE_SDK_TARGET}'
    updated = text
    for old in ('28', '29', '30', '31', '32', '33', '34', '35'):
        updated = updated.replace(f'compileSdkVersion {old}', f'compileSdkVersion {COMPILE_SDK_TARGET}')
        if kts:
            updated = updated.replace(f'compileSdk = {old}', f'compileSdk = {COMPILE_SDK_TARGET}')
            updated = updated.replace(f'compileSdk {old}', f'compileSdk = {COMPILE_SDK_TARGET}')
        else:
            updated = updated.replace(f'compileSdk {old}', f'compileSdk {COMPILE_SDK_TARGET}')
    updated = updated.replace('compileSdk = flutter.compileSdkVersion', compile_sdk)
    updated = updated.replace('compileSdk flutter.compileSdkVersion', compile_sdk)
    return updated


def patch_agp9_kotlin_groovy(path: Path) -> bool:
    """Force Kotlin plugin on AGP 9 for plugins that skip it but still ship Kotlin sources."""
    if path.name != 'build.gradle' or 'file_picker' not in str(path):
        return False
    text = path.read_text(encoding='utf-8')
    if MARKER_FORCE_KOTLIN in text or 'isAgp9OrAbove' not in text:
        return False
    updated = text.replace(
        """apply plugin: 'com.android.library'
if (!isAgp9OrAbove) {
    apply plugin: 'org.jetbrains.kotlin.android'
}""",
        f"""apply plugin: 'com.android.library'
// {MARKER_FORCE_KOTLIN}: Flutter 3.44 (AGP 9) still needs explicit Kotlin plugin here
apply plugin: 'org.jetbrains.kotlin.android'""",
    )
    updated = updated.replace(
        """    if (!isAgp9OrAbove) {
        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_17.toString()
        }
    }""",
        f"""    // {MARKER_FORCE_KOTLIN}
    kotlinOptions {{
        jvmTarget = JavaVersion.VERSION_17.toString()
    }}""",
    )
    if updated == text:
        return False
    path.write_text(updated, encoding='utf-8')
    print(f'Patched AGP9 Kotlin in {path}')
    return True


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding='utf-8')
    updated = text.replace('jcenter()', 'mavenCentral()')
    updated = bump_compile_sdk(updated, kts=path.name.endswith('.kts'))
    changed = updated != text
    if changed:
        path.write_text(updated, encoding='utf-8')
        print(f'Patched {path}')
    patch_agp9_kotlin_groovy(path)
    return changed


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


def strip_libserialport_skip_from_root_gradle() -> None:
    """Remove legacy CI hack that disabled plugin tasks (breaks checkReleaseAarMetadata)."""
    marker = 'multisignal_skip_libserialport_android'
    for name in ('build.gradle.kts', 'build.gradle'):
        root = Path('android') / name
        if not root.exists():
            continue
        text = root.read_text(encoding='utf-8')
        if marker not in text:
            continue
        root.write_text(text.split(marker, 1)[0].rstrip() + '\n', encoding='utf-8')
        print(f'Removed libserialport skip block from {root}')


def main() -> None:
    hosted = pub_cache_root() / 'hosted' / 'pub.dev'
    if hosted.is_dir():
        for build_gradle in hosted.glob('*/android/build.gradle'):
            patch_file(build_gradle)
        for build_gradle in hosted.glob('*/android/build.gradle.kts'):
            patch_file(build_gradle)

    ensure_gradle_properties(Path('android'))
    strip_libserialport_skip_from_root_gradle()


if __name__ == '__main__':
    main()