import bpy, bmesh, math, json, os, re, hashlib
from mathutils import Vector, Matrix

BASE = r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\pickaxes'
NAME = 'Pickaxes_Preview_06'
assert NAME not in bpy.data.scenes, 'Preview already exists; do not overwrite edits'
os.makedirs(BASE, exist_ok=True)

def fingerprint(objects):
    h = hashlib.sha256()
    for o in sorted(objects, key=lambda o:o.name):
        h.update(repr((o.name, list(map(tuple,o.matrix_world)), [c.name for c in o.users_collection])).encode())
        if o.type == 'MESH':
            h.update(repr(([tuple(v.co) for v in o.data.vertices], [tuple(p.vertices) for p in o.data.polygons], [m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()

originals=list(bpy.data.objects)
before=fingerprint(originals)
source_path=bpy.data.filepath
scene=bpy.data.scenes.new(NAME)
bpy.context.window.scene=scene
models=bpy.data.collections.new('Pickaxes');scene.collection.children.link(models)
stage=bpy.data.collections.new('Pickaxes_Presentation');scene.collection.children.link(stage)
stage.hide_select=True

def enum(obj,prop,value):
    setattr(obj,prop,next(e.identifier for e in obj.bl_rna.properties[prop].enum_items if e.identifier==value))

def material(name,h):
    def lin(c): return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    m=bpy.data.materials.new('Pickaxe_'+name);m.use_nodes=True
    rgba=tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m.diffuse_color=rgba
    node=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value=rgba;node.inputs['Roughness'].default_value=.82
    return m

def mesh(name,verts,faces,mats,ids,col,parent=None):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
    o=bpy.data.objects.new(name,d);col.objects.link(o);o.parent=parent
    for m in mats:d.materials.append(m)
    for i,p in enumerate(d.polygons):p.material_index=ids[i%len(ids)]
    bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
    return o

def solid(name,poly,mats,col,root,z,depth,bevel):
    n=len(poly);area=sum(poly[i][0]*poly[(i+1)%n][1]-poly[(i+1)%n][0]*poly[i][1] for i in range(n))
    sign=1 if area>0 else -1;inner=[]
    for i,p in enumerate(poly):
        p=Vector(p);d1=(p-Vector(poly[i-1])).normalized();d2=(Vector(poly[(i+1)%n])-p).normalized()
        n1=Vector((-d1.y,d1.x))*sign;n2=Vector((-d2.y,d2.x))*sign
        shift=(n1+n2).normalized();inner.append(tuple(p+shift*(bevel/max(.35,shift.dot(n1)))))
    verts=[(x,y,z-depth/2) for x,y in poly]+[(x,y,z+depth/2-bevel) for x,y in poly]+[(x,y,z+depth/2) for x,y in inner]
    faces=[tuple(reversed(range(n)))];ids=[2]
    for i in range(n):
        j=(i+1)%n;faces.append((i,j,j+n,i+n));ids.append(2)
    for i in range(n):
        j=(i+1)%n;faces.append((n+i,n+j,2*n+j,2*n+i));ids.append(1)
    faces.append(tuple(range(2*n,3*n)));ids.append(0)
    return mesh(name,verts,faces,mats,ids,col,root)

# Outline sampled visually from the wiki's six-pickaxe reference; coordinates
# are converted into a grip-centred upright local basis for later programming.
angle=math.radians(48.5)
rotation=Matrix.Rotation(-angle,2)
def points(coords):
    return [tuple(rotation @ Vector(((x-350)*.027,(371-y)*.027))) for x,y in coords]

head=points([(303,366),(308,354),(320,340),(337,325),(349,318),(355,318),(355,321),(344,331),(333,345),(326,357),(320,371)])
handle=points([(310,341),(313,338),(317,339),(377,390),(378,394),(375,397),(371,396),(311,346)])
red_head=points([(302,367),(307,353),(320,339),(335,325),(348,317),(355,316),(355,320),(343,332),(332,346),(325,359),(320,372)])

variants=[
 ('wood','MADEIRA','8C5A30','AB7544','52351E','73502E','93683F','47301C'),
 ('stone','PEDRA','A9AFB0','D1D6D4','596264','704B31','926A49','44301F'),
 ('gold','OURO','D4C23C','F3E779','7D7024','615432','817349','3F3925'),
 ('diamond','DIAMANTE','42D7DB','8CF6F1','1D7478','3D3020','625038','241D16'),
 ('amethyst','AMETISTA','AB43CE','DD7BEF','59216F','39281D','5E4530','211A14'),
 ('reidite','REIDITE','B94D41','E87560','672D2A','7B7778','A49D9C','49464B'),
]
report=[]
for i,(tier,label,*colors) in enumerate(variants):
    item=tier+'_pickaxe'
    assert item not in bpy.data.collections
    c=bpy.data.collections.new(item);models.children.link(c)
    root=bpy.data.objects.new(item+'_root',None);c.objects.link(root)
    root.location=(-3.0+(i%3)*3.0,1.6-(i//3)*3.3,0)
    root.rotation_euler.z=angle;root.empty_display_size=.12
    root['item_id']=item;root['tier']=i+1;root['category']='pickaxe'
    mats=[material(item+'_'+part,hexcolor) for part,hexcolor in zip(['head','head_light','head_edge','handle','handle_light','handle_edge'],colors)]
    solid(item+'_handle',handle,mats[3:],c,root,.15,.14,.018)
    solid(item+'_head',red_head if tier=='reidite' else head,mats[:3],c,root,.19,.19,.026)
    entry={'item_id':item,'label':label,'parts':[],'triangles':0,'non_manifold_edges':0}
    for o in c.objects:
        if o.type!='MESH':continue
        o['item_id']=item;o['part']=o.name.removeprefix(item+'_')
        o.data.calc_loop_triangles();entry['triangles']+=len(o.data.loop_triangles)
        bm=bmesh.new();bm.from_mesh(o.data);entry['non_manifold_edges']+=sum(not e.is_manifold for e in bm.edges);bm.free()
        assert not o.data.validate(verbose=False),'Invalid mesh corrected unexpectedly'
        entry['parts'].append(o.name)
    assert entry['non_manifold_edges']==0
    report.append(entry)

floor=material('backdrop','233941');white=material('labels','EDF0E8');muted=material('secondary','A7C2C5')
mesh('Pickaxes_Backdrop',[(-100,-100,-.025),(100,-100,-.025),(100,100,-.025),(-100,100,-.025)],[(0,1,2,3)],[floor],[0],stage)
def text(body,x,y,size,mat):
    d=bpy.data.curves.new('Pickaxes_Label_'+body,'FONT');d.body=body;d.size=size
    o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=(x,y,0);d.materials.append(mat)
text('PICARETAS',-4.27,3.48,.36,white)
text('06 MODELOS  /  CABO E CABECA SEPARADOS',-4.25,3.11,.115,muted)
for i,(tier,label,*_) in enumerate(variants):
    x=-3+(i%3)*3;y=1.6-(i//3)*3.3
    text(label,x-1.03,y-1.10,.19,white)
    text(tier+'_pickaxe',x-1.03,y-1.34,.10,muted)
text('PREVIA 01  /  LOW-POLY',-4.25,-3.59,.10,muted)

camd=bpy.data.cameras.new('Pickaxes_Camera');cam=bpy.data.objects.new(camd.name,camd);stage.objects.link(cam)
cam.location=(-.1,-2.2,19);target=Vector((-.1,.05,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
enum(camd,'type','ORTHO');camd.ortho_scale=10.2;scene.camera=cam
for name,loc,power,size in [('Key',(-4,4,9),1000,7),('Fill',(5,0,7),400,6)]:
    d=bpy.data.lights.new('Pickaxes_'+name,'AREA');o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=loc
    o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
world=bpy.data.worlds.new('Pickaxes_World');world.use_nodes=True
node=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');node.inputs['Color'].default_value=(.4,.4,.4,1);node.inputs['Strength'].default_value=.55;scene.world=world
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    values=re.findall(r"'([^']+)'",str(e));standard=next((v for v in values if v.lower()=='standard'),None)
    if standard:scene.view_settings.view_transform=standard
scene.render.resolution_x=1500;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'picaretas-preview.png')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            sp=area.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False
            sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
assert fingerprint(originals)==before,'Original objects changed'
with open(os.path.join(BASE,'validation.json'),'w',encoding='utf8') as f:
    json.dump({'original_objects_unchanged':True,'reference':'https://starveiopro.fandom.com/wiki/Pickaxes','models':report},f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=source_path)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'pickaxes-session.blend'),copy=True)
print(json.dumps(report))
