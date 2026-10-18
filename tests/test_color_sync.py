"""Exercise the actual Godot synchronizer in an isolated project.

Set PILE_DOWN_GODOT_BIN when Godot is not on PATH.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


PROJECT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("PILE_DOWN_GODOT_BIN") or shutil.which("godot")


@unittest.skipUnless(GODOT, "Set PILE_DOWN_GODOT_BIN or put godot on PATH")
class ColorSyncTests(unittest.TestCase):
    def test_shader_globals_line_endings_and_missing_binding(self):
        for newline in ("\n", "\r\n"):
            with self.subTest(newline=repr(newline)), tempfile.TemporaryDirectory() as folder:
                fixture = Path(folder)
                tools = fixture / "resources/scripts/tools"
                settings = fixture / "resources/scripts/settings"
                tools.mkdir(parents=True)
                settings.mkdir(parents=True)
                shutil.copyfile(PROJECT / "resources/scripts/tools/SyncColors.gd",
                                tools / "SyncColors.gd")
                (settings / "colors.gd").write_text(
                    "extends RefCounted\nconst FIRST := Color(1, 0, 0, 1)\n"
                    "const SECOND := Color(0, 1, 0, 1)\n", encoding="utf-8")
                bindings = [
                    {"file": "project.godot", "section": "[shader_globals]/" + name,
                     "key": '"value"', "kind": "color", "colors": [constant]}
                    for name, constant in (("first", "FIRST"), ("second", "SECOND"))
                ]
                manifest = tools / "color_bindings.json"
                manifest.write_text(json.dumps(bindings), encoding="utf-8")
                config = fixture / "project.godot"
                config.write_bytes(newline.join([
                    "config_version=5", "", "[shader_globals]", "",
                    "first={", '"type": "color",', '"value": Color(0, 0, 0, 1)', "}",
                    "second={", '"type": "color",', '"value": Color(0, 0, 0, 1)', "}", "",
                ]).encode())

                def run(*args):
                    result = subprocess.run(
                        [GODOT, "--headless", "--path", str(fixture), "--script",
                         "resources/scripts/tools/SyncColors.gd", *args],
                        capture_output=True, text=True, timeout=30)
                    return result.returncode, result.stdout + result.stderr

                code, output = run()
                self.assertEqual(code, 0, output)
                synchronized = config.read_bytes()
                self.assertIn(b"Color(1.000000000, 0.000000000, 0.000000000, 1.000000000)", synchronized)
                self.assertIn(b"Color(0.000000000, 1.000000000, 0.000000000, 1.000000000)", synchronized)
                if newline == "\r\n":
                    self.assertNotIn(b"\n", synchronized.replace(b"\r\n", b""))
                else:
                    self.assertNotIn(b"\r", synchronized)
                code, output = run("--", "--check")
                self.assertEqual(code, 0, output)
                self.assertEqual(config.read_bytes(), synchronized)
                bindings[1]["section"] = "[shader_globals]/removed"
                manifest.write_text(json.dumps(bindings), encoding="utf-8")
                code, output = run()
                self.assertNotEqual(code, 0, output)
                self.assertIn('[shader_globals]/removed "value"', output)
                self.assertEqual(config.read_bytes(), synchronized)


if __name__ == "__main__":
    unittest.main()
