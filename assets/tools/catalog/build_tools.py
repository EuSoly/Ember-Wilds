import bpy,bmesh,math,os,json,hashlib,re
from mathutils import Vector
from collections import Counter
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\catalog'
NAME='Tools_Catalog_23'
assert NAME not in bpy.data.scenes,'Catalog exists; preserve edits'
os.makedirs(BASE,exist_ok=True)
source=bpy.data.filepath
originals=list(bpy.data.objects)
def fingerprint():
    h=hashlib.sha256()
    for o in originals:
        h.update(repr((o.name,tuple(map(tuple,o.matrix_world)),[c.name for c in o.users_collection])).encode())
        if o.type=='MESH':h.update(repr(([tuple(v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons],[m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()
before=fingerprint()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'before-tools.blend'),copy=True)
scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
models=bpy.data.collections.new('Tools');scene.collection.children.link(models)
stage=bpy.data.collections.new('Tools_Presentation');scene.collection.children.link(stage);stage.hide_select=True
groups={}
for name in ['Hammers','Shovels','Shields','UtilityTools']:
    c=bpy.data.collections.new(name);models.children.link(c);groups[name]=c
def enum(o,p,v):setattr(o,p,next(e.identifier for e in o.bl_rna.properties[p].enum_items if e.identifier==v))
def mat(name,h):
    def lin(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    m=bpy.data.materials.new('Tools_'+name);m.use_nodes=True
    rgba=tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m.diffuse_color=rgba;n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=rgba;n.inputs['Roughness'].default_value=.82
    return m
def palette(name,colors):return [mat(name+'_'+str(i),h) for i,h in enumerate(colors)]
pal={k:palette(k,v) for k,v in {
 'wood':['8C633E','B48755','513B28'],'stone':['A9B1B1','D9DEDA','5B6264'],
 'gold':['D9C245','F8E98B','83702B'],'diamond':['43D8DF','B4FFFB','247F97'],
 'amethyst':['AF4ED2','EC98F8','60297D'],'reidite':['C05242','F28A68','702B2B'],
 'super':['42B96E','A5F79B','226D51'],'steel':['515B60','87979A','28353B'],
 'leather':['413127','735640','271F1A'],'pages':['D7C9A8','F2E9CC','9B896C'],
 'book':['7F391F','B46032','482619'],'water':['339EBD','7BE3EA','1C596F']}.items()}
def mesh(part,verts,faces,mats,ids=None):
    name=ITEM+'_'+part;me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);COL.objects.link(o);o.parent=ROOT
    for m in mats:me.materials.append(m)
    for i,p in enumerate(me.polygons):p.material_index=(ids or [0])[i%len(ids or [0])]
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    o['item_id']=ITEM;o['part']=part
    return o
def symmetric_surface(part,verts,faces,mats,ids=None):
    # Separate raised front/back ornaments within one editable mesh.
    n=len(verts);v=verts+[(x,y,-z) for x,y,z in verts]
    f=faces+[tuple(n+i for i in reversed(face)) for face in faces]
    mi=(ids or [0]*len(faces));return mesh(part,v,f,mats,mi+mi)
def solid(part,poly,mats,depth=.16,bevel=.018,z=0):
    n=len(poly);sign=1 if sum(poly[i][0]*poly[(i+1)%n][1]-poly[(i+1)%n][0]*poly[i][1] for i in range(n))>0 else -1
    inner=[]
    for i,p in enumerate(poly):
        q=Vector(p);a=(q-Vector(poly[i-1])).normalized();b=(Vector(poly[(i+1)%n])-q).normalized()
        na=Vector((-a.y,a.x))*sign;nb=Vector((-b.y,b.x))*sign;d=(na+nb).normalized()
        inner.append(tuple(q+d*(bevel/max(.4,d.dot(na)))))
    verts=[(x,y,z-depth/2) for x,y in inner]+[(x,y,z-depth/2+bevel) for x,y in poly]+[(x,y,z+depth/2-bevel) for x,y in poly]+[(x,y,z+depth/2) for x,y in inner]
    faces=[tuple(reversed(range(n))),tuple(range(3*n,4*n))];ids=[0,0]
    for level in range(3):
        for i in range(n):
            j=(i+1)%n;faces.append((level*n+i,level*n+j,(level+1)*n+j,(level+1)*n+i));ids.append(2 if level==1 else 1)
    if z: return symmetric_surface(part,verts,faces,mats,ids)
    return mesh(part,verts,faces,mats,ids)
def rect(x0,y0,x1,y1,b=.04):return [(x0+b,y0),(x1-b,y0),(x1,y0+b),(x1,y1-b),(x1-b,y1),(x0+b,y1),(x0,y1-b),(x0,y0+b)]
def ring(part,outer,inner,mats,depth=.12,z=0):
    n=len(outer);assert n==len(inner)
    v=[(x,y,zz) for zz in [z-depth/2,z+depth/2] for poly in [outer,inner] for x,y in poly];f=[];ids=[]
    for i in range(n):
        j=(i+1)%n
        f.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)]);ids.extend([0,0,2,1])
    return symmetric_surface(part,v,f,mats,ids) if z else mesh(part,v,f,mats,ids)
