"""Generate editable text scenes and original placeholder audio. Run explicitly, never at runtime."""
from pathlib import Path
import json, math, struct, wave

ROOT=Path(__file__).resolve().parents[1]
def write(path,text):
    p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
def s(value): return json.dumps(value,ensure_ascii=False)
def vec(x,y): return f'Vector2({x}, {y})'

class Scene:
    def __init__(self): self.ext=[];self.sub=[];self.nodes=[]
    def resource(self,path,type='Script'):
        i=f'e{len(self.ext)+1}';self.ext.append(f'[ext_resource type="{type}" path="res://{path}" id="{i}"]');return f'ExtResource("{i}")'
    def shape(self,w,h):
        i=f's{len(self.sub)+1}';self.sub.append(f'[sub_resource type="RectangleShape2D" id="{i}"]\nsize = {vec(w,h)}');return f'SubResource("{i}")'
    def node(self,name,type='Node2D',parent=None,props=None,instance=None,groups=None):
        head=f'[node name="{name}"'
        if instance: head+=f' parent="{parent}" instance={instance}'
        else:
            head+=f' type="{type}"'
            if parent is not None: head+=f' parent="{parent}"'
        if groups: head+=' groups=['+','.join(s(g) for g in groups)+']'
        head+=']'
        self.nodes.append(head+'\n'+'\n'.join(f'{k} = {v}' for k,v in (props or {}).items()))
    def save(self,path): write(path,'[gd_scene load_steps=%d format=3]\n\n'%(len(self.ext)+len(self.sub)+1)+'\n\n'.join(self.ext+self.sub+self.nodes)+'\n')

def platform(scene,name,x,y,w,h=24,moving=False,metal=False):
    script=None
    if moving:
        script=scene.resource('scripts/moving_platform.gd')
    props={'position':vec(x,y),'collision_layer':'1','collision_mask':'0'}
    if script: props.update(script=script,travel=vec(0,-145),period='4.0')
    groups=(['moving_platforms'] if moving else [])+(['metal'] if metal else [])
    scene.node(name,'AnimatableBody2D' if moving else 'StaticBody2D','.',props,groups=groups)
    scene.node('CollisionShape2D','CollisionShape2D',name,{'shape':scene.shape(w,h),**({'one_way_collision':'true'} if h<=24 else {})})
    points=f'PackedVector2Array({-w/2}, {-h/2}, {w/2}, {-h/2}, {w/2}, {h/2}, {-w/2}, {h/2})'
    scene.node('Surface','Polygon2D',name,{'polygon':points,'color':'Color(0.34,0.46,0.43,1)' if not metal else 'Color(0.64,0.59,0.43,1)'})
    scene.node('Edge','Line2D',name,{'points':f'PackedVector2Array({-w/2}, {-h/2}, {w/2}, {-h/2})','width':'2.0','default_color':'Color(0.76,0.76,0.59,1)'})

def make_entities():
    sc=Scene();script=sc.resource('scripts/player.gd');art=sc.resource('scripts/actor_art.gd')
    sc.node('Player','CharacterBody2D',props={'script':script,'collision_layer':'2','collision_mask':'1','floor_snap_length':'8.0'})
    sc.node('CollisionShape2D','CollisionShape2D','.',{'position':vec(0,-31),'shape':sc.shape(24,56)})
    sc.node('Art','Node2D','.',{'script':art})
    sc.node('Camera2D','Camera2D','.',{'position':vec(190,-230),'position_smoothing_enabled':'true','position_smoothing_speed':'7.0','limit_left':'0','limit_top':'0','limit_right':'3200','limit_bottom':'720','limit_smoothed':'true'})
    sc.save('scenes/entities/player.tscn')
    sc=Scene();script=sc.resource('scripts/enemy.gd');art=sc.resource('scripts/actor_art.gd')
    sc.node('Enemy','CharacterBody2D',props={'script':script,'collision_layer':'4','collision_mask':'1'},groups=['enemies'])
    sc.node('CollisionShape2D','CollisionShape2D','.',{'position':vec(0,-23),'shape':sc.shape(44,42)})
    sc.node('Art','Node2D','.',{'script':art,'kind':s('charger')})
    sc.save('scenes/entities/enemy.tscn')
    sc=Scene();script=sc.resource('scripts/death_visual.gd');art=sc.resource('scripts/actor_art.gd')
    sc.node('Death','Node2D',props={'script':script,'modulate':'Color(0.66,0.78,0.8,0.27)'})
    sc.node('Art','Node2D','.',{'script':art,'echo':'true'})
    sc.save('scenes/entities/death.tscn')

