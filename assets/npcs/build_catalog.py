"""Build the Starve-inspired 2.5D NPC collection in the approved rabbit blend.
Run inside Blender. Existing scenes, including the approved rabbit, are preserved.
All model parts are closed meshes, Z up and facing -Y. No external textures.
"""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector

BASE = Path(r'C:\Users\Elize\Desktop\Roblox\starve')
PREVIEW = BASE / 'build/previews'
TAU = math.tau
if bpy.data.scenes.get('NPC_Catalog_23'):
    raise RuntimeError('The catalog already exists. Edit its meshes directly; rebuild only in a separate working copy.')
scene = bpy.data.scenes.new('NPC_Catalog_23')
bpy.context.window.scene = scene
library = bpy.data.collections.new('NPCS | 23 models')
stage = bpy.data.collections.new('STUDIO | cameras lights labels')
scene.collection.children.link(library)
scene.collection.children.link(stage)
groups = {}
catalog = []

def material(name, color):
    name = 'NPC | ' + name
    if bpy.data.materials.get(name): return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    def lin(v): return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    rgba = (*[lin(int(color[i:i+2],16)/255) for i in (0,2,4)],1)
    m.diffuse_color = rgba
    m.use_nodes = True
    n = next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value = rgba
    n.inputs['Roughness'].default_value = .83
    n.inputs['Specular IOR Level'].default_value = .12
    return m

P = {k:material(k,c) for k,c in {
 'ivory':'FFF4EC','ink':'191C29','white':'FFFFFF','hostile':'B63B58',
 'charcoal':'34303C','gray':'817B8B','pink':'EAB0C1','snow':'E3F3F4',
 'ice':'AACFD8','brown':'80543B','fur':'4C332E','tan':'AD7951',
 'beak':'F4AB54','teal':'78C9CB','teal_dark':'2E727D','mint':'BAE8E4',
 'orange':'EF794F','crab':'E95535','red':'C4404E','dark_red':'792E3D',
 'purple':'44357B','violet':'7C63C4','sucker':'AC8BE6','lava':'4E282C',
 'lava_mid':'75403B','flame':'F39332','gold':'FFD657','gold_dark':'DAA421',
 'cream':'FFF0AD','sand':'B87558','sand_dark':'713C36',
 'stage':'45635F','label':'ECF2DF','label_dim':'B4CDC1'}.items()}

def ellipse(rx=1,ry=1,n=32):
    return [(rx*math.cos(TAU*i/n),ry*math.sin(TAU*i/n)) for i in range(n)]

def smooth(poly, passes=1):
    for _ in range(passes):
        poly=[p for a,b in zip(poly,poly[1:]+poly[:1]) for p in
              [(.75*a[0]+.25*b[0],.75*a[1]+.25*b[1]),(.25*a[0]+.75*b[0],.25*a[1]+.75*b[1])]]
    return poly

def mesh_object(name,verts,faces,col,mat,parent=None):
    me=bpy.data.meshes.new(name)
    me.from_pydata(verts,[],faces); me.update()
    bm=bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new(name,me); col.objects.link(ob)
    if mat: me.materials.append(mat)
    ob.parent=parent
    for f in me.polygons: f.use_smooth=len(f.vertices)==4
    return ob

