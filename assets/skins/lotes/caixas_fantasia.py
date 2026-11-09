"""Lote 06: relevos de fantasia e animais com acabamento de topo e laterais.

Tigre, crocodilo, lince, papagaio e sapo não são NPCs da biblioteca do jogo;
suas esculturas são originais. Mantém os temas e paletas do catálogo de caixas.
"""
import math
from skin_lib import ellipse,mat
from caixas_organicas import mesh,puff,tube,crystal,vein_leaf


def arc(s,x,y,r,start,end,color,z=2.10,width=.035,ry=None):
    points=[(x+r*math.cos(a),y+(ry or r)*math.sin(a),z) for a in [start+(end-start)*i/20 for i in range(21)]]
    return tube(s,points,width,color,'CurvedDetail',sides=6,steps=1)


def eye(s,x,y,z,iris='#B4A15B',radius=.145):
    # Shallow inlays keep the expression integrated into the sculpt from side views.
    for dx,dy,rx,ry,zz,color,kind in [
        (0,0,radius,radius*1.12,z,'#243036','EyeSocket'),
        (0,0,radius*.76,radius*.85,z+.012,iris,'Iris'),
        (0,0,radius*.37,radius*.65,z+.024,'#192329','Pupil'),
        (-.035,-.04,radius*.22,radius*.22,z+.036,'#F5F1DE','EyeGlint')]:
        s.flat(ellipse(x+dx,y+dy,rx,ry,16),zz,.012,color,smooth=False,kind=kind)


def plate(s,points,z,height,color,kind='StonePlate'):
    """Faceted beveled slab with a real shoulder and a contrasting top."""
    cx=sum(x for x,y in points)/len(points);cy=sum(y for x,y in points)/len(points)
    n=len(points);verts=[]
    for scale,zz in [(1,z),(.99,z+height*.55),(.83,z+height)]:
        verts.extend((cx+(x-cx)*scale,cy+(y-cy)*scale,zz) for x,y in points)
    faces=[tuple(reversed(range(n)))]
    for k in range(2):
        for i in range(n):faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
    faces.append(tuple(2*n+i for i in range(n)))
    return mesh(s,verts,faces,color,kind)


def magma(s):
    s.base(planks=False)
    s.box((0,0,2.015),(2.24,2.24,.08),'#CE7336','MoltenUnderlay')
    slabs=[([(-1.08,-1.02),(-.20,-1.08),(-.12,-.57),(-.47,-.30),(-1.06,-.48)],.18),
           ([(.03,-1.06),(1.06,-.94),(.90,-.35),(.43,-.20),(.10,-.49)],.25),
           ([(-1.09,-.30),(-.44,-.12),(-.29,.22),(-.65,.63),(-1.04,.40)],.27),
           ([(.46,-.02),(1.05,-.22),(1.05,.56),(.58,.48),(.26,.28)],.18),
           ([(-1.04,.58),(-.64,.77),(-.18,.46),(.02,.89),(-.10,1.09),(-1.01,1.06)],.19),
           ([(.13,.67),(.47,.58),(1.04,.76),(1.00,1.07),(.25,1.05)],.28)]
    for i,(points,h) in enumerate(slabs):
        o=plate(s,points,2.04,h,('#48333F','#593D49','#3C303D')[i%3],'ObsidianShard')
        o.data.materials.append(mat('#77505A'))
        o.data.polygons[-1].material_index=1 if i%2==0 else 0
    # A molten seam forks through the broken plates; cooled edge ridges remain visible.
    s.line([(-.1,-1),(-.01,-.49),(-.31,-.12),(-.13,.30),(.13,.63),(.12,1.05)],.055,'#FFCA69',z=2.06,emit=.6)
    s.line([(-.31,-.12),(-.7,-.30),(-1.04,-.36)],.045,'#FFCA69',z=2.06,emit=.6)
    s.line([(-.13,.30),(.40,.42),(1.02,.64)],.04,'#FFCA69',z=2.06,emit=.6)
    crystal(s,.02,.02,2.12,.25,.45,'#E7A44B',tilt=(.08,-.05),kind='AmberCore',highlight='#FAD77E')
    for side in range(4):
        s.wall_line(side,[(-.94,1.54),(-.45,1.22),(-.54,.85),(.04,.62),(.30,.28)],.09,'#D4883E',emit=.4)
        s.wall_line(side,[(-.54,.85),(-.88,.54)],.05,'#EDB34F',emit=.4)
        for u,h in [(-.69,.43),(.56,1.08)]:
            s.wall(side,[(u-.25,h-.15),(u+.13,h-.18),(u+.25,h+.14),(u-.13,h+.22)],'#493340',depth=.07)
            s.wall_line(side,[(u-.14,h+.06),(u+.08,h+.11)],.03,'#81535F',depth=.10)