ROOMS={
 'gate':('校门外',2400), 'courtyard':('前院',3600), 'hall':('教学走廊',3600),
 'equipment':('器材室',3000), 'library':('图书馆',1920), 'stacks':('旧书库',3600),
 'measure':('测量廊',3600), 'echo':('回声教室',3000), 'junction':('中央连廊',4000),
 'machine':('机电间',3400), 'security':('安保室',3400), 'maintenance':('维护通道',4800),
 'bell':('钟庭',2900), 'tower':('钟楼上层',3000), 'research':('研究层前室',3500), 'archive':('档案井',3800)
}

def make_room(rid,name,width):
    sc=Scene();art=sc.resource('scripts/room_art.gd');inter=sc.resource('scripts/interactable.gd');actor=sc.resource('scripts/actor_art.gd');enemy=sc.resource('scenes/entities/enemy.tscn','PackedScene')
    font=sc.resource('resources/chinese_font.tres','FontVariation')
    sc.node(name,props={'metadata/width':str(width),'metadata/room_id':s(rid)})
    sc.node('Backdrop','Node2D','.',{'script':art,'room_id':s(rid),'width':str(float(width)),'z_index':'-10'})
    # Segmented ground makes traversable, forgiving platforming gaps; gaps never hold a book spawn.
    gaps={'courtyard':[(1400,1530),(2370,2500)],'stacks':[(1750,1870)],'measure':[(1050,1180),(2230,2360)],'machine':[(2670,3090)],'maintenance':[(1250,1380),(2350,2480),(3500,3630)],'tower':[(1350,1480),(2250,2370)],'archive':[(1900,2020)]}.get(rid,[])
    left=0
    for n,(a,b) in enumerate(gaps+[(width,width)]):
        if a>left: platform(sc,'Floor'+str(n),(a+left)/2,680,a-left,120)
        left=b
    platform(sc,'LeftWall',-20,230,40,1100);platform(sc,'RightWall',width+20,230,40,1100)
    count=0
    def obj(kind,x,title='',text='',id='',target='',entry=(150,580),req='',y=620,node=None,echo=False):
        nonlocal count
        count+=1;key=node or 'Object'+str(count)
        sc.node(key,'Node2D','.',{'script':inter,'position':vec(x,y),'kind':s(kind),'stable_id':s(id or rid+'_'+key),'title':s(title),'text':s(text),'target':s(target),'entry':vec(*entry),'requirement':s(req),'echo_allowed':'true' if echo else 'false'})
        if kind=='exit':
            sc.node('Sign','Label',key,{'offset_left':'-85.0','offset_top':'-153.0','offset_right':'85.0','offset_bottom':'-118.0','theme_override_fonts/font':font,'theme_override_font_sizes/font_size':'17','theme_override_colors/font_color':'Color(0.82,0.82,0.69,1)','text':s(title),'horizontal_alignment':'1'})
        return key
    def door(x,title,target,entry=(150,580),req='',text='',y=620): return obj('exit',x,title,text,target=target,entry=entry,req=req,y=y)
    def note(x,title,text,y=620,id=''): return obj('note',x,title,text,y=y,id=id)
    def foe(x,kind='charger',y=620):
        nonlocal count
        count+=1;sc.node('Enemy'+str(count),parent='.',instance=enemy,props={'position':vec(x,y),'kind':s(kind),'stable_id':s(rid+'_animal_'+str(count))})
    def stairs(start,y=525,steps=3):
        for n in range(steps): platform(sc,'Step'+str(start)+'_'+str(n),start+n*160,y-n*85,120)
    if rid=='gate':
        obj('cooper',650,'抬起架子',id='rescue')
        sc.node('CooperArt','Node2D','Object1',{'script':actor,'kind':s('collie'),'peaceful':'true'})
        platform(sc,'FallenRack',695,595,120,12)
        note(1160,'迟到的值日生','你比平时晚到了几分钟。\n校门还开着，广播却已经停了。\n\n那只狗吃完面包后，终于往校门里走去。\n你跟了上去。')
        door(2190,'进入校园','courtyard',req='cooper_rescued',text='门口的狗还被压在架子下面。')
    elif rid=='courtyard':
        door(140,'校门','gate',(2080,580));door(3390,'教学楼','hall')
        note(690,'空白点名册','第一行仍然写着今天的日期。\n后面的名字，全都不见了。\n\n远处有金属碰撞的声音。')
        stairs(1020,530,3);platform(sc,'Landing',1800,345,250);foe(1950)
        note(2840,'清洁车上的便条','停电时，不要依赖自动门。\n保持旧维护通道可用。\n\n总有人需要从另一边回来。')
    elif rid=='hall':
        door(130,'前院','courtyard',(3250,580));door(1110,'器材室','equipment')
        door(2410,'图书馆','library',req='ruler',text='通往旧馆的门被变形的铁扣卡住。器材室里也许有工具。')
        platform(sc,'Lift',1800,545,150,moving=True)
        platform(sc,'UpperWalk',2040,330,330)
        door(2090,'测量廊','measure',(3210,245),y=318)
        note(3070,'旧门牌','图书馆：向内走。\n器材室：不要让折尺留在潮湿的地方。\n\n纸背面画着一段重复上升又下降的曲线。')
    elif rid=='equipment':
        door(120,'教学走廊','hall',(970,580));obj('ruler',1150,'拿起折尺')
        stairs(570,535,3);platform(sc,'MetalBench',1850,542,84,16,metal=True)
        note(2160,'器材保养记录','折尺展开后需要锁定。\n硬质金属表面会返还下压的力；木头则会吸收它。\n\n实验室里，刻度是一种语言。')
        foe(2530,'watcher')
    elif rid=='library':
        tex=sc.resource('assets/art/library.png','Texture2D')
        from PIL import Image
        w,h=Image.open(ROOT/'assets/art/library.png').size
        sc.node('Painting','Sprite2D','.',{'texture':tex,'centered':'false','position':vec(0,-245),'scale':vec(1920/w,1080/h),'z_index':'-8'})
        # Preserve the painted floor; collision and a subtle edge remain independently editable.
        for n in range(len(sc.nodes)):
            if 'parent="Floor0"' in sc.nodes[n]:
                sc.nodes[n] += '\nvisible = false'
        sc.node('RestoredLight','Polygon2D','.',{'polygon':'PackedVector2Array(430,40,570,40,830,620,210,620)','color':'Color(0.96,0.76,0.4,0.12)','z_index':'-4','visible':'false'})
        atmosphere=sc.resource('scripts/library_atmosphere.gd')
        sc.node('DustAndLight','Node2D','.',{'script':atmosphere,'z_index':'2'})
        door(130,'教学走廊','hall',(2300,580));door(1740,'旧书库','stacks')
        door(1530,'回声教室','echo')
        obj('cooper',570,'和库珀说话',id='library_cooper')
        sc.node('CooperArt','Node2D','Object4',{'script':actor,'kind':s('collie'),'peaceful':'true'})
        obj('return',1010,'归还书籍');obj('major',1290,'研习主修');obj('checkpoint',330,'休息与保存')
        sc.node('GuardianHome','Node2D','.',{'position':vec(750,620),'script':actor,'kind':s('guardian'),'peaceful':'true','visible':'false'})
    elif rid=='stacks':
        door(130,'图书馆','library',(1640,580));door(3340,'测量廊','measure')
        obj('book',920,'试读《测量与周期》','按知识观察键，读出升降装置的周期。\n\n你没有让升降台变高。你只是知道了它何时会到那里。',id='math',y=432)
        stairs(470,535,3);platform(sc,'BookshelfLedge',1010,444,360)
        obj('book',2310,'试读《双语设备手册》','Containment：隔离。\nAnchor：锚。\nExternal interference：外部干预。\n\n角色现在可以理解研究终端的基础信息。',id='language')
        foe(2660,'flier',360)
        door(2900,'档案井升降梯','archive',(3440,580),req='archive_lift',text='升降梯只能从下方解除机械锁。')
    elif rid=='measure':
        door(130,'旧书库','stacks',(3230,580));platform(sc,'PeriodLift',1460,553,180,moving=True)
        stairs(1930,530,3);platform(sc,'ReturnLedge',3160,276,420)
        platform(sc,'MidWalk',2500,315,320);platform(sc,'Approach',2840,280,180)
        door(3260,'教学走廊上层','hall',(2000,260),y=264)
        note(610,'没有锁的门','上面的路没有锁。\n\n先看它什么时候回来，再决定什么时候起跳。')
        foe(1710,'watcher')
    elif rid=='echo':
        door(130,'图书馆','library',(1420,580));door(2780,'中央连廊','junction')
        obj('anchor',1260,'了解因果锚点',id='echo_anchor')
        obj('rope',1550,'悬绳',y=365,node='Rope')
        obj('trolley',1770,'推动配重车',node='Trolley',echo=True)
        note(730,'锚点边的字','先在锚点边，留下向右挥尺的动作。\n结束录制后，走到推车旁。\n按住交互键，让悬绳进入那一尺的范围；同时调用残响。\n\n下面的维护路也通向另一边。你不必使用残响。')
        stairs(2060,530,3)
        door(2440,'侧面检修口','junction',(900,580),req='rope_cut',text='侧门被悬绳连接的配重锁住。',y=438)
        platform(sc,'SideLedge',2440,450,240)
    elif rid=='junction':
        door(140,'回声教室','echo',(2660,580));door(1050,'机电间','machine');door(1740,'安保室','security');door(2510,'维护通道','maintenance')
        obj('checkpoint',560,'在连廊休息');obj('anchor',720,'因果锚点',id='junction_anchor')
        note(3120,'建筑剖面','钟庭的下方留出了一整层空白。\n图书馆下方，也有一条没有画完的竖线。')
        # Optional early traversal: consecutive ruler rebounds climb otherwise unreachable counterweights.
        platform(sc,'WeightA',3300,515,84,16,metal=True)
        platform(sc,'WeightB',3470,355,84,16,metal=True)
        platform(sc,'WeightC',3650,195,84,16,metal=True)
        platform(sc,'HighLanding',3850,35,240)
        door(3850,'上层通风口','tower',y=23)
    elif rid=='machine':
        door(140,'中央连廊','junction',(930,580));door(3180,'钟庭机械桥','bell',req='physics_open',text='配重过重，桥板还没有抬起。')
        note(580,'力矩示意图','同样的力，作用点离支点越远，越容易抬起另一端的重物。\n\n这台机器的负载固定在右侧。支点仍可移动。')
        obj('lever',2190,'调整支点');stairs(1120,535,4);platform(sc,'MachineDeck',1840,290,260)
        foe(2550);obj('checkpoint',2480,'机械桥前休息')
        bridge_script=sc.resource('scripts/knowledge_bridge.gd')
        sc.node('FulcrumBridge','AnimatableBody2D','.',{'script':bridge_script,'position':vec(2880,632),'collision_layer':'1','collision_mask':'0'})
        sc.node('CollisionShape2D','CollisionShape2D','FulcrumBridge',{'shape':sc.shape(440,24)})
        sc.node('Plank','Polygon2D','FulcrumBridge',{'polygon':'PackedVector2Array(-220,-12,220,-12,220,12,-220,12)','color':'Color(0.58,0.57,0.40,1)'})
        sc.node('Pivot','Polygon2D','.',{'position':vec(2580,620),'polygon':'PackedVector2Array(-25,0,25,0,0,-48)','color':'Color(0.68,0.64,0.46,1)'})
    elif rid=='security':
        door(140,'中央连廊','junction',(1620,580));door(3180,'钟庭安保门','bell',req='politics_open',text='依据安保条款，通道保持关闭。')
        note(670,'安保条款','第 4 条：实验设施无四级许可不得通行。\n第 6 条：本地门禁遵守上级安全协议。')
        note(1660,'消防条款','第 17 条：疏散状态优先于实验室安保规定。\n第 18 条：维护人员可在确认通路后进入疏散维护状态。',y=432)
        stairs(1160,535,3);platform(sc,'FileLedge',1690,444,280)
        obj('policy',2490,'规程控制台');foe(2080,'watcher');obj('checkpoint',2890,'安保门前休息')
    elif rid=='maintenance':
        door(140,'中央连廊','junction',(2390,580));door(4590,'钟庭维护门','bell',req='service_open',text='三个手动断路器尚未全部复位。')
        obj('switch',780,'复位一号断路器','一号回路恢复。',id='service_a')
        stairs(1490,535,3);platform(sc,'ServiceLedge',2050,360,440)
        obj('switch',2050,'复位二号断路器','二号回路恢复。',id='service_b',y=348)
        obj('switch',3820,'复位三号断路器','三号回路恢复。',id='service_c')
        foe(1730);foe(2980,'flier',360);foe(4010,'watcher');obj('checkpoint',4280,'钟庭前休息')
        note(3250,'检修者的字','自动系统失效时，逐个恢复独立回路。\n\n这条路很旧，但它不需要任何人批准。')
    elif rid=='bell':
        door(130,'中央连廊','junction',(2420,580));obj('checkpoint',310,'钟庭前休息');obj('anchor',620,'因果锚点',id='bell_anchor')
        obj('bell',720,'敲响旧铃',echo=True);obj('bell',2080,'钟架',echo=True)
        foe(1810,'boss');door(2690,'向下的门','research',req='boss_purified',text='守兽仍然执行着不允许离开钟庭的命令。')
        platform(sc,'Refuge',1010,460,200);platform(sc,'FarRefuge',2420,460,170)
    elif rid=='tower':
        door(140,'中央连廊上方','junction',(3810,0));door(2760,'下行检修梯','research')
        platform(sc,'TowerLift',1710,520,140,moving=True)
        note(750,'旧钟铭牌','晨钟连接的不只是校园广播。\n铭牌的背面，有一枚与研究终端相同的编号。')
        foe(1980,'flier',340)
    elif rid=='research':
        door(130,'钟庭','bell',(2560,580));door(3240,'档案井','archive')
        obj('terminal',860,'读取 AX-17 终端','现实锚 AX-17\n\n钟庭共振环仍在运行。\n当前场域：隔离。\n外部干预可能改变因果执行结果。\n\n最后一条记录：请保留未归档的观测。')
        note(1900,'根系与管线','你抬头望去。\n管线穿过上方的楼板。那正是钟庭的位置。\n\n地面上的学校从没有和这里分开。')
        sc.node('Observer','Node2D','.',{'position':vec(1410,310),'script':actor,'kind':s('watcher')})
        foe(2420,'watcher');platform(sc,'LabLift',2770,535,160,moving=True)
    elif rid=='archive':
        door(130,'研究层','research',(3100,580));door(3510,'旧书库升降梯','stacks',(2820,580),req='archive_lift',text='先解除旁边的升降梯机械锁。')
        obj('book',2600,'取下共振档案','记录中的学校，并没有从世界上消失。\n它被保存在了另一种状态里。\n\n“请将原始档案归还地面图书馆。\n那里仍然是稳定的。”',id='archive',y=348)
        stairs(2110,535,3);platform(sc,'ArchiveLedge',2660,360,350)
        obj('switch',3240,'解除升降梯机械锁','升降梯连通了旧书库。你认出了头顶熟悉的书架。',id='archive_lift')
        obj('terminal',820,'旧馆登记终端','图书馆并非新建在研究所上方。\n研究所是沿着图书馆的锚点向下延伸的。\n\n阅读会改变记忆。归还是为了让记忆有一个位置。')
        foe(1450,'charger');foe(2950,'flier',390)
    sc.save('scenes/rooms/'+rid+'.tscn')

