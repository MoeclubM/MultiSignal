#!/usr/bin/env python3
"""Patch third-party Android Gradle files in pub-cache for CI compatibility."""
from pathlib import Path
import os
import re


def pub_cache_root() -> Path:
    return Path(os.environ.get('PUB_CACHE', Path.home() / '.pub-cache'))


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding='utf-8')
    updated = text.replace('jcenter()', 'mavenCentral()')
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
    }
    existing = {line.split('=')[0].strip(): line for line in lines if '=' in line}
    for key, value in wanted.items():
        if key not in existing:
            lines.append(f'{key}={value}')
    props.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'Updated {props}')


def main() -> None:
    hosted = pub_cache_root() / 'hosted' / 'pub.dev'
    if hosted.is_dir():
        for build_gradle in hosted.glob('flutter_libserialport-*/android/build.gradle'):
            patch_file(build_gradle)
        for build_gradle in hosted.glob('usb_serial-*/android/build.gradle'):
            patch_file(build_gradle)

    ensure_gradle_properties(Path('android'))


if __name__ == '__main__':
    main()