extends Node3D

@export var auto_play_animation: bool = true
@export var preferred_animation_name: String = ""
@export var face_target_on_ready: bool = true
@export var look_at_target: Vector3 = Vector3.ZERO

func _ready() -> void:
	if face_target_on_ready:
		_face_target()

	if auto_play_animation:
		_play_robot_animation()

func _face_target() -> void:
	var target: Vector3 = look_at_target
	target.y = global_position.y
	if global_position.is_equal_approx(target):
		return

	look_at(target)

func _play_robot_animation() -> void:
	var animation_players: Array[AnimationPlayer] = []
	_collect_animation_players(self, animation_players)

	for animation_player in animation_players:
		var animation_name: StringName = _pick_animation_name(animation_player)
		if animation_name != StringName():
			animation_player.play(animation_name)

func _collect_animation_players(node: Node, result: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		result.append(node as AnimationPlayer)

	for child in node.get_children():
		_collect_animation_players(child, result)

func _pick_animation_name(animation_player: AnimationPlayer) -> StringName:
	if not preferred_animation_name.is_empty() and animation_player.has_animation(preferred_animation_name):
		return StringName(preferred_animation_name)

	for animation_name in animation_player.get_animation_list():
		if String(animation_name).to_upper() != "RESET":
			return animation_name

	var animation_list: PackedStringArray = animation_player.get_animation_list()
	if not animation_list.is_empty():
		return StringName(animation_list[0])

	return StringName()