def theme():
    write('resources/ui_theme.tres','''[gd_resource type="Theme" load_steps=6 format=3]
[ext_resource type="FontVariation" path="res://resources/chinese_font.tres" id="font"]
[sub_resource type="StyleBoxFlat" id="normal"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(0.12,0.22,0.24,0.98)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.35,0.48,0.45,1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3
[sub_resource type="StyleBoxFlat" id="hover"]
content_margin_left = 20.0
content_margin_top = 10.0
content_margin_right = 20.0
content_margin_bottom = 10.0
bg_color = Color(0.28,0.40,0.36,1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.79,0.73,0.52,1)
[sub_resource type="StyleBoxFlat" id="panel"]
content_margin_left = 32.0
content_margin_top = 28.0
content_margin_right = 32.0
content_margin_bottom = 28.0
bg_color = Color(0.06,0.12,0.14,0.98)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.45,0.53,0.45,1)
[sub_resource type="StyleBoxFlat" id="bar"]
bg_color = Color(0.65,0.76,0.64,1)
[resource]
default_font = ExtResource("font")
default_font_size = 18
Button/styles/normal = SubResource("normal")
Button/styles/hover = SubResource("hover")
Button/styles/pressed = SubResource("hover")
Button/styles/focus = SubResource("hover")
Button/colors/font_color = Color(0.88,0.86,0.75,1)
Button/colors/font_hover_color = Color(1,0.95,0.80,1)
Label/colors/font_color = Color(0.87,0.86,0.75,1)
RichTextLabel/colors/default_color = Color(0.87,0.86,0.75,1)
PanelContainer/styles/panel = SubResource("panel")
ProgressBar/styles/fill = SubResource("bar")
''')

