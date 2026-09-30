@tool
class_name GameColors
extends RefCounted

# Fixed UI/effect colors. Cosmetic palette .tres resources remain authoritative.
# RuntimeColors applies these values on scene entry, before palette initialization.
# SyncColors.gd only refreshes editor previews and the native boot splash.

# Neutres techniques : modulations et transparence, pas une palette cosmetique.
const WHITE := Color.WHITE
const BLACK := Color.BLACK
const TRANSPARENT := Color.TRANSPARENT
const TRANSPARENT_WHITE := Color(1.0, 1.0, 1.0, 0.0)

# Interface et menus
const ACCENT := Color("4d82c2")
const ACCENT_HOVER := Color("6da7e5")
const HUD_BRIGHT := Color(1, 1, 1, 0.9)
const HUD_MUTED := Color(1, 1, 1, 0.6313726)
const HUD_SUBTLE := Color(1, 1, 1, 0.82)
const LOADING_TEXT := Color(0.216, 0.216, 0.208, 1)
const MENU_BACKGROUND := Color("f7f6f2")
const PANEL_ALT := Color("e8edf3")
const PLACEHOLDER := Color(1, 1, 1, 0.62)
const POPUP_BACKGROUND := Color(0.176, 0.373, 0.62, 1)
const TEXT := Color("3c3c3c")
const TEXT_MUTED := Color("8a8882")
const TEXT_ON_LIGHT_BUTTON := Color("242424")
const TEXT_SUBTLE := Color(0.235, 0.235, 0.235, 0.82)
const VICTORY := Color("ffd700")

# Tuiles, erreurs et effets
const AFTERGLOW_TEXT := Color("b3ffe0")
const AFTERGLOW_TILE := Color(0.4, 0.9, 0.7, 1.0)
const BONUS_CONSUMED := Color(0.65, 0.65, 0.65, 1.0)
const CARD_ERROR := Color("f3b2aa")
const CLOCK_EMPTY := Color(0.8, 0.8, 0.8, 1.0)
const COLORBLIND_TILE := Color("8b8b8b")
const COLORBLIND_VALUE := Color("b4b4b2")
const DANGER := Color("e2554f")
const DRAG_ZONE_BORDER := Color(0.31, 0.64, 0.63, 0.28)
const DRAG_ZONE_FILL := Color(0.31, 0.64, 0.63, 0.04)
const GOLD := Color("d9a514")
const HIDDEN_TILE := Color("b8b8b8")
const HIGHLIGHT_TINT := Color(1.35, 1.35, 1.35, 1.0)
const LAVA_BORDER := Color(0.851, 0.306, 0.247, 0.75)
const LAVA_FILL := Color(0.914, 0.42, 0.353, 0.28)
const LIFE_RECOVERY := Color(0.65, 1.35, 0.9, 1.0)
const LOCK_TINT := Color.WHITE
const PILE_DROP_GLOW := Color(0.31, 0.64, 0.63, 0.24)
const PILE_FLASH := Color(1.25, 1.25, 1.25, 0.35)
const PILE_GOLD_GLOW := Color("#D9A514", 0.4)
const PILE_HOVER_GLOW := Color(0.31, 0.64, 0.63, 0.22)
const PILE_MORPH_EDGE := Color(0.31, 0.64, 0.63, 1.0)
const PILE_REGEN_GLOW := Color(0.31, 0.64, 0.63, 0.25)
const PILE_SHADOW := Color(0.31, 0.64, 0.63, 0.18)
const PILE_VALID_BORDER := Color(0.1, 0.9, 0.35, 0.75)
const PILE_VALID_FILL := Color(0.1, 0.8, 0.3, 0.08)
const PROGRESS_EMPTY := Color(0.725, 0.765, 0.812, 1.0)
const SAFETY_NET_DARK := Color(0.24, 0.28, 0.33, 1.0)
const SAFETY_NET_LIGHT := Color(0.66, 0.71, 0.76, 1.0)
const SELECTION_HIGHLIGHT := Color(1.0, 0.9, 0.32, 1.0)
const SELECTION_RIM := Color(1.0, 0.9, 0.32, 1.0) #Color(0.9, 0.54, 0.08, 1.0)
# false : TILE_TEXT pilote les chiffres ; true : chiffres issus de la palette.
static var tile_text_uses_palette := true
const TILE_TEXT_DARKENING := 0.35
const TILE_TEXT := Color(0.05, 0.05, 0.05, 1)
const TIMER_DANGER := Color("e06455")
const TIMER_RESET := Color("b9e8ff")
const TIMER_WARNING := Color("d0a13a")

