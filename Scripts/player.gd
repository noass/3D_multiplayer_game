extends CharacterBody3D

@export_range(1, 35, 1) var speed: float = 5 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = 9.8

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var camera: Camera3D = $Head2/Camera3D
@onready var skeleton = $playerAnimated/Armature/Skeleton3D

@onready var animationPlayer = $playerAnimated/AnimationPlayer
var isMoving = false
var canMove = true

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	camera.current = is_multiplayer_authority()
	capture_mouse()
	get_parent().sens = camera_sens

func _unhandled_input(event: InputEvent) -> void:
	if canMove:
		if event is InputEventMouseMotion:
			look_dir = event.relative * 0.001
			if mouse_captured: _rotate_camera()
		if Input.is_action_just_pressed("Space"): jumping = true

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		$playerAnimated/Armature/Skeleton3D/Body.cast_shadow = 3
		DisplayServer.window_set_title("3D Game | FPS: " + str(Engine.get_frames_per_second()))
		velocity = _walk(delta) + _gravity(delta) + _jump(delta)
		if(Input.is_action_pressed("W") or Input.is_action_pressed("A") or Input.is_action_pressed("S") or Input.is_action_pressed("D")):
			isMoving = true
		else:
			isMoving = false
		if !isMoving:
			animationPlayer.play("Idle")
		else:
			animationPlayer.play("Walk")
		move_and_slide()
		if get_parent().exited: 
			$"../".exit_game(name.to_int())
			get_tree().quit()
		if (!get_parent().isMenuOpen):
			canMove = true
		else:
			canMove = false
		camera_sens = get_parent().sens
		setName.rpc()
	else:
		$playerAnimated/Armature/Skeleton3D/Body.cast_shadow = 1

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	rotation.y -= look_dir.x * camera_sens * sens_mod
	$Head2.rotation.z = clamp($Head2.rotation.z - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _walk(delta: float) -> Vector3:
	if canMove:
		move_dir = Input.get_vector("A", "D", "W", "S")
		var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

@rpc("any_peer", "call_local")
func setName():
	var index = 0
	for i in GameManager.Players:
		if GameManager.Players[i].id == name.to_int():
			$Label3D.text = GameManager.Players[i].name
		index += 1
	