def ellipse(rx,ry,cy=0,n=12):return [(rx*math.cos(2*math.pi*i/n),cy+ry*math.sin(2*math.pi*i/n)) for i in range(n)]
def gem(part,cx,cy,rx,ry,mats,z=.18,height=.10):
    poly=[(cx-rx,cy),(cx,cy-ry),(cx+rx,cy),(cx,cy+ry)]
    v=[(x,y,z) for x,y in poly]+[(cx-.15*rx,cy+.05*ry,z+height)]
    return symmetric_surface(part,v,[(3,2,1,0),(0,1,4),(1,2,4),(2,3,4),(3,0,4)],mats,[2,2,0,1,0])
def band(part,cy,mats,width=.16):return solid(part,rect(-width,cy-.065,width,cy+.065,.018),mats,depth=.23,bevel=.015)
items=[]
def item(name,label,group,row,column,angle=-25):
    global ITEM,COL,ROOT
    assert name not in bpy.data.collections,name
    ITEM=name;COL=bpy.data.collections.new(name);groups[group].children.link(COL)
    ROOT=bpy.data.objects.new(name+'_root',None);COL.objects.link(ROOT)
    ROOT.location=(-8.25+column*3.3,8.5-row*4.0,.52);ROOT.rotation_euler.z=math.radians(angle);ROOT.empty_display_size=.1
    ROOT['item_id']=name;ROOT['category']=group.lower();ROOT['two_sided']=True
    items.append({'item_id':name,'label':label,'group':group,'row':row,'column':column})
def handle(mats=pal['leather'],bottom=-1.05,top=.72,width=.095):
    solid('handle',rect(-width,bottom,width,top,.035),mats,depth=.15)
def high_handle(tier):
    if tier in ['diamond','amethyst','reidite','super']:
        accent=pal['gold'] if tier=='amethyst' else pal[tier]
        band('collar',.42,accent);band('pommel',-.98,accent,.13)
    if tier=='reidite':
        band('grip_band_1',-.45,pal['reidite'],.12);band('grip_band_2',-.7,pal['reidite'],.12)

