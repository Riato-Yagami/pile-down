"""Generate fullscreen French/English portrait/landscape gameplay trailers."""

import argparse
from copy import deepcopy
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from PIL import Image, ImageDraw, ImageFont
from create_kofi_banner import load_game_assets, make_tile
import trailer_config as config

PROJECT = Path(__file__).resolve().parents[2]
WORK = PROJECT / "wip/trailer"
OUTPUT = PROJECT / "publishing/trailer"
FPS = 30


def title_settings(mode, name):
    """Merge only the edited properties, keeping each screen independent."""
    settings = deepcopy(config.TITLE_DEFAULTS)
    overrides = config.TITLE_OVERRIDES.get(name, {})
    for patch in (config.FORMAT_OVERRIDES.get(mode, {}), overrides, overrides.get(mode, {})):
        for section, values in patch.items():
            if section in settings:
                settings[section].update(values)
    brand = settings["brand"]
    if brand["start"] is None:
        brand["start"] = settings["lift"]["start"]
    return settings


def transition_plan(timeline):
    """Resolve every overlap before encoding so video and sound share one clock."""
    def label(shot):
        return f"{shot[0]}:{shot[1] if shot[0] == 'title' else shot[1]['id']}"

    transitions = []
    for index in range(len(timeline) - 1):
        name = f"{label(timeline[index])}->{label(timeline[index + 1])}"
        settings = dict(config.TRANSITION_DEFAULTS)
        if config.TRANSITION_SEQUENCE:
            settings.update(config.TRANSITION_SEQUENCE[index % len(config.TRANSITION_SEQUENCE)])
        settings.update(config.TRANSITION_OVERRIDES.get(name, {}))
        kind = settings["type"]
        if kind == "cut":
            duration, effect = 0.0, None
        else:
            duration = float(settings["duration"])
            if not math.isfinite(duration) or duration < 1 / FPS:
                raise ValueError(f"{name}: transition duration must be at least {1 / FPS:.4f}s")
            duration = round(duration * FPS) / FPS
            if kind == "fade":
                effect = "fade"
            elif kind == "swipe":
                if settings["style"] not in ("smooth", "slide", "wipe"):
                    raise ValueError(f"{name}: unknown swipe style {settings['style']!r}")
                if settings["direction"] not in ("left", "right", "up", "down"):
                    raise ValueError(f"{name}: unknown direction {settings['direction']!r}")
                effect = settings["style"] + settings["direction"]
            else:
                raise ValueError(f"{name}: unknown transition type {kind!r}")
        transitions.append({**settings, "name": name, "duration": duration, "filter": effect})
    starts = []
    elapsed = 0.0
    for index, (_, _, duration) in enumerate(timeline):
        incoming = transitions[index - 1]["duration"] if index else 0.0
        outgoing = transitions[index]["duration"] if index < len(transitions) else 0.0
        if not math.isfinite(duration) or duration <= incoming + outgoing:
            raise ValueError(f"Shot {index}: duration must exceed its incoming and outgoing overlaps")
        starts.append(round(elapsed * FPS) / FPS)
        elapsed += duration - outgoing
    return transitions, starts, round(elapsed * FPS) / FPS


def video_filter_graph(count, transitions, starts):
    filters = [f"[{index}:v]settb=AVTB,setpts=PTS-STARTPTS,format=yuv420p[v{index}]"
               for index in range(count)]
    previous = "v0"
    for index, transition in enumerate(transitions, 1):
        current = f"cut{index}"
        if transition["type"] == "cut":
            filters.append(f"[{previous}][v{index}]concat=n=2:v=1:a=0,fps={FPS},settb=AVTB[{current}]")
        else:
            filters.append(
                f"[{previous}][v{index}]xfade=transition={transition['filter']}:"
                f"duration={transition['duration']:.6f}:offset={starts[index]:.6f}[{current}]")
        previous = current
    return ";\n".join(filters), previous


def run(command, **kwargs):
    subprocess.run([str(part) for part in command], check=True, **kwargs)


