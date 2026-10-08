@tool
extends Node2D
## Visible parcel and action share this exact world position.
var kind = "recovery"
var stable_id = ""
var title = "散落的书页"
var requirement = ""
var text = ""
var echo_allowed = false
var records: Array = []
var pulse = 0.0
var book_names: Array = []
var outstanding = 0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactables")
		add_to_group("recovery_points")
		refresh()

func refresh() -> void:
	book_names.clear()
	outstanding = 0
	for death in records:
		for book in death.books: book_names.append(RoomCatalog.BOOK_NAMES.get(book, book))
		if not death.recovered: outstanding += 1
	visible = not book_names.is_empty() or outstanding > 0
	if not book_names.is_empty():
		title = "取回 " + "、".join(book_names)
		if State.data.echo_tool_level >= 2 and outstanding > 0: title += " · 缝合亡响"
	elif State.data.echo_tool_level >= 2:
		title = "缝合亡响 · %d 份" % outstanding
	else:
		title = "散落的自己 · 录响器尚不能缝合"
	queue_redraw()

func collect() -> Dictionary:
	var ids: Array = []
	for death in records: ids.append(death.id)
	var result = State.collect_deaths(ids)
	refresh()
	return result

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var paper = Color("e5d3a0")
	var jade = Color("96dbc4")
	draw_arc(Vector2(0,-4),25,0,PI,28,Color(jade,0.5),2,true)
	if not book_names.is_empty() or Engine.is_editor_hint():
		draw_rect(Rect2(-20,-32,40,29),Color("735442"))
		draw_rect(Rect2(-20,-32,40,29),paper,false,2)
		draw_rect(Rect2(-12,-38,23,13),paper)
		draw_line(Vector2(-20,-22),Vector2(20,-22),paper,2,true)
		draw_line(Vector2(-7,-30),Vector2(-7,-5),Color("c39965"),4,true)
		draw_circle(Vector2(7,-20),3,paper)
	if outstanding > 0:
		var y = -54 + sin(pulse*2)*3
		draw_colored_polygon(PackedVector2Array([Vector2(-6,y-9),Vector2(8,y-6),Vector2(5,y+10),Vector2(-8,y+7)]),Color(jade,0.8))
		draw_line(Vector2(0,y+10),Vector2(0,-34),Color(jade,0.35),1,true)
	var label = "书包" if not book_names.is_empty() else "亡响"
	if outstanding > 1: label += " ×%d" % outstanding
	draw_string(preload("res://resources/chinese_font.tres"),Vector2(-32,-77),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,paper)
