@tool
extends Node3D

@export var size = 64
@export var height_map : PackedFloat32Array = []
@export var terrain_material : Material
@export var dig_strength := 0.5
@export var brush_radius := 2.0
@export var square_brush_radius := 4
@export var square_brush_height := 1.0
@export var border_thickness := 1.0
@export var wall_height := 10.0
@export var wall_material : Material

@onready var terrain_mesh: MeshInstance3D = $TerrainMesh


enum BrushType {
	MODIFY,
	DIG,
	FLAT_SQUARE,
	EQUALIZE
}
var current_brush_type: BrushType = BrushType.MODIFY

var collision_shape_node : CollisionShape3D = null
var body : StaticBody3D
var initial_height_map : PackedFloat32Array
var patch_size := 1.0

var debug_points : Array = []
var debug_point_mesh : Mesh = SphereMesh.new()

func _ready():
	if height_map.is_empty():
		height_map.resize(size * size)
		height_map.fill(0.0)
	generate_flat_terrain()
	create_collision()
	initial_height_map = height_map.duplicate()
	create_terrain_border()

func generate_flat_terrain():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	st.set_material(terrain_material)

	var vertex_grid := []

	for x in range(size):
		vertex_grid.append([])
		for y in range(size):
			var height = height_map[x * size + y]
			vertex_grid[x].append(Vector3(x * patch_size - patch_size, height, y * patch_size - patch_size))

	for x in range(size - 1):
		for y in range(size - 1):
			var v1 = vertex_grid[x][y]
			var v2 = vertex_grid[x][y + 1]
			var v3 = vertex_grid[x + 1][y + 1]
			var v4 = vertex_grid[x + 1][y]

			st.add_vertex(v3)
			st.add_vertex(v2)
			st.add_vertex(v1)

			st.add_vertex(v4)
			st.add_vertex(v3)
			st.add_vertex(v1)

	st.generate_normals()
	
	#st.generate_tangents()
	terrain_mesh.mesh = st.commit()

func create_collision():
	if not body:
		body = StaticBody3D.new()
		body.name = "TerrainBody"
		add_child(body)

	if collision_shape_node:
		body.remove_child(collision_shape_node)
		collision_shape_node.queue_free()

	# Transpose height_map from x*size + y to y*size + x
	var collision_heightmap := PackedFloat32Array()
	collision_heightmap.resize(size * size)
	for x in range(size):
		for z in range(size):
			var src_index = x * size + z
			var dst_index = z * size + x  # swap x <-> z
			collision_heightmap[dst_index] = height_map[src_index]

	var heightmap_shape := HeightMapShape3D.new()
	heightmap_shape.map_width = size
	heightmap_shape.map_depth = size
	heightmap_shape.map_data = collision_heightmap

	collision_shape_node = CollisionShape3D.new()
	collision_shape_node.shape = heightmap_shape

	# Scale the shape node to match patch_size
	#collision_shape_node.scale = Vector3(patch_size, 1.0, patch_size)

	# Align it properly with the mesh
	collision_shape_node.position = Vector3(
		(size - 1) * patch_size * 0.5,
		0,
		(size - 1) * patch_size * 0.5
	)

	body.add_child(collision_shape_node)
	clear_debug_points()
	#debug_collision_shape()
	
func cycle_brush_type():
	var brush_names := BrushType.keys()
	var current_index := brush_names.find(BrushType.find_key(current_brush_type))
	current_index = (current_index + 1) % brush_names.size()
	current_brush_type = BrushType[brush_names[current_index]]
	print("Brush type changed to: ", brush_names[current_index])

func modify_terrain(world_pos: Vector3, amount: float):
	var local_pos = to_local(world_pos)
	var modified = false
	for x in range(size):
		for y in range(size):
			var world_x = x * patch_size
			var world_y = y * patch_size
			var dist = Vector2(world_x, world_y).distance_to(Vector2(local_pos.x, local_pos.z))
			if dist < brush_radius:
				var index = x * size + y
				var influence = amount * (1.0 - dist / brush_radius)
				height_map[index] += influence

				var min_height = initial_height_map[index]
				height_map[index] = clamp(height_map[index], min_height, 5.0)
				modified = true
	if modified:
		generate_flat_terrain()
		create_collision()
		