def ui_scene():
    sc=Scene();script=sc.resource('scripts/ui.gd');th=sc.resource('resources/ui_theme.tres','Theme');mapping=sc.resource('scripts/map_drawing.gd');painting=sc.resource('assets/art/library.png','Texture2D')
    sc.node('UI','CanvasLayer',props={'script':script,'layer':'10','process_mode':'3'})
    def control(name,parent='.',props=None,type='Control'):
        d={'layout_mode':'0','mouse_filter':'2','theme':th};d.update(props or {});sc.node(name,type,parent,d)
    def label(name,parent,text,x,y,w,h=32,size=18):
        control(name,parent,{'offset_left':str(float(x)),'offset_top':str(float(y)),'offset_right':str(float(x+w)),'offset_bottom':str(float(y+h)),'text':s(text),'theme_override_font_sizes/font_size':str(size)},'Label')
    def vlabel(name,parent,text,size=20):
        sc.node(name,'Label',parent,{'layout_mode':'2','text':s(text),'theme_override_font_sizes/font_size':str(size),'horizontal_alignment':'1'})
    def button(name,parent,text): sc.node(name,'Button',parent,{'layout_mode':'2','text':s(text),'custom_minimum_size':vec(0,43)})
    def overlay(name,w,h):
        control(name,props={'visible':'false','anchors_preset':'15','anchor_right':'1.0','anchor_bottom':'1.0','grow_horizontal':'2','grow_vertical':'2','mouse_filter':'0'})
        control('Shade',name,{'anchors_preset':'15','anchor_right':'1.0','anchor_bottom':'1.0','color':'Color(0.015,0.03,0.04,0.80)','mouse_filter':'0'},'ColorRect')
        control('Panel',name,{'offset_left':str((1280-w)/2),'offset_top':str((720-h)/2),'offset_right':str((1280+w)/2),'offset_bottom':str((720+h)/2),'mouse_filter':'0'},'PanelContainer')
        sc.node('Body','VBoxContainer',name+'/Panel',{'layout_mode':'2','theme_override_constants/separation':'13'})
        return name+'/Panel/Body'
    control('HUD',props={'anchors_preset':'15','anchor_right':'1.0','anchor_bottom':'1.0'})
    control('Readability','HUD',{'offset_right':'1280.0','offset_bottom':'86.0','color':'Color(0.035,0.065,0.075,0.64)'},'ColorRect')
    control('Top','HUD',{'offset_left':'24.0','offset_top':'18.0','offset_right':'455.0','offset_bottom':'94.0'})
    label('Health','HUD/Top','',0,0,320,26,18);label('Sanity','HUD/Top','',0,29,155,28,17);label('Branch','HUD/Top','',270,0,150,30,16)
    control('SanityBar','HUD/Top',{'offset_left':'163.0','offset_top':'42.0','offset_right':'322.0','offset_bottom':'47.0','show_percentage':'false'},'ProgressBar')
    label('Objective','HUD','',640,24,610,30,17);label('Footer','HUD','',28,676,720,25,14);label('Echo','HUD','',810,670,420,35,17)
    label('Observation','HUD','',160,105,1000,45,18)
    label('Toast','.','',120,590,1040,68,19);sc.nodes[-1]+='\nhorizontal_alignment = 1\nautowrap_mode = 2\nvisible = false'
    label('Prompt','.','',300,628,680,40,19);sc.nodes[-1]+='\nhorizontal_alignment = 1'
    label('RoomTitle','.','',830,87,400,100,25);sc.nodes[-1]+='\nhorizontal_alignment = 2'
    p=overlay('Home',500,530)
    vlabel('Eyebrow',p,'一 所 被 留 下 的 学 校',16);vlabel('Title',p,'余 页',72);vlabel('Subtitle',p,'M A R G I N',19)
    vlabel('Line',p,'过去的动作，写下现在的答案。',17)
    button('Continue',p,'继续旅程');button('New',p,'开始新的旅程');button('Settings',p,'设置与按键');button('Quit',p,'离开')
    p=overlay('Pause',480,400);vlabel('Title',p,'暂且合上这一页',29)
    button('Resume',p,'继续');button('Settings',p,'设置与按键');button('Home',p,'返回标题');button('Quit',p,'保存并离开')
    p=overlay('Dialogue',920,500);vlabel('Title',p,'',28)
    sc.node('Text','RichTextLabel',p,{'layout_mode':'2','custom_minimum_size':vec(0,292),'size_flags_vertical':'3','bbcode_enabled':'false','theme_override_font_sizes/normal_font_size':'22','theme_override_constants/line_separation':'8'})
    sc.node('Choices','HBoxContainer',p,{'layout_mode':'2','theme_override_constants/separation':'12','alignment':'1'})
    for n in ['First','Second','Third']:button(n,p+'/Choices','继续')
    p=overlay('Map',1040,610);vlabel('Title',p,'走过的地方',28)
    sc.node('MapDrawing','Control',p,{'layout_mode':'2','custom_minimum_size':vec(930,365),'script':mapping})
    vlabel('Notes',p,'',16);button('Close',p,'返回')
    p=overlay('Settings',680,650);vlabel('Title',p,'设置与按键',28)
    sc.node('Volume','HSlider',p,{'layout_mode':'2','min_value':'0.0','max_value':'1.0','step':'0.05','value':'0.55','tooltip_text':s('主音量')})
    sc.node('Fullscreen','CheckButton',p,{'layout_mode':'2','text':s('全屏显示')})
    sc.node('Scroll','ScrollContainer',p,{'layout_mode':'2','custom_minimum_size':vec(0,370),'size_flags_vertical':'3'})
    sc.node('Bindings','VBoxContainer',p+'/Scroll',{'layout_mode':'2','size_flags_horizontal':'3'})
    for name in ['left','right','down','jump','dodge','attack','interact','observe','record','replay','map','pause']:button(name,p+'/Scroll/Bindings',name)
    button('Close',p,'返回')
    label('Annotation','.','',650,215,520,160,31);sc.nodes[-1]+='\nmodulate = Color(1,0.48,0.40,0)\nhorizontal_alignment = 1'
    sc.save('scenes/ui/game_ui.tscn')

