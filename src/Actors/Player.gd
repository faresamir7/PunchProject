extends Actor

var last_strike: = "left";
onready var sprite: = $AnimatedSprite; 
onready var attack_hitbox: = $AnimatedSprite/Attack_Areas;
onready var speed_text: = $SpeedText;
onready var animation_text: = $AnimationText;
onready var health_text: = $HealthText;
onready var gravity_text: = $GravityText;
onready var player: = get_parent().get_node("Player");
var is_staggered: = false;
var uppercutted: = false;
var downsmashed: = false;
var blocking: = false;
var blocked_attack: = false;
onready var velocity_text: = $VelocityText;

func _ready():
	sprite.set_animation("stand");
	disable_attack();
	
func _on_Hitbox_Area_area_entered(area):
	if((area.get_parent().get_parent().get_name() == "Enemy") and (area.get_name() == "Attack_Areas")):
		stagger();
	return;

func _physics_process(_delta):
	var is_jump_interrupted: = Input.is_action_just_released("downsmash") and _velocity.y < 0.0;
	var direction = Vector2(0,0);
	if(health==0):
		queue_free();
	if(OS.get_ticks_msec() - ms_since_stagger >= 75) and blocked_attack:
		is_staggered = false;
	elif(OS.get_ticks_msec() - ms_since_stagger >= 500):
		is_staggered = false;
	if(!is_staggered):
		direction = get_direction();
		if(direction.x<0):
			sprite.set_flip_h(true);
			attack_hitbox.set_scale(Vector2(-1,1));
		if(direction.x>0):
			sprite.set_flip_h(false);
			attack_hitbox.set_scale(Vector2(1,1));
		if(direction.x == 0 and is_on_floor() and (!is_jabbing() or sprite.get_frame() == 4)):
			sprite.set_animation("stand");
			disable_attack();
			uppercutted = false;
			downsmashed = false;
			speed.x = 200;
			gravity = 3000;
		if(Input.get_action_strength("jab")):
			if(((is_jabbing() and sprite.get_frame()==4)) or !is_jabbing()) and !downsmashed :
				disable_attack();
				if(last_strike == "left"):
					sprite.set_animation("jab_right");
					last_strike = "right";
				else:
					sprite.set_animation("jab_left");
					last_strike = "left";
				speed.x = 400;
				gravity = 3000;
			if(sprite.get_frame()==0):
				attack_hitbox.get_node("front_collision").set_disabled(false);
			elif(sprite.get_frame()==3 and is_jabbing()):
				disable_attack();
		if(!is_on_floor() and !is_jabbing() and !is_jumping() and !is_downsmashing() and !downsmashed):
			sprite.set_animation("falling");
			disable_attack();
		else:
			if(direction.x<0 or direction.x>0) and (!is_jabbing() or sprite.get_frame() == 4) and (!is_jumping()) and (!is_falling()):
				sprite.set_animation("walk");
				disable_attack();
				uppercutted = false;
				downsmashed = false;
				blocking = false;
				if(speed.x>300):
					speed.x-= 1;
				gravity = 3000;
		if Input.get_action_strength("uppercut"):
			if(is_jumping() and !is_uppercutting() and !uppercutted):
				disable_attack();
				if(last_strike == "left"):
					sprite.set_animation("uppercut_right");
					attack_hitbox.get_node("down_collision").set_disabled(false);
					attack_hitbox.get_node("up_collision").set_disabled(false);
					last_strike = "right";
					speed.x = 200;
				else:
					sprite.set_animation("uppercut_left");
					attack_hitbox.get_node("down_collision").set_disabled(false);
					attack_hitbox.get_node("up_collision").set_disabled(false);
					last_strike = "left";
					speed.x = 200;
				uppercutted = true;
				ms_since_jump = OS.get_ticks_msec();
		if(Input.get_action_strength("downsmash")):
			if(!is_on_floor() and !is_downsmashing() and !downsmashed):
				disable_attack();
				if(last_strike == "left"):
					sprite.set_animation("downsmash_right");
					attack_hitbox.get_node("down_collision").set_disabled(false);
					last_strike = "right";
				else:
					sprite.set_animation("downsmash_left");
					attack_hitbox.get_node("down_collision").set_disabled(false);
					last_strike = "left";
				downsmashed = true;
				speed.x = 200;
				gravity = 6000;
		if(Input.get_action_strength("block") and !is_downsmashing() and !is_jabbing()):
			if(!is_on_floor()):
				sprite.set_animation("block_air");
			else:
				sprite.set_animation("block");
			blocking = true;
			disable_attack();
	else:
		direction = Vector2(-1 if _velocity.x < 0 else 1, 0);
	_velocity = calculate_move_velocity(_velocity, speed, direction, is_jump_interrupted);
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL);
	health_text.set_text("Health : "+String(health));
	speed_text.set_text("Speed : "+String(speed.x));
	animation_text.set_text("Animation : "+sprite.get_animation()+" "+String(sprite.get_frame()));
	gravity_text.set_text("Gravity : "+String(gravity));
	velocity_text.set_text("Velocity : "+String(_velocity));
	
func get_direction() -> Vector2:
	if(is_staggered):
		return Vector2(0,1);
	return Vector2(
		0 if Input.get_action_strength("block") and is_on_floor() else Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if (Input.get_action_strength("uppercut") and is_on_floor() and !Input.get_action_strength("block") and ( OS.get_ticks_msec() - ms_since_jump >= 500)) else 1.0
	)

func is_jabbing() -> bool:
	return ((sprite.get_animation() == "jab_right") or (sprite.get_animation() == "jab_left"));
	
func is_jumping() -> bool:
	return _velocity.y<0;
	
func is_falling() -> bool:
	return _velocity.y>0;
	
func is_uppercutting() -> bool:
	return ((sprite.get_animation() == "uppercut_right") or (sprite.get_animation() == "uppercut_left"));
	
func is_downsmashing() -> bool:
	return ((sprite.get_animation() == "downsmash_right") or (sprite.get_animation() == "downsmash_left"));
	
func is_blocking() -> bool:
	if(Input.get_action_strength("block")==1):
		return true;
	return false;
	
func disable_attack():
	attack_hitbox.get_node("down_collision").set_disabled(true);
	attack_hitbox.get_node("front_collision").set_disabled(true);
	attack_hitbox.get_node("up_collision").set_disabled(true);

func calculate_move_velocity( 
		linear_velocity: Vector2,
		speed: Vector2,
		direction: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var out: = linear_velocity;
	out.x = speed.x * direction.x;
	out.y += gravity * get_physics_process_delta_time(); 
	if direction.y == -1.0:
		out.y =speed.y * direction.y;
	if is_jump_interrupted:
		out.y = 0;
	return out;

func stagger():
	if(!is_blocking()) :
		sprite.set_animation("take_hit");
		health -= 1;
		_velocity = Vector2(300 if (sprite.get_scale().x == -1) else -200,-750);
		blocked_attack = false;
	if(is_blocking()):
		_velocity = Vector2(300 if (sprite.get_scale().x == -1) else -50,_velocity.y);
		blocked_attack = true;
	is_staggered = true;
	disable_attack();
	ms_since_stagger = OS.get_ticks_msec();

