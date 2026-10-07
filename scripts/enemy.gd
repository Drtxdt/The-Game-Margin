extends CharacterBody2D

@export_enum("charger","flier","watcher","boss") var kind: String = "charger"
@export var stable_id = ""
var hp = 30
var purified = false
var mode = "idle"
var timer = 1.0
var facing = -1.0
var sequence = 0
var attack_kind = "charge"
var home = Vector2.ZERO
var hit_flash = 0.0
var world: Node
var decoy = Vector2.INF
var feint=false
var bell_resistance=0.0

func _ready() -> void:
	world = get_tree().get_first_node_in_group("world")
	home = position
	hp = Balance.BOSS_HEALTH if kind=="boss" else Balance.ENEMY_HEALTH
	purified = State.has_flag("boss_purified" if kind=="boss" else stable_id)
	$Art.kind = kind
	$Art.peaceful = purified
	if kind=="boss":
		$Art.scale = Vector2(2.8,2.8)

func _physics_process(delta: float) -> void:
	if world == null or world.transitioning:
		return
	if purified:
		velocity.x = 0
		if kind!="flier":
			velocity.y += 1600*delta
			move_and_slide()
		return
	var target: Vector2 = world.player.position
	if decoy != Vector2.INF:
		target = decoy
	var distance = position.distance_to(target)
	hit_flash = maxf(0,hit_flash-delta)
	$Art.modulate = Color(1.6,1.2,1.0) if hit_flash>0 else Color.WHITE
	timer -= delta
	bell_resistance=maxf(0,bell_resistance-delta)
	if kind!="flier":
		velocity.y = minf(900,velocity.y+1600*delta)
	if mode=="idle":
		velocity.x = move_toward(velocity.x,0,1100*delta)
		if distance < (850 if kind=="boss" else 550) and timer<=0:
			facing = 1 if target.x>position.x else -1
			mode = "tell"
			timer = 0.85 if kind=="boss" else 0.65
			var pattern = ["charge","leap","sweep","roar"]
			attack_kind = pattern[sequence%4] if kind=="boss" else kind
			sequence += 1
			if kind=="charger" and State.data.san_max<=80 and sequence%3==0:
				feint=true
	elif mode=="tell":
		velocity.x = 0
		if timer<=0:
			mode = "feint" if feint else "attack"
			timer = 0.65 if kind=="boss" else 0.55
			if feint: timer=0.23
			if attack_kind=="leap":
				velocity = Vector2(facing*370,-620)
			if kind=="flier":
				velocity = (target-position).normalized()*430
			world.sound("warning")
	elif mode=="feint":
		velocity.x=facing*110
		if timer<=0:
			feint=false
			facing=signf(world.player.position.x-position.x)
			mode="tell"
			timer=0.4
	elif mode=="attack":
		if attack_kind in ["charge","charger"]:
			velocity.x = facing*(560 if kind=="boss" else 400)
		elif attack_kind=="sweep":
			velocity.x = facing*160
		elif attack_kind in ["roar","watcher"]:
			velocity.x = 0
			if timer>0.35 and absf(world.player.position.x-position.x)<(270 if kind=="boss" else 210) and absf(world.player.position.y-position.y)<90:
				world.player.hurt(1,position)
		if kind=="boss" and attack_kind=="charge" and world.can_hit_bell(position):
			stun(2.4)
			world.ring_bell(position)
		if timer<=0:
			mode = "recover"
			timer = 1.05 if kind=="boss" else 0.9
	elif mode in ["recover","stun"]:
		velocity.x = move_toward(velocity.x,0,1400*delta)
		if timer<=0:
			mode="idle"
			timer=0.25
			decoy=Vector2.INF
	if kind=="flier" and mode!="attack":
		velocity = (home-position)*1.8
	move_and_slide()
	if position.y>900:
		position=home
		velocity=Vector2.ZERO
		stun(0.8)
	$Art.facing = facing
	$Art.moving = minf(absf(velocity.x)/200,1)
	$Art.attacking = mode=="attack"
	if mode=="attack" and world.player.position.distance_to(position)<(95 if kind=="boss" else 45):
		world.player.hurt(1,position)
	queue_redraw()

func _draw() -> void:
	if mode=="tell" and not purified:
		var height = -205 if kind=="boss" else -84
		draw_line(Vector2(-9,height-12),Vector2(0,height+6),Color("e6b87c"),4,true)
		draw_line(Vector2(0,height+6),Vector2(9,height-12),Color("e6b87c"),4,true)
	if kind=="boss" and not purified:
		draw_rect(Rect2(-85,-218,170,5),Color("283c40"))
		draw_rect(Rect2(-85,-218,170*float(hp)/Balance.BOSS_HEALTH,5),Color("c5917b"))

func hit(amount: int, _source: Node) -> void:
	if purified:
		return
	hp -= amount
	hit_flash = 0.12
	if kind!="boss":
		stun(0.35)
	if hp<=0:
		purified=true
		mode="idle"
		$Art.peaceful=true
		world.enemy_purified(self)

func stun(duration: float) -> void:
	mode="stun"
	timer=duration
	velocity.x=0

func hear(point: Vector2) -> void:
	if kind=="boss" and bell_resistance>0: return
	decoy = point
	facing = signf(point.x-position.x)
	stun(1.8)
	if kind=="boss": bell_resistance=4.0
