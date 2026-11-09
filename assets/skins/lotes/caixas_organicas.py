"""Lote 05 revisado: volumes reconhecíveis no topo e acabamentos nos quatro lados.

Substitui os emblemas simples da primeira versão. Mantém IDs, dimensões de
encaixe e pivô no chão. Peças pequenas usam malhas de baixa resolução.
"""
import math
import bpy
import bmesh
from mathutils import Vector
from skin_lib import mat,ellipse


def mesh(s,verts,faces,color,kind,smooth=False):
    me=bpy.data.meshes.new(kind)
    me.from_pydata([(s.ox+x,s.oy+y,z) for x,y,z in verts],[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    for p in me.polygons:p.use_smooth=smooth
    me.materials.append(mat(color))
    o=bpy.data.objects.new(s._name(kind),me);s.coll.objects.link(o)
    return o


def puff(s,loc,scale,color,kind='SoftVolume'):
    bm=bmesh.new();bmesh.ops.create_uvsphere(bm,u_segments=12,v_segments=8,radius=1)
    bmesh.ops.scale(bm,vec=scale,verts=bm.verts)
    bmesh.ops.translate(bm,vec=(s.ox+loc[0],s.oy+loc[1],loc[2]),verts=bm.verts)
    me=bpy.data.meshes.new(kind);bm.to_mesh(me);bm.free()
    for p in me.polygons:p.use_smooth=True
    o=bpy.data.objects.new(s._name(kind),me);s.coll.objects.link(o);me.materials.append(mat(color))
    return o


def curve(points,steps=4):
    p=[Vector(v) for v in points];out=[]
    for i in range(len(p)-1):
        a,b,c,d=p[max(0,i-1)],p[i],p[i+1],p[min(len(p)-1,i+2)]
        for k in range(steps):
            t=k/steps
            out.append((2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)*.5)
    return out+[p[-1]]


def tube(s,points,radius,color,kind='Stem',end=None,sides=8,steps=4):
    path=curve(points,steps);verts=[]
    for i,p in enumerate(path):
        tangent=(path[min(i+1,len(path)-1)]-path[max(i-1,0)]).normalized()
        axis=Vector((0,0,1)) if abs(tangent.z)<.95 else Vector((0,1,0))
        u=tangent.cross(axis).normalized();v=tangent.cross(u).normalized()
        r=radius+(0 if end is None else end-radius)*i/(len(path)-1)
        for j in range(sides):
            q=p+r*(u*math.cos(j*math.tau/sides)+v*math.sin(j*math.tau/sides));verts.append(tuple(q))
    faces=[tuple(reversed(range(sides)))]
    for i in range(len(path)-1):
        for j in range(sides):
            k=(j+1)%sides;faces.append((i*sides+j,i*sides+k,(i+1)*sides+k,(i+1)*sides+j))
    faces.append(tuple((len(path)-1)*sides+j for j in range(sides)))
    return mesh(s,verts,faces,color,kind,True)


def crystal(s,x,y,z,r,h,color,tilt=(0,0),kind='Crystal',highlight='#D8F7F1'):
    n=6;verts=[]
    for zz,rr,offset in [(z,r,(0,0)),(z+h*.72,r*.82,(tilt[0]*.72,tilt[1]*.72))]:
        verts +=[(x+offset[0]+rr*math.cos(j*math.tau/n),y+offset[1]+rr*math.sin(j*math.tau/n),zz) for j in range(n)]
    verts.append((x+tilt[0],y+tilt[1],z+h))
    faces=[tuple(reversed(range(n)))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]+[(j+n,(j+1)%n+n,12) for j in range(n)]
    o=mesh(s,verts,faces,color,kind)
    o.data.materials.append(mat(highlight))
    for p in o.data.polygons:
        if p.index in (2,8):p.material_index=1
    return o


def lava_ribbon(s,points,width,color):
    path=curve(points);verts=[]
    for i,p in enumerate(path):
        d=path[min(i+1,len(path)-1)]-path[max(i-1,0)]
        n=Vector((-d.y,d.x,0)).normalized()
        w=width*(1-.45*i/(len(path)-1))
        verts.extend([tuple(p+n*w),tuple(p-n*w)])
    top=len(verts);verts +=[(x,y,z-.035) for x,y,z in verts]
    faces=[]
    for i in range(len(path)-1):
        a=i*2;b=a+2
        faces.extend([(a,a+1,b+1,b),(a+top,b+top,b+1+top,a+1+top),
                      (a,b,b+top,a+top),(a+1,a+1+top,b+1+top,b+1)])
    faces.extend([(0,top,top+1,1),(top-2,top-1,top*2-1,top*2-2)])
    return mesh(s,verts,faces,color,'MoltenLava')


def outline_leaf(s,points,color,z=2.10,center=None):
    from caixas_catalogo import branch
    o=s.flat(points,z,.055,color,smooth=False,kind='LeafBlade')
    if center:
        a,b=center;branch(s,[a,b],.032,'#D8AC63',z=z+.06,taper=.4,thick=.018)
    return o


def vein_leaf(s,x,y,length,width,angle,color,z=2.08):
    from caixas_catalogo import branch
    c,si=math.cos(angle),math.sin(angle)
    def pos(u,v):return (x+c*u-si*v,y+si*u+c*v)
    points=[pos(0,0),pos(-width*.7,length*.25),pos(-width,length*.55),pos(-width*.55,length*.83),pos(0,length),pos(width*.55,length*.83),pos(width,length*.55),pos(width*.7,length*.25)]
    s.flat(points,z,.055,color,kind='VeinedLeaf')
    branch(s,[pos(0,0),pos(0,length*.5),pos(0,length*.93)],.025,'#BBD09A',z+.065,taper=.3,thick=.018)
    for h in (.3,.55,.72):
        for sg in (-1,1):branch(s,[pos(0,length*h),pos(sg*width*.63,length*(h+.13))],.018,'#BBD09A',z+.066,thick=.015)


def volcano(s):
    s.base(planks=False)
    # A hollow crater with individually shaded rock facets, not a disc on a lid.
    n=12;verts=[]
    for ring in range(4):
        for i in range(n):
            a=i*math.tau/n
            r=[1.07,.54,.34,.29][ring]*(1+.055*math.sin(i*2.3))
            z=[2.02,2.70,2.66,2.36][ring]+(0 if ring in (0,3) else .055*math.sin(i*1.7))
            verts.append((r*math.cos(a),r*math.sin(a),z))
    faces=[]
    for j in range(3):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.append(tuple(3*n+i for i in range(n)))
    faces.append(tuple(reversed(range(n))))
    o=mesh(s,verts,faces,'#51403B','VolcanicCrater')
    for c in ('#695047','#382E2E','#886248'):o.data.materials.append(mat(c))
    for p in o.data.polygons:p.material_index=(p.index%3) if p.index<12 else 2
    s.flat(ellipse(0,0,.295,.295,18),2.38,.035,'#EF862D',smooth=False,emit=.7,kind='LavaPool')
    for x,y,r in [(-.10,.03,.08),(.09,-.10,.055)]:s.disk(x,y,r,'#FFD86B',z=2.43,emit=.8)
    lava_ribbon(s,[(.02,.48,2.71),(.19,.68,2.52),(.28,.98,2.17),(.45,1.23,2.04)],.12,'#E5722D')
    lava_ribbon(s,[(.02,.48,2.72),(.19,.68,2.53),(.28,.98,2.18),(.45,1.23,2.05)],.045,'#FFC85A')
    lava_ribbon(s,[(-.48,-.13,2.71),(-.68,-.30,2.47),(-1.06,-.38,2.12)],.075,'#F7AF3D')
    for x,y,r in [(-.86,.65,.22),(.78,-.65,.24),(-.5,-.9,.16)]:
        crystal(s,x,y,2.00,r,.24,'#61483F',kind='Basalt',highlight='#8B7462')
    from caixas_catalogo import side_pattern
    side_pattern(s,'cracks','#E99B34')
    for side in range(4):
        for x,h in [(-.6,.48),(.50,1.15)]:
            s.wall(side,[(x-.25,h-.13),(x+.14,h-.16),(x+.27,h+.08),(x-.15,h+.17)],'#55403C')


def tools(s):
    s.base(planks=True,straps=True)
    # Curved double pick head, socket, wrapped handle and a chipped ore cluster.
    tube(s,[(-.75,.79,2.14),(-.34,.29,2.18),(.18,-.35,2.23),(.43,-.69,2.26)],.09,'#B97D46','PickHandle',end=.075)
    head=[(-.38,-.88),(-.12,-.98),(.20,-.91),(.52,-.71),(.80,-.43),(.99,-.06),(.66,-.29),(.37,-.48),(.10,-.64),(-.17,-.76)]
    s.flat(head,2.28,.16,'#8FB8BB',kind='ForgedPickHead',smooth=False)
    s.flat([(-.38,-.88),(-.12,-.98),(.20,-.91),(.52,-.71),(.80,-.43),(.99,-.06),(.71,-.36),(.43,-.65),(.12,-.83)],2.445,.025,'#D8ECE2',kind='SharpenedEdge',smooth=False)
    socket=s.box((.30,-.63,2.39),(.30,.36,.23),'#55747B','PickSocket');socket.rotation_euler.z=-.6
    for i in range(4):
        x=-.59+i*.06;y=.59-i*.08
        tube(s,[(x-.05,y-.045,2.23),(x+.055,y+.045,2.23)],.027,'#61402D','HandleWrap',steps=1)
    rock=[(-1,-.65),(-.83,-1.0),(-.4,-1.04),(-.16,-.82),(-.40,-.43),(-.83,-.35)]
    s.flat(rock,2.02,.18,'#646E72',smooth=False,kind='OreMatrix')
    for x,y,r,h,c in [(-.73,-.72,.18,.51,'#77CDBD'),(-.41,-.83,.13,.37,'#AF8BD2'),(-.91,-.42,.11,.27,'#D5B56A')]:crystal(s,x,y,2.16,r,h,c,tilt=(.05,-.04))
    for x,y in [(.75,.60),(.52,.88),(.89,.87)]:puff(s,(x,y,2.08),(.12,.10,.07),'#C8A35B','GoldNugget')
    for side in range(4):
        s.wall_line(side,[(-.88,.44),(.85,1.39)],.11,'#87623E')
        for u in (-.48,.16,.68):s.wall_line(side,[(u,.71),(u+.13,.96)],.035,'#543827')
        s.wall(side,[(-.18,.40),(-.32,.64),(-.09,.93),(.10,.68),(.06,.44)],'#91D9CD',depth=.08)


def icing_rosette(s,x,y,z,r=.17):
    # Fluted piping in one closed mesh; keeps its six ridges without many spheres.
    n=18;verts=[]
    for k,(scale,height) in enumerate(((.86,0),(1,.38),(.65,.83),(.06,1.35))):
        for j in range(n):
            a=j*math.tau/n+k*.17
            rr=r*scale*(.84+.16*math.cos(j*math.tau/n*6))
            verts.append((x+rr*math.cos(a)-k*r*.045,y+rr*math.sin(a),z+height*r))
    faces=[tuple(reversed(range(n)))]
    for k in range(3):
        for j in range(n):faces.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    faces.append(tuple(3*n+j for j in range(n)))
    mesh(s,verts,faces,'#FFF1CF','CreamPiping',True)


def strawberry(s,x,y,z,size=.26):
    from caixas_catalogo import branch
    points=[(x-size*.85,y-size*.5),(x,y-size*.74),(x+size*.85,y-size*.5),(x+size*.75,y+size*.22),(x,y+size),(x-size*.75,y+size*.22)]
    s.flat(points,z,.16,'#BA5270',kind='Strawberry')
    for dx,dy in [(-.12,-.04),(.10,-.07),(0,.14),(-.06,.04),(.08,.06)]:
        s.flat(ellipse(x+dx,y+dy,.013,.023,8),z+.165,.015,'#F7D293',smooth=False,kind='BerrySeed')
    for a in (-.9,0,.9):
        vein_leaf(s,x,y-size*.46,.22,.06,a+math.pi,'#658348',z+.17)


def cake(s):
    # The box itself is the cake: sponge layers and filling, a tray and dripping icing.
    s.box((0,0,.10),(2.66,2.66,.20),'#DCCDA9','CakeTray',.08)
    s.box((0,0,.96),(2.39,2.39,1.52),'#B68B58','Sponge',.13)
    for z in (.63,1.14):
        s.box((0,0,z),(2.43,2.43,.13),'#FFF0CA','CreamLayer',.035)
        s.box((0,0,z-.095),(2.41,2.41,.07),'#A85B70','BerryFilling',.02)
    s.box((0,0,1.85),(2.54,2.54,.28),'#F4E8C4','IcedLid',.08)
    # Irregular icing silhouettes flow from the top down each side.
    for side in range(4):
        pts=[(-1.19,1.96),(1.19,1.96),(1.19,1.72)]
        for i in range(17):
            u=1.19-i*2.38/16;h=1.72-.18*(.5+.5*math.sin(i*1.8+side))**3
            pts.append((u,h))
        pts.append((-1.19,1.96));s.wall(side,pts,'#F4E8C4',depth=.085,kind='IcingDrips')
        for u,h in [(-.7,.40),(.25,.9),(.76,1.4)]:
            s.wall(side,ellipse(u,h,.035,.025,8),'#8F6843',depth=.045,kind='CakeCrumb')
    for i in range(7):
        for x,y in [(-1.07+i*.35,-1.08),(-1.07+i*.35,1.08)]:icing_rosette(s,x,y,2.035,.105)
    for i in range(1,6):
        for x in (-1.08,1.08):icing_rosette(s,x,-1.08+i*.35,2.035,.105)
    for x,y in [(-.46,-.38),(.22,-.48),(.48,.19)]:strawberry(s,x,y,2.02)
    for x,y in [(-.47,.37),(-.13,.56),(.55,.55)]:icing_rosette(s,x,y,2.09,.20)
    # A curved chocolate drizzle, away from the berries.
    tube(s,[(-.76,.10,2.04),(-.24,.11,2.04),(.05,.27,2.04),(.20,.62,2.04)],.025,'#795039','ChocolateDrizzle',sides=6)


def cage(s):
    s.base(planks=False)
    s.box((0,0,1.995),(2.24,2.24,.09),'#172C35','DarkInterior')
    for x in (-.82,-.41,0,.41,.82):
        s.box((x,0,2.11),(.075,2.24,.14),'#A5BDC3','TopGrille')
    for y in (-.78,0,.78):s.box((0,y,2.18),(2.23,.09,.075),'#CADBDD','CrossRail')
    for x in (-1.02,1.02):
        for y in (-1.02,1.02):
            s.box((x,y,2.16),(.25,.25,.12),'#758F9D','BoltedCorner')
            s.disk(x,y,.055,'#DCE5DB',z=2.23,kind='Bolt')
    # Lock and hasp are readable on top, with an actual open shackle.
    tube(s,[(-.16,.55,2.24),(-.16,.30,2.29),(0,.20,2.31),(.16,.30,2.29),(.16,.55,2.24)],.045,'#D7C182','LockShackle')
    s.box((0,.67,2.24),(.48,.41,.17),'#B59B56','Padlock')
    s.disk(0,.65,.055,'#3D4245',z=2.335,kind='Keyhole')
    s.line([(0,.65),(0,.79)],.035,'#3D4245',z=2.34)
    for side in range(4):
        s.wall(side,[(-.95,.33),(.95,.33),(.95,1.43),(-.95,1.43)],'#253F4A',depth=.04)
        for x in (-.75,-.38,0,.38,.75):s.wall_line(side,[(x,.37),(x,1.4)],.065,'#A5BDC3',depth=.10)
        for h in (.42,1.34):s.wall_line(side,[(-1,h),(1,h)],.09,'#CADBDD',depth=.13)


def spikes(s):
    s.base(planks=False)
    # Segmented carapace, with curved horns rising above and beyond the rim.
    for y,w in [(-.63,.65),(-.05,.82),(.53,.66)]:
        pts=[(-w,y-.30),(0,y-.43),(w,y-.30),(w*.85,y+.23),(0,y+.40),(-w*.85,y+.23)]
        s.flat(pts,2.05,.12,'#57937A',smooth=False,kind='ArmorPlate')
        s.line([(-w*.75,y-.20),(0,y-.28),(w*.75,y-.20)],.035,'#88B69B',z=2.18)
    for sg in (-1,1):
        for y in (-.75,0,.75):
            s.disk(sg*.93,y,.16,'#2C594E',z=2.04,kind='HornSocket')
            tube(s,[(sg*.94,y,2.08),(sg*1.14,y-.08,2.34),(sg*1.10,y-.23,2.60),(sg*.87,y-.40,2.76)],.14,'#D8E3CA','CurvedThorn',end=.005,sides=7)
    for side in range(4):
        for u in (-.62,0,.62):
            s.wall(side,[(u-.25,1.25),(u+.25,1.25),(u+.22,.65),(u,.45),(u-.22,.65)],'#72A68C',depth=.055)
            s.wall_line(side,[(u-.12,1.08),(u+.09,.88)],.035,'#305E51',depth=.085)
            s.wall(side,[(u-.09,.63),(u+.09,.63),(u+.12,.85),(u,1.08),(u-.12,.85)],'#D8E3CA',depth=.13)


def watermelon(s):
    s.box((0,0,.90),(2.43,2.43,1.80),'#398A43','MelonRind',.14)
    s.box((0,0,.12),(2.48,2.48,.22),'#2C6137','Foot',.06)
    for side in range(4):
        for i,u in enumerate((-.86,-.41,.10,.62,.98)):
            pts=[(u-.09,.22),(u-.15,.60),(u-.05,.98),(u-.12,1.53),(u-.04,1.77),(u+.09,1.77),(u+.03,1.27),(u+.13,.91),(u+.05,.42),(u+.08,.22)]
            s.wall(side,pts,'#76B35D',depth=.035,kind='RindStripe')
    s.box((0,0,1.87),(2.51,2.51,.19),'#BDD98B','PaleRind',.06)
    s.box((0,0,1.99),(2.29,2.29,.12),'#E35D68','CutFlesh',.055)
    s.box((0,0,2.057),(2.09,2.09,.02),'#EB7378','FleshCenter',.045)
    # Curved seed arrangement and a raised wedge with layered rind.
    for a in (-2.65,-2.0,-1.30,-.55,.2,.9,1.6,2.35):
        x,y=.78*math.cos(a),.78*math.sin(a)
        pts=[(x-.05,y-.07),(x,y-.14),(x+.05,y-.07),(x+.06,y+.05),(x,y+.09),(x-.06,y+.05)]
        s.flat(pts,2.08,.025,'#413B32',kind='MelonSeed')
    before=set(s.coll.objects)
    s.flat([(-.55,-.55),(.60,-.55),(.1,.27)],2.10,.14,'#3E8446',smooth=False,kind='WedgeRind')
    s.flat([(-.49,-.49),(.52,-.49),(.1,.20)],2.245,.025,'#CBE3A4',smooth=False,kind='WedgePith')
    s.flat([(-.40,-.43),(.43,-.43),(.1,.11)],2.275,.035,'#E35D68',smooth=False,kind='WedgeFlesh')
    for x,y in [(-.16,-.31),(.18,-.22),(.26,-.34)]:s.disk(x,y,.03,'#413B32',z=2.315,ry=.055)
    for o in set(s.coll.objects)-before:
        for v in o.data.vertices:v.co.z+=(.27-(v.co.y-s.oy))*.47
    tube(s,[(-1.03,.87,1.87),(-1.34,1.0,2.03),(-1.45,.70,2.04),(-1.28,.64,2.03)],.045,'#477D3D','CurledStem')


def ice(s):
    s.base(planks=False)
    plate=[(-1.12,-.70),(-.75,-1.13),(.45,-1.06),(1.12,-.71),(1.08,.60),(.65,1.12),(-.55,1.04),(-1.13,.55)]
    s.flat(plate,2.02,.12,'#82BED1',smooth=False,kind='IceSlab')
    for x,y,r,h,tilt in [(-.67,-.67,.23,.75,(-.08,-.08)),(-.97,-.34,.17,.43,(-.1,0)),(-.32,-.82,.16,.40,(.03,-.05))]:crystal(s,x,y,2.10,r,h,'#A9E3E9',tilt)
    cx,cy=.30,.28
    s.flat(ellipse(cx,cy,.15,.15,6),2.165,.045,'#E7F9F4',smooth=False,kind='SnowflakeCore')
    for i in range(6):
        a=i*math.tau/6;u=Vector((math.cos(a),math.sin(a)));v=Vector((-u.y,u.x))
        p=lambda r,side=0:(cx+r*u.x+side*v.x,cy+r*u.y+side*v.y)
        s.line([p(.1),p(.67)],.065,'#E7F9F4',z=2.17,kind='SnowflakeArm')
        for d in (.36,.53):
            for sg in (-1,1):s.line([p(d-.06,sg*.14),p(d+.08)],.044,'#E7F9F4',z=2.17)
    s.line([(-1,.50),(-.55,.62),(-.33,.99)],.03,'#DDF8EE',z=2.16)
    for side in range(4):
        s.wall_line(side,[(-.95,1.52),(-.50,1.10),(-.65,.66),(-.2,.43)],.045,'#D5F4F4')
        s.wall_line(side,[(-.50,1.10),(.1,1.27),(.65,.98)],.035,'#D5F4F4')
        for u,length in [(-.87,.35),(-.27,.23),(.36,.42),(.83,.21)]:
            s.wall(side,[(u-.10,1.64),(u+.11,1.64),(u+.07,1.40),(u,1.64-length)],'#C8EFF2',depth=.10,kind='Icicle')


def maple(s,x,y,r,angle,color,z):
    from caixas_catalogo import branch
    local=[(0,-.52),(-.20,-.28),(-.55,-.35),(-.48,-.06),(-.9,.08),(-.62,.25),(-.70,.63),(-.31,.49),(0,1),(.26,.51),(.61,.70),(.56,.31),(.91,.10),(.52,-.03),(.57,-.36),(.18,-.27)]
    c,si=math.cos(angle),math.sin(angle)
    pos=lambda u,v:(x+r*(u*c-v*si),y+r*(u*si+v*c))
    s.flat([pos(u,v) for u,v in local],z,.065,color,smooth=False,kind='MapleLeaf')
    branch(s,[pos(0,-.7),pos(0,0),pos(0,.81)],.035,'#E9C182',z+.07,taper=.4,thick=.02)
    for u,v in [(-.50,.46),(.48,.48),(-.65,.09),(.64,.10),(-.32,-.23),(.34,-.23)]:
        branch(s,[pos(0,-.11),pos(u,v)],.022,'#E9C182',z+.072,taper=.4,thick=.018)


def autumn(s):
    s.base(planks=True)
    tube(s,[(-.95,.86,2.04),(-.28,.37,2.10),(.16,-.28,2.10),(.82,-.91,2.10)],.05,'#75472D','AutumnTwig',end=.02)
    maple(s,-.53,-.42,.69,-.65,'#C67539',2.08)
    maple(s,.48,-.20,.75,.6,'#DDA648',2.17)
    maple(s,-.10,.62,.61,2.9,'#A94F31',2.26)
    for x,y in [(-.80,.73),(.80,.70)]:
        puff(s,(x,y,2.18),(.16,.23,.13),'#B47C3D','Acorn')
        puff(s,(x,y-.12,2.27),(.18,.12,.07),'#765038','AcornCap')
        tube(s,[(x,y-.15,2.29),(x+.03,y-.25,2.34)],.025,'#67442D','AcornStem',steps=2)
    for side in range(4):
        s.wall_line(side,[(-.85,.45),(-.32,.72),(.28,.88),(.8,1.3)],.06,'#CB9855')
        for u,h in [(-.45,.75),(.48,1.08)]:
            s.wall(side,[(u,h-.15),(u-.25,h-.06),(u-.15,h+.1),(u-.23,h+.28),(u,h+.20),(u+.15,h+.4),(u+.25,h+.16),(u+.38,h+.15),(u+.17,h-.04)],'#D29145',depth=.065,kind='FallenLeaf')


def cotton(s):
    s.base(planks=True)
    tube(s,[(-.78,1.06,2.04),(-.27,.55,2.10),(.03,.05,2.12),(.18,-.65,2.15)],.065,'#836546','CottonBranch',end=.025)
    tube(s,[(-.22,.43,2.12),(.39,.32,2.14),(.72,.00,2.16)],.045,'#836546','CottonBranch',end=.02)
    tube(s,[(0,.07,2.12),(-.40,-.24,2.15),(-.64,-.63,2.16)],.04,'#836546','CottonBranch',end=.02)
    for x,y,z,r in [(-.64,-.57,2.22,.39),(.32,-.66,2.20,.36),(.66,.26,2.20,.37)]:
        for i in range(5):
            a=i*math.tau/5
            vein_leaf(s,x,y,.47,.10,a,'#A08C62',z-.12)
        for i in range(5):
            a=i*math.tau/5
            puff(s,(x+math.cos(a)*r*.46,y+math.sin(a)*r*.46,z+.10),(r*.65,r*.65,.23),'#F2EEDF','CottonBoll')
        puff(s,(x,y,z+.15),(r*.49,r*.50,.24),'#FFFAED','CottonCenter')
    vein_leaf(s,-.44,.75,.51,.19,-1.4,'#8B9474',2.10)
    for side in range(4):
        s.wall_line(side,[(-.78,.45),(-.13,.76),(.48,1.30)],.06,'#8E7453')
        for i in range(5):
            a=i*math.tau/5
            s.wall(side,ellipse(.18+.15*math.cos(a),.98+.15*math.sin(a),.15,.14,12),'#F2EEDF',depth=.075,kind='CottonRelief')


def petal(s,cx,cy,angle,inner,length,width,z,color):
    # Convex, slightly cupped petals with a center ridge and closed underside.
    c,si=math.cos(angle),math.sin(angle)
    local=[(-width*.40,inner),(-width*.87,inner+length*.36),(-width,inner+length*.75),
           (-width*.86,inner+length*.92),(-width*.50,inner+length),
           (0,inner+length*1.02),(width*.50,inner+length),(width*.86,inner+length*.92),
           (width,inner+length*.75),(width*.87,inner+length*.36),(width*.40,inner)]
    verts=[]
    for u,v in local:verts.append((cx+u*c-v*si,cy+u*si+v*c,z+.045*(v-inner)/length))
    n=len(local)
    verts.append((cx-(inner+length*.5)*si,cy+(inner+length*.5)*c,z+.065))
    verts +=[(x,y,zz-.035) for x,y,zz in verts[:n]]
    faces=[(i,(i+1)%n,n) for i in range(n)]+[tuple(reversed(range(n+1,2*n+1)))]+[(i,i+n+1,(i+1)%n+n+1,(i+1)%n) for i in range(n)]
    return mesh(s,verts,faces,color,'MarigoldPetal',True)


def marigold(s):
    s.base(planks=True)
    tube(s,[(.72,1.12,2.05),(.48,.66,2.08),(.04,.23,2.10),(-.12,-.23,2.11)],.065,'#657F40','FlowerStem',end=.045)
    for x,y,l,w,a in [(.42,.62,.64,.18,-1.2),(.35,.55,.72,.18,1.0),(.05,.22,.60,.16,1.5)]:vein_leaf(s,x,y,l,w,a,'#82964A',2.10)
    cx,cy=-.16,-.25
    for count,inner,length,width,z,colors in [(18,.22,.76,.105,2.14,('#D99A39','#E8AF4A')),(15,.13,.57,.11,2.24,('#E8B34E','#F2C65F')),(11,.06,.35,.09,2.35,('#EDBC52','#F5D375'))]:
        for i in range(count):petal(s,cx,cy,i*math.tau/count+z,inner,length,width,z,colors[i%2])
    for i in range(7):
        a=i*math.tau/7;puff(s,(cx+.09*math.cos(a),cy+.09*math.sin(a),2.48),(.055,.055,.055),'#C58B2D','FlowerDisk')
    puff(s,(.86,.70,2.18),(.16,.20,.18),'#DDA748','FlowerBud')
    for side in range(4):
        s.wall_line(side,[(-.7,.40),(-.22,.70),(.28,1.23)],.06,'#7B8F47')
        for u,h in [(-.35,.63),(.04,.91)]:s.wall(side,[(u,h),(u-.26,h+.05),(u-.35,h+.28),(u-.08,h+.21)],'#97A55E')
        for i in range(9):
            a=i*math.tau/9
            s.wall(side,ellipse(.28+.18*math.cos(a),1.23+.18*math.sin(a),.085,.085,10),'#E9B54E',depth=.065,kind='FlowerRelief')
        s.wall(side,ellipse(.28,1.23,.10,.10,12),'#BC7D27',depth=.10)


BUILDERS={'volcano':volcano,'tools':tools,'cake':cake,'cage':cage,'spikes':spikes,
          'watermelon':watermelon,'ice':ice,'autumn':autumn,'cotton':cotton,'marigold':marigold}
