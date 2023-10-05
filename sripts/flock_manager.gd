extends Node2D
@onready var tile_map: TileMap = $"../TileMap"
@onready var crow_spawn_timer = $CrowSpawnTimer

@export_group('Timers and Periods')
@export var crow_scene: PackedScene = preload("res://scenes/units/crow.tscn")
@export var crow_spawn_time: int
@export var wander_reset_time: float
@export_group('')

@export_group('Crow Parameters')
@export var max_crow_speed: float
@export var max_crow_count: float
@export_group('')

@export_group('Behavior Weights')
@export var cohesion_weight: float
@export var alignment_weight: float
@export var separation_weight: float
@export var bounds_weight: float
@export var wander_weight: float
@export_group('')

var tree_tiles: Array = []

signal crow_spawned
signal crow_died

# Called when the node enters the scene tree for the first time.
func _ready():
	tile_map.map_tile_added.connect(_on_map_tile_added)
	crow_spawn_timer = crow_spawn_time

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass


func _on_crow_spawn_timer_timeout():
	var crow_count = get_tree().get_nodes_in_group('Crows').size()
	if tree_tiles.size() > 0 and crow_count < max_crow_count:
		spawn_crow()


func spawn_crow():
	# select a spawner tree
	var random_index = randi() % tree_tiles.size()
	var spawner_tree = tree_tiles[random_index]
	# spawn a crow at the location of a random spawner tree TOP(!)
	var crow = crow_scene.instantiate()
	crow.global_position = tile_map.map_to_local(Vector2i(spawner_tree.position.x, spawner_tree.position.y - 1))
	add_child(crow)
	crow_spawned.emit()

func _on_map_tile_added(tile_data):
	if tile_data.tile_type == tile_map.tile_types.TREE:
		tree_tiles.append(tile_data)
