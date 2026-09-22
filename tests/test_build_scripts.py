"""Offline regression tests; run with Python 3 and Bash (Git Bash on Windows)."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile


PROJECT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("PILE_DOWN_BASH") or shutil.which("bash")


@unittest.skipUnless(BASH, "Set PILE_DOWN_BASH to the Bash executable")
class BuildScriptsTest(unittest.TestCase):
    def setUp(self):
        scratch = PROJECT / "build" / "tmp" / "build-script-tests"
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix="case-", dir=scratch)
        self.project = Path(self.temp.name).resolve()
        assert self.project.is_relative_to(scratch.resolve())
        self.addCleanup(self.temp.cleanup)
        (self.project / "build/scripts").mkdir(parents=True)
        for script in (PROJECT / "build/scripts").glob("*"):
            if script.is_file():
                shutil.copy2(script, self.project / "build/scripts" / script.name)
        (self.project / "VERSION").write_text("v2.0\n", encoding="utf-8")
        self.fake_godot = self.project / "fake-godot.sh"
        self.env = os.environ.copy()
        for name in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "PILE_DOWN_TEMPLATE_ARCHIVE"):
            self.env.pop(name, None)
        self.env["PILE_DOWN_GODOT_BIN"] = self.fake_godot.as_posix()
        self.env["PILE_DOWN_PYTHON_BIN"] = Path(sys.executable).as_posix()
        self.set_version("4.7.2.stable.official.ed1daf0bf")

    def set_version(self, version):
        self.fake_godot.write_text(
            "#!/usr/bin/env bash\nprintf '%s\\n' '" + version + "'\n",
            encoding="utf-8", newline="\n",
        )
        self.fake_godot.chmod(0o755)

    def run_script(self, *args):
        return subprocess.run(
            [BASH, (self.project / "build/scripts" / "ensure_export_templates.sh").as_posix(), *args],
            env=self.env, cwd=self.project, capture_output=True, text=True, timeout=30,
        )

    def seed_archive(self, release):
        cache = self.project / "build" / ".cache" / "templates"
        cache.mkdir(parents=True, exist_ok=True)
        archive = cache / f"Godot_v{release}_export_templates.tpz"
        with zipfile.ZipFile(archive, "w") as bundle:
            bundle.writestr("templates/version.txt", release.replace("-", "."))
            bundle.writestr("templates/web_nothreads_debug.zip", "debug fixture")
            bundle.writestr("templates/web_nothreads_release.zip", "release fixture")
        return archive

    def test_official_mono_and_prerelease_versions(self):
        for version, release, directory in (
            ("4.7.2.stable.official.ed1daf0bf", "4.7.2-stable", "4.7.2.stable"),
            ("4.6.stable.mono.official.abcdef", "4.6-stable", "4.6.stable"),
            ("4.8.beta1.official.abcdef", "4.8-beta1", "4.8.beta1"),
        ):
            with self.subTest(version=version):
                self.set_version(version)
                self.seed_archive(release)
                result = self.run_script("web")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                templates = list((self.project / "build" / ".cache").rglob("web_nothreads_release.zip"))
                self.assertTrue(any(p.parent.name == directory for p in templates))
                if os.name == "nt":
                    expected = self.project / "build/.cache/config/Godot/export_templates" / directory
                    self.assertTrue((expected / "web_nothreads_release.zip").is_file())

    def test_installed_templates_do_not_require_archive_or_network(self):
        archive = self.seed_archive("4.7.2-stable")
        self.assertEqual(self.run_script("web").returncode, 0)
        archive.unlink()
        result = self.run_script("web")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("Downloading", result.stdout)

    def test_invalid_platform_and_missing_arguments(self):
        for args in ((), ("unknown",)):
            with self.subTest(args=args):
                result = self.run_script(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Downloading", result.stdout)

    def test_invalid_engine_version(self):
        self.set_version("not-a-version")
        result = self.run_script("web")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unrecognized Godot version", result.stderr)

    def prepare_android(self, version="17.0.12"):
        jdk = self.project / "Java SDK"
        sdk = self.project / "Android SDK"
        for path, output in (
            (jdk / "bin/java", version),
            (jdk / "bin/javac", "javac " + version),
            (sdk / "platform-tools/adb", "Android Debug Bridge"),
        ):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("#!/usr/bin/env bash\necho '" + output + "'\n",
                            encoding="utf-8", newline="\n")
            path.chmod(0o755)
        for name in ("PILE_DOWN_JAVA_HOME", "PILE_DOWN_ANDROID_SDK", "ANDROID_SDK_ROOT"):
            self.env.pop(name, None)
        self.env["JAVA_HOME"] = str(jdk)
        self.env["ANDROID_HOME"] = str(sdk)
        self.env["PILE_DOWN_ANDROID_EXPORT_MODE"] = "debug"
        keystore = self.project / "build/.android/debug.keystore"
        keystore.parent.mkdir(parents=True)
        keystore.write_text("fixture")
        archive = self.seed_archive("4.7.2-stable")
        with zipfile.ZipFile(archive, "a") as bundle:
            for name in ("android_debug.apk", "android_release.apk"):
                bundle.writestr("templates/" + name, "fixture")
        self.fake_godot.write_text(
            '#!/usr/bin/env bash\nset -eu\n'
            'if [[ "$1" == "--version" ]]; then\n'
            '  echo "4.7.2.stable.official.fixture"\n'
            'else\n'
            '  test -f "$JAVA_HOME/bin/javac"\n'
            '  test -f "$ANDROID_HOME/platform-tools/adb"\n'
            '  test -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH"\n'
            '  if [[ "$*" == *"--script"* ]]; then exit 0; fi\n'
            '  printf fixture > "${@: -1}"\n'
            'fi\n', encoding="utf-8", newline="\n",
        )

    def run_android(self):
        return subprocess.run(
            [BASH, (self.project / "build/scripts/build_android.sh").as_posix()],
            env=self.env, cwd=self.project, capture_output=True, text=True, timeout=30,
        )

    def test_android_standard_environment_with_spaces(self):
        self.prepare_android()
        result = self.run_android()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.project / "build/platforms/android/pile-down-android-v2.0.apk").is_file())

    def test_android_rejects_java_8_before_downloading(self):
        self.prepare_android("1.8.0_121")
        result = self.run_android()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("OpenJDK 17 or newer is required", result.stderr)
        self.assertNotIn("Downloading", result.stdout)

    def prepare_aab(self):
        self.prepare_android()
        archive = self.seed_archive("4.7.2-stable")
        with zipfile.ZipFile(archive, "a") as bundle:
            for name in ("android_source.zip", "android_release.apk"):
                bundle.writestr("templates/" + name, "fixture")
        self.env["GODOT_ANDROID_KEYSTORE_RELEASE_PATH"] = "upload key.keystore"
        self.env["GODOT_ANDROID_KEYSTORE_RELEASE_USER"] = "upload"
        self.env["GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"] = "fixture-secret"
        self.fake_godot.write_text(
            '#!/usr/bin/env bash\nset -eu\n'
            'if [[ "$1" == "--version" ]]; then\n'
            '  echo "4.7.2.stable.official.fixture"\n'
            'elif [[ "$*" == *"--script"* ]]; then\n'
            '  exit 0\n'
            'else\n'
            '  printf "%s\\n" "$@" > export-args.txt\n'
            '  [[ -n "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ]]\n'
            '  exit_code="${PILE_DOWN_TEST_EXPORT_EXIT:-0}"\n'
            '  if [[ "$exit_code" != 0 ]]; then exit "$exit_code"; fi\n'
            '  printf bundle > "${@: -1}"\n'
            'fi\n', encoding="utf-8", newline="\n",
        )

    def run_aab(self):
        return subprocess.run(
            [BASH, (self.project / "build/scripts/build_android_aab.sh").as_posix()],
            env=self.env, cwd=self.project, capture_output=True, text=True, timeout=30,
        )

    def test_aab_release_preset_templates_and_existing_gradle(self):
        self.prepare_aab()
        for existing in (False, True):
            if existing:
                (self.project / "android/build").mkdir(parents=True)
            result = self.run_aab()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            args = (self.project / "export-args.txt").read_text().splitlines()
            self.assertIn("--export-release", args)
            self.assertIn("Android AAB", args)
            self.assertEqual("--install-android-build-template" in args, not existing)
            self.assertTrue(list((self.project / "build/.cache").rglob("android_source.zip")))
            output = self.project / "build/platforms/android/pile-down-android-v2.0.aab"
            self.assertEqual(output.read_text(), "bundle")
            self.assertNotIn("fixture-secret", result.stdout + result.stderr)

    def test_aab_requires_signing_and_propagates_export_failure(self):
        self.prepare_aab()
        self.env.pop("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD")
        result = self.run_aab()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", result.stderr)
        self.assertFalse((self.project / "export-args.txt").exists())
        self.env["GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"] = "fixture-secret"
        self.env["PILE_DOWN_TEST_EXPORT_EXIT"] = "7"
        result = self.run_aab()
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertNotIn("build ready", result.stdout)

    def test_aab_rejects_java_25_before_export(self):
        self.prepare_android("25.0.1")
        result = self.run_aab()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("JDK 17 to 23", result.stderr)
        self.assertNotIn("Downloading", result.stdout)
        self.assertFalse((self.project / "export-args.txt").exists())

    def test_build_all_includes_aab_and_propagates_failure(self):
        scripts = ("windows", "web", "linux", "android", "android_aab")
        for platform in scripts:
            script = self.project / f"build/scripts/build_{platform}.sh"
            script.write_text(
                '#!/usr/bin/env bash\n'
                f'echo {platform} >> builds.txt\n'
                + ('exit "${PILE_DOWN_TEST_EXPORT_EXIT:-0}"\n' if platform == "android_aab" else ''),
                encoding="utf-8", newline="\n",
            )
            script.chmod(0o755)
        for exit_code in (0, 7):
            with self.subTest(exit_code=exit_code):
                self.env["PILE_DOWN_TEST_EXPORT_EXIT"] = str(exit_code)
                result = subprocess.run(
                    [BASH, (self.project / "build/scripts/build_all.sh").as_posix()],
                    env=self.env, cwd=self.project, capture_output=True, text=True, timeout=30,
                )
                self.assertEqual(result.returncode, exit_code, result.stdout + result.stderr)
                log = self.project / "builds.txt"
                self.assertEqual(log.read_text().splitlines(), list(scripts))
                log.unlink()
                self.assertEqual("builds are ready" in result.stdout, exit_code == 0)

    def test_android_explicit_overrides_standard_environment(self):
        self.prepare_android()
        self.env["PILE_DOWN_JAVA_HOME"] = self.env["JAVA_HOME"]
        self.env["PILE_DOWN_ANDROID_SDK"] = self.env["ANDROID_HOME"]
        self.env["JAVA_HOME"] = "missing-java"
        self.env["ANDROID_HOME"] = "missing-sdk"
        result = self.run_android()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_corrupt_cached_archive_fails(self):
        archive = self.seed_archive("4.7.2-stable")
        archive.write_bytes(b"interrupted archive")
        result = self.run_script("web")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(list((self.project / "build/.cache").rglob("web_nothreads_release.zip")))

    def test_archive_executable_permissions_and_no_stale_entries(self):
        source = self.project / "pile-down.x86_64"
        source.write_bytes(b"executable fixture")
        archive = self.project / "release.zip"
        with zipfile.ZipFile(archive, "w") as old:
            old.writestr("stale.txt", "old build")
        result = subprocess.run(
            [sys.executable, str(PROJECT / "build/scripts/package_archive.py"),
             "--executable", str(archive), str(source)],
            capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        with zipfile.ZipFile(archive) as bundle:
            self.assertEqual(bundle.namelist(), [source.name])
            entry = bundle.getinfo(source.name)
            self.assertEqual(entry.create_system, 3)
            self.assertEqual((entry.external_attr >> 16) & 0o777, 0o755)
            self.assertEqual(bundle.read(source.name), source.read_bytes())
            self.assertIsNone(bundle.testzip())

    def test_missing_output_does_not_replace_previous_archive(self):
        archive = self.project / "release.zip"
        archive.write_bytes(b"previous build")
        result = subprocess.run(
            [sys.executable, str(PROJECT / "build/scripts/package_archive.py"),
             str(archive), str(self.project / "missing.exe")],
            capture_output=True, text=True, timeout=30,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing build output", result.stderr)
        self.assertEqual(archive.read_bytes(), b"previous build")

    def test_platform_folder_keeps_archives_of_multiple_versions(self):
        archive = self.seed_archive("4.7.2-stable")
        with zipfile.ZipFile(archive, "a") as bundle:
            for name in ("linux_debug.x86_64", "linux_release.x86_64"):
                bundle.writestr("templates/" + name, "template fixture")
        self.fake_godot.write_text(
            '#!/usr/bin/env bash\nset -eu\n'
            'if [[ "$1" == "--version" ]]; then\n'
            '  echo "4.7.2.stable.official.ed1daf0bf"\n'
            'else\n'
            '  printf "%s" "$PILE_DOWN_TEST_CONTENT" > "${@: -1}"\n'
            'fi\n', encoding="utf-8", newline="\n",
        )
        for version in ("v2.0", "v2.1"):
            (self.project / "VERSION").write_text(version, encoding="utf-8")
            self.env["PILE_DOWN_TEST_CONTENT"] = version
            result = subprocess.run(
                [BASH, (self.project / "build/scripts/build_linux.sh").as_posix()],
                env=self.env, cwd=self.project.parent,
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        platform = self.project / "build/platforms/linux"
        for version in ("v2.0", "v2.1"):
            with zipfile.ZipFile(platform / f"pile-down-linux-{version}.zip") as bundle:
                self.assertEqual(bundle.read("pile-down.x86_64"), version.encode())
        self.assertEqual((platform / "pile-down.x86_64").read_bytes(), b"v2.1")
        self.assertFalse((self.project / "build/versions").exists())


if __name__ == "__main__":
    unittest.main()
