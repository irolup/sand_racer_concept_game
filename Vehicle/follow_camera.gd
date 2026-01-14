extends Camera3D

const FOV_SPEED_FACTOR = 60
const FOV_SMOOTH_FACTOR = 0.2
const FOV_CHANGE_MIN_SPEED = 0.05

@export var min_distance := 2.0
@export var max_distance := 4.0
@export var angle_v_adjust := 0.0
@export var height := 1.5
@export var target_node_path: NodePath
@export var angle_offset: float = 2.0

var orbit_yaw := 0.0
var orbit_pitch := 15.0  # Clamp this to avoid flipping

@export var orbit_distance := 3.0
@export var orbit_speed := 0.3
@export var orbit_pitch_min := -30.0
@export var orbit_pitch_max := 60.0

var orbit_rotating := false

var camera_type := CameraType.EXTERIOR

var initial_transform: Transform3D
var base_fov: float
var desired_fov: float
var previous_position: Vector3

enum CameraType {
	EXTERIOR,
	INTERIOR,
	TOP_DOWN,
	FREE_ORBIT,
	MAX,
}

func _ready():
	initial_transform = transform
	base_fov = fov
	desired_fov = fov
	previous_position = global_position
	update_camera()
	
func handle_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"cycle_camera"):
			camera_type = wrapi(camera_type + 1, 0, CameraType.MAX) as CameraType
			update_camera()
		if camera_type == CameraType.FREE_ORBIT and event is InputEventMouseMotion:
			orbit_yaw -= event.relative.x * orbit_speed
			orbit_pitch = clamp(orbit_pitch - event.relative.y * orbit_speed, orbit_pitch_min, orbit_pitch_max)


func follow_target() -> void:
	var target = get_node(target_node_path)
	if not target: return

	match camera_type:
		CameraType.EXTERIOR:
			var target_pos: Vector3 = target.global_transform.origin
			var pos: Vector3 = global_transform.origin
			var from_target: Vector3 = pos - target_pos

			# Clamp distance
			var dist := from_target.length()
			if dist < min_distance:
				from_target = from_target.normalized() * min_distance
			elif dist > max_distance:
				from_target = from_target.normalized() * max_distance

			from_target.y = height
			var new_pos = target_pos + from_target
			look_at_from_position(new_pos, target_pos, Vector3.UP)

		CameraType.TOP_DOWN:
			# Follow target from above
			var target_pos = target.global_transform.origin
			global_position.x = target_pos.x
			global_position.z = target_pos.z
			rotation_degrees = Vector3(270, 180, 0)
		
		CameraType.FREE_ORBIT:
			var target_pos = target.global_transform.origin
	
			var yaw_rad = deg_to_rad(orbit_yaw)
			var pitch_rad = deg_to_rad(orbit_pitch)

			var rot_basis = Basis(Vector3(1, 0, 0), pitch_rad) * Basis(Vector3(0, 1, 0), yaw_rad)
			var offset = -rot_basis.z * orbit_distance

			var new_pos = target_pos + offset + Vector3.UP * height
			look_at_from_position(new_pos, target_pos, Vector3.UP)

	# FOV adaptation
	desired_fov = clamp(base_fov + (abs(global_position.length() - previous_position.length()) - FOV_CHANGE_MIN_SPEED) * FOV_SPEED_FACTOR, base_fov, 100)
	fov = lerpf(fov, desired_fov, FOV_SMOOTH_FACTOR)

	# Slight pitch adjustment
	transform.basis = Basis(transform.basis[0], deg_to_rad(angle_v_adjust)) * transform.basis

	previous_position = global_position

func update_camera():
	match camera_type:
		CameraType.EXTERIOR:
			transform = initial_transform
		CameraType.INTERIOR:
			global_transform = get_node(^"../../InteriorCameraPosition").global_transform
		CameraType.TOP_DOWN:
			global_transform = get_node(^"../../TopDownCameraPosition").global_transform

	# Detach camera for free movement
	set_as_top_level(camera_type != CameraType.INTERIOR)
