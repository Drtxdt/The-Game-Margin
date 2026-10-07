"""Package this project's editable source and tested Windows build. No dependency downloads."""
from pathlib import Path
import hashlib, json, zipfile, os, shutil

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'builds'
WINDOWS=BUILD/'windows'
reports={}
for kind in ['integration','traversal','routes']:
    report_path=ROOT/'tests/output'/f'exe-{kind}-report.json'
    report=json.loads(report_path.read_text(encoding='utf-8-sig'))
    if report.get('failed') or not report.get('checks') or not all(c['passed'] for c in report['checks']):
        raise RuntimeError(f'Refusing to package failed {kind} checks.')
    errors=(ROOT/'tests/output'/f'exe-{kind}-stderr.log').read_text(encoding='utf-8-sig')
    if errors.strip(): raise RuntimeError(f'Review {kind} stderr before packaging.')
    reports[kind]=report
WINDOWS.mkdir(parents=True,exist_ok=True)
(WINDOWS/'licenses').mkdir(exist_ok=True)
for source in (ROOT/'docs/licenses').glob('*.txt'):
    shutil.copy2(source,WINDOWS/'licenses'/source.name)
shutil.copy2(ROOT/'docs/CREDITS.md',WINDOWS/'素材来源.md')
(WINDOWS/'开始游玩.txt').write_text('''余页 / Margin · 0.1 首轮全流程试玩版

双击 Margin.exe。无需安装 Godot、Node 或 Forge。

A、D 移动；Space 跳跃；Shift 闪避；J 攻击；空中 S+J 下劈。
E 交互；Q 观察；R 录制；F 调用残响；Tab 地图；Esc 暂停。
菜单用方向键和 Enter，也可用鼠标。设置内可改键。

存档目录：%APPDATA%\\MarginDemo
备份：journey.json.bak。重新开始会替换本工程的当前进度。

这是完整流程的首轮试玩构建。45–75 分钟首次探索目标尚未取得玩家计时验收。
图书馆使用手绘样板素材，其余场景为统一占位美术；角色动画和道具仍待修整。
请记录总时间、卡住的房间、残响理解过程和守兽尝试次数。

随附素材来源及第三方许可见同目录。
''',encoding='utf-8-sig')

def archive(output,files,prefix):
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for path,relative in files:
            z.write(path,str(Path(prefix)/relative))

archive(BUILD/'Margin-Windows.zip',[(p,p.relative_to(WINDOWS)) for p in WINDOWS.rglob('*') if p.is_file()],'Margin')
source_files=[]
for folder, dirs, names in os.walk(ROOT):
    directory=Path(folder)
    dirs[:]=[d for d in dirs if d not in {'.godot','.git','node_modules','godot-forge','builds','__pycache__'} and not (directory.name=='tests' and d=='output')]
    for name in names:
        path=directory/name
        if path.suffix in {'.log','.tmp','.pyc'}: continue
        source_files.append((path,path.relative_to(ROOT)))
for name in ['.gdignore','exe-integration-report.json','exe-traversal-report.json','exe-routes-report.json','standalone-performance.json','standalone-library.png','standalone-library-before.png','standalone-bell.png','standalone-archive.png','forge-keyboard-scenario.json','final-new-runtime-errors.json']:
    path=ROOT/'tests/output'/name
    if path.exists(): source_files.append((path,path.relative_to(ROOT)))
archive(BUILD/'Margin-Source.zip',source_files,'Margin')

def digest(path):
    with path.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()

manifest={'version':'0.1-first-playtest','engine':'4.7.2.stable.official.ed1daf0bf','forge_commit':'b0da85fac67dd067c16bfe791227c0e7edb56d7e','files':[],'tests':{}}
for path in [WINDOWS/'Margin.exe',BUILD/'Margin-Windows.zip',BUILD/'Margin-Source.zip']:
    manifest['files'].append({'path':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':digest(path)})
for name in ['exe-integration-report.json','exe-traversal-report.json','exe-routes-report.json','standalone-performance.json']:
    path=ROOT/'tests/output'/name
    if path.exists(): manifest['tests'][name]=json.loads(path.read_text(encoding='utf-8-sig'))
(BUILD/'delivery-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'files':manifest['files'],'source_file_count':len(source_files)},ensure_ascii=False,indent=2))
