"""Append only the requested Margin MCP entry, with an adjacent backup."""
from pathlib import Path
import tomllib
config=Path(r'C:\Users\dell\.codex\config.toml')
text=config.read_text(encoding='utf-8')
parsed=tomllib.loads(text)
if 'godot_margin' in parsed.get('mcp_servers',{}):
    print('godot_margin already present; existing entry preserved.')
else:
    addition='''

[mcp_servers.godot_margin]
command = "D:/nodejs/node.exe"
args = ["E:/my_game/Margin/tools/godot-forge/dist/index.js", "--project", "E:/my_game/Margin", "--godot", "D:/Godot_v4.7.2/Godot_v4.7.2-stable_win64.exe", "--launch", "gui"]
startup_timeout_sec = 120
tool_timeout_sec = 180
'''
    tomllib.loads(text+addition)
    backup=config.with_name('config.toml.before-margin')
    if not backup.exists(): backup.write_bytes(config.read_bytes())
    config.write_text(text+addition,encoding='utf-8')
    print('Added godot_margin; preserved existing configuration and adjacent backup.')