def capture(godot, mode, language, work):
    metadata_path = work / "capture.json"
    metadata_path.unlink(missing_ok=True)
    log = work / "capture.log"
    log.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix="pile-down-trailer-") as profile:
        environment = os.environ.copy()
        for key in ("APPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME"):
            environment[key] = profile
        startup = None
        if os.name == "nt":
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
        command = [
            godot, "--path", PROJECT, "--rendering-method", "gl_compatibility",
            "--resolution", "432x768" if mode == "portrait" else "768x432",
            "--rendering-driver", "opengl3", "--write-movie", work / "gameplay.avi",
            "--fixed-fps", FPS, "--disable-vsync", "--quit-after", 4500,
            "--log-file", work / "capture.log",
            "--script", "res://resources/scripts/tools/CaptureTrailer.gd",
            "--", metadata_path, mode, language,
        ]
        process = subprocess.Popen([str(part) for part in command], cwd=PROJECT,
                                   env=environment, startupinfo=startup)
        try:
            deadline = time.monotonic() + 600
            while process.poll() is None:
                if log.exists() and "ERROR:" in log.read_text(encoding="utf-8", errors="replace"):
                    raise RuntimeError(f"Godot capture failed; inspect {log}")
                if time.monotonic() > deadline:
                    raise TimeoutError("Godot trailer capture exceeded 600 seconds")
                time.sleep(0.1)
            if process.returncode:
                raise subprocess.CalledProcessError(process.returncode, command)
            if "ERROR:" in log.read_text(encoding="utf-8", errors="replace"):
                raise RuntimeError(f"Godot capture failed; inspect {log}")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    validate_capture(metadata)
    return metadata


def trailer_segments(metadata):
    # Older recordings can contain extra footage; only these shots enter the edit.
    return [segment for segment in metadata["segments"]
            if segment["id"] in ("gameplay", "friends", "shell", "conveyor")]


def validate_capture(metadata):
    if (metadata.get("capture_version") != 6 or metadata.get("audio") != "sfx_only"
            or metadata.get("friend_level") != 1 or metadata.get("max_companions") != 1):
        raise RuntimeError("Record again without --reuse-capture: footage of the conveyor challenge is required")
    if metadata["friend_placements"] < 1 or metadata["swaps"] < 2:
        raise RuntimeError("Capture must demonstrate companion placements and pile swaps")
    if metadata.get("conveyor_placements", 0) < 2 or metadata.get("conveyor_distance", 0) <= 20:
        raise RuntimeError("The conveyor challenge must demonstrate moving tiles and successful plays")
    segments = trailer_segments(metadata)
    if [segment["id"] for segment in segments] != ["gameplay", "friends", "shell", "conveyor"]:
        raise RuntimeError("Expected all four gameplay sequences in order")
    if segments[-1].get("challenge") != "conveyor_belt" or segments[-1].get("hand_mode") != "conveyor":
        raise RuntimeError("The final shot must use the real conveyor challenge")
    profiles = [(s["pile_count"], s["hand_size"], s["start_value"]) for s in segments]
    if len(set(profiles)) != 4 or len({s["displayed_round"] for s in segments}) != 4:
        raise RuntimeError("Each shot must use its own difficulty and genuine round counter")


def ease_out(value, bounce=False):
    value = max(0.0, min(1.0, value))
    if bounce:
        return 1 + 2.70158 * (value - 1) ** 3 + 1.70158 * (value - 1) ** 2
    return 1 - (1 - value) ** 3


def progress_at(time, start, duration):
    if time < start:
        return 0.0
    return min(1.0, (time - start) / duration) if duration > 0 else 1.0


def fitted_font(font_path, lines, settings, width):
    size = int(settings["font_size"])
    minimum = int(settings["min_font_size"])
    if not 1 <= minimum <= size:
        raise ValueError("Font sizes must satisfy 1 <= min_font_size <= font_size")
    while True:
        font = ImageFont.truetype(str(font_path), size)
        if max(font.getlength(line) for line in lines) <= width - 2 * settings["margin_x"]:
            return font
        if size == minimum:
            raise ValueError("Text exceeds the available width: reduce margin_x/font size or add a line break")
        size = max(minimum, size - 2)


