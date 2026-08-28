# Item Editor (Godot 4 prototype)

Editor inferior `@tool` para `ItemData`. Copiar esta carpeta como
`res://addons/item_editor/` y activar `plugin.cfg` desde **Project > Project
Settings > Plugins**.

## Incluye

- Catálogo y repositorio que escanean recursivamente
  `res://data_core/items/resources/`.
- Lista ordenada por `Items.ItemId`, búsqueda por ID, nombres, tipo de uso y
efecto.
- Formulario para todos los campos exportados de `ItemData`.
- `OptionButton` generado desde los enums reales `Items.ItemId`,
  `ItemConstants.Pocket`, `Items.ItemType`, `HoldEffects.HoldEffect`,
  `Items.BattleUsage` e `Items.EffectItem`.
- `EditorResourcePicker` `Texture2D` y vista previa para `icon`.
- Validación oficial mediante `ItemData._validate()` más validaciones de
  enums, parámetros y IDs duplicados.
- Guardar y revertir con `ResourceLoader.CACHE_MODE_IGNORE`.
- Crear y duplicar usando únicamente IDs definidos en `Items.ItemId` que aún
  estén libres.
- Papelera y restauración con operaciones de archivo no destructivas.

## Supuestos y límites deliberados

- Los recursos nuevos se escriben en
  `res://data_core/items/resources/custom/`.
- Por seguridad, la acción **Papelera** solo mueve recursos que estén dentro
  de la carpeta `custom`; los recursos base/oficiales se pueden editar y
  guardar, pero no se mueven físicamente.
- La restauración devuelve recursos a `custom` y conserva su nombre de archivo.
- `Items.ItemId` es un enum cerrado. Por eso crear/duplicar no inventa IDs
  numéricos: muestra solo valores libres del enum. Cambiar el ID en el
  formulario también queda sujeto a la validación de `ItemData` y a la
  detección de duplicados.
- No se modifica `Items.ItemId`, `ItemData`, `ItemDB`, GitHub ni el staging del
  editor de especies.
