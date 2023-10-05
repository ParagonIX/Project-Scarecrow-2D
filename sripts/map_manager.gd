extends TileMap

@export_group('Map Settings')
@export_range(0, 50, 1) var starting_map_size : int = 3
@export_subgroup('Tile Probabilities')
@export_range(0, 1, 0.01) var water_prob
@export_range(0, 1, 0.01) var grass_prob
@export_range(0, 1, 0.01) var rock_prob
@export_range(0, 1, 0.01) var fence_prob
@export_range(0, 1, 0.01) var tree_prob
@export_range(0, 1, 0.01) var wheat_prob

enum tile_types {
	WATER,
	GRASS,
	ROCK,
	FENCE,
	TREE,
	WHEAT,
}
enum map_layers {
	LEVEL,
	LOW_PROPS,
	HIGH_PROPS,
	EFFECTS
}
class TileInfo:
	var position : Vector2i
	var tile_type : int
	var wheat_level : float
	
	func _init(location : Vector2i, type : int):
		position = location
		tile_type = type
		wheat_level = 0.0
		
	func _to_string() -> String:
		var description = 'Position: %s; Type: %s' % [position, tile_type]
		return description

var level : Array
var max_wheat_level : float = 100.0
var possible_new_tile_positions : Array
var game_manager: Node2D

const PROPS_TILESET_ID = 0
const MAP_TILESET_ID = 1

const WHEAT_ALTLAS_COORD : Vector2i = Vector2i(21, 10)
const WHEAT_STAGES_QT : int = 4

signal wheat_cycle_complete
signal map_tile_added(tile_data)

# Called when the node enters the scene tree for the first time.
func _ready():	
	game_manager = get_parent()
	initialize_level()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_wheat_tiles(delta)


func get_random_tile_type():
	var possible_tiles = [
		{'type': tile_types.WATER, 'weight': water_prob},
		{'type': tile_types.GRASS, 'weight': grass_prob},
		{'type': tile_types.ROCK, 'weight': rock_prob},
		{'type': tile_types.FENCE, 'weight': fence_prob},
		{'type': tile_types.TREE, 'weight': tree_prob},
		{'type': tile_types.WHEAT, 'weight': wheat_prob}		
	]
	
	var total_weight = 0.0
	
	for option in possible_tiles:
		total_weight += option["weight"]
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for option in possible_tiles:
		cumulative_weight += option["weight"]
		if random_value < cumulative_weight:
			
			return option['type']
			
	return possible_tiles[-1]['type']


func place_tile(tile: TileInfo):
	level.append(tile)
	emit_signal("map_tile_added", tile)
	possible_new_tile_positions.erase(tile.position)
	
	match tile.tile_type:
		
		tile_types.WATER:
			var water_tiles: Array[Vector2i] = []
			for tile_of_type in level:
				if tile_of_type.tile_type == tile_types.WATER:
					water_tiles.append(Vector2i(tile_of_type.position.x, tile_of_type.position.y))					
			set_cells_terrain_connect(map_layers.LEVEL, water_tiles, 1, 0)
		
		tile_types.GRASS:
			place_grass_tiles()
			
		tile_types.ROCK:
			# place level tile
			place_grass_tiles()
			
			# place rock
			var rock_sprite_atlas_coord : Vector2i = Vector2i(19 - randi_range(0, 3), 7)
			set_cell(map_layers.LOW_PROPS, tile.position, PROPS_TILESET_ID, rock_sprite_atlas_coord)
			
		tile_types.FENCE:
			# place level tile
			place_grass_tiles()
			
			# place fence
			var fence_tiles: Array[Vector2i] = []
			for tile_of_type in level:
				if tile_of_type.tile_type == tile_types.FENCE:
					fence_tiles.append(Vector2i(tile_of_type.position.x, tile_of_type.position.y))
			set_cells_terrain_connect(map_layers.LOW_PROPS, fence_tiles, 2, 0)
			
		tile_types.TREE:
			# place level tile
			place_grass_tiles()
			
			var tree_root_atlas_coord : Vector2i = Vector2i(1 + 2 * randi_range(0, 2), 9)
			var tree_top_atlas_coord : Vector2i = Vector2i(tree_root_atlas_coord.x, tree_root_atlas_coord.y - 1)
			# place tree
			set_cell(map_layers.LOW_PROPS, Vector2i(tile.position.x, tile.position.y), PROPS_TILESET_ID, tree_root_atlas_coord)
			set_cell(map_layers.HIGH_PROPS, Vector2i(tile.position.x, tile.position.y-1), PROPS_TILESET_ID, tree_top_atlas_coord)
		
		tile_types.WHEAT:
			# place level tile
			place_grass_tiles()
			
			# place wheat
			var tile_pos = Vector2i(tile.position.x, tile.position.y)
			
			set_cell(map_layers.LOW_PROPS, tile_pos, PROPS_TILESET_ID, WHEAT_ALTLAS_COORD)