def text_sprite(text, font, color):
    box = font.getbbox(text)
    sprite = Image.new("RGBA", (box[2] - box[0] + 4, box[3] - box[1] + 4))
    ImageDraw.Draw(sprite).text((2 - box[0], 2 - box[1]), text, font=font, fill=color)
    return sprite


def cascade_cards(tiles, width, height, settings):
    """Two staggered fans fall into a pile below the final headline."""
    cards = []
    for index in range(settings["count"]):
        side = settings["sizes"][index % len(settings["sizes"])]
        tile = tiles[(index * 5 + 2) % len(tiles)].resize((side, side), Image.Resampling.NEAREST)
        cards.append({
            "tile": tile,
            "delay": settings["start"] + index * settings["delay"],
            "flight": settings["flight_duration"] + (index % 6) * settings["flight_step"],
            "start_x": -side if index % 2 == 0 else width + side,
            "end_x": width * (settings["left_x"] + (settings["right_x"] - settings["left_x"])
                              * ((index * 0.381966) % 1)),
            "start_y": height * settings["start_y"],
            "end_y": height * settings["end_y"] - (index % 4) * side * 0.18,
            "angle": ((index * 17) % 29) - 14,
            "spin": -65 if index % 2 == 0 else 65,
        })
    return cards


def draw_cascade(image, cards, time):
    for card in cards:
        local = time - card["delay"]
        if local < 0:
            continue
        progress = progress_at(local, 0, card["flight"])
        center_x = card["start_x"] + (card["end_x"] - card["start_x"]) * ease_out(progress)
        center_y = (card["start_y"] + (card["end_y"] - card["start_y"]) * progress ** 2
                    - image.height * 0.065 * math.sin(math.pi * progress))
        landing = max(0.0, local - card["flight"])
        center_y -= image.height * 0.025 * abs(math.sin(landing * 15)) * math.exp(-landing * 8)
        angle = card["angle"] + card["spin"] * (1 - ease_out(progress))
        sprite = card["tile"].rotate(angle, Image.Resampling.NEAREST, expand=True)
        image.paste(sprite, (round(center_x - sprite.width / 2),
                             round(center_y - sprite.height / 2)), sprite)


def draw_ending_brand(image, sprite, time, settings):
    progress = progress_at(time, settings["start"], settings["duration"])
    if progress <= 0:
        return
    scale = settings["initial_scale"] + (1 - settings["initial_scale"]) * ease_out(
        progress, bounce=settings["bounce"])
    animated = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
                             Image.Resampling.NEAREST)
    opacity = ease_out(progress_at(time, settings["start"], settings["fade_duration"]))
    if opacity < 1.0:
        animated.putalpha(animated.getchannel("A").point(lambda alpha: round(alpha * opacity)))
    center_x = image.width * settings["x"] + settings["offset_x"]
    center_y = (image.height * (settings["y"] + settings["enter_distance_ratio"] * (1 - ease_out(progress)))
                + settings["offset_y"])
    image.paste(animated, (round(center_x - animated.width / 2),
                           round(center_y - animated.height / 2)), animated)


