extends CharacterBody2D

@export var speed : float = 100.0
@export var warp_cd : float = 3.0
@export var warp_distance : float = 16*3
@export var push_out_distance : float = 8.0

@onready var animation_player = $AnimationPlayer
@onready var tile_map : TileMap = $"../TileMap"

var speed_mod_layer = 0

enum orientation {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
var facing = orientation.DOWN 


func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	move_player(direction, delta)
	
	if Input.is_action_just_pressed('warp_jump'):
		warp_jump(direction)


func move_player(direction, delta):
	# Select the right running animation
	if direction:
		if direction.x > 0:
			$Sprite2D.flip_h = false
			animation_player.play('run_right')
			facing = orientation.RIGHT
		
		elif direction.x < 0:
			$Sprite2D.flip_h = true
			animation_player.play('run_right')
			facing = orientation.LEFT
			
		elif direction.y > 0:
			$Sprite2D.flip_h = false
			animation_player.play('run_down')
			facing = orientation.DOWN
			
		elif direction.y < 0:
			$Sprite2D.flip_h = false
			animation_player.play('run_up')
			facing = orientation.UP
		
		var atlas_coord : Vector2i = tile_map.local_to_map(global_position)
		var location_tile_data: TileData = tile_map.get_cell_tile_data(speed_mod_layer, atlas_coord)
		var speed_mod: float
		if location_tile_data:
			speed_mod = location_tile_data.get_custom_data('speed_modifier')
		else:
			speed_mod = 1
		velocity = direction * speed * speed_mod
		
	# Or select the right idle animation
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
		
		if velocity == Vector2.ZERO:
			if facing == orientation.RIGHT:
				$Sprite2D.flip_h = false
				animation_player.play('idle_right')
		
			elif facing == orientation.LEFT:
				$Sprite2D.flip_h = true
				animation_player.play('idle_right')
				
			elif facing == orientation.DOWN:
				$Sprite2D.flip_h = false
				animation_player.play('idle_down')
				
			elif facing == orientation.UP:
				$Sprite2D.flip_h = false
				animation_player.play('idle_up')
	
	# Move if within level borders 
	if not level_bounds_reached(velocity * delta):
		move_and_slide()
	
	
func warp_jump(direction):
	var old_position : Vector2 = global_position
	global_position = old_position + direction * warp_distance
	
	var move_dir = (global_position - old_position).normalized()
	push_out_of_obstacles(move_dir)
	
	
func push_out_of_obstacles(arrival_vector: Vector2):
	if arrival_vector == Vector2.ZERO:
		return
	
	else:
		# push out of obstacles
		if test_move(transform, arrival_vector):
			push_back(arrival_vector)
			push_out_of_obstacles (arrival_vector)
			
		# push put of level borders <- fix!!!
		if level_bounds_reached(arrival_vector):
			push_back(arrival_vector)
			push_out_of_obstacles (arrival_vector)
	
	
func push_back(push_dir : Vector2):
	global_position += -push_dir.normalized() * push_out_distance
	
	
func level_bounds_reached(movement: Vector2):
	# get level tiles
	var existing_tiles_pos : Array[Vector2i] = tile_map.get_used_cells(tile_map.map_layers.LEVEL)
	var new_level_positon = tile_map.local_to_map(global_position + movement)
	
	if  new_level_positon not in existing_tiles_pos:
		return true
	else:
		return false
