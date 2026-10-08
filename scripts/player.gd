extends CharacterBody2D

const SPEED = Balance.MOVE_SPEED
const JUMP = Balance.JUMP_SPEED
const GRAVITY = Balance.GRAVITY
var facing = 1.0
var is_ghost = false
var ghost_ruler = true
var frames: Array = []
var frame_index = 0
var coyote = 0.0
var jump_buffer = 0.0
var dash_left = 0.0
var dash_cooldown = 0.0
var invulnerable = 0.0
var stagger = 0.0
var attack_left = 0.0
var attack_cooldown = 0.0
var combo = 0
var combo_window = 0.0
var down_attack = false
var hits: Array = []
var recent: Array = []
var safe_position = Vector2(150,570)
var last_frame: Dictionary = {}
var world: Node
var step_clock = 0.0
var was_grounded = false

func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")
	if is_ghost:
		$Camera2D.enabled = false
		collision_layer = 0
		modulate = Color(0.6,1.0,0.92,0.65)
		$Art.echo = true

func _physics_process(delta: float) -> void:
	if world == null or world.transitioning:
		return
	var frame: Dictionary
	if is_ghost:
		if frame_index >= frames.size():
			world.last_echo_endpoint=position
			queue_free()
			return
		frame = frames[frame_index]
		frame_index += 1
	else:
		frame = ActionFrame.capture()
		last_frame = frame
		world.capture_frame(frame)
	simulate(frame, delta)
	if not is_ghost:
		if is_on_floor() and world.safe_ground(position):
			safe_position = position
		recent.append([position.x,position.y,facing,absf(velocity.x)>20,attack_left>0])
		if recent.size()>Balance.DEATH_VISIBLE_FRAMES:
			recent.pop_front()
		if position.y > 900:
			world.die()
	$Art.facing = facing
	$Art.moving = minf(absf(velocity.x)/SPEED,1.0)
	$Art.attacking = attack_left > 0
	$Art.downward = down_attack
	$Art.vertical_speed = velocity.y
	$Art.grounded = is_on_floor()
	$Art.hurt_pose = stagger>0
	$Art.dashing = dash_left>0
	if is_on_floor() and not was_grounded: $Art.landing = 0.13
	was_grounded = is_on_floor()
	if not is_ghost and is_on_floor() and absf(velocity.x)>40:
		step_clock -= delta
		if step_clock<=0:
			world.sound("foot")
			step_clock=0.32
	if not is_ghost:
		$Art.modulate.a = 0.45 if invulnerable > 0 and int(invulnerable*16)%2==0 else 1.0

func simulate(frame: Dictionary, delta: float) -> void:
	coyote = Balance.COYOTE_SECONDS if is_on_floor() else maxf(0,coyote-delta)
	jump_buffer = Balance.JUMP_BUFFER_SECONDS if frame.get("jump",false) else maxf(0,jump_buffer-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	invulnerable = maxf(0,invulnerable-delta)
	stagger = maxf(0,stagger-delta)
	attack_cooldown = maxf(0,attack_cooldown-delta)
	attack_left = maxf(0,attack_left-delta)
	combo_window = maxf(0,combo_window-delta)
	var axis: float = frame.get("axis",0.0)
	if absf(axis)>0.1 and dash_left<=0:
		facing = signf(axis)
	if frame.get("dodge",false) and dash_cooldown<=0:
		dash_left = Balance.DASH_SECONDS
		dash_cooldown = Balance.DASH_COOLDOWN
		invulnerable = maxf(invulnerable,0.19)
		world.sound("dash")
	if dash_left>0:
		dash_left -= delta
		velocity = Vector2(facing*Balance.DASH_SPEED,0)
	else:
		if stagger<=0:
			velocity.x = move_toward(velocity.x,axis*SPEED,2400*delta)
		velocity.y = minf(900,velocity.y+GRAVITY*delta)
		if jump_buffer>0 and coyote>0:
			velocity.y = JUMP
			jump_buffer = 0
			coyote = 0
			world.sound("jump")
		if frame.get("release",false) and velocity.y < -190:
			velocity.y = -190
	if frame.get("attack",false) and attack_cooldown<=0 and (ghost_ruler if is_ghost else State.has_flag("ruler")):
		combo = (combo+1)%3 if combo_window>0 else 0
		combo_window = 0.65
		attack_left = 0.20
		attack_cooldown = 0.30 if combo==2 else 0.23
		down_attack = frame.get("down",false) and not is_on_floor()
		hits.clear()
		world.sound("strike")
	if attack_left>0:
		world.resolve_strike(self, down_attack, 16 if combo==2 else 10)
	if frame.get("interact",false):
		world.interact(self)
	move_and_slide()
	if is_ghost and position.y>900:
		queue_free()

func hurt(amount: int, source: Vector2) -> void:
	if is_ghost:
		return
	if invulnerable>0:
		if dash_left>0 and not world.dodge_rewarded:
			State.recover(2)
			world.dodge_rewarded = true
		return
	State.data.hp -= amount
	invulnerable = 1.1
	stagger = 0.17
	velocity = Vector2(signf(position.x-source.x)*260,-220)
	world.sound("hurt")
	world.ui.shake_health()
	State.changed.emit()
	if int(State.data.hp)<=0:
		world.die()

func snapshot_reset(point: Vector2) -> void:
	position = point
	velocity = Vector2.ZERO
	safe_position = point
	invulnerable = 1.0
	attack_left = 0
	dash_left = 0
	dash_cooldown = 0
	attack_cooldown = 0
	stagger = 0
	combo_window = 0
	jump_buffer = 0
	coyote = 0
	step_clock = 0
	recent.clear()