def wind(s):
    s.base(planks=False)
    s.flat(ellipse(0,0,1.06,.98,32),2.03,.07,'#315B59',smooth=False,kind='WindMedallion')
    # Three raised gusts converge on a shallow cyclone, with tapered curled ends.
    for phase in (0,math.tau/3,math.tau*2/3):
        points=[]
        for i in range(20):
            a=phase+i*.105;r=1.00-i*.037
            points.append((r*math.cos(a),r*math.sin(a),2.16+i*.005))
        tube(s,points,.10,'#A5D8C8','WindSpiral',end=.025,sides=8,steps=1)
    s.disk(0,0,.16,'#679F95',z=2.20,kind='CycloneEye')
    # Compact clouds, not just a spiral icon; two feathers follow the circulation.
    for cx,cy in [(-.92,.79),(.89,-.74)]:
        for dx,dy,r in [(-.16,0,.15),(.02,-.05,.22),(.20,.02,.14)]:
            puff(s,(cx+dx,cy+dy,2.14),(r,r*.75,.12),'#DBEEE0','CloudLobe')
    from caixas_catalogo import branch
    for cx,cy,a in [(-.74,-.76,-.7),(.72,.73,2.4)]:
        c,si=math.cos(a),math.sin(a)
        p=lambda u,v:(cx+u*c-v*si,cy+u*si+v*c)
        s.flat([p(0,-.34),p(-.14,-.12),p(-.15,.13),p(0,.40),p(.14,.13),p(.13,-.12)],2.25,.06,'#D6EBDD',kind='WindFeather')
        branch(s,[p(0,-.40),p(0,.33)],.025,'#6EAAA0',z=2.32,thick=.015)
        for h in (-.08,.06,.18):
            for sg in (-1,1):branch(s,[p(0,h-.07),p(sg*.10,h+.04)],.015,'#6EAAA0',z=2.32,thick=.012)
    for side in range(4):
        for u,h,r in [(-.45,.77,.32),(.47,1.10,.23)]:
            pts=[(u+r*math.cos(a),h+r*.65*math.sin(a)) for a in [math.pi+i*math.pi*1.6/18 for i in range(19)]]
            s.wall_line(side,[(-.95,h)]+pts,.065,'#AEDACB')
        s.wall_line(side,[(-.75,.40),(.55,.40),(.88,.57)],.05,'#76B1A5')


