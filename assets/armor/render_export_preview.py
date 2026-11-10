import bpy,json
from pathlib import Path
from mathutils import Vector
BASE=Path(r'C:\Users\Elize\Desktop\Roblox\starve\assets\armor')
OUT=BASE/'roblox'
manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
code=(BASE/'validate_export.py').read_text(encoding='utf-8')
exec(code[code.index('# Visual QA'):])