def title_frames(mode, language, name, duration):
    """Animate generic headlines and staggered tile landings, without subtitles."""
    palette, colors, darkening, font_path, face = load_game_assets()
    width, height = (1080, 1920) if mode == "portrait" else (1920, 1080)
    settings = title_settings(mode, name)
    text = settings["headline"]
    accent = settings["accent"]
    tile_settings = settings["tiles"]
    outro = name == "outro"
    headline = config.COPY[language][name]
    lines = headline.split("\n")
    if (len(lines) == 1 and text["wrap_after"] and len(headline) > text["wrap_after"]
            and len(headline.split()) > 1):
        words = headline.split()
        split = len(words) // 2
        lines = [" ".join(words[:split]), " ".join(words[split:])]
    font = fitted_font(font_path, lines, text, width)
    size = font.size
    words = []
    y = height * text["y"] + text["offset_y"] - (len(lines) - 1) * size * text["line_spacing"] / 2
    for line in lines:
        x = width * text["x"] + text["offset_x"] - font.getlength(line) / 2
        for word in line.split():
            words.append((text_sprite(word, font, colors["TEXT"]), x, y))
            x += font.getlength(word + " ")
        y += size * text["line_spacing"]
    tiles = [make_tile(value, palette, face, font_path, darkening).resize(
                (tile_settings["size"], tile_settings["size"]), Image.Resampling.NEAREST)
             for value in config.TITLE_TILES[name]] if tile_settings["visible"] else []
    cascade = []
    brand = None
    if outro:
        if settings["cascade"]["visible"]:
            deck = [make_tile(value, palette, face, font_path, darkening) for value in range(9)]
            cascade = cascade_cards(deck, width, height, settings["cascade"])
        if settings["brand"]["visible"]:
            brand_font = fitted_font(font_path, [settings["brand"]["text"]], settings["brand"], width)
            brand = text_sprite(settings["brand"]["text"], brand_font, colors["TEXT"])
    for frame in range(round(duration * FPS)):
        time = frame / FPS
        image = Image.new("RGB", (width, height), colors["MENU_BACKGROUND"])
        if brand is not None:
            # The wordmark rises into the space freed by the invitation, under the cards.
            draw_ending_brand(image, brand, time, settings["brand"])
        if cascade:
            draw_cascade(image, cascade, time)
        # Lift the final invitation above the falling cards so it stays readable.
        lift_settings = settings["lift"]
        lift = height * lift_settings["distance_ratio"] * ease_out(progress_at(
            time, lift_settings["start"], lift_settings["duration"])) if outro else 0.0
        draw = ImageDraw.Draw(image)
        # Word delays are short enough to leave the complete message readable.
        for index, (sprite, x, base_y) in enumerate(words):
            progress = progress_at(time, text["start"] + index * text["word_delay"], text["enter_duration"])
            if progress <= 0:
                continue
            animated_y = base_y - lift + text["enter_offset_y"] * (1 - ease_out(progress, bounce=text["bounce"]))
            image.paste(sprite, (round(x), round(animated_y)), sprite)
        line_width = round(accent["width"] * ease_out(progress_at(time, accent["start"], accent["duration"])))
        if accent["visible"] and line_width:
            line_x = round(width * accent["x"] + accent["offset_x"])
            line_y = round(height * accent["y"] + accent["offset_y"] - (lift if accent["follow_lift"] else 0))
            draw.rectangle((line_x - line_width // 2, line_y,
                            line_x + line_width // 2, line_y + accent["height"]), fill=accent["color"])
        for index, tile in enumerate(tiles):
            local = time - tile_settings["start"] - index * tile_settings["delay"]
            if local <= 0:
                continue
            progress = ease_out(progress_at(local, 0, tile_settings["enter_duration"]), bounce=tile_settings["bounce"])
            scale = max(0.15, progress)
            side = max(1, round(tile_settings["size"] * scale))
            animated = tile.resize((side, side), Image.Resampling.NEAREST)
            angle = ((1 - progress_at(local, 0, tile_settings["rotation_duration"]))
                     * tile_settings["rotation"] * (1 if index % 2 == 0 else -1))
            animated = animated.rotate(angle, Image.Resampling.NEAREST, expand=True)
            center_x = (width * tile_settings["x"] + tile_settings["offset_x"]
                        + (index - (len(tiles) - 1) / 2) * tile_settings["spacing"])
            center_y = (height * tile_settings["y"] + tile_settings["offset_y"]
                        + tile_settings["enter_offset_y"] * (1 - progress)
                        + math.sin(local * tile_settings["bob_speed"]) * tile_settings["bob_amplitude"])
            if outro:
                fall = max(0.0, time - tile_settings["fall_start"] - index * tile_settings["fall_delay"])
                fall_progress = progress_at(fall, 0, tile_settings["fall_duration"])
                center_y += height * (tile_settings["fall_distance_ratio"] - index * 0.008) * fall_progress ** 2
                landing = max(0.0, fall - tile_settings["fall_duration"])
                center_y -= height * 0.018 * abs(math.sin(landing * 15)) * math.exp(-landing * 8)
            image.paste(animated, (round(center_x - animated.width / 2),
                                   round(center_y - animated.height / 2)), animated)
        yield image


def encode_title(ffmpeg, mode, language, name, duration, clip):
    width, height = (1080, 1920) if mode == "portrait" else (1920, 1080)
    command = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
               "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", f"{width}x{height}",
               "-framerate", str(FPS), "-i", "pipe:0", "-an", "-c:v", "libx264",
               "-preset", "fast", "-crf", "18", "-pix_fmt", "yuv420p", "-color_range", "tv", str(clip)]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    try:
        for frame in title_frames(mode, language, name, duration):
            process.stdin.write(frame.tobytes())
        process.stdin.close()
        if process.wait(timeout=300):
            raise RuntimeError(f"Title encoding failed: {name}")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


def build_timeline(metadata):
    def title_duration(name):
        return round(config.TITLE_DURATIONS[name] * FPS) / FPS

    timeline = [("title", "intro", title_duration("intro"))]
    for segment in trailer_segments(metadata):
        if segment["id"] != "gameplay":
            timeline.append(("title", segment["id"], title_duration(segment["id"])))
        timeline.append(("game", segment, round((segment["end"] - segment["start"]) * FPS) / FPS))
    timeline.append(("title", "outro", title_duration("outro")))
    return timeline


def compose(ffmpeg, mode, language, metadata, work):
    validate_capture(metadata)
    width, height = (1080, 1920) if mode == "portrait" else (1920, 1080)
    timeline = build_timeline(metadata)
    transitions, starts, elapsed = transition_plan(timeline)
    ending = title_settings(mode, "outro")
    music = PROJECT / config.MUSIC
    audio = config.AUDIO
    encoded = []
    previews = []
    sound_filters = []
    sound_labels = ["music"]
    soundtrack_inputs = []
    for index, (kind, source, duration) in enumerate(timeline):
        clip = work / f"clip-{index}.mp4"
        if kind == "title":
            encode_title(ffmpeg, mode, language, source, duration, clip)
        else:
            vf = f"scale={width}:{height}:flags=neighbor:in_range=pc:out_range=tv,setsar=1,format=yuv420p"
            run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                 "-framerate", FPS, "-start_number", round(source["start"] * FPS),
                 "-i", work / "full/frame%08d.png", "-frames:v", round(duration * FPS),
                 "-vf", vf, "-an", "-c:v", "libx264", "-preset", "fast", "-crf", "18",
                 "-pix_fmt", "yuv420p", "-color_range", "tv", clip], timeout=300)
            # Effects follow the footage, including the overlap of each transition.
            input_index = len(sound_labels)
            soundtrack_inputs += ["-ss", source["start"], "-t", duration, "-i", work / "gameplay.avi"]
            delay = round(starts[index] * 48000)
            label = f"sfx{index}"
            sound_labels.append(label)
            sound_filters.append(
                f"[{input_index}:a]aresample=48000,asetpts=PTS-STARTPTS,"
                f"afade=t=in:d={audio['sfx_fade_in']:.6f},"
                f"afade=t=out:st={max(0, duration - audio['sfx_fade_out']):.6f}:d={audio['sfx_fade_out']:.6f},"
                f"adelay={delay}S:all=1[{label}]")
        encoded.append(clip)
        previews.append(starts[index] + min(duration / 2, 2.0))

    # Music is decoded once, under titles and gameplay alike. Only the ending fades.
    sound_filters.insert(0, f"[0:a]aresample=48000,atrim=duration={elapsed:.6f},"
                         f"asetpts=PTS-STARTPTS,volume={audio['music_volume_db']}dB,"
                         f"afade=t=out:st={max(0, elapsed - audio['music_fade_out']):.6f}:"
                         f"d={audio['music_fade_out']:.6f}[music]")
    sound_filters.append("".join(f"[{label}]" for label in sound_labels)
                         + f"amix=inputs={len(sound_labels)}:normalize=0:duration=first[audio]")
    sound_graph = work / "audio-filter.txt"
    sound_graph.write_text(";\n".join(sound_filters), encoding="utf-8")
    soundtrack = work / "soundtrack.wav"
    run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-stream_loop", "-1", "-i", music,
         *soundtrack_inputs, "-filter_complex", ";".join(sound_filters), "-map", "[audio]",
         "-t", elapsed, "-c:a", "pcm_s16le", "-ar", "48000", "-ac", "2", soundtrack], timeout=300)

    video_filters, previous = video_filter_graph(len(encoded), transitions, starts)
    video_graph = work / "video-filter.txt"
    video_graph.write_text(video_filters, encoding="utf-8")
    output = OUTPUT / f"pile-down-{mode}-{language}.mp4"
    inputs = [part for clip in encoded for part in ("-i", clip)]
    run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y", *inputs, "-i", soundtrack,
         "-filter_complex_threads", "1", "-filter_complex", video_filters,
         "-map", f"[{previous}]", "-map", f"{len(encoded)}:a", "-t", elapsed,
         "-r", FPS, "-c:v", "libx264", "-preset", "fast", "-crf", "19", "-pix_fmt", "yuv420p",
         "-color_range", "tv", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", output],
        timeout=300)
    (work / "edit.json").write_text(json.dumps({
        "duration": elapsed, "transitions": transitions,
        "starts": starts, "music": config.MUSIC, "audio": audio,
        "music_continuous": True, "friend_level": metadata["friend_level"],
        "headlines": config.COPY[language], "subtitles": False,
        "title_tiles": config.TITLE_TILES,
        "title_durations": {name: duration for kind, name, duration in timeline if kind == "title"},
        "title_settings": {name: title_settings(mode, name) for name in config.TITLE_DURATIONS},
        "ending_cascade": {"start": starts[-1] + ending["cascade"]["start"],
                           "cards": ending["cascade"]["count"] if ending["cascade"]["visible"] else 0,
                           "duration": timeline[-1][2] - ending["cascade"]["start"]},
        "ending_brand": {"text": ending["brand"]["text"], "start": starts[-1] + ending["brand"]["start"],
                         "reveal_duration": ending["brand"]["duration"], "layer": "behind_cards",
                         "visible": ending["brand"]["visible"], "x": ending["brand"]["x"],
                         "y": ending["brand"]["y"]},
        "shots": trailer_segments(metadata),
    }, indent=2), encoding="utf-8")
    thumbs = []
    for index, at in enumerate(previews):
        path = work / f"preview-{index}.jpg"
        run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-ss", at,
             "-i", output, "-frames:v", "1", "-update", "1", path])
        thumb = Image.open(path).convert("RGB")
        thumb.thumbnail((320, 320), Image.Resampling.LANCZOS)
        thumbs.append(thumb)
    sheet = Image.new("RGB", (sum(t.width for t in thumbs), max(t.height for t in thumbs)), "#f7f6f2")
    x = 0
    for thumb in thumbs:
        sheet.paste(thumb, (x, 0))
        x += thumb.width
    sheet.save(OUTPUT / f"preview-{mode}-{language}.jpg", quality=95)
    print(f"Ready: {output.relative_to(PROJECT)} ({width}x{height}, ~{elapsed:.1f}s)", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("PILE_DOWN_GODOT_BIN", "godot"))
    parser.add_argument("--ffmpeg", default="ffmpeg")
    parser.add_argument("--reuse-capture", action="store_true")
    parser.add_argument("--format", choices=("both", "portrait", "landscape"), default="both")
    parser.add_argument("--language", choices=("both", "fr", "en"), default="both")
    args = parser.parse_args()
    for executable in ([args.ffmpeg] if args.reuse_capture else [args.godot, args.ffmpeg]):
        if not shutil.which(executable):
            parser.error(f"Executable not found: {executable}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / ".gdignore").touch()
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / ".gdignore").touch()
    for language in (["fr", "en"] if args.language == "both" else [args.language]):
        for mode in (["portrait", "landscape"] if args.format == "both" else [args.format]):
            work = WORK / f"{mode}-{language}"
            work.mkdir(parents=True, exist_ok=True)
            if args.reuse_capture:
                metadata = json.loads((work / "capture.json").read_text(encoding="utf-8"))
            else:
                print(f"Recording {mode}/{language} with isolated saves...", flush=True)
                metadata = capture(args.godot, mode, language, work)
            print(f"Editing {mode}/{language}...", flush=True)
            compose(args.ffmpeg, mode, language, metadata, work)


if __name__ == "__main__":
    main()