class NPC:
    def __init__(self,key,label,biome,boss=False):
        self.key,self.label,self.biome=key,label,biome
        if biome not in groups:
            groups[biome]=bpy.data.collections.new(biome); library.children.link(groups[biome])
        self.col=bpy.data.collections.new(key+' | '+label); groups[biome].children.link(self.col)
        self.root=bpy.data.objects.new(key+'_ROOT',None); self.col.objects.link(self.root)
        self.root['npc_id']=key; self.root['front_axis']='-Y'; self.root['up_axis']='Z'
        self.root['status']='Static visual asset; animation and Roblox integration pending'
        self.root['reference']='https://starveiopro.fandom.com/wiki/'+key.replace(' ','_')
        self.root['boss']=boss
        catalog.append(self)
    def shape(self,name,poly,color,z=.16,h=.5,xy=(0,0),angle=0,bevel=.06):
        area=sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(poly,poly[1:]+poly[:1]))
        if area<0: poly=list(reversed(poly))
        cx=sum(p[0] for p in poly)/len(poly); cy=sum(p[1] for p in poly)/len(poly)
        b=min(bevel,h*.35); f=.94 if b else 1
        rings=[(f,z),(1,z+b),(1,z+h-b),(f,z+h)] if b else [(1,z),(1,z+h)]
        ca,sa=math.cos(angle),math.sin(angle); verts=[]
        for sc,zz in rings:
            for x,y in poly:
                x,y=cx+(x-cx)*sc,cy+(y-cy)*sc
                verts.append((xy[0]+ca*x-sa*y,xy[1]+sa*x+ca*y,zz))
        n=len(poly); faces=[tuple(reversed(range(n)))]
        for j in range(len(rings)-1):
            for i in range(n):
                k=(i+1)%n; faces.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
        faces.append(tuple((len(rings)-1)*n+i for i in range(n)))
        return mesh_object(self.key+'__'+name,verts,faces,self.col,P[color],self.root)
    def disc(self,name,rx,ry,color,xy=(0,0),z=.75,h=.04,n=24):
        return self.shape(name,ellipse(rx,ry,n),color,z,h,xy,bevel=min(.02,h*.3))
    def layered(self,name,poly,color,rim='ivory',z=.12,h=.65,xy=(0,0),angle=0):
        self.shape(name+'_rim',poly,rim,z,h,xy,angle)
        cx=sum(x for x,y in poly)/len(poly); cy=sum(y for x,y in poly)/len(poly)
        inner=[(cx+(x-cx)*.88,cy+(y-cy)*.88) for x,y in poly]
        self.shape(name+'_color',inner,color,z+h-.005,.05,xy,angle,bevel=.012)
    def eyes(self,x=.44,y=-.38,z=.84,r=.23,hostile=False):
        for s in [-1,1]:
            self.disc('eye',r,r,'hostile' if hostile else 'ink',(s*x,y),z,.045)
            self.disc('sparkle',r*.31,r*.31,'white',(s*x-r*.27,y+r*.33),z+.046,.014,n=16)
    def stroke(self,name,points,widths,color,z=.16,h=.23):
        # A tapered planar ribbon with closed ends, suitable for legs and tentacles.
        left=[]; right=[]
        for i,(p,w) in enumerate(zip(points,widths)):
            a=Vector(points[max(i-1,0)]); b=Vector(points[min(i+1,len(points)-1)])
            d=(b-a).normalized(); normal=Vector((-d.y,d.x))
            left.append(tuple(Vector(p)+normal*w)); right.append(tuple(Vector(p)-normal*w))
        self.shape(name,left+list(reversed(right)),color,z,h,bevel=.025)

# The approved rabbit is copied without changing its geometry or materials.
rabbit=NPC('Rabbit','Coelho','01 FLORESTA')
original=bpy.data.collections['RABBIT | editable meshes']
for old in original.objects:
    if old.type=='MESH':
        ob=old.copy(); ob.data=old.data.copy(); ob.name='Rabbit__'+old.name
        rabbit.col.objects.link(ob); ob.parent=rabbit.root

def canine(key,label,biome,arctic=False):
    n=NPC(key,label,biome)
    poly=[(0,-1.25),(.28,-1.08),(.62,-.48),(1.08,-.22),(.92,-.02),(1.13,.15),(.94,.28),(1.12,.45),(.80,.55),(.78,1.18),(.60,1.33),(.29,.91),(0,1.02)]
    poly=poly+[(-x,y) for x,y in reversed(poly[1:-1])]
    n.layered('head',smooth(poly), 'snow' if arctic else 'charcoal','hostile',h=.69)
    for s in [-1,1]:
        n.shape('inner_ear',smooth([(s*.43,.83),(s*.65,1.14),(s*.70,.70)]),'ink' if arctic else 'gray',.865,.025)
    if not arctic:
        n.shape('muzzle',smooth([(-.58,-.12),(-.30,-.28),(0,-.98),(.30,-.28),(.58,-.12),(.64,-.45),(0,-1.11),(-.64,-.45)]),'gray',.865,.03)
    n.eyes(.39,-.28,.905,.18,True)
    n.disc('nose',.16,.11,'ink',(0,-1.01),.91)
    return n