# Six hammers, including the green super hammer from the wiki.
tiers=['stone','gold','diamond','amethyst','reidite','super']
labels=['PEDRA','OURO','DIAMANTE','AMETISTA','REIDITE','SUPER']
for i,(tier,label) in enumerate(zip(tiers,labels)):
    item(tier+'_hammer',label,'Hammers',0,i)
    handle(pal['wood'] if tier in ['stone','gold','super'] else pal['steel'] if tier=='reidite' else pal['leather'])
    width=.69 if tier!='super' else .83;depth=.34 if tier not in ['reidite','super'] else .43
    shape=rect(-width,.55,width,1.23,.10)
    if tier=='reidite':shape=[(-.83,.55),(-.83,1.22),(-.62,1.35),(.62,1.35),(.83,1.22),(.83,.55),(.62,.46),(-.62,.46)]
    solid('head',shape,pal[tier],depth=depth,bevel=.045)
    high_handle(tier)
    if tier=='diamond':
        gem('crystal_face',0,.89,.50,.22,pal[tier],z=.171,height=.10)
    if tier=='amethyst':
        ring('gold_frame',rect(-.60,.61,.60,1.17,.065),rect(-.48,.70,.48,1.08,.045),pal['gold'],depth=.05,z=.185)
        gem('center_crystal',0,.89,.28,.21,pal[tier],z=.18,height=.12)
    if tier=='reidite':
        for j,x in enumerate([-.7,.7]):solid('impact_band_'+str(j+1),rect(x-.11,.51,x+.11,1.28,.025),pal['steel'],depth=.48,bevel=.025)
        gem('head_crystal',0,.9,.38,.28,pal[tier],z=.22,height=.10)
    if tier=='super':
        ring('green_frame',rect(-.76,.61,.76,1.26,.07),rect(-.61,.72,.61,1.15,.04),pal['super'],depth=.055,z=.23)
        for j,x in enumerate([-.25,0,.25]):gem('emerald_'+str(j+1),x,.61 if j==1 else .74,.12,.31 if j==1 else .2,pal['super'],z=.25,height=.10)

# Shovels retain the broad rounded scoop, with crystal ridges in higher tiers.
for i,(tier,label) in enumerate(zip(tiers[:4],labels[:4])):
    item(tier+'_shovel',label,'Shovels',1,i)
    handle(pal['wood'] if tier=='stone' else pal['leather'],top=.65,width=.075)
    scoop=[(-.20,.40),(-.40,.62),(-.43,.98),(-.28,1.24),(0,1.35),(.28,1.24),(.43,.98),(.40,.62),(.20,.40)]
    if tier=='diamond':scoop=[(-.20,.40),(-.43,.62),(-.46,1.04),(-.25,1.28),(0,1.41),(.25,1.28),(.46,1.04),(.43,.62),(.20,.40)]
    solid('scoop',scoop,pal[tier],depth=.18,bevel=.03)
    if tier in ['diamond','amethyst']:
        high_handle(tier)
        if tier=='amethyst':
            inner=[(x*.80,.86+(y-.86)*.78) for x,y in scoop]
            ring('gold_rim',scoop,inner,pal['gold'],depth=.045,z=.09)
        gem('scoop_ridge',0,.87,.13,.35,pal[tier],z=.08,height=.08)

# Two agricultural forks.
for i,tier in enumerate(['stone','gold']):
    item('pitchfork' if i==0 else 'gold_pitchfork','FORCADO' if i==0 else 'FORCADO DE OURO','UtilityTools',1,4+i,angle=-23)
    handle(pal['wood'],bottom=-1.18,top=.47,width=.065)
    solid('fork_base',rect(-.38,.35,.38,.51,.05),pal[tier],depth=.13)
    for j,x in enumerate([-.31,0,.31]):
        poly=[(x-.06,.44),(x+.06,.44),(x+.055,1.22),(x,1.40 if j==1 else 1.33),(x-.055,1.22)]
        solid('tine_'+str(j+1),poly,pal[tier],depth=.12,bevel=.009)
    band('socket',.32,pal[tier],.115)
    if i:gem('gold_emblem',0,.46,.12,.12,pal['gold'],z=.09,height=.05);band('pommel',-1.1,pal['gold'],.1)

