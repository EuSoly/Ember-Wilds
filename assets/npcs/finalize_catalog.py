"""Validate and save the completed NPC library, retaining the existing blend path."""
import bpy, bmesh, json
from pathlib import Path
from mathutils import Vector, Matrix

BASE=Path(r'C:\Users\Elize\Desktop\Roblox\starve')
scene=bpy.data.scenes['NPC_Catalog_23']
bpy.context.window.scene=scene
roots=[o for o in scene.objects if o.get('npc_id')]
assert len(roots)==23, f'Expected 23 NPCs, found {len(roots)}'
records=[]
for root in roots:
    meshes=[o for o in root.children if o.type=='MESH']
    points=[]; triangles=0
    for ob in meshes:
        # Place each part's origin at its center while preserving its position.
        if not ob.get('centered_origin'):
            center=sum((v.co for v in ob.data.vertices),Vector())/len(ob.data.vertices)
            ob.data.transform(Matrix.Translation(-center))
            ob.location+=center
            ob['centered_origin']=True
        bm=bmesh.new(); bm.from_mesh(ob.data)
        assert all(e.is_manifold for e in bm.edges), ob.name+' has open/non-manifold edges'
        assert all(f.calc_area()>1e-9 for f in bm.faces), ob.name+' has degenerate faces'
        bm.free()
        assert len(ob.data.materials)>0, ob.name+' lacks material'
        ob.data.calc_loop_triangles(); triangles+=len(ob.data.loop_triangles)
        points.extend([ob.location+v.co for v in ob.data.vertices])
    dims=[round(max(p[i] for p in points)-min(p[i] for p in points),4) for i in range(3)]
    root['triangle_count']=triangles
    records.append({'id':root['npc_id'],'collection':root.users_collection[0].name,
        'parts':len(meshes),'triangles':triangles,'dimensions_xyz':dims,
        'gallery_position':list(root.location),'reference':root['reference']})

notes='''EMBER WILDS — BIBLIOTECA DE NPCs

Cena principal: NPC_Catalog_23
23 modelos estáticos em coleções individuais, agrupadas por bioma.
O coelho aprovado também continua na cena Rabbit_Prototype_v1.
STUDIO contém apenas cenário, luzes, câmera e legendas.

Todos os NPCs usam Z para cima e -Y como frente.
Cada NPC tem um ROOT, com a origem no centro do personagem ao nível do chão.
A posição dos ROOTs organiza a galeria; não é parte da escala de gameplay.
As partes têm origens individuais e materiais de cores sólidas, sem texturas externas.

Ainda não inclui rig, animações, colisores, LODs ou integração com Roblox.
As escalas relativas são uma proposta visual; ajustar no gameplay.
Para exportar, selecionar somente a coleção do NPC e centralizar uma cópia do ROOT.

Referências de silhueta e paleta: https://starveiopro.fandom.com/wiki/Mobs
Golden Hen / Golden Chick: https://starveiopro.fandom.com/wiki/Non_used_ideas_in_starve.io
Firefly (removido), Scorpion (não lançado) e modos de jogador não integram os 23 NPCs.
'''
txt=bpy.data.texts.get('LEIA-ME | NPCs') or bpy.data.texts.new('LEIA-ME | NPCs')
txt.clear(); txt.write(notes)
manifest={'scene':scene.name,'count':len(records),'status':'static visual models',
 'axes':{'up':'Z','front':'-Y'},'npcs':records}
(BASE/'assets/npcs/catalog.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
for ob in bpy.context.selected_objects: ob.select_set(False)
bpy.context.view_layer.objects.active=None
scene.render.filepath=str(BASE/'build/previews/npcs-colecao-v1.png')
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'assets/npcs/rabbit/coelho-v1.blend'))
bpy.ops.render.render(write_still=True)
print(json.dumps({'saved':bpy.data.filepath,'count':len(records),'triangles':sum(r['triangles'] for r in records),'preview':scene.render.filepath}))