canine('Wolf','Lobo','01 FLORESTA')
n=NPC('Spider','Aranha','01 FLORESTA')
for s in [-1,1]:
    for i in range(4):
        p=[(s*.55,.35-i*.25),(s*(1.13+i*.08),.92-i*.48),(s*(1.54+i*.03),1.22-i*.78)]
        n.stroke('leg_border',p,[.14,.13,.08],'hostile',.12,.26)
        n.stroke('leg',p,[.085,.075,.035],'ink',.37,.06)
n.layered('abdomen',ellipse(.9,1.05),'ink','hostile',xy=(0,.17),h=.59)
n.layered('head',ellipse(.46,.43),'ink','hostile',xy=(0,-.83),z=.3,h=.4)
n.shape('red_mark',[(0,1.00),(.25,.74),(.12,.49),(.32,.19),(0,-.13),(-.32,.19),(-.12,.49),(-.25,.74)],'hostile',.77,.04)
n.eyes(.19,-.92,.78,.10,True)

n=NPC('Boar','Javali','01 FLORESTA')
n.layered('back',ellipse(.73,1.15),'fur',xy=(0,.60),h=.5)
n.layered('head',ellipse(.94,.89),'brown',xy=(0,-.45),h=.7)
for s in [-1,1]:
    n.layered('ear',smooth([(s*.55,.12),(s*1.02,.62),(s*1.15,.15),(s*.78,-.2)]),'pink',z=.3,h=.39)
    n.shape('tusk',smooth([(s*.55,-.77),(s*.74,-1.13),(s*.80,-.98),(s*.71,-.50)]),'ivory',.81,.13)
n.shape('mane',[(-.5,.81),(-.3,1.35),(0,1.5),(.33,1.28),(.50,.81),(.35,.86),(.32,.24),(.1,.44),(0,.07),(-.14,.43),(-.35,.21),(-.3,.82)],'fur',.83,.07)
n.disc('snout',.42,.23,'pink',(0,-1.02),.86,.1)
for s in [-1,1]: n.disc('nostril',.09,.055,'dark_red',(s*.19,-1.04),.97)
n.eyes(.38,-.45,.91,.20)

def bird(key,label,biome,kind='hawk'):
    n=NPC(key,label,biome)
    gold=kind in ['hen','chick']; vulture=kind=='vulture'; chick=kind=='chick'
    color='gold' if gold else ('charcoal' if vulture else 'brown')
    edge='hostile' if vulture else 'ivory'
    n.layered('body',ellipse(.83,1.10),color,edge,xy=(0,.27),h=.59)
    for s in [-1,1]:
        for j in range(4 if gold else 3):
            x=s*(.25+.19*j); yy=1.04+(.22 if j==1 else .1)
            n.layered('feather',ellipse(.16,.65,20),'cream' if gold else ('ivory' if vulture else 'fur'),edge,z=.16,h=.28,xy=(x,yy),angle=-s*(.10+j*.12))
        n.layered('wing',ellipse(.31,.79,24),'gold_dark' if gold else ('charcoal' if vulture else 'tan'),edge,z=.26,h=.39,xy=(s*.73,.39),angle=-s*.28)
    n.layered('head',ellipse(.57,.58),'gold' if gold else ('red' if vulture else 'brown'),edge,xy=(0,-.83),z=.24,h=.59)
    n.shape('beak',smooth([(-.21,-1.20),(0,-1.63),(.21,-1.20)]),'gold_dark' if gold else ('ivory' if vulture else 'ice'),.85,.10)
    n.eyes(.28,-.95,.90,.205,vulture)
    if chick:
        for ob in n.col.objects:
            if ob.type=='MESH':
                for v in ob.data.vertices: v.co*=.68
    return n

