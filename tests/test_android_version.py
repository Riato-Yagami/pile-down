import importlib.util
import json
import shutil
import unittest
import uuid
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "configure_android", Path(__file__).resolve().parents[1] / "build/scripts/configure_android.py"
)
CONFIG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONFIG)


class AndroidVersionTests(unittest.TestCase):
    def setUp(self):
        self.scratch = Path(__file__).resolve().parents[1] / "build/.cache/version-tests"
        self.project = self.scratch / uuid.uuid4().hex
        self.project.mkdir(parents=True)
        self.addCleanup(self.clean_project)
        (self.project / "build/android").mkdir(parents=True)
        (self.project / "VERSION").write_text("2.1\n")
        (self.project / "build/android/version-codes.json").write_text(
            json.dumps({"versions": {"2.0": 1, "2.1": 2}})
        )
        (self.project / "export_presets.cfg").write_text(
            '[preset.0]\nplatform="Windows Desktop"\n[preset.0.options]\nversion/code=999\n'
            '[preset.1]\nplatform="Android"\n[preset.1.options]\nversion/code=1\nversion/name=""\n'
            '[preset.2]\nplatform="Android"\n[preset.2.options]\nversion/code=2\nversion/name=""\n'
        )

    def clean_project(self):
        if not self.project.resolve().is_relative_to(self.scratch.resolve()):
            raise ValueError("Refusing to clean a path outside the test workspace")
        shutil.rmtree(self.project)

    def test_known_and_arbitrary_new_version(self):
        self.assertEqual(CONFIG.sync_version(self.project), ("2.1", 2))
        (self.project / "VERSION").write_text("summer-edition")
        self.assertEqual(CONFIG.sync_version(self.project), ("summer-edition", 3))
        self.assertEqual(CONFIG.sync_version(self.project), ("summer-edition", 3))
        presets = (self.project / "export_presets.cfg").read_text()
        self.assertEqual(presets.count('version/name="summer-edition"'), 2)
        self.assertEqual(presets.count("version/code=3\n"), 2)
        self.assertIn("version/code=999\n", presets)
        (self.project / "VERSION").write_text("2.0")
        self.assertEqual(CONFIG.sync_version(self.project), ("2.0", 1))

    def test_manually_used_code_is_not_reassigned(self):
        p = self.project / "export_presets.cfg"
        p.write_text(p.read_text().replace("version/code=2\n", "version/code=12\n"))
        (self.project / "VERSION").write_text("next")
        self.assertEqual(CONFIG.sync_version(self.project), ("next", 13))

    def test_gradle_hook_survives_repeated_preparation(self):
        p = self.project / "android/build/build.gradle"
        p.parent.mkdir(parents=True)
        p.write_text("// Existing custom build settings\n")
        CONFIG.prepare_gradle(self.project)
        CONFIG.prepare_gradle(self.project)
        self.assertEqual(p.read_text().count("release-optimization.gradle"), 1)
        self.assertTrue(p.read_text().startswith("// Existing custom build settings"))


if __name__ == "__main__":
    unittest.main()
