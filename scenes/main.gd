extends Node

@export var snake_scene: PackedScene

# game
var score: int
var game_started: bool = false

# food
var food_pos: Vector2
var regen_food: bool = true

# grid
@warning_ignore("integer_division")
var cells: int = 1000 / 50
var cell_size: int = 50

# snake
var old_data: Array
var snake_data: Array
var snake: Array

# movement
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction : Vector2
var can_move: bool

func _ready() -> void:
	new_game()
	
func new_game() -> void:
	get_tree().paused = false
	get_tree().call_group("snake_body", "queue_free")
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	move_direction = up
	can_move = true
	generate_snake()
	move_food()
	
func generate_snake() -> void:
	old_data.clear()
	snake_data.clear()
	snake.clear()
	# starting with the start_pos, create tail segments vertically down
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))
		
func add_segment(pos) -> void:
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)
	
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	move_snake()
	
func move_snake():
	if not can_move:
		return
	
	# update movement from keypresses
	if Input.is_action_just_pressed("move_down") and move_direction != up:
		move_direction = down
		can_move = false
		if not game_started:
			start_game()
	
	if Input.is_action_just_pressed("move_up") and move_direction != down:
		move_direction = up
		can_move = false
		if not game_started:
			start_game()
	
	if Input.is_action_just_pressed("move_left") and move_direction != right:
		move_direction = left
		can_move = false
		if not game_started:
			start_game()
	
	if Input.is_action_just_pressed("move_right") and move_direction != left:
		move_direction = right
		can_move = false
		if not game_started:
			start_game()

func start_game() -> void:
	game_started = true
	$MoveTimer.start(1)


func _on_move_timer_timeout() -> void:
	# allow snake movement
	can_move = true
	# use the snake's previous postition to move the segments
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		# move all the segments along by one except for the first one
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
		
	check_outof_bounds()
	check_self_eaten()
	check_food_eaten()
	var interval = 0.7
	if len(snake) > 12:
		interval = 0.1
	elif len(snake) > 9:
		interval = 0.2
	elif len(snake) > 7:
		interval = 0.3
	elif len(snake) > 5:
		interval = 0.5
	$MoveTimer.start(interval)
		
func check_outof_bounds() -> void:
	if (
		snake_data[0].x < 0 or snake_data[0].x > cells - 1 
		or snake_data[0].y < 0 or snake_data[0].y > cells - 1
	):
		end_game()
	
func check_self_eaten() -> void:
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()
		
func check_food_eaten() -> void:
	#if snake eats the food, add a segment and move the food
	if snake_data[0] == food_pos:
		score += 1
		$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
		add_segment(old_data[-1])
		move_food()
		
func move_food() -> void:
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Food.position = (food_pos * cell_size) + Vector2(25, cell_size + 25)
	regen_food = true
	
func end_game() -> void:
	$GameOverMenu.show()
	$MoveTimer.stop()
	game_started = false
	get_tree().paused = true


func _on_game_over_menu_restart() -> void:
	new_game()