bird('Hawk','Falcão','01 FLORESTA')
n=NPC('Penguin','Pinguim','02 NEVE')
for s in [-1,1]: n.layered('flipper',ellipse(.22,.58),'charcoal',z=.17,h=.35,xy=(s*.78,.10),angle=-s*.5)
n.layered('body',ellipse(.79,.92),'charcoal',h=.61)
for s in [-1,1]: n.disc('face_patch',.36,.39,'snow',(s*.32,-.41),.80,.04)
n.eyes(.32,-.43,.85,.24)
n.shape('beak',smooth([(-.18,-.67),(0,-1.02),(.18,-.67)]),'beak',.87,.10)
canine('Arctic Fox','Raposa ártica','02 NEVE',True)
n=NPC('Polar Bear','Urso polar','02 NEVE')
for s in [-1,1]:
    n.layered('ear',ellipse(.36,.36),'snow','hostile',xy=(s*.79,.82),h=.58)
    n.disc('ear_inner',.21,.20,'ink',(s*.79,.84),.76)
n.layered('head',ellipse(1.08,1.03),'snow','hostile',h=.76)
n.layered('muzzle',ellipse(.35,.64),'ivory','snow',z=.5,h=.44,xy=(0,-.79))
n.eyes(.43,-.18,.94,.17,True)
n.disc('nose',.18,.12,'ink',(0,-1.10),1.0)

def mammoth(key,label,baby):
    n=NPC(key,label,'02 NEVE',not baby)
    edge='ivory' if baby else 'hostile'
    for s in [-1,1]:
        n.layered('ear',ellipse(.65,.50),'brown',edge,xy=(s*.89,.13),h=.53)
        if baby:
            poly=[(s*.40,-.44),(s*.67,-.89),(s*.85,-.92),(s*.72,-.68),(s*.68,-.40)]
        else:
            poly=[(s*.38,-.51),(s*.43,-1.03),(s*.73,-1.35),(s*1.18,-1.37),(s*1.56,-1.09),(s*1.68,-.66),(s*1.50,-.37),(s*1.25,-.28),(s*1.43,-.63),(s*1.33,-.95),(s*1.05,-1.04),(s*.81,-.88),(s*.72,-.48)]
        n.shape('tusk',smooth(poly),'ivory',.60,.2)
    n.layered('head',ellipse(.88,1.01),'brown',edge,h=.72)
    n.layered('trunk',smooth([(-.31,-.28),(-.29,-1.29),(-.16,-1.43),(.21,-1.43),(.30,-1.23),(.32,-.28)]),'brown',edge,z=.40,h=.47)
    for yy in [-.62,-.87,-1.10]: n.disc('trunk_crease',.21,.025,'tan',(0,yy),.93,.025,n=16)
    n.shape('fringe',[(-.74,.39),(-.58,.90),(.56,.90),(.74,.39),(.53,.54),(.46,.25),(.27,.47),(.15,.23),(0,.47),(-.14,.23),(-.29,.49),(-.46,.28),(-.55,.52)],'fur',.90,.05)
    n.eyes(.38,-.24,.94,.20 if baby else .14,not baby)
    if not baby:
        for ob in n.col.objects:
            if ob.type=='MESH':
                for v in ob.data.vertices: v.co*=1.2
    return n
mammoth('Baby Mammoth','Mamute filhote',True)
mammoth('Mammoth','Mamute',False)

