import bpy,bmesh,math,os,json,ast
from mathutils import Vector,Matrix
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\pickaxes'
# Reuse geometry helpers without rerunning scene creation.
tree=ast.parse(open(os.path.join(BASE,'build_pickaxes.py'),encoding='utf8').read())
helpers=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['enum','material','mesh','solid','points']],type_ignores=[])
exec(compile(helpers,'pickaxe_helpers','exec'))
angle=math.radians(48.5);rotation=Matrix.Rotation(-angle,2)
scene=bpy.data.scenes['Pickaxes_Preview_06'];bpy.context.window.scene=scene
assert 'diamond_pickaxe_crystal_ridge' not in bpy.data.objects,'Revision already applied'
source=bpy.data.filepath
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'pickaxes-before-details.blend'),copy=True)

def palette(prefix,colors):return [material(prefix+'_'+str(i),h) for i,h in enumerate(colors)]
gold=palette('accent_gold',['C5A94E','F6DE8D','766028'])
diamond=palette('crystal',['5BDDE8','C3FFFC','288FAD'])
purple=palette('amethyst_crystal',['A342CA','EF9EFF','662381'])
red=palette('reidite_crystal',['C95243','FA9775','772B32'])
steel=palette('dark_steel',['464A51','7B7F86','252B32'])

def replace_head(item,coords):
    obj=bpy.data.objects[item+'_head'];col=bpy.data.collections[item];root=bpy.data.objects[item+'_root']
    temp=solid(item+'_head_new',points(coords),list(obj.data.materials),col,root,.19,.21,.028)
    old=obj.data;obj.data=temp.data;obj.data.name=item+'_head_mesh_v2'
    bpy.data.objects.remove(temp,do_unlink=True)
    if old.users==0:bpy.data.meshes.remove(old)

def detail(item,part,coords,mats,z=.20,depth=.21,bevel=.015):
    return solid(item+'_'+part,points(coords),mats,bpy.data.collections[item],bpy.data.objects[item+'_root'],z,depth,bevel)

def crystal(item,part,coords,peak,mats):
    poly=points(coords);p=points([peak])[0];n=len(poly)
    verts=[(x,y,.282) for x,y in poly]+[(p[0],p[1],.41)]
    faces=[tuple(reversed(range(n)))]+[(i,(i+1)%n,n) for i in range(n)]
    return mesh(item+'_'+part,verts,faces,mats,[2]+[1 if i%3==0 else 0 if i%3==1 else 2 for i in range(n)],bpy.data.collections[item],bpy.data.objects[item+'_root'])

# Diamond: geometric crystal head with broad facets and matching grip fittings.
item='diamond_pickaxe'
replace_head(item,[(302,366),(306,351),(320,338),(338,322),(355,316),(356,322),(342,336),(333,346),(327,360),(320,373)])
crystal(item,'crystal_ridge',[(307,363),(313,348),(338,326),(350,321),(329,347),(318,367)],(320,349),diamond)
detail(item,'collar',[(329,352),(340,361),(335,367),(324,358)],diamond,z=.17,depth=.20)
detail(item,'pommel',[(367,388),(372,384),(379,390),(380,395),(375,399),(370,397)],diamond,z=.16,depth=.18)

# Amethyst: gold setting, raised purple crystal, small rear crystal spur.
item='amethyst_pickaxe'
replace_head(item,[(301,366),(305,352),(318,337),(338,323),(354,316),(353,324),(339,339),(329,355),(320,373)])
detail(item,'rear_crystal',[(318,343),(308,337),(303,325),(300,341),(307,353)],purple,z=.18,depth=.17)
detail(item,'gold_setting',[(305,365),(310,350),(321,338),(340,326),(332,340),(325,355),(319,369)],gold,z=.29,depth=.055,bevel=.008)
crystal(item,'inset_crystal',[(310,362),(314,351),(324,339),(334,332),(328,345),(318,365)],(320,349),purple)
detail(item,'collar',[(329,352),(340,361),(335,368),(323,358)],gold,z=.17,depth=.23)
detail(item,'pommel',[(367,388),(372,384),(379,390),(380,395),(375,399),(370,397)],gold,z=.16,depth=.20)

# Reidite: larger angular head, rear hook and armoured handle.
item='reidite_pickaxe'
replace_head(item,[(297,367),(302,351),(316,336),(335,320),(356,310),(352,322),(338,340),(329,356),(324,374)])
detail(item,'rear_hook',[(318,342),(308,335),(303,321),(297,331),(298,344),(308,355)],steel,z=.16,depth=.23)
crystal(item,'head_ridge',[(303,364),(309,350),(331,329),(349,317),(331,343),(321,369)],(317,351),red)
obj=bpy.data.objects[item+'_handle'];obj.data.materials.clear()
for m in steel:obj.data.materials.append(m)
detail(item,'collar',[(326,349),(341,361),(336,368),(321,356)],steel,z=.17,depth=.26)
detail(item,'collar_gem',[(329,354),(336,360),(331,362)],red,z=.32,depth=.06,bevel=.007)
for i,(x,y) in enumerate([(345,369),(355,378)]):
    detail(item,'grip_band_'+str(i+1),[(x-5,y+1),(x-1,y-4),(x+6,y+2),(x+2,y+7)],red,z=.155,depth=.19,bevel=.012)
detail(item,'pommel',[(367,388),(372,383),(381,389),(384,397),(377,402),(369,398)],red,z=.16,depth=.23)

report=[]
for c in bpy.data.collections['Pickaxes'].children:
    tris=bad=0;parts=[]
    for o in c.objects:
        if o.type!='MESH':continue
        o['item_id']=c.name;o['part']=o.name.removeprefix(c.name+'_');o.data.calc_loop_triangles()
        tris+=len(o.data.loop_triangles);parts.append(o.name)
        bm=bmesh.new();bm.from_mesh(o.data);bad+=sum(not e.is_manifold for e in bm.edges);bm.free()
        assert not o.data.validate(verbose=False)
    assert bad==0
    report.append({'item_id':c.name,'triangles':tris,'non_manifold_edges':bad,'parts':parts})
for o in scene.objects:
    if o.type=='FONT' and o.data.body.startswith('PREVIA 01'):o.data.body='PREVIA 02  /  TIERS COM IDENTIDADE PROPRIA'
scene.render.filepath=os.path.join(BASE,'picaretas-preview-v2.png')
with open(os.path.join(BASE,'validation-v2.json'),'w',encoding='utf8') as f:json.dump(report,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=source)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'pickaxes-session-v2.blend'),copy=True)
print(json.dumps(report))
