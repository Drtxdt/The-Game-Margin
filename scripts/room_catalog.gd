class_name RoomCatalog
extends RefCounted

static var _exit_cache: Array = []
static var _width_cache: Dictionary = {}

static func exits() -> Array:
	if not _exit_cache.is_empty(): return _exit_cache
	# Read authored scene properties, without instantiating gameplay or duplicating topology.
	for room_id in ROOMS:
		var scene: PackedScene=load("res://scenes/rooms/%s.tscn" % room_id)
		var scene_state=scene.get_state()
		for node in range(scene_state.get_node_count()):
			var props: Dictionary={}
			for index in range(scene_state.get_node_property_count(node)):
				props[str(scene_state.get_node_property_name(node,index))]=scene_state.get_node_property_value(node,index)
			if node==0: _width_cache[room_id]=float(props.get("metadata/width",3200))
			if props.get("kind","")=="exit":
				_exit_cache.append({"room":room_id,"target":props.target,"id":props.stable_id,"requirement":props.get("requirement","")})
	return _exit_cache

static func width_for(room_id: String) -> float:
	exits()
	return float(_width_cache.get(room_id,3200))

const ROOMS = {
	"gate": ["校门外", "钟响之后", Vector2(0, 0), "学校广播已经停了。门口还有一只不肯离开的狗。"],
	"courtyard": ["前院", "空无一人的早晨", Vector2(1, 0), "风把值日表翻到了昨天。"],
	"hall": ["教学走廊", "一道尚未理解的路", Vector2(2, 0), "每隔一段时间，旧升降台会停在同一个高度。"],
	"equipment": ["器材室", "刻度之间", Vector2(3, 0), "折尺还留着前一个人的温度。"],
	"library": ["图书馆", "可以回来的地方", Vector2(2, 1), "这里很安静。安静和空无一人并不是一回事。"],
	"stacks": ["旧书库", "试读", Vector2(1, 1), "书还没有归还，但其中的知识已经能够使用。"],
	"measure": ["测量廊", "重访", Vector2(1, 2), "规律一直在这里。改变的是你看它的方式。"],
	"echo": ["回声教室", "给未来留下过去", Vector2(2, 2), "锚点记住动作，不替你记住答案。"],
	"junction": ["中央连廊", "三条通往钟声的路", Vector2(3, 2), "上方有风，下方传来水流声。"],
	"machine": ["机电间", "力与支点", Vector2(4, 1), "力量不一定要变大，支点可以改变。"],
	"security": ["安保室", "规则与规则之间", Vector2(4, 2), "所有条文都正确时，也可能产生矛盾。"],
	"maintenance": ["维护通道", "绕行", Vector2(4, 3), "总有人需要在停电的时候走过这里。"],
	"bell": ["钟庭", "仍在履行的命令", Vector2(5, 2), "它拦住你的去路，却没有离开过自己的岗位。"],
	"tower": ["钟楼上层", "风中的空页", Vector2(5, 0), "熟悉的校园，从这里看起来有些不同。"],
	"research": ["研究层前室", "校园的另一面", Vector2(5, 3), "上方的钟架，一直连接着这里的共振环。"],
	"archive": ["档案井", "带回去的一页", Vector2(3, 3), "有些东西需要一个安全的地方才能被记住。"]
}
const BOOK_NAMES = {"math": "《测量与周期》", "language": "《双语设备手册》", "archive": "《场域共振档案》"}
const LINKS = [["gate","courtyard"],["courtyard","hall"],["hall","equipment"],["hall","library"],["library","stacks"],["stacks","measure"],["measure","hall"],["library","echo"],["echo","junction"],["junction","machine"],["junction","security"],["junction","maintenance"],["machine","bell"],["security","bell"],["maintenance","bell"],["junction","tower"],["tower","research"],["bell","research"],["research","archive"],["archive","stacks"]]
