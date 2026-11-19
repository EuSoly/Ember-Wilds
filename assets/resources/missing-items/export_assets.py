"""Export/round-trip validate both asset packs using the existing palette pipeline.

Run in background Blender after build_assets.py. Exporting changes only the
background document; the two editable source files are never overwritten.
"""
import bpy, json, re, sys
from pathlib import Path

BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
template=(REPO/'assets/resources/food/export_roblox.py').read_text(encoding='utf8')
validator=(REPO/'assets/resources/food/validate_roblox_export.py').read_text(encoding='utf8')

def export_pack(name,group,count,subfolder):
    bpy.ops.wm.open_mainfile(filepath=str(BASE/(name+'.blend')))
    if subfolder=='bush':
        assert {c.name for c in bpy.data.collections[group].children} == {'Foliage',*(f'Berry_{i:02d}' for i in range(1,6))}
        assert all(len([o for o in c.objects if o.type=='MESH'])==1 for c in bpy.data.collections[group].children)
    # Keep canonical export IDs free: Blender otherwise adds .001 to new meshes.
    for c in bpy.data.collections[group].children:
        for obj in c.objects:
            if obj.type=='MESH' and obj.name==c.name:
                obj.name='source_'+obj.name
    output=BASE/'roblox'/subfolder
    code=template
    code=re.sub(r'^BASE = .*$', lambda m:'BASE = '+repr(str(BASE)),code,flags=re.M)
    code=code.replace('OUT = os.path.join(BASE, "roblox")','OUT = '+repr(str(output)))
    code=code.replace('NAME = "food"','NAME = '+repr(name))
    code=code.replace('EXPECTED = 16','EXPECTED = '+str(count))
    code=code.replace('bpy.data.collections["Food"]','bpy.data.collections['+repr(group)+']')
    code=code.replace('food_palette',name.replace('-','_')+'_palette')
    code=code.replace('food.blend (cópia em export-work/live-snapshot.blend)',name+'.blend')
    exec(compile(code,'existing_palette_export','exec'),{'__file__':__file__})
    check=re.sub(r'^BASE = .*$',lambda m:'BASE = '+repr(str(output)),validator,flags=re.M)
    exec(compile(check,'existing_fbx_roundtrip_validation','exec'),{'__file__':__file__})
    if subfolder=='bush':
        mf=output/'manifest.json'
        data=json.loads(mf.read_text(encoding='utf8'))
        data['model_id']='berry_bush_1'
        data['fruit_count']=5
        data['orientation']='Blender Z-up; Roblox Y-up, volumetric world resource'
        data['individual_origin']='shared bush base origin; retain all relative part positions'
        data['roblox_names']={f'Berry_{i:02d}':'Berry' for i in range(1,6)}
        mf.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')

if __name__=='__main__':
    if '--bucket-only' not in sys.argv:
        export_pack('missing-items','Missing_Items',15,'items')
        export_pack('berry-bush','BushParts',6,'bush')
    export_pack('empty-bucket','Empty_Bucket',1,'empty-bucket')
    print('REQUESTED_EXPORTS_VALIDATED')
