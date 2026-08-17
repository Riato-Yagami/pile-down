# Index fonctionnel de `GameManager`

`GameManager.gd` expose encore les façades utilisées par `Game.tscn`, les
tests et les signaux. Les implémentations sont progressivement regroupées selon
les domaines ci-dessous.

| Domaine | Fonctions de façade ou points d'entrée | Implémentation spécialisée |
| --- | --- | --- |
| Options et sauvegarde utilisateur | `_setup_audio_controls`, `_setup_gameplay_options`, `_setup_graphics_options`, `_set_adaptive_resolution`, `_setup_save_dialogs`, `_on_volume_changed` | `settings/GameOptionsController.gd` |
| Fond et poussière | `_setup_dust_pool`, `_resize_dust_distribution`, `_rebuild_dust_pool`, `_toggle_dust_effects`, `_toggle_background` | `settings/GameOptionsController.gd` |
| Progression de difficulté | `_increase_difficulty`, `_advance_difficulty`, `_apply_special_tier_relief`, fonctions de probabilités | `gameplay/DifficultyProgression.gd` |
| Snapshot du menu de progression | `_progression_snapshot`, `_progression_highscores`, `_progression_achievements`, `_progression_bonuses`, `_progression_special_rules`, `_progression_fonts`, `_progression_palettes` | `progression/ProgressionSnapshotBuilder.gd` |
| État de progression non lu | `_load_unread_progression_pages`, `_mark_progression_page_unread`, `_mark_progression_item_unread`, `_on_progression_page_viewed`, `_save_unread_progression_pages` | `progression/ProgressionUnreadStore.gd` |
| Notifications de succès | `_queue_achievement_notification`, `_play_achievement_notifications`, `_pause_achievement_notifications`, `_resume_achievement_notifications`, `_position_achievement_popup` | `progression/AchievementNotificationController.gd` |
| Menu des checkpoints | `_open_checkpoint_menu`, `_refresh_checkpoint_button`, `_refresh_checkpoint_list`, `_select_next_checkpoint`, `_show_selected_checkpoint`, `_show_checkpoint_unlocked` | `progression/checkpoints/CheckpointMenuController.gd` |
| Partie et rounds | `start_game`, `start_round`, `_begin_turn`, `_finish_round`, `_finish_game` | orchestration conservée dans `GameManager` |
| Main et placements | `_generate_next_hand`, `_place_selected_card`, `_stack_card`, `_resolve_deja_vu`, `_resolve_double_down`, `_handle_mistake` | orchestration conservée ; génération déléguée à `HandManager` |
| Drag et tactile | `_on_card_drag_started`, `_prepare_drag_companions`, `_handle_pile_touch_input`, `_handle_card_touch_input`, helpers de placeholders | extraction suivante recommandée vers un contrôleur de drag |
| Scores et checkpoints persistants | `_load_high_score`, `_save_high_score`, `_save_checkpoint_progress`, `_load_checkpoint_progress`, `_normalise_checkpoint_ids`, `_migrate_save` | extraction suivante recommandée vers des stores dédiés |
| Debug | `_handle_debug_shortcut`, `_debug_win_round`, `_debug_reset_progression`, `_refresh_debug_help` | extraction suivante recommandée vers un contrôleur debug |

## Fonctions les plus longues encore présentes

- `_ready` : câblage initial de la scène et des signaux ;
- `start_round` : orchestration de début de round ;
- `_finish_game` et `_finish_round` : transitions de fin ;
- `start_game` : initialisation d'un run ;
- `_input` : routage global des entrées ;
- `_load_checkpoint_progress` et `_normalise_checkpoint_ids` : migration des
  anciennes sauvegardes.

Les quatre premières restent volontairement dans l'orchestrateur tant que les
contrats de contexte de round ne sont pas entièrement portés par
`RoundContext`. Les stores de scores/checkpoints et le contrôleur de drag sont
les prochaines frontières présentant le meilleur rapport gain/risque.