def robot(s):
    s.base(planks=False)
    s.box((0,0,2.10),(2.17,2.18,.25),'#8EA9AD','RobotHead',.10)
    s.box((0,-.21,2.265),(1.81,.88,.14),'#324A54','VisorFrame',.06)
    s.box((0,-.21,2.35),(1.61,.65,.065),'#182E3C','VisorGlass',.045)
    for x in (-.43,.43):
        s.disk(x,-.21,.24,'#567C84',z=2.39,kind='LensRing')
        s.disk(x,-.21,.17,'#8DE5D5',z=2.445,emit=.5,kind='OpticalLens')
        s.disk(x-.05,-.26,.045,'#E0F9E4',z=2.50,kind='LensGlint')
    s.box((0,.57,2.27),(1.13,.37,.09),'#425F69','SpeakerHousing',.04)
    for x in (-.4,-.2,0,.2,.4):s.box((x,.57,2.325),(.065,.22,.035),'#1F3541','SpeakerVent',.01)
    for x in (-.86,.86):
        for y in (-.88,.89):
            s.disk(x,y,.072,'#C5D7CF',z=2.25,kind='Screw')
            s.line([(x-.04,y),(x+.04,y)],.018,'#4D6D74',z=2.30)
    tube(s,[(.0,-.99,2.20),(.04,-1.19,2.40),(.17,-1.24,2.60)],.035,'#8EA9AD','Antenna')
    puff(s,(.17,-1.24,2.65),(.11,.11,.10),'#D08B62','AntennaLamp')
    for sg in (-1,1):
        s.box((sg*1.20,0,2.17),(.23,.62,.24),'#5A7B86','HeadModule')
        for y in (-.18,0,.18):s.box((sg*1.20,y,2.30),(.14,.065,.04),'#BDCEC8','ModuleRib')
    for side in range(4):
        s.wall(side,[(-.83,.39),(.83,.39),(.83,1.39),(-.83,1.39)],'#5B7B84',depth=.045,kind='ServicePanel')
        for h in (.55,.70,.85):s.wall_line(side,[(-.61,h),(.15,h)],.055,'#2E4D59',depth=.075)
        for u,c in [(.38,'#D0955C'),(.61,'#7CCFC2')]:s.wall(side,ellipse(u,1.09,.08,.08,12),c,depth=.095)
        s.wall_line(side,[(-.65,1.20),(-.25,1.20),(-.25,1.04),(.05,1.04)],.035,'#B6D0C8',depth=.08)


def fossil(s):
    s.base(planks=False)
    slab=[(-1.08,-.93),(-.36,-1.08),(.58,-1.0),(1.08,-.65),(.97,.24),(1.1,.82),(.51,1.10),(-.68,1.04),(-1.12,.64)]
    plate(s,slab,2.02,.19,'#A48251','FossilSandstone')
    # Fish fossil: segmented spine, paired ribs, rays, skull and a fan-shaped tail.
    bones='#E5CCA0';edge='#745432'
    tube(s,[(.08,-.74,2.25),(-.06,-.32,2.25),(.02,.08,2.25),(.0,.48,2.25)],.055,bones,'FossilSpine',steps=4)
    for i,y in enumerate((-.57,-.33,-.08,.16)):
        s.disk((-.02 if i%2 else .03),y,.10,bones,z=2.25,ry=.085,kind='Vertebra')
        w=(.27,.46,.53,.39)[i]
        for sg in (-1,1):tube(s,[(0,y,2.27),(sg*w*.7,y-.04,2.29),(sg*w,y+.13,2.27),(sg*w*.82,y+.25,2.26)],.043,bones,'Rib',end=.025)
    s.flat([(-.35,.42),(-.47,.69),(-.28,.96),(.17,1.02),(.40,.79),(.27,.42)],2.24,.09,bones,kind='FossilSkull',smooth=False)
    s.disk(-.17,.70,.13,edge,z=2.34,kind='FossilEyeSocket')
    s.disk(.11,.83,.065,edge,z=2.34,kind='FossilNostril')
    s.line([(-.24,.90),(.09,.94),(.29,.82)],.035,edge,z=2.34)
    for x in (-.15,0,.15):s.line([(x,.90),(x+.025,.83)],.025,edge,z=2.35)
    for sg in (-1,1):
        for j in range(3):tube(s,[(.08,-.68,2.24),(sg*(.22+j*.08),-.91,2.25),(sg*(.23+j*.10),-1.07,2.24)],.027,bones,'TailRay',end=.016)
    for x,y in [(-.79,.56),(.75,-.55)]:
        pts=[(x+(.18-i*.0045)*math.cos(i*.29),y+(.18-i*.0045)*math.sin(i*.29),2.25) for i in range(35)]
        tube(s,pts,.022,bones,'Ammonite',end=.012,sides=6,steps=1)
    for a,b,c in [((-.9,-.75),(-.72,-.57),(-.81,-.28)),((.84,.73),(.67,.51),(.79,.26))]:s.line([a,b,c],.024,'#6D5034',z=2.23)
    for side in range(4):
        s.wall_line(side,[(-.82,.48),(-.39,.57),(.07,.49),(.57,.63),(.88,.57)],.035,'#D4B789')
        s.wall_line(side,[(-.91,1.20),(-.53,1.09),(.11,1.18),(.83,1.10)],.035,'#D4B789')
        for u in (-.48,.39):
            pts=[(u+.23*(1-i/32)*math.cos(i*.30),.83+.20*(1-i/32)*math.sin(i*.30)) for i in range(28)]
            s.wall_line(side,pts,.035,bones,depth=.07)


