class_name GameSettings
extends RefCounted

# Options : false remet les onglets en colonne à gauche.
const OPTIONS_TABS_HORIZONTAL := UISettings.TABS_HORIZONTAL
# Espacement entre les lignes, en pixels logiques, selon la hauteur disponible.
const OPTIONS_VERTICAL_PADDING_MIN := UISettings.OPTIONS_VERTICAL_PADDING_MIN
const OPTIONS_VERTICAL_PADDING_MAX := UISettings.OPTIONS_VERTICAL_PADDING_MAX

# Aligne l'apparition des mains et le départ du chrono sur la grille musicale.
const SYNC_HANDS_TO_MUSIC := false
const MUSIC_BPM := 60.0
const MUSIC_SEGMENT_SECONDS := 5.0
const MUSIC_VOLUME_DB := -15.0
const MUSIC_LOW_PASS_CUTOFF_HZ := 800.0
const MUSIC_LOW_PASS_RELEASE_SECONDS := 0.35
const SFX_VOLUME_DB := 6.0
# Matches the question mark pixels in resources/sprites/tiles/tile-back.png.
const COLORBLIND_VALUE_COLOR := GameColors.COLORBLIND_VALUE

const TILE_COLORS: Array[Color] = GameColors.FALLBACK_TILE_COLORS

# 1.0 = un beat, 0.5 = un demi-beat, 2.0 = tous les deux beats.
const HAND_BEAT_INTERVAL := 1.0