# Fonds, particules et voiles
const ANNOUNCEMENT_MUTED := Color(0.8, 0.8, 0.8, 1)
const ANNOUNCEMENT_SCRIM := Color(0.04, 0.04, 0.04, 0.88)
const BACKGROUND_BASE := Color(0.9686, 0.9647, 0.9529, 1.0)
const BACKGROUND_HALO := Color(1.0, 1.0, 1.0, 0.012)
const BACKGROUND_PATTERN := Color(0.31, 0.49, 0.72, 0.16)
const BONUS_SCRIM := Color(0.965, 0.957, 0.94, 0.88)
const DARK_PANEL := Color(0.1, 0.1, 0.1, 0.9)
const DEBUG_DUST_BOUNDS := Color(1, 0, 1, 0.7)
const DUST := Color("77746d")
const END_SCRIM := Color(0.969, 0.965, 0.949, 0.9)
const GAME_DUST := Color(0.46666667, 0.45490196, 0.6313726, 0.93333334)
const OVERLAY_SCRIM := Color(0.969, 0.965, 0.949, 0.92)
const QUIT_SCRIM := Color(0.08, 0.09, 0.12, 0.46)
const RELIEF_LIGHT_INNER := Color(1, 1, 1, 0.72)
const RELIEF_LIGHT_OUTER := Color( 1, 1, 1, 0.18)
const STRIPES_LIGHT := Color(1.0, 1.0, 1.0, 0.58)

# Habillage des themes (les couleurs des tuiles viennent des palettes .tres)
const ARCADE_PANEL_ALT := Color("e2e9ef")
const DARK_THEME_MUTED := Color(0.86, 0.84, 0.88, 0.82)
const MONO_ACCENT := Color("5d6670")
const MONO_BACKGROUND := Color("f1f3f4")
const MONO_BUTTON := Color("626a73")
const MONO_HOVER := Color("7b858f")
const MONO_PANEL_ALT := Color("d5dbe1")
const RAINBOW_PANEL_ALT := Color("e6eceb")
const VAPOR_ACCENT := Color("ef6fe7")
const VAPOR_BACKGROUND := Color("2a2140")
const VAPOR_BUTTON := Color("2bbfd2")
const VAPOR_PANEL := Color("34294d")
const VAPOR_PANEL_ALT := Color("48345f")
const VAPOR_TEXT := Color("f6eaff")
const VAPOR_TEXT_MUTED := Color("c9b8db")

# Palette de repli uniquement pour les donnees vides
const FALLBACK_TILE_0 := Color("2fa7c9")
const FALLBACK_TILE_1 := Color("2fa66a")
const FALLBACK_TILE_2 := Color("3f6fd9")
const FALLBACK_TILE_5 := Color("7fa52b")
const FALLBACK_TILE_6 := Color("d84f83")
const FALLBACK_TILE_7 := Color("e27a2d")
const FALLBACK_TILE_8 := Color("7b5bc7")
const FALLBACK_TILE_9 := Color("a65f32")

const FALLBACK_TILE_COLORS: Array[Color] = [
	FALLBACK_TILE_0,
	FALLBACK_TILE_1,
	FALLBACK_TILE_2,
	DANGER,
	GOLD,
	FALLBACK_TILE_5,
	FALLBACK_TILE_6,
	FALLBACK_TILE_7,
	FALLBACK_TILE_8,
	FALLBACK_TILE_9,
]


static func tile_text_color(palette_color: Color, joker := false) -> Color:
	if not tile_text_uses_palette:
		return TILE_TEXT
	return palette_color if joker else palette_color.darkened(TILE_TEXT_DARKENING)
