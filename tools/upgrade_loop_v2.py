"""Explicit, idempotent first-loop scene edits; never called by the build pipeline."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]

def add_resources(text, lines, count):
    text=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+count}',text,count=1)
    index=text.index('[sub_resource')
    return text[:index]+lines+'\n'+text[index:]

path=root/'scenes/rooms/hall.tscn'
text=path.read_text(encoding='utf-8')
if '[node name="FoldingStairs"' not in text:
    text=add_resources(text,'[ext_resource type="Script" path="res://scripts/shortcut_stairs.gd" id="stairs"]\n',2)
    index=text.index('[node ')
    text=text[:index]+'[sub_resource type="RectangleShape2D" id="stair_shape"]\nsize = Vector2(110, 18)\n\n'+text[index:]
    text+='''
[node name="FoldingStairs" type="Node2D" parent="."]
script = ExtResource("stairs")

[node name="StairLatch" type="Node2D" parent="."]
script = ExtResource("e2")
position = Vector2(2170, 318)
kind = "shortcut"
stable_id = "hall_stairs_open"
title = "展开折叠楼梯"
'''
    for i,(x,y) in enumerate([(2110,414),(2210,502),(2310,590)]):
        text+=f'''
[node name="Step{i}" type="StaticBody2D" parent="FoldingStairs"]
position = Vector2({x}, {y})
collision_layer = 1
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="FoldingStairs/Step{i}"]
shape = SubResource("stair_shape")
one_way_collision = true
disabled = true

[node name="Surface" type="Polygon2D" parent="FoldingStairs/Step{i}"]
polygon = PackedVector2Array(-55,-9,55,-9,55,9,-55,9)
color = Color(0.45,0.43,0.33,1)
'''
    path.write_text(text,encoding='utf-8')

path=root/'scenes/rooms/stacks.tscn';text=path.read_text(encoding='utf-8')
if '[node name="OldRegister"' not in text:
    text=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+1}',text,count=1)
    index=text.index('[node ')
    text=text[:index]+'[sub_resource type="RectangleShape2D" id="register_ledge"]\nsize = Vector2(230, 20)\n\n'+text[index:]
    text+='''
[node name="RegisterLedge" type="StaticBody2D" parent="."]
position = Vector2(1280, 336)
collision_layer = 1
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="RegisterLedge"]
shape = SubResource("register_ledge")
one_way_collision = true

[node name="Surface" type="Polygon2D" parent="RegisterLedge"]
polygon = PackedVector2Array(-115,-10,115,-10,115,10,-115,10)
color = Color(0.42,0.40,0.30,1)

[node name="OldRegister" type="Node2D" parent="."]
script = ExtResource("e2")
position = Vector2(1290, 326)
kind = "note"
stable_id = "stacks_old_register"
title = "旧馆登记簿"
text = "末页只有一行字：留一盏灯给最后回来的人。\\n\\n登记簿边缘有一枚沾着墨的爪印。下面压着一张旧照片：书架还没有这么空，窗外也还没有下雨。"
'''
    path.write_text(text,encoding='utf-8')

path=root/'scenes/rooms/measure.tscn';text=path.read_text(encoding='utf-8')
if '[node name="LiftManual"' not in text:
    text+='''
[node name="LiftManual" type="Node2D" parent="."]
script = ExtResource("e2")
position = Vector2(1300, 620)
kind = "terminal"
stable_id = "measure_lift_manual"
title = "升降台维护牌"
text = "PERIOD：一个完整往返的时间。\\nTURNING POINT：改变方向的位置。\\n\\n平台越接近两端越慢。等它接近脚下，再起跳。\\n观察时，刻度会跟随真实装置一起移动。"

[node name="ObservationMark" type="Line2D" parent="."]
points = PackedVector2Array(1225,619,1360,619)
width = 4.0
default_color = Color(0.77,0.71,0.48,1)
'''
    path.write_text(text,encoding='utf-8')
print('First loop: folding stairs, optional register alcove, bilingual lift plaque.')
