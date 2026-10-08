"""Package this project's editable source and tested Windows build. No dependency downloads."""
from pathlib import Path
import hashlib, json, zipfile, os, shutil

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'builds'
WINDOWS=BUILD/'windows'
reports={}
for kind in ['integration','traversal','recovery','combat','loop','routes','visual']:
    report_path=ROOT/'tests/output'/f'exe-{kind}-report.json'
    report=json.loads(report_path.read_text(encoding='utf-8-sig'))
    if report_path.stat().st_mtime < (WINDOWS/'Margin.exe').stat().st_mtime:
        raise RuntimeError(f'Refusing stale {kind} report from an older executable.')
    if report.get('failed') or not report.get('checks') or not all(c['passed'] for c in report['checks']):
        raise RuntimeError(f'Refusing to package failed {kind} checks.')
    errors=(ROOT/'tests/output'/f'exe-{kind}-stderr.log').read_text(encoding='utf-8-sig')
    if errors.strip(): raise RuntimeError(f'Review {kind} stderr before packaging.')
    reports[kind]=report
performance_path=ROOT/'tests/output/standalone-performance.json'
if performance_path.stat().st_mtime < (WINDOWS/'Margin.exe').stat().st_mtime:
    raise RuntimeError('Refusing stale rendered performance report.')
if (ROOT/'tests/output/exe-render-stderr.log').read_text(encoding='utf-8-sig').strip():
    raise RuntimeError('Review renderer stderr before packaging.')
WINDOWS.mkdir(parents=True,exist_ok=True)
(WINDOWS/'licenses').mkdir(exist_ok=True)
for source in (ROOT/'docs/licenses').glob('*.txt'):
    shutil.copy2(source,WINDOWS/'licenses'/source.name)
shutil.copy2(ROOT/'docs/CREDITS.md',WINDOWS/'素材来源.md')
(WINDOWS/'开始游玩.txt').write_text('''余页 / Margin · 0.2 死亡修复与首个回环样板

双击 Margin.exe。无需安装 Godot、Node 或 Forge。

A、D 移动；Space 跳跃；Shift 闪避；J 攻击；空中 S+J 下劈。
E 交互；Q 观察；R 录制；F 调用残响；Tab 地图；Esc 暂停。
菜单用方向键和 Enter，也可用鼠标。设置内可改键。

存档目录：%APPDATA%\\MarginDemo
备份：journey.json.bak。重新开始会替换本工程的当前进度。

掉书会留下可见书包，按 E 免费取回。首次见库珀获得录响器；累计第六次死亡后再见库珀，开启亡响回收。不要为了升级刻意死亡。
旧版存档自动升级，并保留 journey.json.v1-backup。无需重开旅程。
图书馆改为侧视分层，首个回环加入旧馆支路、升降台观察和永久楼梯。
8–12 分钟首个回环与 45–75 分钟全流程目标尚未取得真人首次计时验收。
其余场景仍为统一占位美术；角色使用 cutout 姿态动画。
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
report_names=[f'exe-{kind}-report.json' for kind in reports]
for name in ['.gdignore',*report_names,'standalone-performance.json','standalone-library.png','standalone-library-before.png','library-basic.png','library-guardian-first.png','library-archive-first.png','standalone-bell.png','standalone-archive.png','recovery-parcel.png','recovery-map.png','measure-observation.png','library-jump.png','library-walk-left.png','library-walk-right.png']:
    path=ROOT/'tests/output'/name
    if path.exists(): source_files.append((path,path.relative_to(ROOT)))
archive(BUILD/'Margin-Source.zip',source_files,'Margin')

def digest(path):
    with path.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()

manifest={'version':'0.2-recovery-library-loop','engine':'4.7.2.stable.official.ed1daf0bf','forge_commit':'b0da85fac67dd067c16bfe791227c0e7edb56d7e','files':[],'tests':{}}
manifest['passed_checks']=sum(len(report['checks']) for report in reports.values())
for path in [WINDOWS/'Margin.exe',BUILD/'Margin-Windows.zip',BUILD/'Margin-Source.zip']:
    manifest['files'].append({'path':str(path.relative_to(ROOT)),'bytes':path.stat().st_size,'sha256':digest(path)})
for name in [*report_names,'standalone-performance.json']:
    path=ROOT/'tests/output'/name
    if path.exists(): manifest['tests'][name]=json.loads(path.read_text(encoding='utf-8-sig'))
(BUILD/'delivery-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'files':manifest['files'],'source_file_count':len(source_files)},ensure_ascii=False,indent=2))