def vortex(s):
    s.base(planks=False)
    s.flat(ellipse(0,0,1.05,1.05,40),2.02,.08,'#30243F',smooth=False,kind='PortalBed')
    # Stone voussoirs surrounding a recessed spiral, plus bright etched glyphs.
    for i in range(12):
        a=i*math.tau/12+.035;b=(i+1)*math.tau/12-.035
        pts=[(.86*math.cos(a),.86*math.sin(a)),(1.08*math.cos(a),1.08*math.sin(a)),(1.08*math.cos(b),1.08*math.sin(b)),(.86*math.cos(b),.86*math.sin(b))]
        plate(s,pts,2.10,.17,('#6B438D','#8659A4')[i%2],'PortalStone')
        x,y=.97*math.cos((a+b)/2),.97*math.sin((a+b)/2)
        s.disk(x,y,.033,'#D6A6EA',z=2.285,emit=.4,kind='PortalGlyph')
    s.flat(ellipse(0,0,.84,.84,40),2.10,.04,'#271C3E',smooth=False,kind='PortalWell')
    from caixas_catalogo import branch
    for phase in (0,math.tau/3,math.tau*2/3):
        pts=[]
        for i in range(24):
            a=phase+i*.13;r=.79-i*.027
            pts.append((r*math.cos(a),r*math.sin(a)))
        branch(s,pts,.13,'#A06BD1',z=2.16,taper=.12,thick=.055)
    arc(s,0,0,.18,0,math.tau,'#D6A8EB',z=2.20,width=.018)
    for x,y,sg in [(-1,-1,-1),(1,1,1)]:
        crystal(s,x,y,2.0,.15,.44,'#A876CA',tilt=(sg*.09,sg*.04),highlight='#E0B8ED')
    for side in range(4):
        for u in (-.65,0,.65):
            s.wall_line(side,[(u-.13,.67),(u,.45),(u+.13,.67),(u,1.04),(u-.13,.67)],.045,'#BD8BDD',emit=.35)
            s.wall_line(side,[(u,1.04),(u,1.37)],.045,'#BD8BDD',emit=.35)


def face_base(s,body,outline,points):
    s.base(planks=False)
    s.flat(points,2.03,.20,outline,kind='HeadBorder')
    s.flat([(x*.92,y*.92) for x,y in points],2.235,.075,body,kind='HeadSculpt')


