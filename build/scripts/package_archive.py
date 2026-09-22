#!/usr/bin/env python3
"""Package flat release archives with portable Unix file permissions."""
import argparse
from pathlib import Path
import shutil
import stat
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", action="store_true")
    parser.add_argument("archive", type=Path)
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    for source in args.files:
        if not source.is_file():
            parser.error(f"Missing build output: {source}")
    if len({source.name for source in args.files}) != len(args.files):
        parser.error("Archive filenames must be unique")
    temporary = args.archive.with_suffix(args.archive.suffix + ".part")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for source in args.files:
            entry = zipfile.ZipInfo.from_file(source, arcname=source.name)
            entry.create_system = 3  # Unix metadata, even when built on Windows.
            entry.external_attr = (stat.S_IFREG | (0o755 if args.executable else 0o644)) << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            with source.open("rb") as contents, archive.open(entry, "w") as target:
                shutil.copyfileobj(contents, target)
    temporary.replace(args.archive)


if __name__ == "__main__":
    main()
