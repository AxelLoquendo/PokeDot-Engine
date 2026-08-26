# Ability Editor prototype

Self-contained Godot 4 `@tool` editor add-on for the existing `AbilityData` resource.
It is intentionally staged outside the project so it does not overwrite any existing
scripts. To try it, copy this directory to `res://addons/ability_editor/`, then
activate **Ability Editor** under Project > Project Settings > Plugins.

## Included

- `ability_catalog.gd`: enum-aware query/presentation layer; searches ID, enum name,
  and `name_key`, and exposes the current `AbilityId.Id` and `WeatherEffect.WeatherID`
  values.
- `ability_repository.gd`: recursive resource repository with cache-free loading,
  validation metadata, collision-safe creation/duplication, save, soft-delete to
  `res://data_core/ability/trash/`, and restore to
  `res://data_core/ability/resources/custom/`.
- `ability_validator.gd`: delegates to `AbilityData._validate()` and adds editor
  checks for reserved IDs, duplicate IDs, and AI rating bounds.
- `ability_form.gd`: edits every field currently exported by `ability_data.gd`,
  including all nine trigger flags, weather enum, stat-modifier JSON, and an
  `EditorResourcePicker` for `AbilityEffect`.
- `ability_dock.gd`: list/search/filter, select, dirty-state tracking, validate,
  save/revert, create, duplicate, trash, and restore workflows.
- `plugin.gd` / `plugin.cfg`: bottom-panel integration.

## Godot API and project assumptions

1. The add-on is copied to `res://addons/ability_editor/` (the preloads use this
   path). The project already exposes the global classes `AbilityData`, `AbilityId`,
   `AbilityEffect`, and `WeatherEffect` from the scripts inspected in
   `repo_analysis/files`.
2. This targets Godot 4.x APIs: `@tool`, `EditorPlugin`, `EditorResourcePicker`,
   `ResourceLoader.CACHE_MODE_IGNORE`, `ResourceSaver.save`,
   `DirAccess.rename_absolute`, `DirAccess.make_dir_recursive_absolute`, and
   `Resource.duplicate(true)`.
3. `AbilityId.Id` is expected to remain contiguous and to keep `COUNT = 319`; the
   current prototype permits IDs 1..318 and reserves `NONE = 0` and `COUNT`.
4. New resources are stored under the `custom` directory. Restore intentionally
   places files there rather than trying to reconstruct a former nested source
   directory. Existing resources are never overwritten by create/duplicate/restore.
5. `stat_modifiers` is edited as a JSON object. JSON keys/values are converted by
   Godot's JSON parser; malformed JSON blocks saving until corrected.
6. Trash is a filesystem move of `.tres` files. Source-control history and any
   project-specific sidecar files are outside this prototype's scope.