def cat(s,lynx=False):
    body='#C29467' if lynx else '#D48539'
    ink='#624535' if lynx else '#62402E';cream='#E9D3AA' if lynx else '#EACBA0'
    points=[(-.83,-.66),(-.42,-.95),(.42,-.95),(.83,-.66),(1.0,-.12),(.83,.60),(.47,.91),(0,1.04),(-.47,.91),(-.83,.60),(-1.0,-.12)]
    face_base(s,body,ink,points)
    # Different silhouettes: round tiger ears; tufted ears and a cheek ruff for the lynx.
    for sg in (-1,1):
        if lynx:
            s.flat([(sg*.45,-.67),(sg*.85,-1.32),(sg*1.03,-.48)],2.08,.21,ink,smooth=False,kind='TuftedEar')
            s.flat([(sg*.60,-.68),(sg*.83,-1.09),(sg*.91,-.56)],2.295,.025,cream,smooth=False,kind='InnerEar')
            tube(s,[(sg*.83,-1.21,2.31),(sg*.86,-1.45,2.32),(sg*.80,-1.54,2.35)],.04,'#47372E','EarTuft',end=.006)
            s.flat([(sg*.58,.10),(sg*1.16,.21),(sg*.98,.41),(sg*1.14,.60),(sg*.76,.68),(sg*.51,.46)],2.28,.055,cream,smooth=False,kind='CheekRuff')
        else:
            puff(s,(sg*.73,-.80,2.19),(.33,.33,.15),ink,'RoundEar')
            puff(s,(sg*.73,-.80,2.33),(.22,.22,.06),cream,'InnerEar')
    for sg in (-1,1):
        puff(s,(sg*.27,.60,2.33),(.34,.27,.10),cream,'MuzzlePad')
        # Brow patch makes the eyes read in small overhead previews.
        s.flat(ellipse(sg*.39,-.12,.25,.16,14),2.315,.035,cream,smooth=False,kind='EyePatch')
        eye(s,sg*.39,-.10,2.36,'#90B4A0' if lynx else '#D9AE57',.145)
        for x,y in [(sg*.19,.52),(sg*.35,.57),(sg*.37,.69)]:s.disk(x,y,.022,ink,z=2.445,kind='WhiskerPore')
        for j in range(2):
            s.line([(sg*.46,.48+j*.17),(sg*.85,.41+j*.22)],.024,cream,z=2.37,kind='Whisker')
    s.flat([(-.15,.39),(.15,.39),(.10,.54),(0,.62),(-.10,.54)],2.45,.045,ink,kind='CatNose')
    tube(s,[(0,.61,2.46),(0,.72,2.45),(-.17,.80,2.40)],.018,ink,'MuzzleLine',sides=6)
    tube(s,[(0,.72,2.45),(.17,.80,2.40)],.018,ink,'MuzzleLine',sides=6)
    if lynx:
        for sg in (-1,1):
            for x,y,r in [(.54,-.51,.07),(.74,-.29,.055),(.17,-.65,.05),(.65,.11,.045)]:s.disk(sg*x,y,r,ink,z=2.32,ry=r*.75,kind='FurSpot')
    else:
        for pts in [[(-.13,-.85),(.13,-.85),(.08,-.47),(0,-.33),(-.08,-.47)],
                    [(-.68,-.55),(-.51,-.63),(-.24,-.39),(-.44,-.43)],
                    [(.68,-.55),(.51,-.63),(.24,-.39),(.44,-.43)]]:
            s.flat(pts,2.32,.025,ink,smooth=False,kind='TigerStripe')
        for sg in (-1,1):
            for y in (.13,.36):s.flat([(sg*.90,y-.11),(sg*.91,y+.04),(sg*.53,y+.12),(sg*.65,y)],2.325,.03,ink,smooth=False,kind='CheekStripe')
    for side in range(4):
        if lynx:
            for u,h,r in [(-.65,.65,.11),(-.25,1.15,.08),(.36,.72,.12),(.72,1.23,.08)]:s.wall(side,ellipse(u,h,r,r*.75,12),ink)
            s.wall_line(side,[(-.82,.38),(-.50,.51),(-.22,.40),(.11,.52),(.43,.41),(.76,.55)],.07,cream)
        else:
            for u in (-.63,0,.63):s.wall(side,[(u-.13,1.46),(u+.12,1.46),(u+.04,.94),(u-.12,.67),(u-.19,.95)],ink,kind='TigerFlankStripe')
            s.wall_line(side,[(-.85,.42),(.85,.42)],.12,cream)


