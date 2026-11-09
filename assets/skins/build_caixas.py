"""Background-only crate gallery, catalog and source traceability.

blender -b --factory-startup --python assets/skins/build_caixas.py
Optional -- 1 3 selects batches to rebuild. Does not touch the live Blender.
"""
import os,sys,json,math
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path[:0]=[HERE,os.path.join(HERE,'lotes')]
import bpy
from caixa_lib import build_caixas,render_caixas
from caixas_catalogo import LOTE,CATALOG

OUT=os.path.join(HERE,'caixas')
os.makedirs(OUT,exist_ok=True)
groups=[(f'caixas{i//10+1}',LOTE[i:i+10]) for i in range(0,len(LOTE),10)]
selected=set(sys.argv[sys.argv.index('--')+1:]) if '--' in sys.argv else set()
for number,(name,lote) in enumerate(groups,1):
    if selected and str(number) not in selected:continue
    build_caixas(lote)
    for entry in lote:
        coll=bpy.data.collections[entry[0]]
        ox,oy,_=coll['pivot']
        curve=bpy.data.curves.new('Label','FONT');curve.body=entry[0].replace('_',' ')
        curve.align_x='CENTER';curve.size=.25
        o=bpy.data.objects.new('PREVIEW_Label_'+entry[0],curve);coll.objects.link(o)
        o.location=(ox,oy+2.35,.03)
        o.rotation_euler.z=math.pi
        from skin_lib import mat
        curve.materials.append(mat('#DDE6E8'))
    render_caixas(os.path.join(OUT,name))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,name+'.blend'))
    print('CRATE_BATCH',name,len(lote),flush=True)
json.dump(dict(count=len(LOTE),source_ids=115,source_npc_file='assets/npcs/rabbit/coelho-v1.blend',
               batches=[dict(name=n,skins=[s[0] for s in lote]) for n,lote in groups],skins=CATALOG),
          open(os.path.join(OUT,'catalog.json'),'w',encoding='utf8'),indent=2,ensure_ascii=False)
