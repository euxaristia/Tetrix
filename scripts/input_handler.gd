class_name TetrixInputHandler
extends RefCounted

const TetrixEngine = preload("res://scripts/engine.gd")

const INITIAL_DELAY: float = 0.12
const REPEAT_INTERVAL: float = 0.025
const DOWN_REPEAT_INTERVAL: float = 0.02
const JOY_INITIAL_DELAY: float = 0.15
const JOY_REPEAT_INTERVAL: float = 0.03

var left_pressed: bool = false
var right_pressed: bool = false
var down_pressed: bool = false

var left_hold_time: float = 0.0
var right_hold_time: float = 0.0
var down_hold_time: float = 0.0

var left_repeat_timer: float = 0.0
var right_repeat_timer: float = 0.0
var down_repeat_timer: float = 0.0

var left_right_conflict: bool = false
var joy_left_right_conflict: bool = false

var joystick_present: bool = false
var joy_left_pressed: bool = false
var joy_right_pressed: bool = false
var joy_down_pressed: bool = false
var joy_up_pressed: bool = false
var joy_a_pressed: bool = false
var joy_y_pressed: bool = false
var joy_start_pressed: bool = false
var joy_select_pressed: bool = false

func update(game: TetrixEngine, delta_time: float, music_enabled: bool) -> bool:
	var next_music_enabled := music_enabled
	var pads := Input.get_connected_joypads()
	joystick_present = not pads.is_empty()
	if joystick_present:
		next_music_enabled = _handle_joystick(pads[0], game, delta_time, next_music_enabled)
	_handle_key_repeats(game, delta_time)
	return next_music_enabled

func _handle_key_repeats(game: TetrixEngine, delta_time: float) -> void:
	var left_state := Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var right_state := Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)

	if left_state and right_state:
		left_right_conflict = true
		left_pressed = false
		right_pressed = false
		return

	if left_right_conflict:
		if not left_state and not right_state:
			left_right_conflict = false
		left_pressed = false
		right_pressed = false
		return

	if left_state:
		if not left_pressed:
			left_pressed = true
			left_hold_time = 0.0
			left_repeat_timer = 0.0
			game.move_left()
		else:
			left_hold_time += delta_time
			if left_hold_time >= INITIAL_DELAY:
				left_repeat_timer += delta_time
				if left_repeat_timer >= REPEAT_INTERVAL:
					left_repeat_timer = 0.0
					game.move_left()
	else:
		left_pressed = false

	if right_state:
		if not right_pressed:
			right_pressed = true
			right_hold_time = 0.0
			right_repeat_timer = 0.0
			game.move_right()
		else:
			right_hold_time += delta_time
			if right_hold_time >= INITIAL_DELAY:
				right_repeat_timer += delta_time
				if right_repeat_timer >= REPEAT_INTERVAL:
					right_repeat_timer = 0.0
					game.move_right()
	else:
		right_pressed = false

	var down_state := Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
	if down_state:
		if not down_pressed:
			down_pressed = true
			down_hold_time = 0.0
			down_repeat_timer = 0.0
			game.soft_drop()
		else:
			down_hold_time += delta_time
			if down_hold_time >= INITIAL_DELAY:
				down_repeat_timer += delta_time
				if down_repeat_timer >= DOWN_REPEAT_INTERVAL:
					down_repeat_timer = 0.0
					game.soft_drop()
	else:
		down_pressed = false

func _handle_joystick(device: int, game: TetrixEngine, delta_time: float, music_enabled: bool) -> bool:
	var left := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT) or Input.get_joy_axis(device, JOY_AXIS_LEFT_X) < -0.5
	var right := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT) or Input.get_joy_axis(device, JOY_AXIS_LEFT_X) > 0.5
	var down := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) > 0.5
	var up := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP) or Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) < -0.5

	if left and right:
		joy_left_right_conflict = true
		joy_left_pressed = false
		joy_right_pressed = false
	elif joy_left_right_conflict:
		if not left and not right:
			joy_left_right_conflict = false
		joy_left_pressed = false
		joy_right_pressed = false
	else:
		if left:
			if not joy_left_pressed:
				joy_left_pressed = true
				left_hold_time = 0.0
				left_repeat_timer = 0.0
				game.move_left()
			else:
				left_hold_time += delta_time
				if left_hold_time >= JOY_INITIAL_DELAY:
					left_repeat_timer += delta_time
					if left_repeat_timer >= JOY_REPEAT_INTERVAL:
						left_repeat_timer = 0.0
						game.move_left()
		else:
			joy_left_pressed = false

		if right:
			if not joy_right_pressed:
				joy_right_pressed = true
				right_hold_time = 0.0
				right_repeat_timer = 0.0
				game.move_right()
			else:
				right_hold_time += delta_time
				if right_hold_time >= JOY_INITIAL_DELAY:
					right_repeat_timer += delta_time
					if right_repeat_timer >= JOY_REPEAT_INTERVAL:
						right_repeat_timer = 0.0
						game.move_right()
		else:
			joy_right_pressed = false

	if down:
		if not joy_down_pressed:
			joy_down_pressed = true
			down_hold_time = 0.0
			down_repeat_timer = 0.0
			game.soft_drop()
		else:
			down_hold_time += delta_time
			if down_hold_time >= JOY_INITIAL_DELAY:
				down_repeat_timer += delta_time
				if down_repeat_timer >= DOWN_REPEAT_INTERVAL:
					down_repeat_timer = 0.0
					game.soft_drop()
	else:
		joy_down_pressed = false

	var a_button := Input.is_joy_button_pressed(device, JOY_BUTTON_A)
	var x_button := Input.is_joy_button_pressed(device, JOY_BUTTON_X)
	if up or a_button or x_button:
		if not joy_up_pressed and not joy_a_pressed:
			joy_up_pressed = up
			joy_a_pressed = a_button or x_button
			game.rotate_piece()
	else:
		joy_up_pressed = false
		joy_a_pressed = false

	var start_button := Input.is_joy_button_pressed(device, JOY_BUTTON_START)
	if start_button:
		if not joy_start_pressed:
			joy_start_pressed = true
			game.toggle_pause()
	else:
		joy_start_pressed = false

	var select_button := Input.is_joy_button_pressed(device, JOY_BUTTON_BACK)
	if select_button:
		if not joy_select_pressed:
			joy_select_pressed = true
			if game.state == TetrixEngine.GameState.GAME_OVER:
				game.reset()
	else:
		joy_select_pressed = false

	var y_button := Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
	if y_button:
		if not joy_y_pressed:
			joy_y_pressed = true
			music_enabled = not music_enabled
	else:
		joy_y_pressed = false

	return music_enabled

func is_using_controller() -> bool:
	return joystick_present