def crocodile(s):
    s.base(planks=False)
    s.flat([(-.74,-.90),(0,-1.04),(.74,-.90),(.89,-.34),(.64,.13),(.57,1.05),(0,1.23),(-.57,1.05),(-.64,.13),(-.89,-.34)],2.04,.22,'#345E35',kind='CrocHeadOutline')
    s.flat([(-.63,-.80),(0,-.91),(.63,-.80),(.74,-.35),(.52,.12),(.47,.96),(0,1.09),(-.47,.96),(-.52,.12),(-.74,-.35)],2.27,.10,'#69994A',kind='CrocHead')
    s.box((0,.55,2.36),(.93,1.05,.16),'#7DA453','LongMuzzle',.11)
    for sg in (-1,1):
        puff(s,(sg*.50,-.37,2.39),(.25,.30,.13),'#8EAE62','EyeRidge')
        eye(s,sg*.50,-.38,2.515,'#E3CB75',.13)
        s.disk(sg*.23,.89,.075,'#355E37',z=2.47,ry=.05,kind='Nostril')
        for y in (.25,.59,.90):
            s.flat([(sg*.46,y-.09),(sg*.68,y+.03),(sg*.46,y+.12)],2.30,.07,'#D7D6A1',smooth=False,kind='CrocTooth')
    for y in (-.72,-.38,-.04):
        s.flat([(-.13,y),(0,y-.15),(.13,y),(0,y+.18)],2.39,.07,'#4F803D',smooth=False,kind='HeadScute')
    s.line([(-.37,1.02),(0,1.08),(.37,1.02)],.028,'#3B6538',z=2.45)
    for side in range(4):
        for row in range(2):
            for i in range(4):
                u=-.75+i*.5+row*.08;h=.61+row*.47
                s.wall(side,[(u-.18,h),(u,h-.14),(u+.18,h),(u,h+.18)],'#86A95E',depth=.06,kind='FlankScute')
        s.wall_line(side,[(-.96,.32),(.96,.32)],.11,'#B7C488')


def parrot(s):
    s.base(planks=False)
    s.flat(ellipse(0,-.06,.85,1.0,24),2.04,.19,'#753B32',smooth=False,kind='ParrotOutline')
    s.flat(ellipse(0,-.06,.75,.90,24),2.235,.065,'#C75343',smooth=False,kind='RedPlumage')
    # Tail feathers and overlapping wing feathers break out beyond the square lid.
    for x,col in [(-.25,'#547C94'),(0,'#559A8A'),(.25,'#C9934C')]:
        s.flat([(x-.13,-.65),(x-.16,-1.25),(x,-1.45),(x+.14,-1.20),(x+.12,-.65)],2.10,.075,col,kind='TailFeather')
    for sg in (-1,1):
        for i,col in enumerate(('#CF6948','#C6A85B','#63A294','#4B8296')):
            x=sg*(.63+i*.12);y=-.46+i*.21
            s.flat([(x-sg*.16,y-.30),(x+sg*.16,y-.09),(x+sg*.10,y+.55),(x-sg*.10,y+.38)],2.20+i*.018,.065,col,kind='WingFeather')
            s.line([(x,y-.15),(x,y+.36)],.018,'#BAD0B4',z=2.28+i*.018)
    s.flat(ellipse(0,.42,.55,.48,22),2.31,.06,'#E4D5B0',smooth=False,kind='FaceMask')
    for sg in (-1,1):
        eye(s,sg*.27,.27,2.39,'#B9A86C',.115)
        for j in range(2):s.line([(sg*.34,.44+j*.10),(sg*.48,.41+j*.10)],.018,'#92765B',z=2.39)
    # Hooked beak: upper horn and lower jaw in separate volumes.
    s.flat([(-.19,.42),(.18,.42),(.24,.68),(.10,1.12),(-.10,1.16),(-.05,.81),(-.25,.69)],2.41,.14,'#55504B',kind='HookedBeak')
    s.flat([(-.13,.54),(.14,.54),(.10,.80),(-.02,.91),(-.09,.72)],2.56,.04,'#B0A58A',kind='BeakHighlight')
    s.disk(.04,.49,.032,'#272F31',z=2.61,kind='BeakNostril')
    for side in range(4):
        for i,col in enumerate(('#C77A50','#D0B66D','#6EAE9C','#578B9E')):
            u=-.72+i*.46
            s.wall(side,[(u-.16,1.28),(u+.16,1.28),(u+.19,.74),(u,.46),(u-.19,.74)],col,depth=.055,kind='FeatherRelief')
            s.wall_line(side,[(u,1.17),(u,.62)],.025,'#E3D3A5',depth=.08)


