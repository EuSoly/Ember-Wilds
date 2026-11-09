"""Catálogo por temas: referência identifica tema/paleta, não desenho copiado.

Mobs: malhas e materiais do NPC_Catalog_23 aprovado, com acabamento lateral novo.
Os IDs 85–114 são consolidados por criatura de madeira, sem seis recolorações.
"""
import math
from functools import partial
from caixa_lib import TOP, ellipse

TIPO='caixa'
LOTE=[]
CATALOG=[]


def register(name,fn,colors,refs=(),mob=None):
    LOTE.append((name,fn,*colors))
    CATALOG.append(dict(id='crate_'+name,reference_ids=list(refs),source_npc=mob,
                        palette=list(colors),mob_alias=mob.lower().replace(' ','_') if mob else None))


def star(s,x,y,r,color,n=5,z=2.04):
    pts=[]
    for i in range(n*2):
        a=math.pi/2+i*math.pi/n; rr=r if i%2==0 else r*.43
        pts.append((x+rr*math.cos(a),y+rr*math.sin(a)))
    s.flat(pts,z,.055,color,smooth=False)


def leaf(s,x,y,scale,color,angle=0,z=2.05):
    pts=[(-.2,0),(-.27,.35),(0,.65),(.27,.35),(.2,0),(0,-.12)]
    c,si=math.cos(angle),math.sin(angle)
    s.flat([(x+scale*(u*c-v*si),y+scale*(u*si+v*c)) for u,v in pts],z,.06,color)


def flower(s,x,y,r,color):
    for i in range(5):
        a=math.tau*i/5
        s.disk(x+math.cos(a)*r*.65,y+math.sin(a)*r*.65,r*.46,color,z=2.12)
    s.disk(x,y,r*.30,'#F7D773',z=2.18)


