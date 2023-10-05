extends Node2D


@export_group('Timers and Periods')
@export var wheat_growth_time : float
@export var new_tile_spawn_time : float
@export_group('')

@export_group('Scores and Points')
@export var coin_worth : int
@export_group('')

@onready var game_ui = $GameUI
@onready var flock_manager = $FlockManager
@onready var tilemap: TileMap = $TileMap
@onready var tile_spawn_timer: Timer = $Tile_Spawn_Timer
@onready var score_label: Label = game_ui.get_node('MarginContainer/PanelContainer/MarginContainer/GridContainer/ScoreCount')
@onready var fps_label: Label = game_ui.get_node('MarginContainer/PanelContainer/MarginContainer/GridContainer/FPSCount')
@onready var crow_count_label: Label = game_ui.get_node('MarginContainer/PanelContainer/MarginContainer/GridContainer/CrowCount')

var score : int = 0
var crow_count : int

# Called when the node enters the scene tree for the first time.
func _ready():
	flock_manager.crow_spawned.connect(_on_crow_spawned)
	tilemap.wheat_cycle_complete.connect(_on_wheat_cycle_complete)
	tile_spawn_timer.start(new_tile_spawn_time)
	crow_count = get_tree().get_nodes_in_group('Crows').size()
	
	
func _process(delta):
	fps_label.text = str(Engine.get_frames_per_second())
	
	
	
func _on_wheat_cycle_complete():
	score += coin_worth	
	score_label.text = str(score)
	

func _on_crow_spawned():
	crow_count += 1
	crow_count_label.text = str(crow_count)

