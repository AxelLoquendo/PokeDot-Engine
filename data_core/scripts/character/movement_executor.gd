@tool
extends RefCounted
class_name MovementExecutor

## The only movement primitive used by ApplyMovement and CharacterNpc.  It intentionally
## delegates collision, speed and animation to CharacterController's existing API.
static func face(target: CharacterController, direction: Vector2) -> void:
	if direction == Vector2.ZERO: return
	target.mirar_hacia_posicion(target.global_position + direction * target.TILE_SIZE)
	restore_idle(target)

static func turn(target: CharacterController, clockwise: bool) -> void:
	var order: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var current: Vector2 = direction_of(target)
	var index: int = order.find(current)
	if index < 0: index = 0
	face(target, order[posmod(index + (1 if clockwise else -1), order.size())])

static func step_duration(target: CharacterController) -> float:
	## One tile always respects the controller's configured movement speed.
	return 1.0 / maxf(target.obtener_velocidad_movimiento(), 0.1)

static func visible_step_cycle_duration(target: CharacterController) -> float:
	## SpriteFrames is authoritative. Both first and second step animations
	## are allowed to finish their complete frame-duration cycle.
	if not target.anim_player or not target.anim_player.sprite_frames:
		return 0.4
	var prefix: String = "first_step_" if target.is_first_step else "second_step_"
	var suffix: String = "down"
	match target.current_direction:
		CharacterController.Direction.NORTH: suffix = "up"
		CharacterController.Direction.EAST: suffix = "right"
		CharacterController.Direction.WEST: suffix = "left"
	var animation_name: String = prefix + suffix
	var frames: SpriteFrames = target.anim_player.sprite_frames
	if not frames.has_animation(animation_name):
		return 0.4
	var fps: float = frames.get_animation_speed(animation_name)
	if fps <= 0.0:
		return 0.4
	var frame_units: float = 0.0
	for index: int in range(frames.get_frame_count(animation_name)):
		frame_units += frames.get_frame_duration(animation_name, index)
	return maxf(frame_units / fps, 0.01)

static func cadence_duration_multiplier(target: CharacterController, mode: String) -> float:
	return maxf(target.obtener_multiplicador_cadencia_en_sitio(mode), 0.5)

static func restore_idle(target: CharacterController) -> void:
	if target.has_method("reproducir_idle"):
		target.call("reproducir_idle")
		return
	if not target.anim_player:
		return
	match target.current_direction:
		CharacterController.Direction.NORTH: target.anim_player.play("idle_up")
		CharacterController.Direction.SOUTH: target.anim_player.play("idle_down")
		CharacterController.Direction.EAST: target.anim_player.play("idle_right")
		CharacterController.Direction.WEST: target.anim_player.play("idle_left")

static func direction_of(target: CharacterController) -> Vector2:
	match target.current_direction:
		CharacterController.Direction.NORTH: return Vector2.UP
		CharacterController.Direction.SOUTH: return Vector2.DOWN
		CharacterController.Direction.EAST: return Vector2.RIGHT
		CharacterController.Direction.WEST: return Vector2.LEFT
	return Vector2.DOWN

static func walk_one(target: CharacterController, direction: Vector2, animation: String = "walk") -> bool:
	if direction == Vector2.ZERO or not target.casilla_permitida(target.global_position + direction * target.TILE_SIZE): return false
	var old_tile: Vector2i = target.casilla_actual
	var new_tile: Vector2i = old_tile + Vector2i(direction)
	if EventObjects.hay_otro_en_casilla(new_tile, target): return false
	var destination: Vector2 = target.position + direction * target.TILE_SIZE
	EventObjects.liberar_casilla(old_tile)
	EventObjects.liberar_reserva(old_tile)
	EventObjects.reservar_casilla(new_tile, target)
	target.input_direction = direction
	target.set_meta("movement_animation_mode", animation)
	target.iniciar_paso_animacion()
	var duration: float = step_duration(target)
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "position", destination, duration)
	await tween.finished
	target.position = target.snap_to_grid(destination)
	target.casilla_actual = new_tile
	target.casilla_reservada = new_tile
	EventObjects.liberar_reserva(new_tile)
	EventObjects.registrar_casilla(new_tile, target)
	target.remove_meta("movement_animation_mode")
	restore_idle(target)
	return true