def dragon(key,label,baby,lava=False):
    n=NPC(key,label,'04 LAVA' if lava else '02 NEVE',not baby)
    edge='ivory' if baby else 'hostile'; col='lava' if lava else 'teal'
    accent='ivory' if lava else 'mint'
    n.layered('tail',smooth([(-.30,.8),(-.34,1.70),(-.12,2.12),(0,1.90),(.18,2.12),(.36,1.68),(.28,.8)]),col,edge,h=.40)
    n.layered('body',ellipse(.97,1.18),col,edge,xy=(0,.26),h=.67)
    if not baby:
        for s in [-1,1]:
            wing=[(s*.64,-.11),(s*1.36,.06),(s*1.75,.69),(s*1.65,1.50),(s*1.38,.91),(s*.92,.58)]
            n.layered('wing',smooth(wing),'lava_mid' if lava else 'teal_dark',edge,z=.37,h=.28)
            mem=[(s*.94,.34),(s*1.56,1.18),(s*1.50,.63),(s*1.22,.53),(s*1.43,.43),(s*1.20,.20)]
            n.shape('wing_membrane',mem,'tan' if lava else 'mint',.72,.025)
    n.layered('head',ellipse(.69,.65),col,edge,z=.35,h=.48,xy=(0,-.86))
    n.layered('snout',ellipse(.46,.29),col,edge,z=.54,h=.33,xy=(0,-1.25))
    n.disc('spine_stripe',.22,1.08,'lava_mid' if lava else 'mint',(0,.47),.84,.035)
    for i in range(5):
        y=-.13+i*.40; w=.16-i*.017
        n.shape('spine',smooth([(-w,y-.07),(0,y+.22),(w,y-.07)]),accent,.90,.10)
    for s in [-1,1]:
        n.disc('nostril',.055,.08,'lava_mid' if lava else 'teal_dark',(s*.23,-1.27),.93)
        if not baby:
            n.shape('horn',smooth([(s*.46,-.65),(s*1.04,-.48),(s*.72,-.27)]),accent,.89,.2)
            for i in range(2):
                x=s*(.20+i*.22)
                n.shape('tooth',[(x-.06,-1.32),(x,-1.50),(x+.06,-1.32)],'ivory',.94,.08)
    n.eyes(.38,-.80,.94,.24 if baby else .17,not baby)
    if baby:
        for s in [-1,1]: n.disc('extra_sparkle',.045,.045,'white',(s*.38+.09,-.88),1.01,.012,n=12)
    return n
dragon('Baby Dragon','Dragão filhote',True)
dragon('Dragon','Dragão',False)

def crab(key,label,king=False):
    n=NPC(key,label,'03 PRAIA E OCEANO',king)
    for s in [-1,1]:
        for i in range(3):
            p=[(s*.63,.40-i*.30),(s*1.13,.68-i*.42),(s*1.27,.94-i*.65)]
            n.stroke('leg_rim',p,[.17,.17,.10],'ivory',.12,.24)
            n.stroke('leg',p,[.11,.11,.06],'crab',.37,.04)
        claw=[(math.cos(t)*.46,math.sin(t)*.46) for t in [math.radians(35)+i*math.radians(290)/24 for i in range(25)]]+[(0,0)]
        n.layered('claw',claw,'crab','ivory',xy=(s*.98,-1.04),z=.13,h=.46,angle=math.pi if s==1 else 0)
    n.layered('shell',ellipse(.94,.79),'crab','ivory',h=.63)
    if king:
        n.disc('shell_crest',.30,.66,'orange',(0,.1),.84,.06)
        for s in [-1,1]:
            for y in [.0,.35,.64]: n.shape('shell_spike',[(s*.77,y-.12),(s*1.13,y),(s*.77,y+.12)],'orange',.65,.18)
    n.eyes(.40,-.34,.85,.22)
    if king:
        for ob in n.col.objects:
            if ob.type=='MESH':
                for v in ob.data.vertices: v.co*=1.24
    return n
crab('Crab','Caranguejo'); crab('King Crab','Caranguejo-rei',True)

n=NPC('GMO Piranha','Piranha GMO','03 PRAIA E OCEANO')
n.layered('tail',smooth([(-.17,.70),(-.37,1.52),(-.06,1.30),(.21,1.75),(.35,1.50),(.16,.70)]),'red','hostile',h=.35)
for s in [-1,1]: n.layered('fin',smooth([(s*.57,-.3),(s*1.14,.35),(s*1.29,.20),(s*.94,-.63)]),'red','hostile',h=.36)
n.layered('body',ellipse(.77,1.0),'red','hostile',h=.61)
n.shape('dorsal_fin',smooth([(-.13,.1),(0,1.1),(.17,.12),(0,.30)]),'dark_red',.83,.23)
n.disc('mouth',.49,.24,'ink',(0,-.67),.82,.03)
for i in range(7):
    x=-.38+i*.126
    n.shape('tooth',[(x-.048,-.53),(x,-.76),(x+.048,-.53)],'ivory',.86,.055)