# Shields use the distinctive oval, crown and winged silhouettes in the wiki.
for i,(tier,label) in enumerate(zip(['wood']+tiers[:5],['MADEIRA']+labels[:5])):
    item(tier+'_shield',label,'Shields',2,i,angle=0)
    if tier=='wood':
        solid('body',ellipse(.85,.63),pal[tier],depth=.20,bevel=.035)
        ring('rim',ellipse(.87,.65),ellipse(.73,.51),pal['wood'],depth=.075,z=.12)
        for j,y in enumerate([-.20,.20]):solid('plank_seam_'+str(j+1),rect(-.68,y-.012,.68,y+.012,.006),pal['leather'],depth=.018,z=.108,bevel=.003)
        solid('central_brace',[(-.50,-.35),(-.43,-.40),(.5,.35),(.43,.40)],pal['wood'],depth=.035,z=.14,bevel=.008)
    elif tier in ['stone','gold']:
        outline=[(0,.84),(.28,.65),(.61,.53),(.82,.18),(.69,-.34),(.38,-.55),(-.38,-.55),(-.69,-.34),(-.82,.18),(-.61,.53),(-.28,.65)]
        solid('body',outline,pal[tier],depth=.23,bevel=.045)
        inner=[(x*.81,y*.81) for x,y in outline]
        ring('raised_rim',outline,inner,pal[tier],depth=.055,z=.145)
        solid('dark_inset',[(-.42,-.39),(.42,-.39),(.48,.05),(.29,.18),(-.29,.18),(-.48,.05)],pal['leather'],depth=.045,z=.14,bevel=.025)
        gem('crest',0,.45,.18,.22,pal[tier],z=.15,height=.10)
    else:
        main=[(0,.80),(.43,.28),(.45,-.18),(0,-.68),(-.45,-.18),(-.43,.28)]
        solid('body',main,pal[tier],depth=.23,bevel=.028)
        for side in [-1,1]:
            wing=[(.26,.32),(.99,.57),(.85,.19),(.59,.03),(.84,.07),(.68,-.25),(.35,-.40)]
            solid('wing_'+('left' if side<0 else 'right'),[(side*x,y) for x,y in wing],pal[tier],depth=.17,bevel=.018)
        if tier=='amethyst':
            inner=[(x*.82,y*.82) for x,y in main];ring('gold_frame',main,inner,pal['gold'],depth=.045,z=.14)
        if tier=='reidite':
            for side in [-1,1]:solid('horn_'+str(side),[(side*.28,.42),(side*.40,.91),(side*.52,.31)],pal['steel'],depth=.19,bevel=.012)
            gem('dark_core',0,-.18,.27,.31,pal['steel'],z=.13,height=.12)
        else:gem('dark_core',0,-.20,.26,.27,pal['steel'],z=.13,height=.08)
        gem('crest_crystal',0,.29,.27,.34,pal[tier],z=.14,height=.16)

# Small 3D utility helpers, all symmetric across local Z.
def shell(part,r0,r1,y0,y1,thickness,mats,n=12,open_bottom=False):
    loops=[(r0,y0),(r1,y1),(r1-thickness,y1),(r0-thickness,y0+thickness)]
    v=[(r*math.cos(2*math.pi*i/n),y,r*math.sin(2*math.pi*i/n)) for r,y in loops for i in range(n)]
    f=[] if open_bottom else [tuple(reversed(range(n))),tuple(range(3*n,4*n))];ids=[] if open_bottom else [2,2]
    for l in range(3):
        for i in range(n):j=(i+1)%n;f.append((l*n+i,l*n+j,(l+1)*n+j,(l+1)*n+i));ids.append([0,1,2][l])
    if open_bottom:
        for i in range(n):j=(i+1)%n;f.append((3*n+i,3*n+j,j,i));ids.append(2)
    return mesh(part,v,f,mats,ids)
def tube(part,a,b,r0,r1,mats,n=10):
    a=Vector(a);b=Vector(b);axis=(b-a).normalized();u=Vector((-axis.y,axis.x,0));u.normalize();w=Vector((0,0,1))
    v=[tuple(p+r*(math.cos(2*math.pi*i/n)*u+math.sin(2*math.pi*i/n)*w)) for p,r in [(a,r0),(b,r1)] for i in range(n)]
    f=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    for i in range(n):j=(i+1)%n;f.append((i,j,n+j,n+i))
    return mesh(part,v,f,mats,[0]*len(f))

