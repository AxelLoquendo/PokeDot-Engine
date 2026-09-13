# Combate, objetos y evoluciones

La lógica de combate está separada de la interfaz. `BattleManager` resuelve
turnos y emite señales para que `scenes/ui_battle/battle.gd` actualice la
pantalla. Esto permite probar un combate desde código sin depender de botones.

## Combate por turnos

La base actual incluye combate individual y:

- prioridad, velocidad y desempate aleatorio;
- PP, precisión, críticos, STAB, tabla de tipos, clima y pantallas;
- estados principales, confusión, retroceso, drenaje, multigolpe y ataques de
  dos turnos;
- cambio de Pokémon, hazards (Púas, Púas Tóxicas, Trampa Rocas y Red Viscosa);
- varias habilidades de entrada, absorción, contacto, daño y fin de turno;
- efectos de movimiento frecuentes: recuperación, Descanso, Haze, Reflect,
  Light Screen, Aurora Veil, clima, Defog, Rapid Spin, Stone Axe, Ceaseless
  Edge y cambios de estadísticas compuestos.

Los efectos que aún no tienen una regla específica no se inventan: se mantienen
como datos en `MoveData` y muestran que todavía no tienen implementación. Esto
evita que un movimiento nuevo produzca resultados erróneos silenciosamente.

## Objetos

`ItemUseResolver.use_on_pokemon(...)` es la única regla compartida para usar un
objeto sobre un Pokémon. Soporta curación de PS, curación de estado, Restaurar
todo, Revivir, restauración de PP y evoluciones por objeto. Devuelve un
`ItemUseResolver.Result` con `success`, `consume_item`, `message` y, si aplica,
la evolución encontrada.

Para uso desde la partida:

```gdscript
var result := player_data.use_bag_item_on_pokemon(
    Items.ItemId.ITEM_POTION,
    player_data.party[0]
)
print(result.message)
```

Ese método valida la mochila, aplica el efecto y consume el objeto solamente si
tuvo éxito. La interfaz de mochila puede llamar a ese método cuando tenga su
selector de objetivo.

En batalla existe `BattleManager.player_choose_item(item_id, target,
move_slot_index)`. El botón **Bag** abre `BagUI` en modo combate: confirmar un
objeto muestra **Usar** y **Salir**. Usar lo aplica al Pokémon activo. Para
objetos de PP, se muestra un segundo selector para elegir el movimiento. Si el
efecto funciona, consume el objeto y el turno; si no funciona, vuelve al menú
de acciones.

Los efectos de objeto `SET_MIST`, `SET_FOCUS_ENERGY`, `INCREASE_STAT` e
`INCREASE_ALL_STATS` se resuelven directamente en `BattleManager`: Neblina
protege de reducciones de estadísticas cinco turnos, Energía Focal aumenta la
probabilidad de crítico y los aumentos no consumen el objeto si la estadística
ya estaba al límite.

Las confirmaciones de aprendizaje y la pregunta tras un debilitamiento usan el
selector de opciones independiente sobre la propia UI de batalla, sin abrir la
caja de diálogo de overworld. En un combate salvaje, el debilitamiento permite
elegir cambiar o escapar; contra entrenadores solo permite elegir reemplazo.

## Evoluciones

Las reglas viven en `EvolutionData` dentro de cada recurso de especie. Las
reglas nuevas usan un `EvolutionTrigger` y una lista de `EvolutionCondition`.
Hay condiciones de nivel, amistad, hora, género, objeto usado/equipado,
movimiento conocido, especie en el equipo, mapa, región, clima, relación de
estadísticas y banderas de evento.

Para comprobar una evolución por objeto no hace falta una lista manual de
piedras: el resolvedor crea un `EvolutionContext` con `used_item_id`, busca la
regla `ITEM_USED` de la especie y aplica el resultado si la regla coincide.

Los combates revisan evoluciones tras subir de nivel y al finalizar una batalla;
las evoluciones por objeto se realizan al usar el objeto sobre el Pokémon.

## Límites actuales

No se consideran implementados por el simple hecho de existir como enum o
recurso: captura, dobles, IA compleja, mecánicas Tera/Mega/Z/Dynamax, muchas
bayas y objetos equipados, y efectos particulares de movimientos. Añade cada
regla al resolvedor antes de usarla en contenido jugable.
