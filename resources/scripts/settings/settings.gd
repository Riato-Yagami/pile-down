class_name GameSettings
extends RefCounted

# Aligne l'apparition des mains et le départ du chrono sur la grille musicale.
const SYNC_HANDS_TO_MUSIC := false
const MUSIC_BPM := 60.0
const MUSIC_SEGMENT_SECONDS := 5.0
const MUSIC_VOLUME_DB := -15.0
const MUSIC_LOW_PASS_CUTOFF_HZ := 800.0
const MUSIC_LOW_PASS_RELEASE_SECONDS := 0.35
const SFX_VOLUME_DB := 6.0
# Matches the question mark pixels in resources/sprites/tiles/tile-back.png.
const COLORBLIND_VALUE_COLOR := Color("#B4B4B2")

#const TILE_COLORS: Array[Color] = [
	#Color("#4D82C2"),
	#Color("#4EA3A2"),
	#Color("#739A62"),
	#Color("#D0A13A"),
	#Color("#E06455"),
	#Color("#8772B5"),
	#Color("#C76B98"),
	#Color("#5E9AC7"),
	#Color("#A26A45"),
	#Color("#65724A"),
#]

#const TILE_COLORS: Array[Color] = [
	#Color("#5F6670"),
	#Color("#4A78C2"),
	#Color("#3F9C9A"),
	#Color("#6E9B5B"),
	#Color("#D2A13A"),
	#Color("#D97A3A"),
	#Color("#D95C5C"),
	#Color("#C85A8A"),
	#Color("#8568B8"),
	#Color("#5C5AA7"),
#]

const TILE_COLORS: Array[Color] = [
	Color("#2FA7C9"),
	Color("#2FA66A"),
	Color("#3F6FD9"),
	Color("#E2554F"),
	Color("#D9A514"),
	Color("#7FA52B"),
	Color("#D84F83"),
	Color("#E27A2D"),
	Color("#7B5BC7"),
	Color("#A65F32"),
]

# 1.0 = un beat, 0.5 = un demi-beat, 2.0 = tous les deux beats.
const HAND_BEAT_INTERVAL := 1.0