func flatten_terrain(world_pos: Vector3):
	var local_pos = to_local(world_pos)
	# Get center brush height
	var center_x = int(round(local_pos.x / patch_size))
	var center_y = int(round(local_pos.z / patch_size))
	center_x = clamp(center_x, 0, size - 1)
	center_y = clamp(center_y, 0, size - 1)
	var center_index = center_x * size + center_y
	var target_height = height_map[center_index]

	for x in range(size):
		for y in range(size):
			var world_x = x * patch_size
			var world_y = y * patch_size
			var dist = Vector2(world_x, world_y).distance_to(Vector2(local_pos.x, local_pos.z))
			if dist < brush_radius:
				var index = x * size + y
				var blend = 1.0 - (dist / brush_radius)
				height_map[index] = lerp(height_map[index], target_height, blend)

	generate_flat_terrain()
	create_collision()
	
func apply_flat_square_brush(world_pos: Vector3):
	var local_pos = to_local(world_pos)
	var center_x = int(round(local_pos.x / patch_size))
	var center_y = int(round(local_pos.z / patch_size))

	var min_x = max(0, center_x - square_brush_radius)
	var max_x = min(size - 1, center_x + square_brush_radius)
	var min_y = max(0, center_y - square_brush_radius)
	var max_y = min(size - 1, center_y + square_brush_radius)

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var index = x * size + y
			var base_height = initial_height_map[index]
			var new_height = base_height + square_brush_height
			height_map[index] = clamp(new_height, base_height, 5.0)

	generate_flat_terrain()
	create_collision()
	
func apply_modification(world_pos: Vector3, amount: float) -> void:
	modify_terrain(world_pos, amount)

func apply_flattening(world_pos: Vector3) -> void:
	flatten_terrain(world_pos)

func debug_collision_shape():
	for x in range(size):
		for y in range(size):
			var height = height_map[x * size + y]
			var world_position = Vector3(x * patch_size, height, y * patch_size)
			
			# Create a new mesh instance for each debug point (sphere)
			var debug_point = MeshInstance3D.new()
			debug_point.mesh = debug_point_mesh
			debug_point.position = world_position
			debug_point.scale = Vector3(0.1, 0.1, 0.1)  # Small size for the debug point
			debug_point.material_override = terrain_material  # Optional: apply material

			# Add the debug point to the scene
			add_child(debug_point)

			# Add point to debug list to keep track of it
			debug_points.append(debug_point)

# Clear the debug points from the scene
func clear_debug_points():
	for point in debug_points:
		point.queue_free()
	debug_points.clear()


func create_terrain_border():
	var half_size = (size - 1) * patch_size * 0.5
	var wall_positions = [
		Vector3(half_size, wall_height * 0.5, -border_thickness * 0.5),
		Vector3(half_size, wall_height * 0.5, (size - 1) * patch_size + border_thickness * 0.5),
		Vector3(-border_thickness * 0.5, wall_height * 0.5, half_size),
		Vector3((size - 1) * patch_size + border_thickness * 0.5, wall_height * 0.5, half_size)
	]

	var wall_scales = [
		Vector3(size * patch_size, wall_height, border_thickness),
		Vector3(size * patch_size, wall_height, border_thickness),
		Vector3(border_thickness, wall_height, size * patch_size),
		Vector3(border_thickness, wall_height, size * patch_size)
	]

	for i in range(4):
		var wall = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = wall_scales[i]
		wall.mesh = mesh
		wall.position = wall_positions[i]
		wall.material_override = wall_material if wall_material else terrain_material
		add_child(wall)

		var wall_body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = wall_scales[i]
		collision.shape = shape
		wall_body.position = wall.position
		wall_body.add_child(collision)
		add_child(wall_body)
	
