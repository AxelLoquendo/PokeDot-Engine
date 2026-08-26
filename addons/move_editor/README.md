# Move Editor prototype

This is a self-contained Godot 4 `@tool` editor dock for `MoveData` resources.

## Files

- `plugin.cfg` / `plugin.gd`: editor-plugin entry point and bottom-panel dock.
- `move_dock.gd`: catalog UI and CRUD workflow (list, search, edit, save, create, duplicate, trash, restore, revert and validation).
- `move_repository.gd`: recursive `.tres` repository with duplicate-ID and load diagnostics.
- `move_catalog.gd`: display/slug helpers; enum values are read from project classes.
- `move_form.gd`: complete MoveData editor, including all enums, numeric parameters and every boolean flag in the source resource.

## Integration assumptions

- The files are copied to `res://addons/move_editor/` (the requested workspace folder is a staging area, so no existing project files were touched here).
- Existing project scripts remain at `res://data_core/move/move_data.gd`, `res://data_core/move/move.gd` (`class_name Moves`), `res://data_core/move/move_struct.gd`, and the PokemonData script that defines `PokemonData.Type`.
- Resources live below `res://data_core/move/resources/`; newly created resources use `res://data_core/move/resources/custom/`.
- Only custom resources are allowed to be moved to trash. Trash is `res://data_core/move/trash/` and restore returns the original filename to the custom folder.
- The source request refers to `moves.gd`; this repository's corresponding class is `move.gd`, which defines `Moves.MoveId`. No replacement enum or duplicate MoveData was introduced.
- Godot's plugin manager should enable `res://addons/move_editor/plugin.cfg` after copying the folder. The dock uses dynamic controls and does not require changes to `project.godot`.