n.eyes(.46,-.34,.88,.14,True)

n=NPC('Kraken','Kraken','03 PRAIA E OCEANO',True)
for i in range(8):
    a=i*TAU/8; ca,sa=math.cos(a),math.sin(a)
    def rot(x,y): return (ca*x-sa*y,sa*x+ca*y)
    pts=[rot(.55,0),rot(1.1,.12),rot(1.5,.33),rot(1.72,.60),rot(1.82,.87)]
    n.stroke('arm_rim',pts,[.32,.33,.25,.14,.015],'hostile',.12,.29)
    n.stroke('arm',pts,[.26,.26,.19,.09,.009],'purple',.42,.10)
    for x,y,r in [(1.04,.12,.14),(1.35,.25,.10),(1.59,.44,.07)]:
        n.disc('sucker',r,r,'violet',rot(x,y),.54,.04,n=16)
n.layered('mantle',ellipse(.94,.96),'purple','hostile',h=.62)
n.disc('mouth_rim',.35,.35,'violet',(0,-.20),.82,.08)
n.disc('mouth',.26,.26,'ink',(0,-.20),.91,.025)
for i in range(10):
    a=i*TAU/10
    n.shape('tooth',[(.26*math.cos(a-.15),-.20+.26*math.sin(a-.15)),(.12*math.cos(a),-.20+.12*math.sin(a)),(.26*math.cos(a+.15),-.20+.26*math.sin(a+.15))],'mint',.945,.04)
n.eyes(.55,.18,.87,.125,True)

n=NPC('Lava Monster','Monstro de lava','04 LAVA')
flame=smooth([(0,1.68),(.70,.88),(1.00,.05),(.86,-.69),(.45,-1.04),(-.45,-1.04),(-.86,-.69),(-1.00,.05),(-.70,.88)],2)
n.layered('outer_flame',flame,'flame','hostile',h=.65)
n.shape('inner_flame',[(x*.76,y*.77-.15) for x,y in flame],'gold',.83,.07)
n.disc('skull',.61,.68,'cream',(0,-.36),.93,.08)
n.eyes(.27,-.30,1.04,.19,True)
for i in range(5):
    x=(i-2)*.14
    n.shape('grin',[(x-.045,-.62),(x+.045,-.62),(x+.04,-.83),(x-.04,-.80)],'dark_red',1.04,.025)
dragon('Baby Lava Dragon','Dragão de lava filhote',True,True)
dragon('Lava Dragon','Dragão de lava',False,True)
bird('Vulture','Abutre','05 DESERTO','vulture')

n=NPC('Sandworm','Verme da areia','05 DESERTO',True)
for i in range(4):
    a=i*TAU/4
    petal=smooth([(-.51,.34),(-.92,1.45),(0,1.22),(.92,1.45),(.51,.34)])
    n.layered('outer_jaw',petal,'sand_dark','hostile',z=.12,h=.46,angle=a)
    inner=[(-.66,.23),(0,1.68),(.66,.23)]
    n.shape('jaw',smooth(inner),'sand',.64,.19,angle=a)
    for s in [-1,1]:
        for j in range(4):
            y=.47+j*.21; x=s*(.49-j*.085)
            tooth=[(x-.065,y-.08),(x+.065,y+.08),(x+s*.24,y+.06)]
            n.shape('jaw_tooth',tooth,'ivory',.84,.09,angle=a)
    for j in range(3):
        v=Vector((.18*(-1 if j%2 else 1),.65+j*.21)); xx=math.cos(a)*v.x-math.sin(a)*v.y; yy=math.sin(a)*v.x+math.cos(a)*v.y
        n.disc('scale',.075,.075,'brown',(xx,yy),.86,.025,n=12)
n.disc('maw_rim',.63,.63,'pink',(0,0),.84,.08)
n.disc('maw',.50,.50,'ink',(0,0),.93,.035)
for i in range(14):
    a=TAU*i/14
    n.shape('inner_tooth',[(.50*math.cos(a-.13),.50*math.sin(a-.13)),(.28*math.cos(a),.28*math.sin(a)),(.50*math.cos(a+.13),.50*math.sin(a+.13))],'ivory',.97,.07)

