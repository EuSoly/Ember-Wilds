"""Natural, single-resource mining deposits. Run in the user's live Blender."""
import bpy,bmesh,os,json,math,random,hashlib,re
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
BASE=os.path.dirname(os.path.abspath(__file__))
NAME='Mining_Deposits_13'
assert NAME not in bpy.data.scenes,'Existing deposits must not be overwritten'
os.makedirs(BASE,exist_ok=True)
prior=list(bpy.data.objects)
def fingerprint():
    h=hashlib.sha256()
    for o in prior:
        h.update(repr((o.name,tuple(map(tuple,o.matrix_world)),[c.name for c in o.users_collection])).encode())
        if o.type=='MESH':h.update(repr(([tuple(v.co) for v in o.data.vertices],[tuple(f.vertices) for f in o.data.polygons],[m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()
before=fingerprint();source_file=bpy.data.filepath
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'before-minerals.blend'),copy=True)
scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
catalog=bpy.data.collections.new('Mining_Deposits');scene.collection.children.link(catalog)
stage=bpy.data.collections.new('Deposits_Presentation');scene.collection.children.link(stage);stage.hide_select=True
def enum(o,p,v):setattr(o,p,next(e.identifier for e in o.bl_rna.properties[p].enum_items if e.identifier==v))
def material(name,h,rough=.76):
    def lin(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    rgba=tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m=bpy.data.materials.new('Ore_'+name);m.use_nodes=True;m.diffuse_color=rgba
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Base Color'].default_value=rgba;n.inputs['Roughness'].default_value=rough
    return m
COLORS={
 'stone':['77818A','9EA9AF','59636D','B9C1C1','68747C'],
 'gold':['C1A341','E3C85D','8A702A','F1DD85','AE8E34'],
 'diamond':['42B6D0','88E4EE','247D99','B6F2F3','359BB9'],
 'amethyst':['9E65C9','C498E5','66368B','DBBCF0','824BB2'],
 'reidite':['A94E70','D7839B','6D304F','E3A6B8','8C3B5B'],
 'emerald':['28A958','63CE80','176B3C','A1E5AA','22864B']}
PAL={k:[material(k+'_'+str(i),v,.84 if k=='stone' else .62) for i,v in enumerate(colors)] for k,colors in COLORS.items()}
names={'stone':'PEDRA','gold':'OURO','diamond':'DIAMANTE','amethyst':'AMETISTA','reidite':'REIDITE','emerald':'ESMERALDA'}
source_map={'stone':['pedra.001','pedra.002','pedra.003'],'gold':['ouro.001','ouro.002'],'diamond':['diamante.001','diamante.002'],'amethyst':['ametista.001','ametista.002'],'reidite':['reidite.001','reidite.002'],'emerald':[]}
groups={}
for k in COLORS:
    c=bpy.data.collections.new(k+'_deposits');catalog.children.link(c);groups[k]=c
records=[];created=[]
def begin(kind,variant,position):
    global KIND,ID,ROOT,COL,RNG
    KIND=kind;ID=kind+'_deposit_'+str(variant).zfill(2);RNG=random.Random(104+list(COLORS).index(kind)*31+variant*11)
    assert ID not in bpy.data.collections
    COL=bpy.data.collections.new(ID);groups[kind].children.link(COL)
    ROOT=bpy.data.objects.new(ID+'_root',None);COL.objects.link(ROOT);ROOT.location=position;ROOT.empty_display_size=.10
    ROOT['item_id']=ID;ROOT['resource_type']=kind;ROOT['variant']=variant;ROOT['purpose']='harvestable_world_deposit';ROOT['pivot']='ground_center'
    records.append({'item_id':ID,'resource':kind,'variant':variant,'source_collection':source_map[kind][variant-1] if source_map[kind] else None,'gallery_position':list(position)})

def shade(me,pal,seed=0):
    for mat in pal:me.materials.append(mat)
    rg=random.Random(seed)
    for f in me.polygons:
        n=f.normal
        if n.z>.68:idx=1 if rg.random()<.75 else 3
        elif n.z<-.25:idx=2
        elif n.x<-.2:idx=4
        else:idx=0
        f.material_index=idx;f.use_smooth=False

def mesh(part,verts,faces):
    me=bpy.data.meshes.new(ID+'_'+part);me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
    shade(me,PAL[KIND],len(created)*13)
    o=bpy.data.objects.new(me.name,me);COL.objects.link(o);o.parent=ROOT;o['resource_type']=KIND;o['part']=part;o['item_id']=ID;created.append(o);return o

def hull(part,points):
    bm=bmesh.new()
    for p in points:bm.verts.new(p)
    bmesh.ops.convex_hull(bm,input=list(bm.verts),use_existing_faces=False)
    unused=[v for v in bm.verts if not v.link_faces]
    if unused:bmesh.ops.delete(bm,geom=unused,context='VERTS')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    # Merge planar triangulation into broad, deliberate low-poly facets.
    bmesh.ops.dissolve_limit(bm,angle_limit=.015,verts=list(bm.verts),edges=list(bm.edges),use_dissolve_boundaries=False)
    bm.verts.ensure_lookup_table();bm.verts.index_update()
    v=[tuple(x.co) for x in bm.verts];f=[tuple(v.index for v in face.verts) for face in bm.faces];bm.free()
    return mesh(part,v,f)

def boulder(part,center,size,seed,angular=False):
    rg=random.Random(seed);x,y,z=center;sx,sy,sz=size;n=7 if angular else 9
    pts=[];phase=rg.uniform(-.3,.3)
    # Truncated foot, irregular shoulder, offset crown: no cylindrical platform.
    for level,(r,h) in enumerate([(.80,0),(1,.30),(.81,.75),(.43,1)]):
        dx,dy=(0,0) if level<2 else (.13*sx,-.08*sy)
        for i in range(n):
            a=i*2*math.pi/n+phase+(0 if level<2 else .18)
            rr=r*rg.uniform(.83,1.12)
            zz=z+sz*h+(rg.uniform(-.07,.07)*sz if level in [1,2] else 0)
            pts.append((x+dx+math.cos(a)*sx*.5*rr,y+dy+math.sin(a)*sy*.5*rr,zz))
    return hull(part,pts)

def prism(part,base,r,height,n=6,style='point',tilt=(0,0),phase=0,aspect=1):
    x,y,z=base;dx,dy=tilt
    rings=[(1,0),(1,.68),(.67,.92)] if style=='flat' else [(.85,0),(1,.61),(.83,.77)] if style=='point' else [(.75,0),(1,.48),(.70,.81)]
    verts=[]
    for rad,h in rings:
        for i in range(n):
            a=i*2*math.pi/n+phase
            verts.append((x+dx*h+r*rad*math.cos(a),y+dy*h+r*aspect*rad*math.sin(a),z+height*h))
    f=[tuple(reversed(range(n)))]
    for j in range(len(rings)-1):
        for i in range(n):k=(i+1)%n;f.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
    if style=='flat':
        # A shallow bevel leading to a hexagonal end cap identifies emerald.
        f.append(tuple(range((len(rings)-1)*n,len(rings)*n)))
    else:
        verts.append((x+dx,y+dy,z+height));tip=len(verts)-1
        for i in range(n):f.append(((len(rings)-1)*n+i,(len(rings)-1)*n+(i+1)%n,tip))
    return mesh(part,verts,f)

def shard(part,base,width,depth,height,azimuth,lean):
    # Thick asymmetrical mineral blade, never a metal plate or decorative mount.
    pts=[(-.50,-.42,0),(.48,-.44,0),(.61,.27,.18),(-.46,.43,.12),(-.40,-.33,.64),(.43,-.29,.77),(.25,.23,.95),(-.20,.30,1)]
    c,s=math.cos(azimuth),math.sin(azimuth);x,y,z=base
    v=[]
    for px,py,pz in pts:
        xx=px*width+lean*pz;yy=py*depth
        v.append((x+c*xx-s*yy,y+s*xx+c*yy,z+pz*height))
    return hull(part,v)

def build_stone(v):
    if v==1:
        boulder('main_rock',(-.18,.12,0),(2.90,2.65,1.75),27)
        boulder('broken_lobe',(1.0,-.35,0),(1.20,1.35,.82),16)
        boulder('foot_chip',(-.92,-1.0,0),(.65,.76,.40),33)
    elif v==2:
        boulder('left_mass',(-.73,.15,0),(2.50,2.65,1.80),65)
        boulder('right_mass',(.83,.05,0),(2.20,2.45,1.49),92)
        boulder('front_lobe',(.1,-1.0,0),(1.45,1.20,.67),32)
    else:
        boulder('main_rock',(.15,.15,0),(3.65,3.15,2.10),102)
        boulder('left_ledge',(-1.28,-.28,0),(1.55,1.95,.95),89)
        boulder('front_ledge',(.75,-1.02,0),(1.58,1.36,.72),92)

def build_gold(v):
    boulder('ore_mass',(0,0,0),(3.10 if v==1 else 3.85,2.60 if v==1 else 3.15,.85),70+v,True)
    blobs=[(-.45,.28,.42,1.95,1.70,1.28),(.75,-.20,.24,1.50,1.65,1.04),(-.85,-.65,.13,.90,1.05,.67)]
    if v==2:blobs=[(-.72,.40,.40,2.05,1.78,1.62),(.80,.34,.32,1.83,1.95,1.36),(.16,-.93,.20,1.64,1.18,.91),(-1.32,-.38,.12,.94,1.31,.70)]
    for j,(x,y,z,w,d,h) in enumerate(blobs):boulder('gold_lobe_'+str(j+1),(x,y,z),(w,d,h),101+j*37+v,True)

def build_diamond(v):
    boulder('mineral_foot',(0,0,0),(3.20 if v==1 else 4.05,2.85 if v==1 else 3.38,.61),201+v,True)
    specs=[(-.33,.40,.25,.82,2.28,(-.22,.22)),(.83,-.12,.18,.73,1.72,(.34,.10)),(-.75,-.73,.10,.64,1.19,(-.28,-.25))]
    if v==2:specs=[(-.55,.45,.22,.92,2.64,(-.30,.33)),(.88,.29,.24,.85,2.09,(.45,.10)),(-.85,-.78,.10,.77,1.46,(-.32,-.23)),(.57,-1.0,.08,.55,1.08,(.23,-.20))]
    for j,(x,y,z,r,h,tilt) in enumerate(specs):prism('diamond_crystal_'+str(j+1),(x,y,z),r,h,4,'point',tilt,phase=.30+j*.43,aspect=.90)

def build_amethyst(v):
    boulder('mineral_foot',(0,0,0),(3.25 if v==1 else 4.12,2.88 if v==1 else 3.4,.60),301+v,True)
    specs=[(-.15,.35,.20,.70,2.56,(-.10,.16)),(.92,-.06,.13,.52,1.85,(.30,.04)),(-.93,-.28,.12,.48,1.58,(-.30,-.10)),(-.03,-.85,.10,.49,1.30,(.04,-.22))]
    if v==2:specs=[(-.42,.50,.22,.73,2.99,(-.23,.30)),(.79,.46,.19,.62,2.51,(.32,.19)),(-1.12,-.22,.12,.56,1.91,(-.38,-.08)),(.72,-.81,.10,.55,1.77,(.33,-.28)),(-.24,-1.03,.08,.47,1.32,(-.09,-.30))]
    for j,(x,y,z,r,h,tilt) in enumerate(specs):prism('amethyst_crystal_'+str(j+1),(x,y,z),r,h,6,'point',tilt,phase=.22+j*.42)

def build_reidite(v):
    boulder('mineral_foot',(0,0,0),(3.5 if v==1 else 4.35,3.1 if v==1 else 3.7,.68),401+v,True)
    count=5 if v==1 else 6
    for j in range(count):
        a=j*2*math.pi/count+.3
        r=.73 if v==1 else .92;h=[1.90,2.39,1.69,2.15,1.54,1.97][j]*(1.1 if v==2 else 1)
        shard('reidite_blade_'+str(j+1),(r*math.cos(a),r*math.sin(a),.10),1.43 if v==1 else 1.64,.76,h,a,.39 if v==1 else .56)
    shard('central_blade',(-.15,.04,.25),1.42,1.1,2.12 if v==1 else 2.75,.6,.1)

def build_emerald(v):
    boulder('mineral_foot',(0,0,0),(3.30 if v==1 else 4.20,2.95 if v==1 else 3.5,.67),501+v,True)
    specs=[(-.33,.38,.23,.80,2.37,(-.15,.18)),(.83,-.02,.18,.62,1.82,(.30,.05)),(-.76,-.72,.12,.62,1.28,(-.21,-.20))]
    if v==2:specs=[(-.51,.48,.20,.83,2.90,(-.20,.26)),(.84,.47,.20,.70,2.33,(.31,.10)),(-1.03,-.57,.10,.67,1.77,(-.28,-.18)),(.49,-.90,.08,.72,1.50,(.15,-.30))]
    for j,(x,y,z,r,h,tilt) in enumerate(specs):prism('emerald_crystal_'+str(j+1),(x,y,z),r,h,6,'flat',tilt,phase=.10+j*.29)

builders={'stone':build_stone,'gold':build_gold,'diamond':build_diamond,'amethyst':build_amethyst,'reidite':build_reidite,'emerald':build_emerald}
for gi,kind in enumerate(COLORS):
    cx=(gi%3-1)*13;cy=6 if gi<3 else -8
    positions=[(cx-2.7,cy,0),(cx+2.7,cy-.5,0)]
    if kind=='stone':positions.append((cx,cy+3.9,0))
    for j,pos in enumerate(positions):begin(kind,j+1,pos);builders[kind](j+1)

# Solid meshes, one mineral palette per resource, grounded pivots, no isolated floating pieces.
bpy.context.view_layer.update()
for rec in records:
    col=bpy.data.collections[rec['item_id']];root=bpy.data.objects[rec['item_id']+'_root'];obs=[o for o in col.objects if o.type=='MESH']
    coords=[v.co for o in obs for v in o.data.vertices];lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    shift=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for o in obs:
        for v in o.data.vertices:v.co-=shift
        o.data.update()
    parts=[];tris=0;boxes=[]
    for o in obs:
        assert not o.data.validate(verbose=False),o.name
        assert all(m.name.startswith('Ore_'+rec['resource']+'_') for m in o.data.materials),o.name
        bm=bmesh.new();bm.from_mesh(o.data)
        assert all(e.is_manifold for e in bm.edges),(o.name,'open edge')
        assert all(f.calc_area()>1e-8 for f in bm.faces),(o.name,'degenerate face')
        assert bm.calc_volume()>0,(o.name,'inverted solid');bm.free()
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);parts.append(o.name)
        boxes.append(([min(v.co[i] for v in o.data.vertices) for i in range(3)],[max(v.co[i] for v in o.data.vertices) for i in range(3)]))
    # Broad phase proves every component belongs to the base cluster (refined visual check follows).
    connected={0}
    for repeat in range(len(boxes)):
        for j,(a,b) in enumerate(boxes):
            if j in connected:continue
            if any(all(a[k]<=boxes[i][1][k]+.015 and b[k]>=boxes[i][0][k]-.015 for k in range(3)) for i in connected):connected.add(j)
    assert len(connected)==len(boxes),(rec['item_id'],'isolated component')
    trees=[BVHTree.FromPolygons([v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons]) for o in obs]
    reached={i for i,o in enumerate(obs) if min(v.co.z for v in o.data.vertices)<.0001}
    for repeat in range(len(obs)):
        for j in range(len(obs)):
            if j not in reached and any(trees[j].overlap(trees[i]) for i in reached):reached.add(j)
    assert len(reached)==len(obs),(rec['item_id'],'floating component')
    rec.update(parts=parts,triangles=tris,bounds_min=list(lo-shift),bounds_max=list(hi-shift),single_resource_materials=True,closed_meshes=True,all_parts_grounded_or_intersect_connected=True)
assert len(records)==13
assert fingerprint()==before,'Original scene geometry changed'

# Gallery presentation; model collections contain no floor, labels, lights or cameras.
floor=material('presentation_floor','253A42');white=material('presentation_text','E6EEE8');muted=material('presentation_muted','A2BEC2')
me=bpy.data.meshes.new('Deposit_Backdrop');me.from_pydata([(-100,-100,-.06),(100,-100,-.06),(100,100,-.06),(-100,100,-.06)],[],[(0,1,2,3)]);o=bpy.data.objects.new(me.name,me);stage.objects.link(o);me.materials.append(floor)
def text(body,x,y,size,mat):
    d=bpy.data.curves.new('Deposit_Label','FONT');d.body=body;d.size=size;ob=bpy.data.objects.new('label_'+body,d);stage.objects.link(ob);ob.location=(x,y,.015);d.materials.append(mat)
text('MINERIOS / DEPOSITOS NATURAIS',-19,20,.65,white)
text('13 VARIANTES  /  6 RECURSOS  /  UMA PALETA POR MINERIO',-19,18.9,.24,muted)
for gi,kind in enumerate(COLORS):
    cx=(gi%3-1)*13;cy=6 if gi<3 else -8
    text(names[kind],cx-5.2,cy+7,.45,white)
    text('03 VARIANTES' if kind=='stone' else '02 VARIANTES',cx-5.2,cy+6.35,.18,muted)
for r in records:
    x,y,_=r['gallery_position'];text(r['item_id'],x-1.65,12.10 if r['item_id']=='stone_deposit_03' else y-2.65,.18,muted)
cd=bpy.data.cameras.new('Deposits_Camera');cam=bpy.data.objects.new(cd.name,cd);stage.objects.link(cam)
target=Vector((0,3.0,.5));cam.location=(0,-35,58);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();enum(cd,'type','ORTHO');cd.ortho_scale=42;scene.camera=cam
for name,loc,power,size in [('Key',(-15,-10,30),7800,15),('Fill',(16,14,26),5500,20)]:
    d=bpy.data.lights.new('Deposits_'+name,'AREA');ob=bpy.data.objects.new(d.name,d);stage.objects.link(ob);ob.location=loc;ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
w=bpy.data.worlds.new('Deposits_World');w.use_nodes=True;n=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');n.inputs['Color'].default_value=(.4,.4,.4,1);n.inputs['Strength'].default_value=.65;scene.world=w
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    value=next((v for v in re.findall(r"'([^']+)'",str(e)) if v.lower()=='standard'),None)
    if value:scene.view_settings.view_transform=value
scene.render.resolution_x=2600;scene.render.resolution_y=2100;scene.render.resolution_percentage=100;enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'minerios-preview.png')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False;sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
with open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8') as f:json.dump({'reference':'https://starveiopro.fandom.com/wiki/Resources#Emerald','source_file':source_file,'originals_preserved':True,'models':records},f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'minerios-trabalho.blend'))
print(json.dumps({'models':len(records),'pieces':len(created),'triangles':sum(r['triangles'] for r in records),'single_resource_palettes':True}))