item('book','LIVRO','UtilityTools',3,0,angle=-18)
solid('pages',rect(-.57,-.78,.57,.78,.035),pal['pages'],depth=.28,bevel=.025)
solid('covers',rect(-.65,-.85,.65,.85,.045),pal['book'],depth=.075,z=.18,bevel=.02)
solid('spine',rect(-.68,-.85,-.51,.85,.025),pal['book'],depth=.43,bevel=.02)
ring('cover_border',rect(-.43,-.64,.47,.64,.025),rect(-.39,-.60,.43,.60,.018),pal['gold'],depth=.018,z=.225)
gem('cover_emblem',.02,0,.19,.26,pal['gold'],z=.23,height=.035)

item('watering_can','REGADOR','UtilityTools',3,1,angle=-15)
ROOT.rotation_euler.x=math.radians(32);ROOT.location.z=.95
shell('body',.48,.55,-.62,.45,.08,pal['wood'])
ring('handle',[(-.4,.23),(-1.0,.36),(-1.18,.10),(-1.12,-.35),(-.45,-.43)],[(-.51,.10),(-.90,.22),(-1.02,.06),(-.98,-.22),(-.51,-.29)],pal['wood'],depth=.14)
tube('spout',(.38,-.23,0),(1.10,.66,0),.12,.09,pal['wood'])
tube('sprinkler',(1.06,.61,0),(1.20,.79,0),.22,.28,pal['steel'],n=12)
shell('top_rim',.55,.55,.38,.48,.075,pal['steel'],open_bottom=True)

item('bucket','BALDE','UtilityTools',3,2,angle=-12)
ROOT.rotation_euler.x=math.radians(34);ROOT.location.z=.95
shell('body',.42,.58,-.65,.43,.08,pal['wood'])
shell('rim',.59,.59,.33,.46,.08,pal['steel'],open_bottom=True)
shell('bottom_band',.435,.46,-.62,-.45,.055,pal['steel'],open_bottom=True)
ring('handle',[(-.54,.32),(-.65,.70),(-.47,1.02),(0,1.15),(.47,1.02),(.65,.70),(.54,.32)],[(-.45,.35),(-.54,.69),(-.40,.92),(0,1.04),(.40,.92),(.54,.69),(.45,.35)],pal['steel'],depth=.10)
tube('water',(0,.24,0),(0,.26,0),.47,.47,pal['water'],n=12)

item('wrench','CHAVE INGLESA','UtilityTools',3,3,angle=-30)
handle(pal['stone'],bottom=-.76,top=.76,width=.105)
top=[(-.12,.60),(-.36,.77),(-.39,1.02),(-.25,1.23),(-.16,1.25),(-.19,.96),(0,.84),(.19,.96),(.16,1.25),(.25,1.23),(.39,1.02),(.36,.77),(.12,.60)]
solid('upper_jaw',top,pal['stone'],depth=.17,bevel=.012)
solid('lower_jaw',[(-x,-y*.83) for x,y in top],pal['stone'],depth=.17,bevel=.012)
solid('handle_inset',rect(-.045,-.55,.045,.55,.02),pal['steel'],depth=.02,z=.085,bevel=.006)

item('machete','FACAO','UtilityTools',3,4,angle=-30)
solid('handle',rect(-.12,-1.03,.12,-.31,.045),pal['leather'],depth=.20,bevel=.022)
blade=[(-.11,-.30),(.14,-.30),(.21,.03),(.32,.50),(.28,.98),(.13,1.35),(-.01,1.19),(-.10,.64),(-.12,.14)]
solid('blade',blade,pal['stone'],depth=.115,bevel=.025)
solid('guard',rect(-.22,-.36,.22,-.24,.025),pal['steel'],depth=.20)
for j,y in enumerate([-.48,-.87]):gem('rivet_'+str(j+1),0,y,.035,.035,pal['stone'],z=.10,height=.013)

