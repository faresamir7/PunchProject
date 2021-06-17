extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL: = Vector2.UP;
var _velocity: = Vector2.ZERO;
export var gravity: = 4000.0;
export var speed: = Vector2(300.0, 1000.0);
export var health: = 100.0;
onready var ms_since_stagger: = OS.get_ticks_msec();
onready var ms_since_jump: = OS.get_ticks_msec();

func get_velocity() -> Vector2:
	return _velocity;
