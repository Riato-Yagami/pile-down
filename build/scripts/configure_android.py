#!/usr/bin/env python3
"""Synchronize Android versions and install the tracked release optimization hook."""
import argparse
import json
import re
from pathlib import Path


def android_sections(presets: str) -> list[str]:
    sections = re.findall(r"(?ms)^\[preset\.(\d+)\]\s*\n(.*?)(?=^\[|\Z)", presets)
    return [number for number, body in sections if re.search(r'^platform="Android"$', body, re.M)]


def sync_version(project: Path) -> tuple[str, int]:
    version = (project / "VERSION").read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9._+-]*", version):
        raise ValueError("VERSION must be a non-empty filename-safe label")
    history_path = project / "build/android/version-codes.json"
    history = json.loads(history_path.read_text(encoding="utf-8"))
    versions = history["versions"]
    if not isinstance(versions, dict) or any(
        type(code) is not int or not 1 <= code <= 2100000000
        for code in versions.values()
    ) or len(set(versions.values())) != len(versions):
        raise ValueError("Invalid or duplicate Android version codes in history")
    preset_path = project / "export_presets.cfg"
    presets = preset_path.read_text(encoding="utf-8")
    numbers = android_sections(presets)
    if not numbers:
        raise ValueError("No Android export preset found")
    patterns = [rf"(?ms)(^\[preset\.{number}\.options\]\s*\n)(.*?)(?=^\[|\Z)" for number in numbers]
    bodies = []
    for pattern in patterns:
        match = re.search(pattern, presets)
        if not match:
            raise ValueError("Missing Android export options")
        bodies.append(match.group(2))
    used_codes = [int(code) for body in bodies for code in re.findall(r"^version/code=(\d+)$", body, re.M)]
    if version not in versions:
        code = max([0, *versions.values(), *used_codes]) + 1
        if code > 2100000000:
            raise ValueError("Android version code limit exceeded")
        versions[version] = code
    code = versions[version]
    for pattern in patterns:
        def update(match: re.Match) -> str:
            body = match.group(2)
            for key, value in [("version/code", str(code)), ("version/name", json.dumps(version))]:
                line = f"{key}={value}"
                if re.search(rf"^{key}=.*$", body, re.M):
                    body = re.sub(rf"^{key}=.*$", lambda _: line, body, flags=re.M)
                else:
                    body += line + "\n"
            return match.group(1) + body
        presets = re.sub(pattern, update, presets)
    # Record allocations first: an interrupted export must never reuse a code
    # for another version label. Each file replacement is atomic.
    atomic_write(history_path, json.dumps(history, indent=2, ensure_ascii=False) + "\n")
    atomic_write(preset_path, presets)
    return version, code


def atomic_write(path: Path, text: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(text, encoding="utf-8", newline="\n")
    temporary.replace(path)


def prepare_gradle(project: Path) -> None:
    gradle_path = project / "android/build/build.gradle"
    if not gradle_path.is_file():
        raise ValueError("Install the Godot Android build template before preparing Gradle")
    hook = "apply from: '../../build/android/release-optimization.gradle'"
    contents = gradle_path.read_text(encoding="utf-8")
    if hook not in contents:
        atomic_write(gradle_path, contents.rstrip() + "\n\n// Pile Down release optimization.\n" + hook + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--prepare-gradle", action="store_true")
    args = parser.parse_args()
    version, code = sync_version(args.project)
    if args.prepare_gradle:
        prepare_gradle(args.project)
    print(f"Android version: {version} (versionCode {code})")


if __name__ == "__main__":
    main()
