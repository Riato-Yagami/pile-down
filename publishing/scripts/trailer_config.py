"""Réglages du trailer : modifier ce fichier, puis relancer avec --reuse-capture.

Les coordonnées x/y et les distances *_ratio sont des fractions de l'image :
0 = gauche/haut, 0.5 = centre, 1 = droite/bas. Diminuer y remonte un élément.
Les tailles, espacements et offset_x/offset_y sont en pixels de la vidéo finale.
Les temps sont en secondes ; le montage les arrondit à 30 images/s.
"""

COPY = {
    "fr": {
        "intro": "PILE DOWN",
        "friends": "CHAQUE GESTE COMPTE",
        "shell": "ATTENTION AUX REGLES SPECIALES",
        "conveyor": "RELEVE LE DEFI",
        "outro": "ENCORE UNE PARTIE ?",
    },
    "en": {
        "intro": "PILE DOWN",
        "friends": "MAKE EVERY MOVE COUNT",
        "shell": "BEWARE OF SPECIAL RULES",
        "conveyor": "RISE TO THE CHALLENGE",
        "outro": "ONE MORE RUN?",
    },
}

TITLE_DURATIONS = {"intro": 1.8, "friends": 2.1, "shell": 2.1, "conveyor": 2.1, "outro": 4.2}
TITLE_TILES = {
    "intro": (8, 5, 2),
    "friends": (6, 3, 1),
    "shell": (7, 4, 0),
    "conveyor": (5, 2, 0),
    "outro": (3, 1, 0),
}

# Réglages communs à tous les écrans de texte.
TITLE_DEFAULTS = {
    "headline": {
        "x": 0.5,                 # Centre horizontal du bloc de texte.
        "y": 0.43,                # Haut du texte ; un bloc multiligne est centré autour.
        "offset_x": 0,
        "offset_y": 0,
        "font_size": 110,         # Réduit automatiquement pour respecter margin_x.
        "min_font_size": 28,
        "margin_x": 70,
        "line_spacing": 1.2,
        "wrap_after": None,       # Nombre de caractères avant coupure en deux lignes.
        "start": 0.04,
        "word_delay": 0.055,
        "enter_duration": 0.36,
        "enter_offset_y": 85,
        "bounce": True,
    },
    "accent": {
        "visible": True,
        "x": 0.5,
        "y": 0.31,
        "offset_x": 0,
        "offset_y": 0,
        "width": 160,
        "height": 6,
        "color": "#4d82c2",
        "start": 0.15,
        "duration": 0.55,
        "follow_lift": True,
    },
    "tiles": {
        "visible": True,
        "x": 0.5,
        "y": 0.70,
        "offset_x": 0,
        "offset_y": 0,
        "size": 153,
        "spacing": 210,
        "start": 0.22,
        "delay": 0.11,
        "enter_duration": 0.48,
        "enter_offset_y": 75,
        "bounce": True,
        "rotation": 12,
        "rotation_duration": 0.6,
        "bob_amplitude": 4,
        "bob_speed": 4,
        "fall_start": 1.10,       # Chute des tuiles décoratives, uniquement en conclusion.
        "fall_delay": 0.07,
        "fall_duration": 0.55,
        "fall_distance_ratio": 0.21,
    },
    "lift": {                    # Remontée de l'accroche finale et du trait.
        "start": 0.90,
        "duration": 0.55,
        "distance_ratio": 0.26,
    },
    "brand": {                   # « PILE DOWN » final, derrière les cartes.
        "visible": True,
        "text": "PILE DOWN",
        "x": 0.5,
        "y": 0.53,               # Ancien placement : 0.58 ; le titre est remonté de 5 %.
        "offset_x": 0,
        "offset_y": 0,
        "font_size": 220,
        "min_font_size": 28,
        "margin_x": 80,
        "start": None,           # None synchronise l'apparition avec lift.start.
        "duration": 0.65,
        "fade_duration": 0.45,
        "enter_distance_ratio": 0.06,
        "initial_scale": 0.72,
        "bounce": True,
    },
    "cascade": {
        "visible": True,
        "start": 1.25,
        "count": 36,
        "delay": 0.035,
        "sizes": (108, 126, 144),
        "start_y": 0.33,
        "end_y": 0.92,
        "left_x": 0.12,
        "right_x": 0.88,
        "flight_duration": 0.85,
        "flight_step": 0.04,
    },
}

# Surcharges par orientation, puis par titre, puis par orientation de ce titre.
# Il suffit de préciser les propriétés à changer, les autres sont conservées.
FORMAT_OVERRIDES = {
    "portrait": {"headline": {"wrap_after": 18}},
    "landscape": {},
}
TITLE_OVERRIDES = {
    "intro": {"headline": {"font_size": 190}},
    "friends": {},
    "shell": {},
    "conveyor": {},
    "outro": {
        "portrait": {},          # Exemple : "brand": {"y": 0.50, "font_size": 200}
        "landscape": {},         # Exemple : "headline": {"offset_y": -20}
    },
}

# type : "fade" (fondu enchaîné), "swipe" (balayage), "cut" (coupe franche).
# direction : "left", "right", "up", "down" ; sens de déplacement/balayage.
# style du swipe : "smooth" (glissement doux), "slide" (glissement), "wipe" (volet).
# direction/style sont ignorés pour fade/cut ; cut n'a aucun chevauchement.
TRANSITION_DEFAULTS = {"type": "swipe", "style": "smooth", "direction": "left", "duration": 10 / 30}

# Surcharges successives, répétées en boucle. [] applique uniquement les valeurs
# par défaut. Pour tout passer en fondu : type="fade" ci-dessus et laisser [].
TRANSITION_SEQUENCE = [
    {},
    {"style": "slide", "direction": "up"},
    {"direction": "right"},
    {"style": "slide", "direction": "down"},
    {"direction": "up"},
    {},
]

# Surcharges d'un raccord précis, prioritaires sur la séquence.
# Noms : title:intro, game:gameplay, title:friends, game:friends, title:shell,
# game:shell, title:conveyor, game:conveyor, title:outro.
TRANSITION_OVERRIDES = {
    # "game:conveyor->title:outro": {"type": "fade", "duration": 0.5},
    # "title:intro->game:gameplay": {"type": "swipe", "style": "wipe", "direction": "left"},
}

MUSIC = "resources/audio/musics/section-1.wav"  # Chemin relatif à la racine du projet.
AUDIO = {"music_volume_db": -15, "music_fade_out": 0.65, "sfx_fade_in": 0.025, "sfx_fade_out": 0.04}
