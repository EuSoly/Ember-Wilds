"""Create the 18 approved utility structures in a new, editable Blender scene."""
import bpy, bmesh, math, os, json, hashlib, re
from mathutils import Vector, Matrix

BASE=os.path.dirname(os.path.abspath(__file__))
NAME='Structures_Catalog_18'
assert NAME not in bpy.data.scenes, 'Do not overwrite an existing editable catalog'
os.makedirs(BASE,exist_ok=True)
original_objects=list(bpy.data.objects)
def fingerprint():
    h=hashlib.sha256()
    for o in original_objects:
        h.update(repr((o.name,tuple(map(tuple,o.matrix_world)),[c.name for c in o.users_collection])).encode())
        if o.type=='MESH':
            h.update(repr(([tuple(v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons],[m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()
before=fingerprint()
source_file=bpy.data.filepath
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'before-structures.blend'),copy=True)
scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
catalog=bpy.data.collections.new('Utility_Structures');scene.collection.children.link(catalog)
groups={}
for k in ['Extractors','Fire_Structures','Misc_Structures']:
    groups[k]=bpy.data.collections.new(k);catalog.children.link(groups[k])
stage=bpy.data.collections.new('Structures_Presentation');scene.collection.children.link(stage);stage.hide_select=True

def enum(o,p,v):
    setattr(o,p,next(e.identifier for e in o.bl_rna.properties[p].enum_items if e.identifier==v))
def material(name,h,emission=0):
    def lin(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    rgba=tuple(lin(int(h[i:i+2],16)/255) for i in [0,2,4])+(1,)
    m=bpy.data.materials.new('Structure_'+name);m.use_nodes=True;m.diffuse_color=rgba
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=rgba;n.inputs['Roughness'].default_value=.78
    if emission:
        n.inputs['Emission Color'].default_value=rgba;n.inputs['Emission Strength'].default_value=emission
    return m
P={}
for name,colors in {
 'wood':['79502F','AA7748','4A3323'], 'wood_light':['A47B50','C99B66','785735'],
 'stone':['778185','AFB9B8','46545A'], 'gold':['ACA440','E8D578','645E2B'],
 'diamond':['40B8CF','A7F3F5','195F73'], 'amethyst':['AC60CC','DCA7EE','623375'],
 'reidite':['9C4157','D37A91','54283D'], 'steel':['36434A','71848B','202D34'],
 'brass':['B69B51','E4C880','705C2F'], 'cream':['D8D0A4','F2EAD0','ADA47D'],
 'purple':['8356A8','B182D3','5C377E'], 'emerald':['43BA6D','99E9AD','237448'],
 'water':['3C8FA2','78C1CD','245B70'], 'coal':['302C2A','594239','1D2226'],
 'flame':['EF801D','FFD867','BD441C'], 'glow':['81DCF1','C4FAFF','3BA7BD']}.items():
    P[name]=[material(name+'_'+str(i),h,.35 if name in ['flame','glow'] else 0) for i,h in enumerate(colors)]
records=[];meshes=[]

def item(name,category,x,y,label):
    global ID,COL,ROOT
    ID=name;assert name not in bpy.data.collections
    COL=bpy.data.collections.new(name);groups[category].children.link(COL)
    ROOT=bpy.data.objects.new(name+'_root',None);COL.objects.link(ROOT);ROOT.location=(x,y,0);ROOT.empty_display_size=.12
    ROOT['item_id']=name;ROOT['category']=category;ROOT['pivot']='ground_center';ROOT['reference']='https://starveiopro.fandom.com/wiki/Structures'
    records.append({'item_id':name,'category':category,'label':label,'gallery_position':[x,y,0]})

def empty(part,loc=(0,0,0),parent=None):
    o=bpy.data.objects.new(ID+'_'+part,None);COL.objects.link(o);o.parent=parent or ROOT;o.location=loc;o.empty_display_size=.10;o['item_id']=ID;o['part']=part
    return o

def mesh(part,verts,faces,pal,ids=None,parent=None):
    name=ID+'_'+part;assert name not in bpy.data.objects,name
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    for m in pal:me.materials.append(m)
    for i,f in enumerate(me.polygons):f.material_index=(ids or [0])[i%len(ids or [0])]
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);COL.objects.link(ob);ob.parent=parent or ROOT;ob['item_id']=ID;ob['part']=part
    meshes.append(ob);return ob

def polygon_prism(part,points,z0,z1,pal,parent=None):
    n=len(points);v=[(x,y,z) for z in [z0,z1] for x,y in points]
    f=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(part,v,f,pal,[2,0]+[1 if i%4==0 else 0 if i%4==1 else 2 for i in range(n)],parent)

def box(part,center,size,pal,bevel=.035,parent=None):
    x,y,z=center;hx,hy,hz=[s*.5 for s in size];b=min(bevel,hx*.3,hy*.3,hz*.6)
    pts=[(-hx+b,-hy),(hx-b,-hy),(hx,-hy+b),(hx,hy-b),(hx-b,hy),(-hx+b,hy),(-hx,hy-b),(-hx,-hy+b)]
    ob=polygon_prism(part,pts,-hz,hz,pal,parent);ob.location=(x,y,z);return ob

def lathe(part,profile,pal,n=12,center=(0,0,0),parent=None,phase=0):
    # Profile is a closed cross-section; radius zero is a single pole.
    v=[];loops=[];faces=[];ids=[]
    for r,z in profile:
        if abs(r)<1e-7:
            loops.append([len(v)]);v.append((center[0],center[1],center[2]+z))
        else:
            loops.append(list(range(len(v),len(v)+n)))
            v.extend([(center[0]+r*math.cos(2*math.pi*i/n+phase),center[1]+r*math.sin(2*math.pi*i/n+phase),center[2]+z) for i in range(n)])
    for j,a in enumerate(loops):
        b=loops[(j+1)%len(loops)]
        if len(a)==1 and len(b)==1:continue
        for i in range(n):
            k=(i+1)%n
            if len(a)==1:f=(a[0],b[i],b[k])
            elif len(b)==1:f=(a[i],b[0],a[k])
            else:f=(a[i],b[i],b[k],a[k])
            faces.append(f);ids.append(1 if j%4==1 else (0 if i%3 else 2))
    return mesh(part,v,faces,pal,ids,parent)

def cyl(part,r,z0,z1,pal,n=12,xy=(0,0),parent=None,r_top=None):
    return lathe(part,[(0,z0),(r,z0),(r if r_top is None else r_top,z1),(0,z1)],pal,n,(xy[0],xy[1],0),parent)

def ring(part,outer,inner,z0,z1,pal,n=12,parent=None):
    return lathe(part,[(outer,z0),(outer,z1),(inner,z1),(inner,z0)],pal,n,parent=parent)

def beam(part,a,b,r,pal,n=8,parent=None,r_end=None):
    av,bv=Vector(a),Vector(b);d=bv-av
    ob=cyl(part,r,0,d.length,pal,n,parent=parent,r_top=r_end)
    ob.location=av;ob.rotation_euler=d.to_track_quat('Z','Y').to_euler();return ob

def gem(part,base,r,height,pal,n=6,parent=None,lean=(0,0)):
    x,y,z=base;v=[(x+r*math.cos(2*math.pi*i/n),y+r*math.sin(2*math.pi*i/n),z) for i in range(n)]
    v.extend([(x+lean[0]*.45+r*.80*math.cos(2*math.pi*i/n),y+lean[1]*.45+r*.80*math.sin(2*math.pi*i/n),z+height*.55) for i in range(n)])
    v.append((x+lean[0],y+lean[1],z+height));f=[tuple(reversed(range(n)))];ids=[2]
    for i in range(n):
        k=(i+1)%n;f.extend([(i,k,k+n,i+n),(i+n,k+n,n*2)]);ids.extend([i%3,(i+1)%3])
    return mesh(part,v,f,pal,ids,parent)

def tube(part,points,r,pal,n=5,parent=None):
    v=[];f=[]
    for j,p in enumerate(points):
        p=Vector(p);prev=Vector(points[max(0,j-1)]);nxt=Vector(points[min(len(points)-1,j+1)]);d=(nxt-prev).normalized()
        u=d.cross(Vector((0,0,1)))
        if u.length<.01:u=Vector((1,0,0))
        else:u.normalize()
        w=d.cross(u).normalized()
        v.extend([tuple(p+r*(u*math.cos(i*2*math.pi/n)+w*math.sin(i*2*math.pi/n))) for i in range(n)])
    f=[tuple(reversed(range(n)))]
    for j in range(len(points)-1):
        for i in range(n):k=(i+1)%n;f.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
    f.append(tuple(range((len(points)-1)*n,len(points)*n)))
    return mesh(part,v,f,pal,[0,1,0,2,0],parent)

def flames(scale=1,z=.25,parent=None):
    holder=empty('flame_anchor',(0,0,z),parent);holder['effect_attachment']='fire';holder['optional_preview_meshes']=True
    for i,(x,y,r,h,dx,dy) in enumerate([(0,0,.52,1.65,.28,.08),(-.43,.04,.30,1.00,-.16,.07),(.38,.04,.28,1.20,.16,-.05),(0,-.32,.32,.92,-.07,-.13)]):
        gem('flame_'+str(i+1),(x*scale,y*scale,0),r*scale,h*scale,P['flame'],5,holder,(dx*scale,dy*scale))
    gem('flame_core',(0,-.30*scale,.03*scale),.27*scale,.80*scale,[P['flame'][1]]*3,5,holder,(.05*scale,0))

# EXTRACTORS: low circular gear housing, spiral rotor, mineral-specific detailing.
tiers=[('stone','PEDRA'),('gold','OURO'),('diamond','DIAMANTE'),('amethyst','AMETISTA'),('reidite','REIDITE')]
for ti,(tier,label) in enumerate(tiers):
    item(tier+'_extractor','Extractors',(ti-2)*7,13,label)
    ROOT['tier']=ti+2;pal=P[tier]
    pts=[]
    for i in range(48):
        a=2*math.pi*i/48;r=1.60 if i%6 in [1,2,3,4] else 1.39;pts.append((r*math.cos(a),r*math.sin(a)))
    polygon_prism('gear_foot',pts,0,.30,P['steel'] if ti==4 else pal)
    lathe('housing',[(0,.23),(1.28,.23),(1.40,.40),(1.40,.96),(1.18,1.18),(.93,1.18),(.93,.85),(0,.85)],pal,12)
    ring('upper_rim',1.25,.91,1.10,1.26,pal,12)
    cyl('rotor_well',.93,.87,.98,P['steel'],16)
    rotor=empty('rotor',(0,0,.98));rotor['animation_axis']='local Z';rotor['motion']='continuous_rotation'
    cyl('rotor_disc',.83,0,.08,pal,16,parent=rotor)
    pts=[]
    for k in range(43):
        t=k/42;a=t*math.pi*4.3;r=.72*(1-t)+.10
        pts.append((r*math.cos(a),r*math.sin(a),.14+.14*t))
    tube('spiral',pts,.065,[pal[1],pal[0],pal[2]],5,rotor)
    cyl('rotor_hub',.13,.08,.30,P['steel'] if ti<2 else pal,8,parent=rotor)
    box('feed_port',(0,-1.34,.58),(.68,.24,.40),P['steel'])
    for j in range(4):
        a=math.pi/4+j*math.pi/2;x,y=1.10*math.cos(a),1.10*math.sin(a)
        cyl('rim_bolt_'+str(j+1),.085,1.20,1.30,P['brass'] if ti==3 else P['steel'],6,(x,y))
    if ti>=2:
        for j in range(4):
            a=j*math.pi/2;x,y=1.28*math.cos(a),1.28*math.sin(a)
            if ti==2:
                gem('crystal_'+str(j+1),(x,y,.55),.18,.70,pal,4,lean=(x*.10,y*.10))
            elif ti==3:
                cyl('crystal_mount_'+str(j+1),.24,.42,.66,P['brass'],8,(x,y))
                gem('crystal_'+str(j+1),(x,y,.60),.21,.94,pal,5,lean=(x*.13,y*.13))
            else:
                ob=box('armor_fin_'+str(j+1),(x,y,.76),(.28,.62,1.18),P['steel']);ob.rotation_euler.z=a
                gem('reidite_fin_'+str(j+1),(x*1.06,y*1.06,.76),.26,1.02,pal,4,lean=(x*.18,y*.18))
        if ti==3:ring('gold_band',1.43,1.35,.45,.57,P['brass'])
        if ti==4:ring('armor_band',1.48,1.34,.34,.49,P['steel'])

# FIRE STRUCTURES: crossed logs and detached low-poly flames; stone furnace.
for large,x in [(False,-7),(True,0)]:
    name='big_fire' if large else 'campfire';item(name,'Fire_Structures',x,5,'FOGUEIRA GRANDE' if large else 'FOGUEIRA')
    s=1.18 if large else .85
    cyl('ember_bed',.79*s,.04,.16,P['coal'],12)
    for j in range(3 if large else 2):
        a=j*math.pi/(3 if large else 2)+.28;d=Vector((math.cos(a),math.sin(a),0))
        start=-d*1.27*s+Vector((0,0,.26));end=d*1.27*s+Vector((0,0,.26))
        beam('log_'+str(j+1),start,end,.21*s,P['wood'],8)
        for k,p in enumerate([start,end]):
            towards=(end-start).normalized()*(1 if k else -1)
            beam('log_end_'+str(j+1)+'_'+str(k+1),p,p+towards*.015,.16*s,P['wood_light'],8)
    flames(s,.33)

item('furnace','Fire_Structures',7,5,'FORNALHA')
lathe('stone_body',[(1.28,0),(1.48,.18),(1.48,1.12),(1.20,1.43),(.76,1.43),(.76,.35),(.0,.35),(.0,0)],P['stone'],8,phase=math.pi/8)
ring('lip',1.24,.74,1.36,1.52,P['stone'],8)
cyl('coal',.73,.36,.46,P['coal'],12)
for j in [-1,0,1]:
    box('grate_bar_'+str(j+2),(j*.37,0,1.51),(.10,1.35,.13),P['steel'])
for j in range(8):
    a=math.pi/8+j*math.pi/4
    ob=box('foot_'+str(j+1),(math.cos(a)*1.17,math.sin(a)*1.17,.15),(.36,.36,.30),P['stone']);ob.rotation_euler.z=a
box('front_vent',(0,-1.40,.65),(.60,.10,.38),P['steel'])
for j in range(3):box('vent_slit_'+str(j+1),(-.18+j*.18,-1.465,.65),(.06,.035,.24),P['flame'])
flames(.53,.42)

# WORKSHOP AND CONSTRUCTION MODULES.
item('workbench','Misc_Structures',-14,-3,'BANCADA')
for ix,x in enumerate([-1.15,1.15]):
    for iy,y in enumerate([-.65,.65]):box('leg_'+str(ix*2+iy+1),(x,y,.78),(.33,.33,1.56),P['wood'])
for j,y in enumerate([-.65,.65]):box('crossbeam_'+str(j+1),(0,y,.44),(2.65,.20,.20),P['wood'])
for j,y in enumerate([-.69,0,.69]):box('top_plank_'+str(j+1),(0,y,1.60),(3.05,.67,.22),P['wood_light'] if j==1 else P['wood'])
polygon_prism('stone_work_surface',[(-1.13,-.65),(.28,-.59),(.50,-.25),(.43,.55),(-.8,.66),(-1.17,.34)],1.72,1.91,P['stone'])
beam('mallet_handle',(.78,-.64,1.79),(.88,.43,1.79),.075,P['wood_light'],6)
box('mallet_head',(.87,.39,1.85),(.56,.27,.25),P['stone'])
beam('chisel',(.07,-.66,1.98),(-.25,-.09,1.98),.055,P['steel'],5)

item('chest','Misc_Structures',-7,-3,'BAU')
box('bottom',(0,0,.13),(2.80,1.95,.26),P['wood'])
for j,y in enumerate([-.91,.91]):box('wall_long_'+str(j+1),(0,y,.83),(2.80,.18,1.14),P['wood'])
for j,x in enumerate([-1.31,1.31]):box('wall_end_'+str(j+1),(x,0,.83),(.18,1.62,1.14),P['wood'])
for j,x in enumerate([-.97,.97]):
    for k,y in enumerate([-.99,.99]):box('strap_body_'+str(j+1)+'_'+str(k+1),(x,y,.77),(.18,.055,1.30),P['brass'])
hinge=empty('lid_hinge',(0,.90,1.42));hinge['animation_axis']='local X';hinge['closed_angle_degrees']=0;hinge['open_angle_degrees']=-105
box('lid_board',(0,-.90,.12),(2.88,2.03,.24),P['wood_light'],parent=hinge)
for j,x in enumerate([-.97,.97]):box('lid_strap_'+str(j+1),(x,-.90,.26),(.20,2.03,.07),P['brass'],parent=hinge)
box('latch',(0,-1.94,-.02),(.35,.09,.48),P['brass'],parent=hinge)
box('keyhole',(0,-2.0,-.05),(.08,.035,.17),P['steel'],parent=hinge)
for j,x in enumerate([-.97,.97]):beam('hinge_pin_'+str(j+1),(x-.17,.97,1.42),(x+.17,.97,1.42),.10,P['brass'])

item('bridge','Misc_Structures',0,-3,'PONTE')
ROOT['module_size']=[4.2,4.2];ROOT['snap_axes']='XY';ROOT['walking_surface_z']=.36
for j,y in enumerate([-1.35,1.35]):box('cross_tie_'+str(j+1),(0,y,.10),(4.12,.32,.20),P['wood'])
for j,x in enumerate([-1.4,0,1.4]):
    box('plank_'+str(j+1),(x,0,.26),(1.30,4.20,.20),P['wood_light'] if j==1 else P['wood'])
    for k,y in enumerate([-1.35,1.35]):
        cyl('peg_'+str(j+1)+'_'+str(k+1),.06,.36,.38,P['wood_light'],6,(x,y))

item('roof','Misc_Structures',7,-3,'TELHADO')
ROOT['module_size']=[4.2,4.2];ROOT['snap_axes']='XY';ROOT['placement_note']='Place above walls; local ground pivot is underside of module'
for j,x in enumerate([-1.45,1.45]):box('batten_'+str(j+1),(x,0,.10),(.24,4.2,.20),P['wood'])
for j,y in enumerate([-1.4,0,1.4]):box('roof_board_'+str(j+1),(0,y,.25+j*.04),(4.20,1.43,.20),P['wood_light'] if j==1 else P['wood'])
for j,y in enumerate([-1.4,0,1.4]):
    for k,x in enumerate([-1.45,1.45]):cyl('peg_'+str(j+1)+'_'+str(k+1),.065,.35+j*.04,.37+j*.04,P['wood_light'],6,(x,y))

item('sign','Misc_Structures',14,-3,'PLACA')
box('post',(0,.10,1.36),(.28,.28,2.72),P['wood'])
for j,z in enumerate([1.62,2.07,2.52]):box('board_'+str(j+1),(0,0,z),(2.90,.20,.43),P['wood_light'] if j==1 else P['wood'])
for j,x in enumerate([-1.17,1.17]):
    box('rear_batten_'+str(j+1),(x,.15,2.07),(.14,.16,1.37),P['wood'])
    for k,z in enumerate([1.62,2.52]):beam('nail_'+str(j+1)+'_'+str(k+1),(x,-.11,z),(x,-.13,z),.055,P['steel'],6)
anchor=empty('text_anchor',(0,-.12,2.07));anchor['surface_gui_face']='front (-Y)';anchor['text_area']=[2.5,1.15]

# SHELTER AND SPECIAL STRUCTURES.
item('well','Misc_Structures',-14,-11,'POCO')
cyl('water',1.14,.12,.16,[P['water'][0]]*3,24)
for row in range(2):
    for j in range(12):
        a=j*2*math.pi/12+row*math.pi/12;da=math.pi/12-.014
        pts=[(r*math.cos(t),r*math.sin(t)) for r,t in [(1.65,a-da),(1.65,a+da),(1.14,a+da),(1.14,a-da)]]
        polygon_prism('stone_'+str(row+1)+'_'+str(j+1).zfill(2),pts,.02+row*.53,.53+row*.53,P['stone'] if j%3 else [P['stone'][1],P['stone'][0],P['stone'][2]])
for j in range(12):
    a=j*math.pi/6;da=math.pi/12-.012
    pts=[(r*math.cos(t),r*math.sin(t)) for r,t in [(1.74,a-da),(1.74,a+da),(1.08,a+da),(1.08,a-da)]]
    polygon_prism('rim_stone_'+str(j+1).zfill(2),pts,1.06,1.27,P['stone'])

item('bed','Misc_Structures',-7,-11,'CAMA')
for j,x in enumerate([-1.27,1.27]):
    for k,y in enumerate([-1.75,1.75]):
        h=1.59 if y>0 else 1.02
        box('post_'+str(j+1)+'_'+str(k+1),(x,y,h*.5),(.24,.24,h),P['wood'])
for j,x in enumerate([-1.25,1.25]):box('rail_'+str(j+1),(x,0,.56),(.23,3.7,.30),P['wood'])
box('slat_base',(0,0,.53),(2.40,3.55,.15),P['wood'])
box('headboard',(0,1.74,1.25),(2.70,.20,.44),P['wood'])
box('footboard',(0,-1.74,.83),(2.70,.20,.28),P['wood'])
box('mattress',(0,0,.82),(2.38,3.39,.38),P['cream'],.12)
box('blanket',(0,-.52,1.03),(2.41,2.16,.14),P['purple'],.07)
box('blanket_fold',(0,.52,1.10),(2.42,.32,.18),P['cream'],.06)
box('pillow',(0,1.12,1.11),(1.79,.68,.24),P['cream'],.10)

item('totem','Misc_Structures',0,-11,'TOTEM')
lathe('base',[(0,0),(1.10,0),(1.18,.18),(.95,.34),(0,.34)],P['wood'],8)
lathe('carved_body',[(0,.25),(.74,.25),(.84,.52),(.84,1.88),(.64,2.15),(0,2.15)],P['wood'],8,phase=math.pi/8)
for side in [-1,1]:
    # Repeated features on both faces keep the asset readable from either side.
    for j,x in enumerate([-.37,.37]):
        ob=cyl('eye_socket_'+str(side)+'_'+str(j+1),.23,0,.10,P['wood_light'],8);ob.location=(x,side*.78,1.40);ob.rotation_euler.x=side*-math.pi/2
        ob=cyl('eye_'+str(side)+'_'+str(j+1),.10,0,.025,P['wood'],8);ob.location=(x,side*.89,1.40);ob.rotation_euler.x=side*-math.pi/2
    box('nose_'+str(side),(0,side*.87,1.10),(.20,.24,.42),P['wood_light'])
    box('mouth_'+str(side),(0,side*.83,.71),(.67,.12,.13),P['wood'])
for j,x in enumerate([-.99,.99]):
    gem('ear_'+str(j+1),(x,0,1.0),.30,.82,P['wood_light'],4)
gem('crown',(0,0,2.08),.35,.42,P['wood_light'],4)

def magic_structure(name,x,label,pal,emerald=False):
    item(name,'Misc_Structures',x,-11,label)
    lathe('pedestal',[(0,0),(1.12,0),(1.45,.20),(1.45,.48),(1.18,.66),(0,.66)],P['stone'] if not emerald else P['steel'],8)
    ring('outer_ring',1.32,.93,.61,.84,pal,8)
    cyl('recess',.93,.60,.70,P['steel'],16)
    ring('inner_ring',.78,.56,.70,.86,[pal[1],pal[0],pal[2]],8)
    for j in range(8):
        a=math.pi/8+j*math.pi/4;x1,y1=1.35*math.cos(a),1.35*math.sin(a)
        gem('outer_crystal_'+str(j+1),(x1,y1,.38),.24,.65 if not emerald else .82,pal,4,lean=(x1*.18,y1*.18))
    core=empty('core_anchor',(0,0,.69));core['effect_attachment']='glow';core['animation_axis']='local Z'
    if emerald:
        gem('core',(0,0,.02),.46,.95,pal,6,core)
        ring('core_setting',.58,.44,.0,.16,P['emerald'],6,parent=core)
    else:
        cyl('energy_core',.49,0,.12,P['glow'],12,parent=core)
        gem('central_crystal',(0,0,.10),.29,.46,P['glow'],6,core)
    for j in range(8):
        a=j*math.pi/4
        ob=box('rune_'+str(j+1),(math.cos(a)*1.10,math.sin(a)*1.10,.86),(.11,.27,.045),[pal[1]]*3);ob.rotation_euler.z=a

magic_structure('resurrection_stone',7,'PEDRA DE RESSURREICAO',P['diamond'])
magic_structure('emerald_machine',14,'MAQUINA DE ESMERALDA',P['emerald'],True)

# Verify all generated solids and preserve every pre-existing mesh and transform.
bpy.context.view_layer.update()
for rec in records:
    col=bpy.data.collections[rec['item_id']];root=bpy.data.objects[rec['item_id']+'_root'];triangles=0;parts=[];bounds=[];bad_edges=0
    for o in col.objects:
        if o.type!='MESH':continue
        assert not o.data.validate(verbose=False),o.name
        bm=bmesh.new();bm.from_mesh(o.data)
        bad=sum(not e.is_manifold for e in bm.edges);bad_edges+=bad
        assert bad==0,(o.name,bad)
        assert all(f.calc_area()>1e-9 for f in bm.faces),o.name
        assert bm.calc_volume()>0,(o.name,'inverted volume')
        bm.free();o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);parts.append(o.name)
        transform=root.matrix_world.inverted()@o.matrix_world
        bounds.extend([transform@v.co for v in o.data.vertices])
    mins=[min(v[i] for v in bounds) for i in range(3)];maxs=[max(v[i] for v in bounds) for i in range(3)]
    assert mins[2]>-.001,(rec['item_id'],mins)
    if mins[2]>1e-6:
        dz=mins[2]
        for child in root.children:child.location.z-=dz
        mins[2]=0;maxs[2]-=dz
    rec.update(parts=parts,triangles=triangles,non_manifold_edges=bad_edges,bounds_min=mins,bounds_max=maxs)
assert len(records)==18
assert fingerprint()==before,'Existing objects were changed'

# Non-selectable presentation only; independent of the model collections.
floor=material('background','263D46');white=material('text','E9F0EA');muted=material('muted','A0BDC2')
def text(body,x,y,size,mat):
    d=bpy.data.curves.new('Structure_Label','FONT');d.body=body;d.size=size
    o=bpy.data.objects.new('label_'+body,d);stage.objects.link(o);o.location=(x,y,.018);d.materials.append(mat)
me=bpy.data.meshes.new('Structure_Backdrop');me.from_pydata([(-90,-90,-.06),(90,-90,-.06),(90,90,-.06),(-90,90,-.06)],[],[(0,1,2,3)])
o=bpy.data.objects.new(me.name,me);stage.objects.link(o);me.materials.append(floor)
text('ESTRUTURAS / UTILIDADES',-17,20,.65,white)
text('18 MODELOS  /  LOW-POLY  /  PECAS SEPARADAS E EDITAVEIS',-17,18.9,.23,muted)
for title,y in [('EXTRATORES',16.6),('FOGUEIRAS / FORNALHA',8.6),('OFICINA / CONSTRUCAO',.6),('ABRIGO / ESPECIAIS',-7.4)]:text(title,-17,y,.34,white)
for r in records:
    x,y,_=r['gallery_position'];text(r['label'],x-2.10,y-2.80,.22,white);text(r['item_id'],x-2.10,y-3.18,.15,muted)
cd=bpy.data.cameras.new('Structures_Camera');cam=bpy.data.objects.new(cd.name,cd);stage.objects.link(cam)
target=Vector((0,1.3,.25));cam.location=(0,-34,61);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();enum(cd,'type','ORTHO');cd.ortho_scale=38.8;scene.camera=cam
for name,loc,power,size in [('Key',(-12,-8,28),6500,16),('Fill',(15,12,23),5000,18)]:
    d=bpy.data.lights.new('Structures_'+name,'AREA');o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
w=bpy.data.worlds.new('Structures_World');w.use_nodes=True;n=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');n.inputs['Color'].default_value=(.38,.38,.38,1);n.inputs['Strength'].default_value=.6;scene.world=w
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    values=re.findall(r"'([^']+)'",str(e));value=next((v for v in values if v.lower()=='standard'),None)
    if value:scene.view_settings.view_transform=value
scene.render.resolution_x=2400;scene.render.resolution_y=2400;scene.render.resolution_percentage=100
enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'structures-preview.png')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False;sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
with open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8') as f:
    json.dump({'reference':'https://starveiopro.fandom.com/wiki/Structures','source_file':source_file,'originals_unchanged':True,'models':records},f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'structures-trabalho.blend'))
print(json.dumps({'created':len(records),'mesh_parts':len(meshes),'triangles':sum(r['triangles'] for r in records),'originals_unchanged':True}))
