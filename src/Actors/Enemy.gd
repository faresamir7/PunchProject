extends "res://src/Actors/Actor.gd"

onready var sprite: = $AnimatedSprite; 
onready var attack_hitbox: = $AnimatedSprite/Attack_Areas;
onready var health_text: = $HealthText;
onready var player: = get_node("../Player");
var direction: = -1;
var is_staggered: = false;
 
func _ready():
	set_physics_process(false);
	_velocity.x = -speed.x;
	attack_hitbox.get_node("front_collision").set_disabled(true);
	
func _on_Hitbox_Area_area_entered(area):
	if((area.get_parent().get_parent().get_name() == "Player")and(area.get_name() == "Attack_Areas")):
		health -= 1;
		stagger(area);
	return;
	
func _on_Hitbox_Area_body_entered(_body):
	if(!is_staggered):
		attack();

func _physics_process(delta):
	_velocity.y += gravity * delta;
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL);
	if(position.x > player.get_position().x):
		direction = -1;
	elif(position.x < player.get_position().x):
		direction = 1;
	else:
		direction = 0;
	if(OS.get_ticks_msec() - ms_since_stagger >= 500) and is_on_floor():
		is_staggered = false;
	if(health == 0):
		queue_free();
	if(direction == 1):
		attack_hitbox.set_scale(Vector2(-1,1));
		sprite.set_flip_h(true);
		
	if(direction == -1):
		attack_hitbox.set_scale(Vector2(1,1));
		sprite.set_flip_h(false);
		
	if(!is_staggered):
		if(is_attack_over()):
			sprite.set_animation("walk");
			attack_hitbox.get_node("front_collision").set_disabled(true);
		elif(sprite.get_frame() >= 1):
			attack_hitbox.get_node("front_collision").set_disabled(false);
			_velocity.x = 0;
		else:
			_velocity.x = 0;
	if((_velocity.x < 50 and direction > 0) or (_velocity.x > -50 and direction < 0)):
		if _velocity.y == 0 :
			_velocity.x += 5*direction;
		else:
			_velocity.x += direction;
	if(((_velocity.x > 50 and direction > 0) or (_velocity.x < -50 and direction < 0)) and is_on_floor() and !is_staggered):
		_velocity.x -= 10*direction;

func attack():
	sprite.set_animation("attack");

func is_attack_over() -> bool:
	return ((sprite.get_animation() == "attack") and (sprite.get_frame() == 2)) or (!sprite.get_animation() == "attack");

func stagger(area: Area2D):
	if(area.get_parent().get_animation() == "jab_left"):
		sprite.set_animation("take_hit_1");
	if(area.get_parent().get_animation() == "jab_right"):
		sprite.set_animation("take_hit_2");
	if(area.get_parent().get_animation() == "uppercut_left"):
		sprite.set_animation("uppercutted_left");
	if(area.get_parent().get_animation() == "uppercut_right"):
		sprite.set_animation("uppercutted_right");
	if(area.get_parent().get_animation() == "downsmash_right") or (area.get_parent().get_animation() == "downsmash_left"):
		sprite.set_animation("downsmashed");
	_velocity.y = area.get_parent().get_parent().get_velocity().y;
	if(_velocity.x<area.get_parent().get_parent().get_velocity().x):
		_velocity.x = area.get_parent().get_parent().get_velocity().x;
	is_staggered = true;
	attack_hitbox.get_node("front_collision").set_disabled(true);
	ms_since_stagger = OS.get_ticks_msec();
