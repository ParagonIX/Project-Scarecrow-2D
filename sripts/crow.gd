extends CharacterBody2D
class_name Crow



@export var is_flying: bool
@export var hunger: float

@onready var animation_player = $AnimationPlayer
@onready var flock_manager = $".."
@onready var tile_map: TileMap = $"../../TileMap"
@onready var neigbour_radius = $NeigbourRadius
@onready var wander_timer : Timer = $WanderTimer
@onready var wander_line = $WanderLine
@onready var crow_sprite = $CrowSprite
@onready var cohesion_line = $CohesionLine
@onready var alignment_line = $AlignmentLine
@onready var separation_line = $SeparationLine

var max_crow_speed: float
var cohesion_weight: float
var alignment_weight: float
var separation_weight: float
var bounds_weight: float
var wander_weight: float
var wander_velocity: Vector2
var visible_flock: Array = []

const NEIGHBOR_RADIUS = 16  # Adjust the radius for neighbor detection
const AVOID_RADIUS = 10  # Adjust the radius for avoiding collisions
const BOUNDS_RADIUS = 10

func _ready():
	wander_weight = flock_manager.wander_weight
	max_crow_speed = flock_manager.max_crow_speed
	cohesion_weight = flock_manager.cohesion_weight
	alignment_weight = flock_manager.alignment_weight
	separation_weight = flock_manager.separation_weight
	bounds_weight = flock_manager.bounds_weight
	wander_timer.wait_time = flock_manager.wander_reset_time
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * max_crow_speed
	animation_player.play("crow_flying")
	
	# set collision shape radius to neighbor radius
	var shape_data = neigbour_radius.shape

# Check if the shape is a CircleShape2D
	if shape_data is CircleShape2D:
		# Cast the shape to CircleShape2D
		var circle_shape = shape_data as CircleShape2D

		# Set the new radius
		circle_shape.radius = NEIGHBOR_RADIUS

func _physics_process(delta):
	# Update the boid's position based on its velocity
	look_at(global_position + velocity)
	#velocity = velocity.normalized() * max_crow_speed
	
	# Apply flocking behaviors
	flock()
	stay_in_bounds()
	wander()
	if velocity.length() > max_crow_speed:
		velocity = velocity.normalized() * max_crow_speed
	move_and_slide()
	
func flock():
	var alignment = Vector2()
	var cohesion = Vector2()
	var separation = Vector2()

	var neighbor_count = 0

	for boid in get_tree().get_nodes_in_group("Crows"):
		if boid != self:
			var distance = global_position.distance_to(boid.global_position)

			# Alignment: Align with neighboring boids
			if distance < NEIGHBOR_RADIUS:
				alignment += boid.velocity
				neighbor_count += 1
			# Cohesion: Move towards the center of mass of neighboring boids
				cohesion += boid.global_position

			# Separation: Avoid collisions with neighboring boids
			if distance < AVOID_RADIUS:
				separation += (global_position - boid.global_position) / distance

	if neighbor_count > 0:
		alignment /= neighbor_count
		cohesion /= neighbor_count
		cohesion -= global_position

	if separation.length() > 0:
		separation = separation.normalized()

	# Adjust the boid's velocity based on flocking behaviors
	velocity += alignment.normalized() * alignment_weight
	alignment_line.look_at(global_position + alignment.normalized() * alignment_weight)
	velocity += cohesion.normalized() * cohesion_weight
	cohesion_line.look_at(global_position + cohesion.normalized() * cohesion_weight)
	velocity += separation.normalized() * separation_weight
	separation_line.look_at(global_position + separation.normalized() * separation_weight)

	# Limit the boid's speed
	if velocity.length() > max_crow_speed:
		velocity = velocity.normalized() * max_crow_speed

func stay_in_bounds():
	var level_bounds = get_level_bounds()
	var left_edge = tile_map.map_to_local(level_bounds.position).x
	var right_edge = tile_map.map_to_local(level_bounds.position + level_bounds.size).x
	var top_edge = tile_map.map_to_local(level_bounds.position).y
	var bottom_edge = tile_map.map_to_local(level_bounds.position + level_bounds.size).y
	var margin = BOUNDS_RADIUS

	if global_position.x < left_edge - margin or global_position.x > right_edge + margin:
		velocity.x = -velocity.x
		wander_velocity = get_random_velocity(wander_weight)
		wander_timer.stop()
		wander_timer.start()

	if global_position.y < top_edge - margin or global_position.y > bottom_edge + margin:
		velocity.y = -velocity.y
		wander_velocity = get_random_velocity(wander_weight)
		wander_timer.stop()
		wander_timer.start()

	# Limit the boid's speed
	if velocity.length() > max_crow_speed:
		velocity = velocity.normalized() * max_crow_speed


func get_level_bounds():
	var bounds = Rect2()

	if tile_map != null:
		bounds = tile_map.get_used_rect()
	
	return bounds
	

func wander():
	velocity += wander_velocity
	wander_line.look_at(global_position + wander_velocity)
	wander_line.scale = Vector2.ONE * wander_velocity.length()


func _on_wander_timer_timeout():
	wander_velocity = get_random_velocity(wander_weight)


func get_random_velocity(weight):
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)) * weight