def audio():
    directory=ROOT/'assets/audio';directory.mkdir(parents=True,exist_ok=True)
    sr=22050
    specs={'jump':(420,.14),'strike':(150,.16),'hurt':(90,.25),'dash':(230,.16),'bell':(523,.9),'page':(660,.22),'warning':(180,.4)}
    for name,(freq,duration) in specs.items():
        samples=[]
        for i in range(int(sr*duration)):
            t=i/sr;env=(1-t/duration)**2
            signal=math.sin(2*math.pi*freq*t*(1.0+t*(2 if name=='jump' else -.25)))
            if name=='bell':signal=(signal+0.35*math.sin(2*math.pi*freq*2.76*t))/1.35
            samples.append(int(signal*env*9000))
        with wave.open(str(directory/(name+'.wav')),'wb') as f:f.setparams((1,2,sr,0,'NONE','not compressed'));f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
    for name,freqs in [('ambient',[65.406,98,130.81]),('warm',[130.81,164.814,196.0,261.626])]:
        duration=16;samples=[]
        for i in range(sr*duration):
            t=i/sr;env=min(1,t/0.8,(duration-t)/0.8)
            signal=sum(math.sin(2*math.pi*f*t)*(0.8+0.2*math.sin(t*.6+j)) for j,f in enumerate(freqs))/len(freqs)
            samples.append(int(signal*env*4500))
        with wave.open(str(directory/(name+'.wav')),'wb') as f:f.setparams((1,2,sr,0,'NONE','not compressed'));f.writeframes(struct.pack('<'+'h'*len(samples),*samples))

def main_scene():
    sc=Scene();script=sc.resource('scripts/world.gd');player=sc.resource('scenes/entities/player.tscn','PackedScene');ui=sc.resource('scenes/ui/game_ui.tscn','PackedScene');ambient=sc.resource('assets/audio/ambient.wav','AudioStream');warm=sc.resource('assets/audio/warm.wav','AudioStream')
    sc.node('Margin','Node2D',props={'script':script},groups=['world'])
    sc.node('Player',parent='.',instance=player,props={'position':vec(150,580)})
    sc.node('Music','AudioStreamPlayer','.',{'stream':ambient,'volume_db':'-18.0','autoplay':'true'})
    sc.node('MusicWarm','AudioStreamPlayer','.',{'stream':warm,'volume_db':'-45.0','autoplay':'true'})
    sc.node('UI',parent='.',instance=ui)
    sc.save('scenes/main.tscn')

if __name__=='__main__':
    raise SystemExit('Archived prototype generator: edit the Godot scenes directly. This tool no longer overwrites polished content.')
