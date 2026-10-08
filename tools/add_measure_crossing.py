from pathlib import Path
import re
path=Path(__file__).resolve().parents[1]/'scenes/rooms/measure.tscn'
text=path.read_text(encoding='utf-8')
if '[node name="CounterweightHousing"' not in text:
    text=re.sub(r'load_steps=(\d+)',lambda m:f'load_steps={int(m[1])+2}',text,count=1)
    index=text.index('[node ')
    text=text[:index]+'''[sub_resource type="RectangleShape2D" id="housing_shape"]
size = Vector2(120, 216)

[sub_resource type="RectangleShape2D" id="transfer_shape"]
size = Vector2(100, 20)

'''+text[index:]
    text=text.replace('position = Vector2(1710, 620)','position = Vector2(1880, 620)')
    text+='''
[node name="CounterweightHousing" type="StaticBody2D" parent="."]
position = Vector2(1760, 512)
collision_layer = 1
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="CounterweightHousing"]
shape = SubResource("housing_shape")

[node name="Surface" type="Polygon2D" parent="CounterweightHousing"]
polygon = PackedVector2Array(-60,-108,60,-108,60,108,-60,108)
color = Color(0.29,0.39,0.36,1)

[node name="Edge" type="Line2D" parent="CounterweightHousing"]
points = PackedVector2Array(-60,-108,60,-108)
width = 3.0
default_color = Color(0.76,0.72,0.55,1)

[node name="TransferLip" type="StaticBody2D" parent="."]
position = Vector2(1615, 433)
collision_layer = 1
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="TransferLip"]
shape = SubResource("transfer_shape")
one_way_collision = true

[node name="Surface" type="Polygon2D" parent="TransferLip"]
polygon = PackedVector2Array(-50,-10,50,-10,50,10,-50,10)
color = Color(0.44,0.47,0.36,1)
'''
    path.write_text(text,encoding='utf-8')