def branch(s,points,width,color,z=2.065,taper=.45,thick=.055):
    """Open Catmull-Rom ribbon: continuous organic branches, rounded tips."""
    path=[]
    for i in range(len(points)-1):
        p0,p1,p2,p3=points[max(0,i-1)],points[i],points[i+1],points[min(len(points)-1,i+2)]
        for k in range(6):
            t=k/6
            path.append(tuple(.5*(2*p1[j]+(-p0[j]+p2[j])*t+(2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t*t+(-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t*t*t) for j in (0,1)))
    path.append(points[-1]);left=[];right=[]
    for i,p in enumerate(path):
        a,b=path[max(0,i-1)],path[min(len(path)-1,i+1)]
        dx,dy=b[0]-a[0],b[1]-a[1];d=math.hypot(dx,dy) or 1
        r=width*.5*(1-(1-taper)*i/(len(path)-1))
        left.append((p[0]-dy/d*r,p[1]+dx/d*r));right.append((p[0]+dy/d*r,p[1]-dx/d*r))
    s.flat(left+right[::-1],z,thick,color,smooth=False,kind='OrganicBranch')
    for p,r in [(path[0],width*.5),(path[-1],width*.5*taper)]:
        s.flat(ellipse(*p,r,r,12),z,thick,color,smooth=False,kind='BranchTip')


def leaf_between(s,start,tip,width,color,z=2.10):
    dx,dy=tip[0]-start[0],tip[1]-start[1];d=math.hypot(dx,dy)
    nx,ny=-dy/d*width,dx/d*width
    mid=((start[0]+tip[0])*.5,(start[1]+tip[1])*.5)
    s.flat([start,(mid[0]+nx,mid[1]+ny),tip,(mid[0]-nx,mid[1]-ny)],z,.045,color)
    branch(s,[start,mid,tip],.025,'#B1CD8A',z+.05,taper=.2,thick=.018)


def honey_ring(s,x,y,r,z=2.07):
    outer=ellipse(x,y,r,r,6,rot=math.pi/6)
    inner=ellipse(x,y,r-.065,r-.065,6,rot=math.pi/6)
    s.flat(outer,z-.04,.035,'#98601C',smooth=False,kind='HoneyCellFloor')
    for i in range(6):
        j=(i+1)%6
        s.flat([outer[i],outer[j],inner[j],inner[i]],z,.12,'#F4C343',smooth=False,kind='WaxWall')


def side_pattern(s,kind,color=None):
    c=color or s.accent
    for side in range(4):
        if kind=='paw':
            s.wall(side,ellipse(0,.67,.23,.17,12),c)
            for u,h in [(-.28,.91),(0,1.01),(.28,.91)]: s.wall(side,ellipse(u,h,.09,.10,10),c)
        elif kind=='feather':
            for u in (-.45,0,.45):
                s.wall(side,[(u-.12,.45),(u-.19,.82),(u,.99),(u+.12,.71)],c)
        elif kind=='scales':
            for u,h in [(-.55,.7),(0,.7),(.55,.7),(-.28,1.12),(.28,1.12)]:
                s.wall(side,[(u-.21,h),(u,h-.19),(u+.21,h),(u,h+.10)],c)
        elif kind=='web':
            for u in (-.7,0,.7): s.wall_line(side,[(u,.35),(0,1.42),(-u,.35)],.035,c)
            s.wall_line(side,[(-.55,.73),(0,.62),(.55,.73)],.045,c)
            s.wall_line(side,[(-.36,1.02),(0,.94),(.36,1.02)],.045,c)
        elif kind=='tentacles':
            s.wall_line(side,[(-.9,.55),(-.55,.65),(-.36,1.08),(0,1.15),(.34,.67),(.65,.51),(.85,.67)],.14,c)
            for u in (-.65,.65): s.wall(side,ellipse(u,.65,.07,.08,10),'#AC8BE6',depth=.065)
        elif kind=='runes':
            for u in (-.6,0,.6):
                s.wall_line(side,[(u,.45),(u,1.17),(u+.20,.97),(u,.78),(u-.17,.97)],.06,c,emit=.5)
        elif kind=='cracks':
            s.wall_line(side,[(-.9,1.45),(-.4,1.17),(-.55,.77),(.1,.64),(.38,.29)],.065,c,emit=.5)
            s.wall_line(side,[(-.55,.77),(-.84,.47)],.05,c,emit=.5)
        elif kind=='grain':
            s.wall_line(side,[(-.95,.7),(-.40,.78),(0,.60),(.4,.75),(.93,.69)],.045,c)
            s.wall(side,ellipse(.5,1.07,.18,.10,12),c)
            s.wall(side,ellipse(.5,1.07,.10,.045,10),s.body,depth=.055)
        elif kind=='vine':
            s.wall_line(side,[(-.8,.35),(-.5,.73),(0,.85),(.4,1.17),(.8,1.43)],.07,c)
            for u,h in [(-.5,.73),(0,.85),(.4,1.17)]:
                s.wall(side,[(u,h),(u-.25,h+.08),(u-.28,h+.29),(u-.05,h+.22)],c)
        elif kind=='bones':
            s.wall_line(side,[(-.48,.53),(.48,1.17)],.12,c)
            s.wall_line(side,[(-.48,1.17),(.48,.53)],.12,c)
            for u in (-.48,.48):
                for h in (.53,1.17): s.wall(side,ellipse(u,h,.12,.09,10),c)
        elif kind=='stars':
            for u,h,r in [(-.6,.6,.12),(0,1,.19),(.6,.65,.1)]:
                s.wall(side,[(u,h+r),(u+r*.35,h+.035),(u+r,h),(u+.035,h-r*.35),(u,h-r),(u-r*.35,h-.035),(u-r,h),(u-.035,h+r*.35)],c)
        else:
            for u in (-.6,0,.6):
                s.wall(side,[(u-.12,.53),(u-.12,1.15),(u+.12,1.15),(u+.12,.53)],c)


def basic(s,style='wood'):
    s.base(planks=style in ('wood','pine','adventure','bones','swords'),straps=style in ('wood','pine','iron','gold'))
    if style in ('wood','pine'):
        s.line([(-.98,-.97),(.98,.97)],.20,s.accent,z=2.06)
        side_pattern(s,'grain',s.outline)
    elif style in ('iron','gold'):
        s.flat([(-.68,-.68),(.68,-.68),(.68,.68),(-.68,.68)],2.025,.06,s.outline,smooth=False)
        if style=='gold':
            s.flat([(-.44,-.38),(.44,-.38),(.6,.30),(.28,.10),(0,.52),(-.28,.10),(-.6,.30)],2.10,.08,s.accent,smooth=False)
        else:
            for x in (-.4,.4):
                for y in (-.4,.4): s.disk(x,y,.10,s.accent,z=2.1)
        side_pattern(s,'stripes')
    elif style in ('runes','cosmic'):
        s.disk(0,0,.80,s.outline,z=2.03)
        if style=='cosmic':
            star(s,0,0,.65,s.accent,z=2.12)
            for x,y in [(-.8,-.8),(.8,.7),(-.7,.7)]: star(s,x,y,.18,'#C7B2FF',n=4)
            side_pattern(s,'stars')
        else:
            s.line([(0,-.65),(.47,0),(0,.65),(-.47,0),(0,-.65)],.11,s.accent,z=2.11,emit=.5)
            s.line([(-.6,0),(.6,0)],.10,s.accent,z=2.12,emit=.5)
            side_pattern(s,'runes')
    elif style=='adventure':
        s.flat([(-.75,-.8),(.55,-.7),(.8,.75),(-.55,.8)],2.05,.08,'#E9CB8A',smooth=False)
        s.line([(-.4,-.4),(.15,-.20),(-.12,.28),(.45,.46)],.07,'#A95438',z=2.15)
        star(s,.45,.46,.16,'#A95438',n=4,z=2.16)
        side_pattern(s,'grain',s.outline)
    elif style=='bones':
        s.disk(0,.13,.55,s.accent,z=2.07)
        s.box((0,-.35,2.13),(.65,.35,.10),s.accent,'Jaw')
        for x in (-.22,.22): s.disk(x,.15,.13,s.outline,z=2.15)
        side_pattern(s,'bones')
    elif style=='swords':
        for sign in (-1,1):
            s.line([(-.7,sign*-.7),(.65,sign*.65)],.15,s.accent,z=2.08)
            s.line([(-.67,sign*-.2),(-.2,sign*-.67)],.12,'#A63C36',z=2.14)
        side_pattern(s,'bones',s.outline)


def mob(s,key,pattern):
    s.base(planks=False)
    s.lid_npc(key)
    side_pattern(s,pattern)


def themed(s,kind):
    from caixas_organicas import BUILDERS
    if kind in BUILDERS:
        BUILDERS[kind](s)
        return
    from caixas_fantasia import BUILDERS as FANTASIA
    if kind in FANTASIA:
        FANTASIA[kind](s)
        return
    s.base(planks=kind in ('garden','autumn','coral','tools','fossil'),straps=False)
    if kind=='honey':
        # Pointy hexagonal lattice: dx=sqrt(3)*r, dy=1.5*r, half-column offset.
        r=.31;dx=math.sqrt(3)*r
        for row in range(-2,3):
            cols=(-1,0,1) if row%2==0 else (-1.5,-.5,.5,1.5)
            for col in cols:
                x=col*dx;y=row*1.5*r
                honey_ring(s,x,y,r)
                if (row+int(col*2))%3==0:
                    s.flat(ellipse(x,y,r-.085,r-.085,6,rot=math.pi/6),2.065,.035,'#E8A52B',smooth=False,kind='Honey')
                    branch(s,[(x-.10,y+.08),(x,y+.11),(x+.07,y+.07)],.03,'#FFE298',z=2.105)
        for side in range(4):
            for row in range(2):
                for col in range(4-row):
                    x=(col-(3-row)/2)*math.sqrt(3)*.245;h=.58+row*1.5*.245
                    s.wall(side,ellipse(x,h,.245,.245,6,rot=math.pi/6),s.accent)
                    s.wall(side,ellipse(x,h,.17,.17,6,rot=math.pi/6),s.outline,depth=.065)
    elif kind=='tomb':
        s.box((0,.87,2.06),(1.95,.53,.24),'#555E60','StonePlinth',.06)
        s.box((0,.87,2.20),(1.70,.40,.15),'#A9ADA5','StoneFoot',.035)
        before=set(s.coll.objects)
        # Straight shoulders, semicircular arch and stepped base, raised at 38 degrees.
        arch=[(-.73,.88),(.73,.88),(.73,-.36)]
        arch +=[(.73*math.cos(a),-.36-.73*math.sin(a)) for a in [i*math.pi/16 for i in range(17)]]
        s.flat(arch,2.09,.22,'#626B6C',smooth=False,kind='Headstone')
        inset=[(x*.86,y*.87) for x,y in arch]
        s.flat(inset,2.315,.035,'#AEB5AD',smooth=False,kind='CarvedInset')
        s.line([(-.30,-.36),(.30,-.36)],.12,'#535F60',z=2.355)
        s.line([(0,-.76),(0,.14)],.12,'#535F60',z=2.355)
        for y,w in [(.36,.40),(.54,.28)]:s.line([(-w,y),(w,y)],.035,'#77837F',z=2.355)
        s.line([(.65,.75),(.42,.52),(.52,.30)],.028,'#535F60',z=2.36)
        s.line([(-.5,-.75),(-.36,-.62),(-.42,-.45)],.025,'#535F60',z=2.36)
        for o in set(s.coll.objects)-before:
            for v in o.data.vertices:
                y=v.co.y-s.oy;h=.88-y
                v.co.y=s.oy+.88-h*.79
                v.co.z+=h*.62
        for side in range(4):
            s.wall(side,[(-.65,.35),(.65,.35),(.65,1.27),(.43,1.43),(-.43,1.43),(-.65,1.27)],'#8D9893')
            s.wall_line(side,[(-.24,1.03),(.24,1.03)],.09,'#4E5A5B',depth=.075)
            s.wall_line(side,[(0,.61),(0,1.27)],.09,'#4E5A5B',depth=.075)
    elif kind=='aquarium':
        pool=[(-1,-.8),(-.8,-1),(.8,-1),(1,-.8),(1,.8),(.8,1),(-.8,1),(-1,.8)]
        s.flat(pool,2.035,.065,'#236F85',kind='PoolRim')
        s.flat([(x*.91,y*.91) for x,y in pool],2.105,.035,'#64C6CE',kind='Water')
        for x in (-.75,-.52):
            branch(s,[(x,.80),(x-.12,.48),(x+.06,.25)],.09,'#338E79',z=2.15)
        for x,y,r in [(-.6,.83,.11),(-.30,.87,.13),(.05,.85,.09),(.6,.86,.12)]:s.disk(x,y,r,'#D6CD9C',z=2.15,ry=r*.6)
        # Distinct tail, dorsal/pectoral fins, fuller body and curved gill.
        s.flat([(-.43,-.02),(-.93,-.40),(-.87,-.03),(-.96,.33)],2.16,.075,'#D98B2C',kind='Tail')
        s.flat([(-.27,-.28),(-.20,-.59),(.18,-.48),(.39,-.25)],2.16,.065,'#EEB147',kind='DorsalFin')
        s.flat([(-.20,.29),(.0,.53),(.29,.30)],2.16,.065,'#D98B2C',kind='LowerFin')
        s.flat([(-.55,0),(-.37,-.29),(.06,-.38),(.46,-.28),(.71,-.07),(.73,.04),(.53,.22),(.12,.35),(-.33,.24)],2.23,.12,'#F6CA55',kind='FishBody')
        s.flat([(-.35,.15),(.10,.24),(.56,.13),(.38,.27),(0,.32)],2.355,.025,'#FFE6A0',kind='FishBelly')
        branch(s,[(.27,-.24),(.16,-.07),(.23,.19)],.035,'#C78429',z=2.365)
        s.flat([(-.15,-.04),(-.40,.13),(-.11,.18),(.02,.05)],2.37,.035,'#E9A63B',kind='PectoralFin')
        s.disk(.46,-.10,.105,'#233F49',z=2.37)
        s.disk(.48,-.13,.032,'#F5FFFF',z=2.425)
        for x,y,r in [(.73,-.55,.12),(.56,-.81,.07),(-.55,-.68,.095)]:
            s.disk(x,y,r,'#D7F9F2',z=2.15);s.disk(x,y,r*.65,'#64C6CE',z=2.20)
        for side in range(4):
            s.wall_line(side,[(-1,.7),(-.6,.8),(0,.65),(.5,.82),(1,.7)],.10,s.accent)
            for u,h in [(-.6,1.15),(.45,.48),(.62,1.25)]: s.wall(side,ellipse(u,h,.09,.09,12),'#E7FFFF')
    elif kind=='coral':
        # Asymmetric fan coral: curved/tapered forked branches with rounded ends.
        s.flat([(-1,.66),(-.7,.37),(-.08,.50),(.4,.42),(.9,.72),(.66,.94),(-.65,.95)],2.04,.095,'#649A8A',kind='ReefRock')
        coral_paths=[([(-.40,.70),(-.44,.30),(-.55,-.18),(-.41,-.62),(-.50,-.94)],.21),
            ([(-.48,.20),(-.78,-.04),(-.91,-.44),(-1.04,-.61)],.16),
            ([(-.74,-.02),(-.99,.02),(-1.08,-.20)],.11),
            ([(-.55,-.16),(-.76,-.43),(-.72,-.76)],.12),
            ([(-.47,.06),(-.16,-.19),(-.12,-.51),(.07,-.73)],.16),
            ([(-.15,-.26),(.12,-.26),(.29,-.48)],.10),
            ([(-.41,-.58),(-.22,-.77),(-.20,-1.0)],.10)]
        for points,w in coral_paths:branch(s,points,w,'#D565A0',z=2.16,taper=.48,thick=.11)
        for x,y in [(-.50,-.94),(-.72,-.76),(-1.04,-.61),(.07,-.73),(.29,-.48),(-.20,-1)]:s.disk(x,y,.045,'#EFA9C6',z=2.275)
        # Three porous tube sponges, unequal sizes and heights.
        for x,y,r,h in [(.52,.12,.18,.26),(.83,.33,.14,.18),(.35,.43,.15,.16)]:
            s.flat(ellipse(x,y,r,r,16),2.10,h,'#E7AD43',smooth=False,kind='TubeSponge')
            s.disk(x,y,r*.62,'#8A5C2B',z=2.10+h+.005)
            s.disk(x-.025,y+.01,r*.36,'#B37B30',z=2.10+h+.055)
        for x,y,r in [(.60,-.68,.30),(.92,-.64,.21),(.77,-.90,.24)]:
            s.disk(x,y,r,'#E6846D',z=2.12,ry=r*.62)
            branch(s,[(x-r*.65,y),(x,y-.06),(x+r*.65,y)],.035,'#F2B08B',z=2.18)
        for side in range(4):
            s.wall_line(side,[(-.7,.37),(-.56,.72),(-.68,1.12)],.10,'#5EAFA4')
            s.wall_line(side,[(-.56,.72),(-.30,.85),(-.17,1.08)],.07,'#5EAFA4')
            for u,h,r in [(.3,.52,.15),(.62,.76,.13),(.45,1.03,.1)]:s.wall(side,ellipse(u,h,r,r,12),'#E6846D')
    elif kind=='present':
        for size in [(2.6,.27,.1),(.27,2.6,.1)]: s.box((0,0,2.06),size,s.accent,'Ribbon')
        for sg in (-1,1):
            s.flat([(0,0),(sg*.7,-.3),(sg*.8,.4),(sg*.25,.35)],2.13,.16,s.accent)
            s.flat([(sg*.22,.08),(sg*.60,-.1),(sg*.62,.24)],2.30,.02,s.body)
        side_pattern(s,'stripes')
    elif kind in ('garden','autumn','cotton','marigold'):
        if kind in ('garden','autumn'):
            if kind=='garden':
                branch(s,[(.18,1.10),(.05,.67),(-.17,.24),(-.45,-.35)],.095,'#8DBA76',z=2.05)
                branch(s,[(.05,.67),(.35,.73),(.68,.34),(.65,-.40)],.075,'#8DBA76',z=2.05)
                branch(s,[(-.15,.26),(-.53,.38),(-.89,.17)],.065,'#8DBA76',z=2.05)
                branch(s,[(.67,.25),(.89,.03),(.95,-.28)],.05,'#8DBA76',z=2.05)
                for a,b,w in [((-.20,.17),(-.70,-.02),.14),((-.03,.52),(-.44,.80),.16),((.37,.69),(.78,.85),.15),((.65,.05),(.36,-.19),.13),((-.86,.18),(-1.10,-.10),.10)]:
                    leaf_between(s,a,b,w,'#80AD68')
                flower(s,-.45,-.35,.38,'#B69ADA');flower(s,.65,-.40,.35,'#F3858F')
                s.disk(.95,-.32,.10,'#EBA2B7',z=2.10)
            else:
                for x,y,a in [(-.7,-.6,-1),(.6,-.5,1),(-.5,.6,2),(.65,.5,-2)]:
                    leaf(s,x,y,.8,s.accent,a)
                leaf(s,0,0,1.3,'#D68C38',.4)
            side_pattern(s,'vine')
        else:
            for i in range(8):
                a=i*math.tau/8
                s.disk(.55*math.cos(a),.55*math.sin(a),.40,s.accent,z=2.10)
            s.disk(0,0,.38,s.body,z=2.18)
            side_pattern(s,'vine',s.accent)
    elif kind in ('magma','volcano'):
        if kind=='volcano':
            s.disk(0,0,.88,s.outline,z=2.06)
            s.disk(0,0,.66,s.accent,z=2.11)
            for x,y in [(-.3,.25),(.3,-.15),(.1,.4)]:s.disk(x,y,.15,'#FFE184',z=2.18,emit=.8)
        else:
            for x,y in [(-.5,-.5),(.5,.5),(-.55,.5),(.5,-.5)]:
                s.flat([(x-.36,y-.33),(x+.25,y-.38),(x+.4,y+.1),(x,y+.4),(x-.38,y+.25)],2.06,.10,s.outline,smooth=False)
            s.line([(-.9,-.92),(-.15,-.3),(.12,.2),(.9,.85)],.12,s.accent,z=2.19,emit=.7)
        side_pattern(s,'cracks')
    elif kind=='tools':
        s.line([(-.68,-.68),(.66,.68)],.17,'#C2854C',z=2.07)
        s.line([(-.0,.75),(.4,.42),(.9,.1)],.30,'#C3E2DF',z=2.15)
        for x,y in [(-.72,.4),(.6,-.6)]:star(s,x,y,.32,s.accent,n=4,z=2.11)
        side_pattern(s,'stripes',s.outline)
    elif kind=='cake':
        s.box((0,0,2.07),(2.25,2.25,.24),s.accent,'Icing',.12)
        for x,y in [(-.8,-.8),(.8,-.8),(-.8,.8),(.8,.8),(-.8,0),(.8,0)]:s.disk(x,y,.16,'#AA5578',z=2.23)
        for side in range(4):
            for h in (.65,1.12):s.wall_line(side,[(-1,h),(1,h)],.14,s.accent)
            for x in (-.65,0,.65):s.wall(side,ellipse(x,1.42,.13,.19,12),s.accent)
    elif kind=='cage':
        for x in (-.75,-.25,.25,.75):s.box((x,0,2.08),(.1,2.2,.1),s.accent,'Grille')
        s.box((0,0,2.13),(2.2,.13,.1),s.accent,'Crossbar')
        side_pattern(s,'stripes')
    elif kind=='spikes':
        for x,y in [(-.8,-.8),(0,-.8),(.8,-.8),(-.8,0),(.8,0),(-.8,.8),(0,.8),(.8,.8)]:
            s.flat([(x-.12,y-.15),(x+.12,y-.15),(x+.2,y+.12),(x,y+.30),(x-.2,y+.12)],2.08,.17,s.accent,smooth=False)
        side_pattern(s,'scales')
    elif kind=='watermelon':
        s.box((0,0,2.02),(2.23,2.23,.11),'#DB565E','FruitFlesh',.1)
        for x,y in [(-.7,-.6),(0,-.7),(.7,-.6),(-.4,.1),(.4,.1),(0,.7)]:
            s.flat(ellipse(x,y,.07,.14,10),2.09,.035,s.outline,smooth=False)
        side_pattern(s,'stripes')
    elif kind=='ice':
        for a in range(3):
            angle=a*math.pi/3
            x,y=math.cos(angle)*.9,math.sin(angle)*.9
            s.line([(-x,-y),(x,y)],.12,s.accent,z=2.10)
        for x,y in [(-1,-1),(1,-1),(-1,1),(1,1)]:
            s.flat([(x-.2,y-.1),(x,y+.35),(x+.2,y-.1)],2.05,.24,'#D3F8FF',smooth=False)
        side_pattern(s,'scales')
    elif kind=='robot':
        s.box((0,.15,2.08),(1.65,.90,.15),s.outline,'Screen')
        for x in (-.4,.4):s.box((x,.15,2.19),(.32,.32,.05),'#7CE6D7','DisplayEye',emit=.7)
        for x in (-.5,0,.5):s.box((x,-.65,2.08),(.18,.23,.06),s.accent,'Button')
        for side in range(4):
            for h in (.60,.85,1.10):s.wall_line(side,[(-.65,h),(.65,h)],.07,s.outline)
    elif kind=='fossil':
        s.line([(0,-.9),(0,.85)],.14,s.accent,z=2.10)
        for y in (-.6,-.2,.2,.6):
            for sg in (-1,1):s.line([(0,y),(sg*.35,y+.15),(sg*.6,y+.02)],.11,s.accent,z=2.11)
        side_pattern(s,'bones')
    elif kind=='vortex':
        s.disk(0,0,.98,s.outline,z=2.04)
        for phase in (0,math.pi*2/3,math.pi*4/3):
            points=[]
            for i in range(14):
                a=phase+i*.14;r=.18+i*.058
                points.append((r*math.cos(a),r*math.sin(a)))
            s.line(points,.14,s.accent,z=2.13,emit=.5)
        side_pattern(s,'runes')
    elif kind=='wind':
        for y in (-.5,0,.5):s.line([(-.8,y),(.25,y),(.6,y+.12),(.45,y+.32),(.2,y+.25)],.11,s.accent,z=2.08)
        for x,y in [(-1,-1),(1,1)]:star(s,x,y,.30,s.accent,n=4)
        side_pattern(s,'stars')


def animal(s,kind,wood=False):
    from caixas_fantasia import ANIMALS,wood_frog
    if wood and kind=='frog':
        wood_frog(s)
        return
    if not wood and kind in ANIMALS:
        ANIMALS[kind](s)
        return
    s.base(planks=wood)
    body=s.body; edge=s.accent
    # These animals are not NPCs; use original sculpted wooden or plush masks.
    s.disk(0,0,.96,edge,z=2.04,ry=.90)
    s.disk(0,0,.83,body,z=2.10,ry=.78)
    if kind in ('tiger','lynx','wolf','boar'):
        for sg in (-1,1):
            s.flat([(sg*.48,-.55),(sg*.95,-1.30),(sg*1.02,-.44)],2.07,.16,edge,smooth=False)
            s.flat([(sg*.67,-.62),(sg*.88,-1.10),(sg*.91,-.55)],2.24,.025,body,smooth=False)
    elif kind=='crocodile':
        s.box((0,.6,2.17),(1.25,1.35,.18),body,'Snout',.15)
        for x in (-.5,.5):
            for y in (.4,.8,1.1):s.flat([(x,y-.1),(x*1.30,y),(x,y+.1)],2.25,.07,edge,smooth=False)
    elif kind=='parrot':
        for x in (-.5,0,.5):leaf(s,x,-.75,.85,edge,z=2.13)
        s.flat([(-.24,.4),(.24,.4),(.1,.95),(-.24,.73)],2.20,.16,'#E8BB55')
    elif kind=='deer':
        for sg in (-1,1):
            s.line([(sg*.65,-.4),(sg*.9,-1.25),(sg*1.2,-1.50)],.13,edge,z=2.14)
            s.line([(sg*.92,-1.17),(sg*.60,-1.45)],.12,edge,z=2.14)
    elif kind=='frog':
        for x in (-.7,.7):s.disk(x,-.55,.38,edge,z=2.12)
    else:
        for x in (-.75,.75):s.disk(x,-.65,.32,edge,z=2.09)
    for x in (-.39,.39):
        s.disk(x,.05,.17,'#191C29',z=2.34)
        s.disk(x-.045,.10,.045,'#FFF4EC',z=2.40)
    if kind in ('tiger','lynx','wolf','bear','boar','deer'):
        s.disk(0,.48,.29,edge,z=2.24,ry=.22)
        s.disk(0,.50,.13,'#191C29',z=2.32,ry=.08)
    if kind=='tiger':
        for sg in (-1,1):
            for y in (-.4,0,.4):s.line([(sg*.82,y),(sg*.61,y+.12)],.10,edge,z=2.22)
    if kind=='boar':
        for sg in (-1,1):s.flat([(sg*.5,.5),(sg*.68,.92),(sg*.77,.43)],2.30,.13,edge)
    if wood:
        for x in (-.9,.9):leaf(s,x,-.9,.65,'#599150',angle=x,z=2.25)
        side_pattern(s,'grain',edge)
    else:side_pattern(s,'scales' if kind=='crocodile' else ('feather' if kind=='parrot' else 'paw'))


# Existing cosmetic IDs retain their names; the remaining themes are asset IDs ready for import.
for name,style,colors,refs in [
 ('default','wood',('#A67B45','#594024','#D5AF68'),range(6)),
 ('pinho','pine',('#B98B55','#6B4A26','#D4AB71'),[12]),
 ('ferro','iron',('#6B7280','#363F48','#C9CED6'),[13,43]),
 ('runica','runes',('#4B2E83','#28183F','#C58BE8'),[16]),
 ('ouro','gold',('#B8861B','#6A461B','#FFE066'),[14,30]),
 ('cosmica','cosmic',('#1E1B3A','#111326','#FF4545'),[19,20,76]),
 ('aventureiro','adventure',('#A67B45','#594024','#D5AF68'),[6,39]),
 ('ossada','bones',('#8E6341','#493426','#E3C991'),[7,10,11]),
 ('espadas','swords',('#A67B45','#594024','#CCD5DA'),[8,9]),
 ('rubi','gold',('#A94939','#592A29','#E68465'),[17]),
 ('diamante','iron',('#1E929D','#17525D','#85EAE4'),[15]),
]:register(name,partial(basic,style=style),colors,refs)

for name,key,pattern,colors,refs in [
 ('coelho','Rabbit','paw',('#EEA7CD','#AA718F','#FFF4F5'),[44,50]),
 ('lobo','Wolf','paw',('#34303C','#191C29','#B63B58'),[51]),
 ('aranha','Spider','web',('#191C29','#34303C','#B63B58'),[52]),
 ('javali','Boar','paw',('#80543B','#4C332E','#FFF4EC'),[56,57]),
 ('falcao','Hawk','feather',('#80543B','#4C332E','#FFF4EC'),[53]),
 ('pinguim','Penguin','feather',('#34303C','#191C29','#FFF4EC'),[65]),
 ('raposa_artica','Arctic Fox','paw',('#E3F3F4','#34303C','#B63B58'),[55]),
 ('urso_polar','Polar Bear','paw',('#E3F3F4','#34303C','#B63B58'),[54]),
 ('mamute_filhote','Baby Mammoth','paw',('#AD7951','#4C332E','#FFF4EC'),[]),
 ('mamute','Mammoth','paw',('#AD7951','#4C332E','#B63B58'),[61]),
 ('dragao_filhote','Baby Dragon','scales',('#78C9CB','#2E727D','#BAE8E4'),[62]),
 ('dragao','Dragon','scales',('#78C9CB','#2E727D','#B63B58'),[64]),
 ('caranguejo','Crab','scales',('#EF794F','#C4404E','#FFF4EC'),[70]),
 ('caranguejo_rei','King Crab','scales',('#EF794F','#C4404E','#FFF4EC'),[37,69]),
 ('piranha','GMO Piranha','scales',('#C4404E','#792E3D','#EF794F'),[59,67]),
 ('kraken','Kraken','tentacles',('#44357B','#191C29','#B63B58'),[24,60]),
 ('monstro_lava','Lava Monster','cracks',('#792E3D','#4E282C','#F39332'),[68]),
 ('dragao_lava_filhote','Baby Lava Dragon','scales',('#75403B','#4E282C','#FFF4EC'),[63]),
 ('dragao_lava','Lava Dragon','scales',('#75403B','#4E282C','#B63B58'),[66]),
 ('abutre','Vulture','feather',('#34303C','#191C29','#B63B58'),[]),
 ('verme_areia','Sandworm','bones',('#B87558','#713C36','#FFF0AD'),[58]),
 ('galinha_dourada','Golden Hen','feather',('#FFD657','#DAA421','#FFF0AD'),[83]),
 ('pintinho_dourado','Golden Chick','feather',('#FFD657','#DAA421','#FFF0AD'),[84]),
]:register(name,partial(mob,key=key,pattern=pattern),colors,refs,key)

for name,kind,colors,refs in [
 ('favo','honey',('#B88323','#694518','#F4C343'),[21]),
 ('lapide','tomb',('#777C7D','#45494B','#B6B8AD'),[22]),
 ('aquario','aquarium',('#3D9E9B','#236268','#B8EEE0'),[25]),
 ('recife','coral',('#88744C','#4D4937','#D9AC59'),[27]),
 ('presente','present',('#BB443C','#652B2B','#E3BD3D'),[28]),
 ('jardim','garden',('#32785A','#1D4939','#76B47B'),[29,75]),
 ('vulcao','volcano',('#784829','#432A24','#F8B32E'),[31,38]),
 ('minerador','tools',('#995932','#543827','#91D9CD'),[32]),
 ('bolo','cake',('#B1844B','#6F492D','#EDE0BC'),[33,34]),
 ('grade','cage',('#566B78','#26333B','#D0DCE2'),[35,36]),
 ('espinhos','spikes',('#49846B','#244B43','#D3E2CF'),[40]),
 ('melancia','watermelon',('#3A8B43','#21552F','#79B857'),[41,42]),
 ('gelo','ice',('#6099B4','#365775','#CEF2F7'),[18,23,26,45,47,74]),
 ('outono','autumn',('#86532F','#49351F','#E4AD56'),[46]),
 ('algodao','cotton',('#B7ADA3','#68635C','#F0ECE2'),[48]),
 ('calendula','marigold',('#AF762D','#6D4A28','#D99A39'),[49]),
 ('magma','magma',('#6D3943','#332231','#E9A23B'),[71]),
 ('vento','wind',('#477F7A','#284F50','#BCE8DA'),[72]),
 ('robo','robot',('#6D868D','#334953','#A7BCC0'),[73]),
 ('fossil','fossil',('#806036','#483A29','#BFA873'),[78]),
 ('vortice','vortex',('#5D388D','#302246','#AE69D2'),[79]),
]:register(name,partial(themed,kind=kind),colors,refs)

for name,kind,colors,refs in [
 ('tigre','tiger',('#D48539','#653D2C','#824428'),[77]),
 ('crocodilo','crocodile',('#568D3D','#284F30','#A8BC67'),[80]),
 ('lince','lynx',('#C29467','#604333','#E4CFA6'),[81]),
 ('papagaio','parrot',('#BD453C','#66302D','#63BAA7'),[82]),
]:register(name,partial(animal,kind=kind),colors,refs)

for i,kind in enumerate(('frog','deer','boar','wolf','bear')):
    name=('sapo','cervo','javali','lobo','urso')[i]+'_madeira'
    register(name,partial(animal,kind=kind,wood=True),('#9F7346','#4C3829','#D0A674'),range(85+i,115,5))

# Every source ID is accounted for once. Consolidation stays reviewable.
_refs=[r for c in CATALOG for r in c['reference_ids']]
assert sorted(_refs)==list(range(115)), 'triagem incompleta ou duplicada'
