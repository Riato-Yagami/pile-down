"""Compose the Ko-fi banner from Pile Down's own sprite, palette and font.

Run with Python and Pillow: python publishing/scripts/create_kofi_banner.py
"""

from pathlib import Path
import re

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


PROJECT = Path(__file__).resolve().parents[2]
OUTPUT = PROJECT / "publishing/kofi/banner.png"
SIZE = (1200, 400)


def centered_text(image, text, font, color, center):
    """Center visible glyphs, including the font's baseline offsets."""
    mask = Image.new("L", image.size)
    draw = ImageDraw.Draw(mask)
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    position = (
        round(center[0] - (right - left) / 2 - left),
        round(center[1] - (bottom - top) / 2 - top),
    )
    draw.text(position, text, font=font, fill=255)
    # Preserve hard pixel edges when enlarging/rotating the original assets.
    mask = mask.point(lambda value: 255 if value >= 128 else 0)
    image.paste(color, (0, 0), mask)


def load_game_assets():
    palette_source = (PROJECT / "resources/data/palettes/00_arcade.tres").read_text()
    palette = [
        tuple(round(float(channel) * 255) for channel in channels.split(","))
        for channels in re.findall(r"Color\(([^)]+)\)", palette_source)
    ]
    if len(palette) != 10:
        raise ValueError("The CLASSIC palette must contain ten tile colors")

    settings = (PROJECT / "resources/scripts/settings/colors.gd").read_text()
    ui_colors = {
        name: "#" + re.search(
            rf'const {name} := Color\("([0-9a-fA-F]{{6}})"\)', settings
        ).group(1)
        for name in ("MENU_BACKGROUND", "TEXT")
    }
    darkening = float(re.search(r"TILE_TEXT_DARKENING := ([\d.]+)", settings).group(1))
    project_settings = (PROJECT / "project.godot").read_text()
    font_path = PROJECT / re.search(
        r'theme/custom_font="res://([^"]+)"', project_settings
    ).group(1)
    face = Image.open(PROJECT / "resources/sprites/tiles/tile-face.png").convert("RGBA")
    return palette, ui_colors, darkening, font_path, face


def make_tile(value, palette, face, font_path, darkening):
    tile = face.copy()
    pixels = tile.load()
    color = palette[value]
    for y in range(tile.height):
        for x in range(tile.width):
            red, green, blue, alpha = pixels[x, y]
            # Same green chroma mask as the actual Card.tscn shader.
            if green > 0.65 * 255 and green > red * 1.6 and green > blue * 1.6:
                pixels[x, y] = (*color[:3], alpha)
    number_color = tuple(round(channel * (1 - darkening)) for channel in color[:3])
    centered_text(
        tile, str(value), ImageFont.truetype(str(font_path), 20), number_color,
        (tile.width / 2, tile.height / 2 - 1),
    )
    return tile.resize((tile.width * 3, tile.height * 3), Image.Resampling.NEAREST)


def main():
    palette, ui_colors, darkening, font_path, face = load_game_assets()
    banner = Image.new("RGB", SIZE,
                    "white"
                    #    ui_colors["MENU_BACKGROUND"]
    )
    # (value, center x, center y, angle)
    layout = (
        (0, 80, 85, 12),
        (4, 270, 85, -8),
        (2, 175, 205, -5),
        (1, 70, 318, 10),
        (6, 285, 318, -12),
        (7, 930, 85, 9),
        (8, 1120, 85, -12),
        (3, 1025, 205, 5),
        (5, 915, 318, -9),
        (9, 1130, 318, 11),
    )
    occupied = Image.new("L", SIZE)
    for value, x, y, angle in layout:
        tile = make_tile(value, palette, face, font_path, darkening)
        group = tile.rotate(angle, Image.Resampling.NEAREST, expand=True)
        position = (x - group.width // 2, y - group.height // 2)
        if not (0 <= position[0] <= SIZE[0] - group.width
                and 0 <= position[1] <= SIZE[1] - group.height):
            raise ValueError(f"Tile {value} would be cropped")
        silhouette = Image.new("L", SIZE)
        silhouette.paste(group.getchannel("A"), position)
        # Keep at least ten pixels of background between unrelated tile contours.
        if ImageChops.multiply(occupied.filter(ImageFilter.MaxFilter(21)), silhouette).getbbox():
            raise ValueError(f"Tile {value} is too close to another tile")
        occupied = ImageChops.lighter(occupied, silhouette)
        banner.paste(group, position, group)

    centered_text(
        banner, "juels", ImageFont.truetype(str(font_path), 144),
        ui_colors["TEXT"], (SIZE[0] / 2, SIZE[1] / 2),
    )
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    banner.save(OUTPUT, optimize=True)
    if OUTPUT.stat().st_size >= 8_000_000:
        raise ValueError("Ko-fi banner exceeds 8 MB")
    print(f"{OUTPUT.relative_to(PROJECT)}: {SIZE[0]} x {SIZE[1]}, {OUTPUT.stat().st_size} bytes")


if __name__ == "__main__":
    main()
