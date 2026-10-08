"""Capture editable project sources for a named delivery milestone."""
from pathlib import Path
import os, sys, zipfile

root = Path(__file__).resolve().parents[1]
name = sys.argv[1]
if name not in ('milestone-a', 'milestone-b', 'milestone-c'):
    raise SystemExit('Expected milestone-a, milestone-b or milestone-c')
destination = root / 'builds' / name
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(destination / 'Margin-Source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for folder, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in {'.git', '.godot', 'node_modules', 'godot-forge', 'builds', '__pycache__', 'output'}]
        for filename in files:
            path = Path(folder) / filename
            if path.suffix not in {'.log', '.tmp', '.pyc'}:
                archive.write(path, Path('Margin') / path.relative_to(root))
print(destination / 'Margin-Source.zip')