static func copy_direction(player: CharacterController) -> Vector2:
	return player.input_direction if player.input_direction != Vector2.ZERO else direction_of(player)

static func visual_state(target: CharacterController, state: String) -> void:
	target.set_meta("movement_visual_state", state)
	# Disguise/tree/mountain are state markers until a project sprite resolver exists.
	target.visible = state != "invisible" and state != "buried" and state != "hide"

static func berry_tree_growth(target: CharacterController) -> void:
	target.set_meta("movement_visual_state", "berry_tree_growth")
	target.set_meta("berry_tree_growth_supported", false)

## Executes one atomic action. This is the sole low-level entry point shared by
## autonomous state machines and ApplyMovement.
static func execute_action(target: CharacterController, action: Dictionary) -> void:
	var kind: MovementTypes.MovementAction = int(action.get("kind", MovementTypes.MovementAction.WAIT))
	match kind:
		MovementTypes.MovementAction.WAIT:
			await target.get_tree().create_timer(float(action.get("seconds", 0.1))).timeout
		MovementTypes.MovementAction.FACE:
			face(target, action.get("direction", Vector2.ZERO))
		MovementTypes.MovementAction.TURN_CLOCKWISE: turn(target, true)
		MovementTypes.MovementAction.TURN_COUNTERCLOCKWISE: turn(target, false)
		MovementTypes.MovementAction.WALK, MovementTypes.MovementAction.JOG, MovementTypes.MovementAction.RUN:
			await walk_one(target, action.get("direction", Vector2.ZERO), String(action.get("mode", "walk")))
		MovementTypes.MovementAction.COPY_PLAYER:
			var player: CharacterController = target.get_tree().get_first_node_in_group(&"player") as CharacterController
			if player: await walk_one(target, copy_direction(player), "walk")
		MovementTypes.MovementAction.FOLLOW_PLAYER:
			var follower: CharacterController = target.get_tree().get_first_node_in_group(&"player") as CharacterController
			if follower:
				var delta: Vector2i = follower.casilla_actual - target.casilla_actual
				var direction: Vector2 = Vector2.ZERO
				if abs(delta.x) >= abs(delta.y) and delta.x != 0: direction = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
				elif delta.y != 0: direction = Vector2.DOWN if delta.y > 0 else Vector2.UP
				await walk_one(target, direction, "walk")
		MovementTypes.MovementAction.WALK_IN_PLACE:
			var in_place_mode: String = String(action.get("mode", "walk"))
			# Direction is visual-only: no position, grid reservation, or collision change.
			target.input_direction = direction_of(target)
			target.set_meta("movement_animation_mode", in_place_mode)
			target.iniciar_paso_animacion()
			var base_cycle: float = visible_step_cycle_duration(target)
			var duration_multiplier: float = cadence_duration_multiplier(target, in_place_mode)
			var old_scale: float = target.anim_player.speed_scale if target.anim_player else 1.0
			if target.anim_player:
				# Keep the complete SpriteFrames cycle, but slow only this in-place action.
				target.anim_player.speed_scale = old_scale / duration_multiplier
			await target.get_tree().create_timer(base_cycle * duration_multiplier).timeout
			if target.anim_player:
				target.anim_player.speed_scale = old_scale
			target.remove_meta("movement_animation_mode")
			restore_idle(target)

		MovementTypes.MovementAction.HIDE: visual_state(target, "invisible")
		MovementTypes.MovementAction.SHOW: visual_state(target, "visible")
		MovementTypes.MovementAction.TREE_DISGUISE: visual_state(target, "tree_disguise")
		MovementTypes.MovementAction.MOUNTAIN_DISGUISE: visual_state(target, "mountain_disguise")
		MovementTypes.MovementAction.BURIED: visual_state(target, "buried")
		MovementTypes.MovementAction.BERRY_TREE_GROWTH: berry_tree_growth(target)
