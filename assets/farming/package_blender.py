"""Assemble a review .blend with named scenes; keep source catalogs untouched."""
import bpy
from pathlib import Path
BASE=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(BASE/'farming-preview.blend'))
bpy.context.preferences.filepaths.save_version=0
overview=bpy.context.scene;overview.name='01 - Fazenda pronta'
for file,name in [('farming-plants.blend','02 - Crescimento - 36 modelos'),('farming-icons.blend','03 - Sementes - agua - gelo'),('planter-box.blend','04 - Caixa de plantacao')]:
    with bpy.data.libraries.load(str(BASE/file),link=False) as (src,dst):dst.scenes=src.scenes
    assert len(dst.scenes)==1
    dst.scenes[0].name=name
bpy.context.window.scene=overview
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'fazenda-completa.blend'))
print('REVIEW_BLEND_READY: four named scenes')
