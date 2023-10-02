extends Node2D


@export_group('Timers and Periods')
@export var tile_spawn_period : float = 5.0
@export var wheat_growth_time : float = 15.0
@export var new_tile_spawn_time : float = 5.0
@export_group('')

@export_group('Scores and Points')
@export var coin_worth : int = 1
@export_group('')

@onready var tilemap = $TileMap
@onready var tile_spawn_timer = $Tile_Spawn_Timer

var score : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap.wheat_cycle_complete.connect(_on_wheat_cycle_complete)
	tile_spawn_timer.start(new_tile_spawn_time)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _on_wheat_cycle_complete():
	score += coin_worth

