import bpy,bmesh,os,json,math,hashlib,re
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\builds'
NAME='Builds_Catalog_24'
assert NAME not in bpy.data.scenes,'Existing build catalog must not be overwritten'
os.makedirs(BASE,exist_ok=True)
old_objects=list(bpy.data.objects)
def fingerprint():
    h=hashlib.sha256()
    for o in old_objects:
        h.update(repr((o.name,tuple(map(tuple,o.matrix_world)),[c.name for c in o.users_collection])).encode())
        if o.type=='MESH':h.update(repr(([tuple(v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons],[m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()
original_hash=fingerprint()
tiers=[('wood','madeira','MADEIRA'),('stone','pedra','PEDRA'),('gold','ouro','OURO'),('diamond','diamante','DIAMANTE'),('amethyst','ametista','AMETISTA'),('reidite','reidite','REIDITE')]
source={}
# Assemble source parts in memory only to produce closed door halves.
for en,pt,label in tiers:
    col=bpy.data.collections['parede_'+pt];parts=[o for o in col.objects if o.type=='MESH']
    world=[o.matrix_world@v.co for o in parts for v in o.data.vertices]
    anchor=Vector(((min(v.x for v in world)+max(v.x for v in world))/2,(min(v.y for v in world)+max(v.y for v in world))/2,min(v.z for v in world)))
    bm=bmesh.new();mats=[]
    for o in parts:
        vm={v.index:bm.verts.new(o.matrix_world@v.co-anchor) for v in o.data.vertices}
        for p in o.data.polygons:
            m=o.data.materials[p.material_index]
            if m not in mats:mats.append(m)
            f=bm.faces.new([vm[i] for i in p.vertices]);f.material_index=mats.index(m)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(en,'source assembly is not closed')
    source[en]={'parts':parts,'anchor':anchor,'bm':bm,'mats':mats,'bvh':BVHTree.FromBMesh(bm),'height':max(v.co.z for v in bm.verts)}

scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
models=bpy.data.collections.new('Builds_Catalog');scene.collection.children.link(models)
groups={}
for name in ['Walls_Reference','Spikes','Doors','SpikeDoors']:
    c=bpy.data.collections.new(name);models.children.link(c);groups[name]=c
stage=bpy.data.collections.new('Builds_Presentation');scene.collection.children.link(stage);stage.hide_select=True
def enum(o,p,v):setattr(o,p,next(e.identifier for e in o.bl_rna.properties[p].enum_items if e.identifier==v))
def material(name,h):
    def lin(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
    m=bpy.data.materials.new('Build_'+name);m.use_nodes=True
    rgba=tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,);m.diffuse_color=rgba
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Base Color'].default_value=rgba;n.inputs['Roughness'].default_value=.83
    return m
def pal(name,colors):return [material(name+'_'+str(i),h) for i,h in enumerate(colors)]
palettes={k:pal(k,v) for k,v in {
 'wood':['855333','B87C4A','523422'],'stone':['8D9598','CBD4D1','4B5459'],
 'gold':['ACAB3C','E4DB78','656829'],'diamond':['39B7CF','A4F8FF','176174'],
 'amethyst':['B367D1','E1B7F3','683978'],'reidite':['9B425B','D87C94','54283E'],
 'steel':['39434B','75828C','222A30'],'trim':['BE9E4D','F0D18C','745A2B']}.items()}
records=[];created=[]
def item(tier,kind,row,col):
    global ITEM,COL,ROOT,TIER
    TIER=tier;ITEM=tier+'_'+kind
    assert ITEM not in bpy.data.collections,ITEM
    COL=bpy.data.collections.new(ITEM);groups[['Walls_Reference','Spikes','Doors','SpikeDoors'][row]].children.link(COL)
    ROOT=bpy.data.objects.new(ITEM+'_root',None);COL.objects.link(ROOT);ROOT.location=(-17.5+col*7,12-row*8,0);ROOT.empty_display_size=.15
    ROOT['item_id']=ITEM;ROOT['tier']=col+1;ROOT['category']=kind
    records.append({'item_id':ITEM,'kind':kind,'tier':tier,'source_collection':'parede_'+tiers[col][1],'new_model':row!=0})
def newmesh(part,verts,faces,mats,ids=None,parent=None):
    name=ITEM+'_'+part;me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    for m in mats:me.materials.append(m)
    for i,p in enumerate(me.polygons):p.material_index=(ids or [0])[i%len(ids or [0])]
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    o=bpy.data.objects.new(name,me);COL.objects.link(o);o.parent=parent or ROOT;o['item_id']=ITEM;o['part']=part;created.append(o)
    return o
def box(part,center,size,mats,parent=None):
    x,y,z=center;dx,dy,dz=[a/2 for a in size]
    v=[(x+xx*dx,y+yy*dy,z+zz*dz) for zz in [-1,1] for yy in [-1,1] for xx in [-1,1]]
    return newmesh(part,v,[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)],mats,[2,0,2,0,1,2],parent)
def prism(part,start,end,radius,mats,n=6,tip=True,end_radius=None,parent=None):
    a=Vector(start);b=Vector(end);d=(b-a).normalized();u=d.cross(Vector((0,0,1)))
    if u.length<.01:u=Vector((1,0,0))
    else:u.normalize()
    v=d.cross(u).normalized()
    if tip:
        shoulder=a+(b-a)*.29
        verts=[tuple(p+radius*factor*(u*math.cos(2*math.pi*i/n)+v*math.sin(2*math.pi*i/n))) for p,factor in [(a,.76),(shoulder,1)] for i in range(n)]+[tuple(b)]
        faces=[tuple(reversed(range(n)))];ids=[2]
        for i in range(n):
            j=(i+1)%n;faces.extend([(i,j,n+j,n+i),(n+i,n+j,2*n)]);ids.extend([2,1 if i%3==0 else 0 if i%3==1 else 2])
    else:
        er=radius if end_radius is None else end_radius
        verts=[tuple(p+r*(u*math.cos(2*math.pi*i/n)+v*math.sin(2*math.pi*i/n))) for p,r in [(a,radius),(b,er)] for i in range(n)]
        faces=[tuple(reversed(range(n))),tuple(range(n,2*n))];ids=[2,0]
        for i in range(n):j=(i+1)%n;faces.append((i,j,n+j,n+i));ids.append(1 if i%3==0 else 0)
    return newmesh(part,verts,faces,mats,ids,parent)
def gem(part,x,y,z,rx,ry,height,mats,parent=None):
    verts=[(x-rx,y,z),(x,y-ry,z),(x+rx,y,z),(x,y+ry,z),(x-.10*rx,y+.05*ry,z+height)]
    return newmesh(part,verts,[(3,2,1,0),(0,1,4),(1,2,4),(2,3,4),(3,0,4)],mats,[2,2,0,1,0],parent)
def topz(x,y):
    hit=source[TIER]['bvh'].ray_cast(Vector((x,y,5)),Vector((0,0,-1)))
    return hit[0].z if hit[0] else 1.92
def copy_wall():
    s=source[TIER]
    for j,o in enumerate(s['parts']):
        data=o.data.copy();data.transform(Matrix.Translation(-s['anchor'])@o.matrix_world)
        part='body' if o.name.startswith('corpo') else 'detail_'+str(j)
        obj=bpy.data.objects.new(ITEM+'_'+part,data);COL.objects.link(obj);obj.parent=ROOT;obj['item_id']=ITEM;obj['part']=part;created.append(obj)
def door_halves():
    leaves={}
    for side in [-1,1]:
        bm=source[TIER]['bm'].copy();plane=side*.045
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-6,plane_co=(plane,0,0),plane_no=(1,0,0))
        remove=[v for v in bm.verts if (v.co.x-plane)*side < -1e-6]
        bmesh.ops.delete(bm,geom=remove,context='VERTS')
        cut=[e for e in bm.edges if e.is_boundary]
        result=bmesh.ops.holes_fill(bm,edges=cut,sides=0)
        for f in result['faces']:f.material_index=0
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges),(ITEM,side,'open half')
        name=ITEM+'_panel_'+('left' if side<0 else 'right')
        me=bpy.data.meshes.new(name);bm.to_mesh(me);bm.free()
        for m in source[TIER]['mats']:me.materials.append(m)
        obj=bpy.data.objects.new(name,me);COL.objects.link(obj);obj.parent=ROOT;created.append(obj)
        obj['item_id']=ITEM;obj['open_translation']=[side*2.25,0,0];obj['part']='panel_'+('left' if side<0 else 'right')
        leaves[side]=obj
    ROOT['opening_axis']='local X';ROOT['open_travel_per_leaf']=2.25
    return leaves
def door_details(leaves):
    trim=palettes['wood'] if TIER=='wood' else palettes['steel'] if TIER=='reidite' else palettes[TIER]
    for side in [-1,1]:
        p=leaves[side]
        for j,y in enumerate([-.83,.83]):
            x=side*.80;z=topz(x,y)
            prism('fastener_'+str(side)+'_'+str(j),(x,y,z-.04),(x,y,z+.11),.16,trim,n=8,tip=False,parent=p)
        x=side*.29;z=topz(x,0)
        for j,y in enumerate([-.30,.30]):box('handle_mount_'+str(side)+'_'+str(j),(x,y,z+.08),(.16,.18,.24),trim,p)
        box('handle_'+str(side),(x,0,z+.22),(.14,.74,.14),trim,p)
        if TIER in ['diamond','amethyst','reidite']:
            x=side*1.05;y=0;z=topz(x,y)
            if TIER=='amethyst':
                gem('gold_setting_'+str(side),x,y,z+.008,.33,.49,.045,palettes['trim'],p)
                gem('crystal_'+str(side),x,y,z+.05,.24,.37,.21,palettes[TIER],p)
            else:gem('crystal_'+str(side),x,y,z+.008,.29,.43,.22,palettes[TIER],p)
            if TIER=='reidite':
                for j,y in enumerate([-.70,.70]):
                    z=topz(side*1.25,y);box('armor_'+str(side)+'_'+str(j),(side*1.25,y,z+.06),(.25,.45,.18),palettes['steel'],p)
def spikes(leaves=None):
    mat=palettes[TIER]
    for i in range(8):
        theta=math.pi/8+i*math.pi/4;d=Vector((math.cos(theta),math.sin(theta),0));side=1 if d.x>0 else -1;p=leaves[side] if leaves else ROOT
        length=3.05 if TIER in ['diamond','amethyst'] else 3.28 if TIER=='reidite' else 2.92
        radius=.33 if TIER in ['diamond','amethyst'] else .43 if TIER=='reidite' else .27
        start=d*1.57+Vector((0,0,1.13));end=d*length+Vector((0,0,1.65 if TIER!='reidite' else 1.82))
        prism('spike_'+str(i+1).zfill(2),start,end,radius,mat,n=5 if TIER=='wood' else 4 if TIER=='stone' else 6,parent=p)
        if TIER in ['diamond','amethyst','reidite']:
            socket=palettes['trim'] if TIER=='amethyst' else palettes['steel'] if TIER=='reidite' else mat
            prism('spike_socket_'+str(i+1).zfill(2),d*1.70+Vector((0,0,1.17)),d*1.94+Vector((0,0,1.25)),radius*1.12,socket,n=6,tip=False,parent=p)
    if TIER in ['amethyst','reidite']:
        for i in range(4):
            theta=math.pi/4+i*math.pi/2;d=Vector((math.cos(theta),math.sin(theta),0));p=leaves[1 if d.x>0 else -1] if leaves else ROOT
            x,y=d.x*1.27,d.y*1.27;z=topz(x,y)
            prism('crown_crystal_'+str(i+1),(x,y,z-.07),(x*1.15,y*1.15,z+.60),.19 if TIER=='amethyst' else .25,mat,n=5,parent=p)
    if TIER=='diamond':
        for i in range(4):
            theta=math.pi/4+i*math.pi/2;x,y=math.cos(theta)*1.25,math.sin(theta)*1.25;p=leaves[1 if x>0 else -1] if leaves else ROOT
            gem('rim_crystal_'+str(i+1),x,y,topz(x,y)+.005,.17,.22,.14,mat,p)

for row,kind in enumerate(['wall','spike','door','spike_door']):
    for col,(en,pt,label) in enumerate(tiers):
        item(en,kind,row,col)
        if row<2:
            copy_wall()
            if row==1:spikes()
        else:
            leaves=door_halves();door_details(leaves)
            if row==3:spikes(leaves)

# Whole-model weld checks account for the user's intentionally separated wall faces.
for record in records:
    col=bpy.data.collections[record['item_id']];ROOT=bpy.data.objects[record['item_id']+'_root']
    bpy.context.view_layer.update();bm=bmesh.new();tris=0;parts=[]
    for o in col.objects:
        if o.type!='MESH':continue
        assert not o.data.validate(verbose=False),o.name
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);parts.append(o.name)
        transform=ROOT.matrix_world.inverted()@o.matrix_world
        vm={v.index:bm.verts.new(transform@v.co) for v in o.data.vertices}
        for face in o.data.polygons:bm.faces.new([vm[i] for i in face.vertices])
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
    bad=sum(not e.is_manifold for e in bm.edges);bm.free();assert bad==0,(record['item_id'],bad)
    record.update(parts=parts,triangles=tris,non_manifold_edges_after_assembly=bad)
assert fingerprint()==original_hash,'Original user models were changed'
for s in source.values():s['bm'].free()

def label(body,x,y,size,mat):
    d=bpy.data.curves.new('Build_Label_'+body,'FONT');d.body=body;d.size=size
    o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=(x,y,.015);d.materials.append(mat)
floor=material('background','233941');white=material('text','EDF0E8');muted=material('muted','A7C2C5')
me=bpy.data.meshes.new('Build_Backdrop');me.from_pydata([(-100,-100,-.04),(100,-100,-.04),(100,100,-.04),(-100,100,-.04)],[],[(0,1,2,3)]);o=bpy.data.objects.new(me.name,me);stage.objects.link(o);me.materials.append(floor)
label('BUILDS / SUAS PAREDES COMO BASE',-21,18.7,.53,white)
label('18 NOVOS MODELOS  /  6 PAREDES DE REFERENCIA  /  PECAS EDITAVEIS',-21,17.75,.22,muted)
for row,title in enumerate(['PAREDES / SEUS MODELOS','ESPINHOS','PORTAS','PORTAS COM ESPINHOS']):
    cy=12-row*8
    label(title,-21,cy+3.75,.33,white)
    for col,(en,pt,name) in enumerate(tiers):
        x=-17.5+col*7;label(name,x-1.75,cy-3.45,.23,white)
        label(en+'_'+['wall','spike','door','spike_door'][row],x-1.75,cy-3.86,.15,muted)
cd=bpy.data.cameras.new('Builds_Camera');cam=bpy.data.objects.new(cd.name,cd);stage.objects.link(cam)
target=Vector((0,.5,0));cam.location=(0,-31,68);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();enum(cd,'type','ORTHO');cd.ortho_scale=45.5;scene.camera=cam
for name,loc,power,size in [('Key',(-18,14,33),8000,20),('Fill',(18,-8,25),5500,18)]:
    d=bpy.data.lights.new('Builds_'+name,'AREA');o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
w=bpy.data.worlds.new('Builds_World');w.use_nodes=True;n=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');n.inputs['Color'].default_value=(.4,.4,.4,1);n.inputs['Strength'].default_value=.6;scene.world=w
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    values=re.findall(r"'([^']+)'",str(e));s=next((v for v in values if v.lower()=='standard'),None)
    if s:scene.view_settings.view_transform=s
scene.render.resolution_x=2400;scene.render.resolution_y=2100;scene.render.resolution_percentage=100
enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'builds-preview.png')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False;sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
with open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8') as f:json.dump({'reference':'https://starveiopro.fandom.com/wiki/Structures','source_file':'C:/Users/Elize/Desktop/Roblox/Assets/recursos.blend','originals_unchanged':True,'models':records},f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'builds-trabalho.blend'))
print(json.dumps([{'id':r['item_id'],'triangles':r['triangles'],'parts':len(r['parts'])} for r in records]))
