"""One-time explicit scene migration. Polished .tscn files remain the content source."""
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
for path in (root/'scenes/rooms').glob('*.tscn'):
    text=path.read_text(encoding='utf-8')
    if '[node name="RecoveryAnchor"' not in text:
        text+='\n[node name="RecoveryAnchor" type="Marker2D" parent="."]\nposition = Vector2(%d, 623)\n' % (310 if path.stem=='bell' else 150)
    if path.stem=='library' and 'id="layers"' not in text:
        text=text.replace('load_steps=11','load_steps=15')
        insert='''[ext_resource type="Script" path="res://scripts/library_layers.gd" id="layers"]
[ext_resource type="Script" path="res://scripts/furniture_art.gd" id="furniture"]
[ext_resource type="Texture2D" path="res://assets/art/library_desk.png" id="desk"]
[ext_resource type="Texture2D" path="res://assets/art/library_bench.png" id="bench"]

'''
        text=text.replace('[sub_resource type="RectangleShape2D" id="s1"]',insert+'[sub_resource type="RectangleShape2D" id="s1"]')
        text=text.replace('assets/art/library.png','assets/art/library_wall.png')
        text=text.replace('position = Vector2(0, -245)','position = Vector2(0, 60)')
        text=re.sub(r'scale = Vector2\(1\.148[^\n]+','scale = Vector2(0.8839779, 0.77348066)',text)
        blocks=re.split(r'(?=\[node )',text)
        for i,block in enumerate(blocks):
            if re.match(r'\[node name="Object[1-7]" ',block) and 'kind = "cooper"' not in block:
                blocks[i]=block.rstrip()+'\ncustom_art = true\n\n'
        text=''.join(blocks)
        text+='''
[node name="GroundArt" type="Node2D" parent="."]
script = ExtResource("layers")
layer = "ground"
z_index = -3

[node name="RestoredShelves" type="Node2D" parent="."]
script = ExtResource("layers")
layer = "restoration"
z_index = -5

[node name="ForegroundPosts" type="Node2D" parent="."]
script = ExtResource("layers")
layer = "foreground"
z_index = 4
'''
        for node,kind in [('Object1','door'),('Object2','door'),('Object3','door'),('Object5','desk'),('Object6','desk'),('Object7','bench')]:
            text+=f'\n[node name="Furniture" type="Node2D" parent="{node}"]\nscript = ExtResource("furniture")\nkind = "{kind}"\nz_index = -1\n'
        for node,title in [('Object5','归还台'),('Object6','研习桌'),('Object7','休息长椅')]:
            text+=f'''\n[node name="Sign" type="Label" parent="{node}"]
offset_left = -65.0
offset_top = -105.0
offset_right = 65.0
offset_bottom = -80.0
theme_override_fonts/font = ExtResource("e5")
theme_override_font_sizes/font_size = 15
theme_override_colors/font_color = Color(0.82,0.78,0.65,1)
text = "{title}"
horizontal_alignment = 1
'''
    path.write_text(text,encoding='utf-8')
print('Updated recovery anchors and library layer scene.')