def wood_frog(s):
    s.base(planks=True)
    # Carved wooden frog with crouching legs and splayed toes, not a round mammal face.
    s.flat([(-.78,-.53),(-.44,-.91),(.44,-.91),(.78,-.53),(.90,.14),(.61,.73),(0,.94),(-.61,.73),(-.90,.14)],2.03,.23,'#654931',kind='CarvedFrogOutline')
    s.flat([(-.67,-.46),(-.34,-.78),(.34,-.78),(.67,-.46),(.76,.12),(.51,.63),(0,.81),(-.51,.63),(-.76,.12)],2.27,.08,'#AE8150',kind='WoodFrogBody')
    for sg in (-1,1):
        puff(s,(sg*.51,-.59,2.33),(.31,.32,.14),'#D2AC76','CarvedEyeBulge')
        eye(s,sg*.51,-.60,2.465,'#8B9B63',.15)
        tube(s,[(sg*.61,.17,2.29),(sg*1.01,.39,2.23),(sg*.88,.79,2.18),(sg*1.10,.98,2.15)],.12,'#91683E','FoldedFrogLeg',end=.055)
        for k in range(3):
            x=sg*(.90+k*.18);y=1.10+(k%2)*.12
            tube(s,[(sg*1.10,.95,2.15),(x,y,2.13)],.04,'#C6A16C','FrogToe',end=.055,steps=2)
        s.disk(sg*.22,.27,.032,'#674C32',z=2.365,kind='Nostril')
    arc(s,0,.23,.49,.15,math.pi-.15,'#765536',z=2.37,width=.025,ry=.31)
    # Growth rings across the back and wood knots make the material explicit.
    for r in (.20,.32,.44):arc(s,0,-.20,r,3.8,5.6,'#C19862',z=2.36,width=.018,ry=r*.72)
    for x,y in [(-.55,.10),(.48,.32)]:
        arc(s,x,y,.08,0,math.tau,'#7C5A39',z=2.37,width=.016,ry=.045)
    vein_leaf(s,-.25,-.83,.55,.17,.75,'#729453',2.36)
    vein_leaf(s,-.25,-.83,.43,.14,-.65,'#84A364',2.37)
    for side in range(4):
        s.wall_line(side,[(-1,.52),(-.51,.65),(0,.55),(.56,.67),(1,.59)],.035,'#6E5034')
        s.wall_line(side,[(-1,1.25),(-.43,1.16),(.11,1.29),(.64,1.17),(1,1.25)],.035,'#C19A63')
        for r in (.12,.23,.34):
            pts=[(.26+r*math.cos(a),.88+r*.60*math.sin(a)) for a in [i*math.tau/24 for i in range(25)]]
            s.wall_line(side,pts,.025,'#735435')
        s.wall(side,[(-.9,.36),(-.63,.42),(-.71,.63),(-.88,.57)],'#76904E',depth=.06,kind='Moss')


BUILDERS={'magma':magma,'wind':wind,'robot':robot,'fossil':fossil,'vortex':vortex}
ANIMALS={'tiger':lambda s:cat(s,False),'lynx':lambda s:cat(s,True),
         'crocodile':crocodile,'parrot':parrot}
