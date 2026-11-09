"""Substitui apenas coleções revisadas, preservando as demais cenas da galeria.

blender -b --factory-startup --python assets/skins/update_caixas_review.py -- 4 favo lapide aquario recife jardim
Não executar gallery_caixas.py sobre uma galeria com edições do artista.
"""
import os,sys,json,hashlib
import bpy

HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(HERE,'caixas')
batch,*names=sys.argv[sys.argv.index('--')+1:]
assert names
path=os.path.join(OUT,'caixas-revisao.blend')
bpy.ops.wm.open_mainfile(filepath=path)
sc=next(s for s in bpy.data.scenes if s.name.startswith(f'{int(batch):02d} - '))

def fingerprint(coll):
    data=[]
    for o in sorted(coll.all_objects,key=lambda o:o.name):
        if o.type=='MESH':
            data.append((o.name,list(map(list,o.matrix_world)),[list(v.co) for v in o.data.vertices],
                         [list(p.vertices) for p in o.data.polygons],
                         [(m.name,list(m.diffuse_color)) for m in o.data.materials]))
    return hashlib.sha256(json.dumps(data).encode()).hexdigest()

old={n:next(c for c in sc.collection.children if c.name==n) for n in names}
unchanged={c.name:fingerprint(c) for scene in bpy.data.scenes for c in scene.collection.children if c not in old.values()}
with bpy.data.libraries.load(os.path.join(OUT,f'caixas{batch}.blend'),link=False) as (src,dst):
    assert all(n in src.collections for n in names)
    dst.collections=list(names)
assert len(dst.collections)==len(names) and all(dst.collections)
for name,new in zip(names,dst.collections):
    sc.collection.children.link(new)
    for o in list(old[name].all_objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.collections.remove(old[name])
    new.name=name
    new['revision']='Acabamento revisado em 2026-11-09'
for name,h in unchanged.items():
    assert fingerprint(bpy.data.collections[name])==h, f'Coleção fora do escopo alterada: {name}'
bpy.context.window.scene=sc
bpy.ops.wm.save_as_mainfile(filepath=path)
print('REVIEW_UPDATED',names,'UNTOUCHED',len(unchanged))
