"""Use the existing FBX/palette pipeline and its round-trip validator."""
import bpy,re
from pathlib import Path
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[2]
bpy.ops.wm.open_mainfile(filepath=str(BASE/'areia-e-terra.blend'))
bpy.context.preferences.filepaths.save_version=0
code=(REPO/'assets/resources/food/export_roblox.py').read_text(encoding='utf8')
code=re.sub(r'^BASE = .*$',lambda m:'BASE = '+repr(str(BASE)),code,flags=re.M)
code=code.replace('NAME = "food"','NAME = "areia-e-terra"').replace('EXPECTED = 16','EXPECTED = 2')
code=code.replace('bpy.data.collections["Food"]','bpy.data.collections["Soil_Icons"]')
code=code.replace('food_palette','soil_palette').replace('food.blend (cópia em export-work/live-snapshot.blend)','areia-e-terra.blend')
exec(compile(code,'soil_palette_export','exec'),{'__file__':__file__})
code=(REPO/'assets/resources/food/validate_roblox_export.py').read_text(encoding='utf8')
code=re.sub(r'^BASE = .*$',lambda m:'BASE = '+repr(str(BASE/'roblox')),code,flags=re.M)
exec(compile(code,'soil_roundtrip_validation','exec'),{'__file__':__file__})
print('SOIL_EXPORT_VALIDATED')
