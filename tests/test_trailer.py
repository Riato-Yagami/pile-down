"""Trailer layout and timing checks: python -m unittest discover -s tests -p test_trailer.py."""

from copy import deepcopy
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "publishing/scripts"))
import create_trailer as trailer


class TrailerSettingsTest(unittest.TestCase):
    def test_title_and_orientation_overrides_keep_other_settings(self):
        defaults = deepcopy(trailer.config.TITLE_DEFAULTS)
        with patch.object(trailer.config, "TITLE_OVERRIDES", {
            "outro": {"brand": {"x": 0.4}, "lift": {"start": 1.1},
                      "portrait": {"brand": {"y": 0.48}}},
        }):
            portrait = trailer.title_settings("portrait", "outro")
            landscape = trailer.title_settings("landscape", "outro")
            self.assertEqual(portrait["brand"]["y"], 0.48)
            self.assertEqual(landscape["brand"]["y"], defaults["brand"]["y"])
            self.assertEqual(portrait["brand"]["x"], 0.4)
            self.assertEqual(portrait["brand"]["start"], 1.1)
            self.assertEqual(portrait["headline"]["wrap_after"], 18)
            self.assertIsNone(landscape["headline"]["wrap_after"])
            portrait["brand"]["x"] = 0
            self.assertEqual(trailer.config.TITLE_DEFAULTS, defaults)

    def test_final_brand_position_uses_ratios_and_pixel_offsets(self):
        settings = trailer.title_settings("portrait", "outro")["brand"]
        sprite = Image.new("RGBA", (100, 40), "white")
        for width, height in ((1080, 1920), (1920, 1080)):
            with self.subTest(size=(width, height)):
                frame = Image.new("RGB", (width, height))
                trailer.draw_ending_brand(frame, sprite, 3, {**settings, "offset_y": -10})
                left, top, right, bottom = frame.getbbox()
                self.assertAlmostEqual((left + right) / 2, width * settings["x"], delta=1)
                self.assertAlmostEqual((top + bottom) / 2, height * settings["y"] - 10, delta=1)


class TrailerTransitionsTest(unittest.TestCase):
    def setUp(self):
        self.timeline = [("title", name, 2.0) for name in ("intro", "friends", "shell", "outro")]
        for name, value in (
            ("TRANSITION_DEFAULTS", {"type": "swipe", "direction": "left", "style": "smooth", "duration": 0.2}),
            ("TRANSITION_SEQUENCE", []),
            ("TRANSITION_OVERRIDES", {}),
        ):
            patcher = patch.object(trailer.config, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_variable_overlaps_and_cuts_share_the_same_clock(self):
        trailer.config.TRANSITION_SEQUENCE = [{}, {"type": "fade", "duration": 0.51}, {"type": "cut"}]
        transitions, starts, duration = trailer.transition_plan(self.timeline)
        self.assertEqual(starts, [0.0, 1.8, 3.3, 5.3])
        self.assertEqual(duration, 7.3)
        self.assertEqual([t["duration"] for t in transitions], [0.2, 0.5, 0.0])
        self.assertEqual([t["filter"] for t in transitions], ["smoothleft", "fade", None])

    def test_specific_transition_has_priority(self):
        trailer.config.TRANSITION_SEQUENCE = [{"direction": "up"}]
        trailer.config.TRANSITION_OVERRIDES = {
            "title:friends->title:shell": {"style": "wipe", "direction": "right", "duration": 0.4},
        }
        transitions, _, _ = trailer.transition_plan(self.timeline)
        self.assertEqual([t["filter"] for t in transitions], ["smoothup", "wiperight", "smoothup"])
        self.assertEqual(transitions[1]["duration"], 0.4)

    def test_invalid_transitions_fail_before_encoding(self):
        for values in ({"duration": 0}, {"duration": float("nan")}, {"duration": 1.1},
                       {"direction": "diagonal"}, {"style": "typo"}, {"type": "typo"}):
            with self.subTest(values=values):
                trailer.config.TRANSITION_SEQUENCE = [values]
                with self.assertRaises(ValueError):
                    trailer.transition_plan(self.timeline)

    @unittest.skipUnless(shutil.which("ffmpeg"), "FFmpeg is required for transition rendering")
    def test_ffmpeg_renders_fade_cut_and_swipe_with_expected_timing(self):
        # A swipe after a cut also checks that concat preserves a usable frame rate.
        trailer.config.TRANSITION_SEQUENCE = [
            {"type": "fade"}, {"type": "cut"}, {"style": "wipe", "direction": "up", "duration": 0.5},
        ]
        transitions, starts, duration = trailer.transition_plan(self.timeline)
        graph, label = trailer.video_filter_graph(4, transitions, starts)
        command = [shutil.which("ffmpeg"), "-hide_banner", "-loglevel", "error"]
        for color in ("red", "lime", "blue", "white"):
            command += ["-f", "lavfi", "-i", f"color=c={color}:s=64x36:r=30:d=2"]
        command += ["-filter_complex_threads", "1", "-filter_complex", graph, "-map", f"[{label}]",
                    "-t", str(duration), "-pix_fmt", "rgb24", "-f", "rawvideo", "pipe:1"]
        result = subprocess.run(command, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
        frame_bytes = 64 * 36 * 3
        self.assertEqual(len(result.stdout) // frame_bytes, round(duration * trailer.FPS))

        def center_pixel(at):
            frame = round(at * trailer.FPS)
            offset = frame * frame_bytes + (18 * 64 + 32) * 3
            return tuple(result.stdout[offset:offset + 3])

        red, green, blue = center_pixel(0.5), center_pixel(2.5), center_pixel(4.5)
        self.assertGreater(red[0], 240)
        self.assertGreater(green[1], 240)
        self.assertGreater(blue[2], 240)
        self.assertTrue(all(value > 240 for value in center_pixel(7.0)))
        blend = center_pixel(1.9)
        self.assertGreater(blend[0], 50)
        self.assertGreater(blend[1], 50)


if __name__ == "__main__":
    unittest.main()