func initialize_level():
	for x in range(starting_map_size):
		for y in range(starting_map_size):
			
			var tile_info : TileInfo = TileInfo.new(Vector2i(x, y), get_random_tile_type())
			# make sure that starting tile is grass
			if tile_info.position.x == 1 and tile_info.position.y == 1:
				tile_info.tile_type = tile_types.GRASS
			
			place_tile(tile_info)


func place_grass_tiles():
	var grass_tiles: Array[Vector2i] = []
	for tile_of_type in level:
		if tile_of_type.tile_type in [tile_types.GRASS, tile_types.ROCK, tile_types.FENCE, tile_types.TREE, tile_types.WHEAT]:
			grass_tiles.append(Vector2i(tile_of_type.position.x, tile_of_type.position.y))					
	set_cells_terrain_connect(map_layers.LEVEL, grass_tiles, 1, 1)


func handle_wheat_tiles(delta):
	var wheat_tiles : Array = []
	for x in range(level.size()):			
			if level[x].tile_type == tile_types.WHEAT:
				wheat_tiles.append(level[x])
				
	for wheat_tile in wheat_tiles:
		var wheat_location : Vector2i = Vector2i(wheat_tile.position.x, wheat_tile.position.y)
		
		if wheat_tile.wheat_level < max_wheat_level:
			var wheat_stage = int(wheat_tile.wheat_level / (max_wheat_level/(WHEAT_STAGES_QT +1)))
			var wheat_stage_atlas_coord : Vector2i 
			
			wheat_tile.wheat_level += max_wheat_level / game_manager.wheat_growth_time * delta
			wheat_stage_atlas_coord = Vector2i(WHEAT_ALTLAS_COORD.x - wheat_stage, WHEAT_ALTLAS_COORD.y)
			set_cell(map_layers.LOW_PROPS, wheat_location, PROPS_TILESET_ID, wheat_stage_atlas_coord)
			
		else:
			wheat_tile.wheat_level = 0
			emit_signal('wheat_cycle_complete')


func get_new_tile_position():
	var tile_positions : Array = get_used_cells(map_layers.LEVEL)
	
	var x_min : int = 0
	var y_min : int = 0
	var x_max : int = 0
	var y_max : int = 0
	
	for tile_pos in tile_positions:
		if tile_pos.x > x_max:
			x_max = tile_pos.x
		if tile_pos.x < x_min:
			x_min = tile_pos.x
		if tile_pos.y > y_max:
			y_max = tile_pos.y
		if tile_pos.y < y_min:
			y_min = tile_pos.y
	
	
	if possible_new_tile_positions.size() == 0:
		for x in range (x_min - 1, x_max + 2):
			for y in range (y_min - 1, y_max + 2):
				if Vector2i(x, y) not in tile_positions:
					possible_new_tile_positions.append(Vector2i(x, y))
	
	
	var random_index : int = randi() %  possible_new_tile_positions.size()
			
	return possible_new_tile_positions[random_index]


func _on_tile_spawn_timer_timeout():
	# generate a location shift (choose on what side of existing level to spawn the new tile)
	var new_tile_pos = get_new_tile_position()
	var new_tile_type = get_random_tile_type()
	
	var new_tile : TileInfo = TileInfo.new(new_tile_pos, new_tile_type)
	place_tile(new_tile)