bird('Golden Hen','Galinha dourada','06 DOURADOS','hen')
bird('Golden Chick','Pintinho dourado','06 DOURADOS','chick')

# Raised feather rows give each bird a readable wing pattern at game scale.
for n in catalog:
    if n.key in ['Hawk','Vulture','Golden Hen','Golden Chick']:
        small=.68 if n.key=='Golden Chick' else 1.0
        colors={'Hawk':('fur','tan'),'Vulture':('gray','charcoal'),'Golden Hen':('gold_dark','gold'),'Golden Chick':('gold_dark','gold')}
        dark,light=colors[n.key]
        for s in [-1,1]:
            for j in range(3):
                ob=n.shape('upper_wing_feather',ellipse(.14,.57,20),dark,.84,.045,(s*(.28+j*.16),.42+j*.06),-s*(.10+j*.08),bevel=.012)
                if small!=1:
                    for v in ob.data.vertices: v.co*=small
            for j in range(3):
                ob=n.disc('shoulder_feather',.14,.24,light,(s*(.21+j*.14),-.06+j*.09),.90,.035,n=20)
                if small!=1:
                    for v in ob.data.vertices: v.co*=small

def stage_obj(name,data):
    o=bpy.data.objects.new(name,data); stage.objects.link(o); return o

def text_obj(body,xy,size=.30,color='label'):
    cu=bpy.data.curves.new('Label '+body,'FONT'); cu.body=body; cu.size=size; cu.align_x='CENTER'
    ob=stage_obj('Label '+body,cu); ob.location=(*xy,.025); cu.materials.append(P[color]); return ob

for index,n in enumerate(catalog):
    x=(index%5-2)*6; y=(2-index//5)*6
    n.root.location=(x,y,0)
    text_obj(n.label,(x,y-2.32),.33)
    text_obj(n.key.upper(),(x,y-2.76),.17,'label_dim')

text_obj('EMBER WILDS',(0,16.15),.8)
text_obj('23 NPCs  /  COLEÇÃO 2.5D',(0,15.35),.30,'label_dim')
text_obj('MODELOS ESTÁTICOS  •  FRENTE -Y  •  PARTES EDITÁVEIS',(0,-16.0),.25,'label_dim')
mesh_object('Backdrop',[(-200,-200,-.02),(200,-200,-.02),(200,200,-.02),(-200,200,-.02)],[(0,1,2,3)],stage,P['stage'])
cam=stage_obj('Catalog Camera',bpy.data.cameras.new('Catalog Camera'))
cam.data.type=next(i.identifier for i in cam.data.bl_rna.properties['type'].enum_items if i.identifier=='ORTHO')
cam.data.ortho_scale=36.5
target=Vector((0,0,.1)); cam.location=(0,-22,51)
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler(); scene.camera=cam
for name,pos,power,size in [('Catalog Key',(-10,-10,24),12500,20),('Catalog Fill',(14,12,18),8000,18)]:
    lt=stage_obj(name,bpy.data.lights.new(name,'AREA')); lt.location=pos; lt.data.energy=power; lt.data.size=size
    lt.rotation_euler=(Vector((0,0,0))-lt.location).to_track_quat('-Z','Y').to_euler()
scene.world=bpy.data.worlds['Rabbit_preview_world'].copy()
scene.render.resolution_x=2500; scene.render.resolution_y=2700; scene.render.resolution_percentage=100
scene.render.image_settings.file_format=next(i.identifier for i in scene.render.image_settings.bl_rna.properties['file_format'].enum_items if i.identifier=='PNG')
scene.render.filepath=str(PREVIEW/'npcs-colecao-v1.png')
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA'
        area.spaces.active.overlay.show_overlays=False
        area.spaces.active.shading.color_type=next(i.identifier for i in area.spaces.active.shading.bl_rna.properties['color_type'].enum_items if i.identifier=='MATERIAL')
print('Created',len(catalog),'NPCs in',scene.name)