# Validate geometry, matching front/back materials and untouched existing assets.
manifest=[]
def key(v):return tuple(round(float(x),5) for x in v)
for entry in items:
    col=bpy.data.collections[entry['item_id']];count=bad=0;parts=[]
    for o in col.objects:
        if o.type!='MESH':continue
        assert not o.data.validate(verbose=False),o.name
        bm=bmesh.new();bm.from_mesh(o.data);bad+=sum(not e.is_manifold for e in bm.edges);bm.free()
        assert Counter(key(v.co) for v in o.data.vertices)==Counter(key((v.co.x,v.co.y,-v.co.z)) for v in o.data.vertices),o.name
        def signature(f,mirror=False):return (f.material_index,tuple(sorted(key((o.data.vertices[i].co.x,o.data.vertices[i].co.y,-o.data.vertices[i].co.z) if mirror else o.data.vertices[i].co) for i in f.vertices)))
        assert Counter(signature(f) for f in o.data.polygons)==Counter(signature(f,True) for f in o.data.polygons),('Material symmetry',o.name)
        o.data.calc_loop_triangles();count+=len(o.data.loop_triangles);parts.append(o.name)
    assert bad==0,(col.name,bad)
    manifest.append(dict(entry,parts=parts,triangles=count,non_manifold_edges=bad,two_sided_verified=True))
assert fingerprint()==before,'Existing assets changed'

def label(body,x,y,size,material):
    d=bpy.data.curves.new('Tools_Label_'+body,'FONT');d.body=body;d.size=size
    o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=(x,y,0);d.materials.append(material)
bg=mat('background','233941');white=mat('lettering','EDF0E8');muted=mat('secondary','A7C2C5')
me=bpy.data.meshes.new('Tools_Backdrop');me.from_pydata([(-100,-100,-.05),(100,-100,-.05),(100,100,-.05),(-100,100,-.05)],[],[(0,1,2,3)]);o=bpy.data.objects.new(me.name,me);stage.objects.link(o);me.materials.append(bg)
for row,title in enumerate(['MARTELOS','PAS E FORCADOS','ESCUDOS','UTILITARIOS']):label(title,-9.5,10.20-row*4,.28,white)
for e in items:
    x=-8.25+e['column']*3.3;y=8.5-e['row']*4
    label(e['label'],x-1.05,y-1.47,.17,white);label(e['item_id'],x-1.05,y-1.69,.105,muted)
label('23 MODELOS / PECAS SEPARADAS / ACABAMENTO NAS DUAS FACES',-9.5,-5.7,.14,muted)
cd=bpy.data.cameras.new('Tools_Camera');cam=bpy.data.objects.new(cd.name,cd);stage.objects.link(cam)
cam.location=(0,-.9,28);target=Vector((0,2.65,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();enum(cd,'type','ORTHO');cd.ortho_scale=21.5;scene.camera=cam
for name,loc,power,size in [('Key',(-8,9,16),2300,11),('Fill',(8,0,14),1400,10)]:
    d=bpy.data.lights.new('Tools_'+name,'AREA');o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
w=bpy.data.worlds.new('Tools_World');w.use_nodes=True;n=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');n.inputs['Color'].default_value=(.4,.4,.4,1);n.inputs['Strength'].default_value=.6;scene.world=w
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    choices=re.findall(r"'([^']+)'",str(e));s=next((c for c in choices if c.lower()=='standard'),None)
    if s:scene.view_settings.view_transform=s
scene.render.resolution_x=2400;scene.render.resolution_y=2000;scene.render.resolution_percentage=100
enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'ferramentas-preview.png')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False;sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
with open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8') as f:json.dump({'reference':'https://starveiopro.fandom.com/wiki/Items','existing_assets_unchanged':True,'models':manifest},f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=source)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'tools-session.blend'),copy=True)
print(json.dumps([{'id':m['item_id'],'triangles':m['triangles'],'parts':len(m['parts'])} for m in manifest]))
