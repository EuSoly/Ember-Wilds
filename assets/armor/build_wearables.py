"""Wearable costumes fitted to the captured player. Same .blend, separate review scenes."""
import bpy,bmesh,math,json,runpy
from mathutils import Vector,Matrix
from pathlib import Path
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
H=runpy.run_path(str(BASE/"build_helmet_tiers.py"))
material=H["material"]
# Reuse checked primitive builders with their own shared global namespace.
HG=H["mesh"].__globals__
mesh=H["mesh"];prism=H["prism"];tube=H["tube"];line=H["line"];ball=H["ball"];crystal=H["crystal"]
GROUPS={
"01 Frio e calor":[("earmuffs","PROTETOR DE ORELHA"),("coat","CASACO"),("winter_hat","GORRO E CACHECOL"),("fur_hat","CHAPEU DE PELE"),("turban","TURBANTE"),("ninja","ROUPA NINJA"),("pilot","CHAPEU DE PILOTO"),("diamond_protection","PROTECAO DE DIAMANTE"),("amethyst_protection","PROTECAO DE AMETISTA"),("reidite_protection","PROTECAO DE REIDITE")],
"02 Especiais":[("explorer","EXPLORADOR"),("hood","CAPUZ"),("winter_hood","CAPUZ DE INVERNO"),("peasant","TUNICA DE CAMPONES"),("winter_peasant","CAMPONES DE INVERNO"),("diving_mask","MASCARA DE MERGULHO"),("diving_suit","ROUPA DE MERGULHO"),("witch","CHAPEU DE BRUXA"),("santa","GORRO DE NATAL"),("elf","GORRO DE ELFO")],
"03 Coroas":[("life_crown","COROA DA VIDA"),("angel_crown","COROA DO ANJO"),("luck_crown","COROA DA SORTE")]}
COLORS={"cream":"E9D8B6","fur":"F4EBDD","leather":"815235","dark":"262E3A","blue":"457AAB","red":"AA3F38","teal":"3E9598","gold":"DFAE51","green":"5C7942","purple":"6C4296","black":"202534"}
def mat(k):return material("Roupa "+k,COLORS[k])
def start(id):
    global coll,root,group
    assert bpy.data.objects.get("wear_"+id) is None,id+" exists"
    group=next(g for g,rows in GROUPS.items() if any(i==id for i,t in rows))
    rows=GROUPS[group];idx=next(n for n,(i,t) in enumerate(rows) if i==id)
    scene=bpy.data.scenes.get("Armaduras - "+group)
    if not scene:
        scene=bpy.data.scenes.new("Armaduras - "+group);scene.world=bpy.data.scenes["Armaduras - 9 capacetes"].world.copy()
    bpy.context.window.scene=scene
    coll=bpy.data.collections.new("VEST_"+id);scene.collection.children.link(coll)
    root=bpy.data.objects.new("wear_"+id,None);coll.objects.link(root)
    root.location=(-(idx%3)*8.2,(idx//3)*9.2,0)
    root["item_id"]=id;root["status"]="Proposta visual; nao integrado";root["attachment"]="Body local origin; 1 unit=1 stud; +Y front"
    HG.update({"coll":coll,"root":root,"tag":id})
    refs=bpy.data.collections.new("MAN_"+id);scene.collection.children.link(refs)
    for src in bpy.data.collections["01 Personagem - copia do Studio"].objects:
        ob=src.copy();ob.data=src.data;ob.name=id+"_"+src.name;ob.parent=None
        refs.objects.link(ob);ob.matrix_world=Matrix.Translation(root.location)@src.matrix_world
        ob.hide_render=False;ob.hide_set(False)
def rounded_path(w=1.92,d=1.92,r=.96,steps=6):
    pts=[]
    for cx,cy,a in [(w-r,d-r,0),(-w+r,d-r,90),(-w+r,-d+r,180),(w-r,-d+r,270)]:
        for j in range(steps):
            ang=math.radians(a+j*90/(steps-1))
            pts.append((cx+r*math.cos(ang),cy+r*math.sin(ang)))
    return pts
def cloak(name,m,zlo=-.72,zhi=.95,front=1.30):
    pts=[(1.91,front),(1.95,.4),(1.95,-.96)]
    for i in range(1,9):
        a=-math.pi/2*i/8;pts.append((.96+.99*math.cos(a),-.96+.99*math.sin(a)))
    pts.extend([(.5,-1.95),(0,-1.95),(-.5,-1.95),(-.96,-1.95)])
    for i in range(1,9):
        a=-math.pi/2-math.pi/2*i/8;pts.append((-.96+.99*math.cos(a),-.96+.99*math.sin(a)))
    pts.extend([(-1.95,.4),(-1.91,front)])
    vs=[]
    for i,(x,y) in enumerate(pts):
        for z,t in [(zhi,1),(.0,1.04),(zlo,1.08),(zlo,1.02),(.0,.99),(zhi,.96)]:vs.append((x*t,y*t,z))
    fs=[]
    for i in range(len(pts)-1):
        for j in range(6):fs.append((i*6+j,(i+1)*6+j,(i+1)*6+(j+1)%6,i*6+(j+1)%6))
    fs+=[tuple(range(6))[::-1],tuple(range(len(vs)-6,len(vs)))]
    ob=mesh(name,vs,fs,m,.04)
    # Front fabric follows the vertical face below the eye platform.
    chest=[(1.91,1.30),(1.65,1.68),(.96,1.98),(0,1.98),(-.96,1.98),(-1.65,1.68),(-1.91,1.30)]
    cv=[]
    for x,y in chest:
        for z,t in [(zhi,1),(.0,1.04),(zlo,1.08),(zlo,1.02),(.0,.99),(zhi,.96)]:cv.append((x*t,y*t,z))
    cf=[]
    for i in range(len(chest)-1):
        for j in range(6):cf.append((i*6+j,(i+1)*6+j,(i+1)*6+(j+1)%6,i*6+(j+1)%6))
    cf+=[tuple(range(6))[::-1],tuple(range(len(cv)-6,len(cv)))]
    mesh(name+" - frente",cv,cf,m,.04)
    return ob
def fabric_cap(name,m,height=2.04,wide=1.92,front=-.13):
    # Smooth rounded crown bounded behind the player's eyes.
    outline=[(-wide,front),(-wide,-.88),(-wide*.88,-1.53),(-wide*.52,-1.94),(0,-2.02),(wide*.52,-1.94),(wide*.88,-1.53),(wide,-.88),(wide,front),(wide*.5,front-.04),(0,front-.10),(-wide*.5,front-.04)]
    center=Vector((0,-.86))
    vs=[]
    N=len(outline)
    for t,z in [(1,1.25),(.94,1.52),(.72,height-.1),(.36,height),(.02,height+.03)]:
        vs.extend([(center.x+(x-center.x)*t,center.y+(y-center.y)*t,z) for x,y in outline])
    fs=[]
    for k in range(4):
        for i in range(N):j=(i+1)%N;fs.append((k*N+i,k*N+j,(k+1)*N+j,(k+1)*N+i))
    fs+=[tuple(range(N))[::-1],tuple(range(4*N,5*N))]
    ob=mesh(name,vs,fs,m,.04)
    for p in ob.data.polygons:p.use_smooth=True
    return ob
def brow(m,z=1.31,r=.10):
    line("Bainha da testa",[(-1.95,.03,z),(-1.32,-.04,z+.08),(-.65,-.10,z+.12),(0,-.13,z+.13),(.65,-.10,z+.12),(1.32,-.04,z+.08),(1.95,.03,z)],r,m)
def furline(name,pts,r=.15,m=None):
    m=m or mat("fur")
    line(name+" base",pts,r*.85,m)
    for j in range(len(pts)-1):
        a=Vector(pts[j]);b=Vector(pts[j+1]);n=max(1,int((b-a).length/(r*1.15)))
        for k in range(n):
            p=a.lerp(b,k/n);ball(name+" tufo",p,(r,r*.84,r*.85),m,12)
def collar(m,fur=False):
    pts=[(-1.91,1.15,.97),(-1.45,1.56,1.04),(-.75,1.78,1.07),(0,1.84,1.07),(.75,1.78,1.07),(1.45,1.56,1.04),(1.91,1.15,.97)]
    if fur:furline("Gola felpuda",pts,.17,m)
    else:line("Gola",pts,.19,m)
def scarf(m):
    collar(m)
    prism("Ponta do cachecol",[(1.08,1.58,1.1),(1.54,1.55,1.11),(2.10,2.17,.32),(1.62,2.36,.23)],.13,m,.06)
    for i in range(4):line("Franja",[(1.65+i*.12,2.27,.3),(1.65+i*.12,2.53,.22)],.025,m)
def tail(name,pts,width,m):
    vs=[]
    for x,y,z in pts:vs.extend([(x-width/2,y,z),(x+width/2,y,z)])
    fs=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(pts)-1)]
    ob=mesh(name,vs,fs,m);s=ob.modifiers.new("Tecido","SOLIDIFY");s.thickness=.07;b=ob.modifiers.new("Bainha","BEVEL");b.width=.035;b.segments=2
    return ob
def loop(name,center,rx,ry,m,r=.055,z=0,segments=32):
    x,y,zz=center
    pts=[(x+rx*math.cos(a*2*math.pi/segments),y+ry*math.sin(a*2*math.pi/segments),zz+z) for a in range(segments+1)]
    return line(name,pts,r,m)
def goggles(m,center_y=.55,z=1.26,forehead=False):
    rx=.53 if not forehead else .45;ry=.48 if not forehead else .34
    for side in (-1,1):
        x=side*(.80 if not forehead else .64)
        loop("Aro dos oculos",(x,center_y,z),rx,ry,m,.085)
        if forehead:ball("Lente escura",(x,center_y,z-.03),(rx*.85,ry*.85,.025),mat("dark"))
        else:
            line("Brilho na lente",[(x-.21,center_y-.29,z+.015),(x-.04,center_y-.35,z+.015),(x+.11,center_y-.32,z+.015)],.016,material("Vidro brilho","BCE8EC"))
    line("Ponte dos oculos",[(-.25,center_y,z),(.25,center_y,z)],.07,m)
def gem(name,pos,m,r=.22,h=.38,sides=6):
    crystal(name,(pos[0],pos[1],pos[2]),(pos[0],pos[1],pos[2]+h),r,m,None,sides)
def stitches(points,m=None):
    m=m or mat("cream")
    for i,p in enumerate(points):
        x,y,z=p;line("Ponto da costura",[(x-.04,y-.02,z),(x+.04,y+.02,z)],.012,m)
def leaf(name,pos,scale,m,ang=0):
    x,y,z=pos;s=scale
    poly=[(0,s,0),(-s*.38,0,.10),(0,-s,0),(s*.38,0,.10)]
    c=math.cos(ang);si=math.sin(ang)
    pts=[(x+a*c-b*si,y+a*si+b*c,z+d) for a,b,d in poly]
    return prism(name,pts,.035,m,.018)
def ears(m,flap=False):
    for s in (-1,1):
        ball("Protecao da orelha",(s*1.98,-.02,1.02),(.28,.61,.45 if not flap else .72),m)
def brim(m,width=2.42,back=2.22,z=1.34):
    pts=[(-width,.03,z),(-width,-.90,z+.03),(-width*.88,-1.80,z+.02),(-width*.48,-back,z),(0,-back-.08,z),(width*.48,-back,z),(width*.88,-1.80,z+.02),(width,-.90,z+.03),(width,.03,z),(width*.5,-.14,z),(0,-.18,z),( -width*.5,-.14,z)]
    return prism("Aba larga",pts,.12,m,.06)
def earmuffs():
    start("earmuffs");teal=mat("teal")
    pts=[(-1.98,-.12,1.2),(-1.75,-.45,1.75),(-1.05,-.63,2.04),(0,-.67,2.14),(1.05,-.63,2.04),(1.75,-.45,1.75),(1.98,-.12,1.2)]
    line("Arco acolchoado",pts,.105,teal)
    for s in (-1,1):
        ball("Concha externa",(s*2.04,-.08,1.1),(.36,.61,.55),teal)
        for j in range(7):
            a=2*math.pi*j/7;ball("Pelucia",(s*2.13,-.08+.39*math.cos(a),1.1+.35*math.sin(a)),(.30,.22,.21),mat("fur"),12)
    root["design"]="Arco turquesa fino e duas conchas de pelucia creme."
def coat():
    start("coat");m=mat("leather");cloak("Casaco de pele",m);fabric_cap("Capuz arredondado",m,1.85)
    brow(mat("fur"),1.32,.17);collar(mat("fur"),True);ears(m)
    for s in (-1,1):
        line("Cordao",( (s*.28,1.78,.98),(s*.38,1.92,.40)),.035,mat("cream"))
        ball("Botao de madeira",(s*.38,1.93,.36),(.10,.07,.12),mat("dark"),12)
    root["design"]="Casaco castanho com gola e capuz de pele, cordoes e fechos."
def winter_hat():
    start("winter_hat");m=mat("blue")
    fabric_cap("Gorro de la",m,2.27);brow(material("La clara","78A3C7"),1.4,.19)
    for x in [-1.4,-1,-.6,-.2,.2,.6,1,1.4]:
        line("Trama do gorro",[(x,-.25,1.55),(x*.78,-.58,2.03),(x*.40,-.88,2.27)],.018,material("La costura","30618D"))
    ball("Pom pom",(0,-.91,2.45),(.35,.34,.30),mat("fur"));scarf(mat("red"))
    root["design"]="Gorro azul com trama, pompom branco e cachecol vermelho com franjas."
def fur_hat():
    start("fur_hat");m=material("Pele de mamute","B7A68D")
    fabric_cap("Ushanka acolchoada",m,1.91);ears(m,True)
    furline("Faixa frontal",[(-1.90,.04,1.42),(-.95,-.12,1.53),(0,-.19,1.56),(.95,-.12,1.53),(1.90,.04,1.42)],.21)
    for s in (-1,1):
        furline("Aba de orelha",[(s*1.96,.2,1.22),(s*1.99,.42,.87),(s*1.93,.60,.44)],.21)
    stitches([(x,-.62,2.01) for x in [-1.1,-.8,-.5,0,.5,.8,1.1]],mat("leather"))
    root["design"]="Chapeu de pele tipo ushanka, abas longas e faixa espessa de pelo."
def turban():
    start("turban");m=mat("cream");fabric_cap("Base do turbante",m,2.05)
    for j in range(4):
        pts=[(-1.87,-.08-j*.16,1.35+j*.15),(-1.13,-.18-j*.20,1.60+j*.14),(0,-.35-j*.20,1.83+j*.10),(1.13,-.18-j*.20,1.60+j*.14),(1.87,-.08-j*.16,1.35+j*.15)]
        line("Faixa enrolada",pts,.17,m)
    gem("Broche",(0,-.20,1.85),mat("gold"),.18,.22,6)
    tail("Pano caido",[(1.64,-1.2,1.7),(2.0,-1.72,1.0),(2.16,-2.27,.25)],.52,m)
    root["design"]="Turbante de linho com voltas sobrepostas, broche e cauda de tecido."
def ninja():
    start("ninja");m=mat("black");fabric_cap("Capuz ninja",m,1.93);cloak("Manto ninja",m)
    brow(material("Ninja faixa","3C465A"),1.31,.11)
    # Lower mask stays in front of, never on top of the eye discs.
    prism("Mascara de tecido",[(-1.48,1.20,1.22),(-.7,1.12,1.24),(.7,1.12,1.24),(1.48,1.20,1.22),(1.28,1.80,1.10),(-1.28,1.80,1.10)],.15,m,.07)
    for k in range(2):tail("Ponta da faixa",[(.6,-1.75,1.54),(1.35+k*.25,-2.22,1.85),(2.25+k*.25,-2.70,1.74-k*.28)],.24,mat("red"))
    stitches([(x,1.5,1.25) for x in [-.8,-.5,0,.5,.8]],material("Ninja costura","525E72"))
    root["design"]="Capuz escuro, mascara inferior e duas pontas vermelhas atras."
def pilot():
    start("pilot");m=mat("leather");fabric_cap("Touca de aviador",m,1.97);ears(m,True);brow(mat("cream"),1.31,.08)
    goggles(mat("gold"),-.53,2.02,True)
    line("Correia dos oculos",[(-1.96,-.55,1.41),(-1.1,-.60,1.98),(1.1,-.60,1.98),(1.96,-.55,1.41)],.075,mat("dark"))
    stitches([(0,-.1-i*.18,2.02 if i<6 else 1.85) for i in range(9)])
    root["design"]="Touca de couro com abas, costura central e oculos de aviador na testa."
def thermal(id,hexcol,style):
    start(id);m=material(id,hexcol,.35,.4);light=material(id+" claro",{"diamond_protection":"A6EBEC","amethyst_protection":"C7A4EE","reidite_protection":"F58DBB"}[id],.3)
    cloak("Manto termico",m);fabric_cap("Capuz isolante",m,2.05);ears(m)
    if style==0:
        brow(light,1.34,.12);goggles(mat("dark"))
        for x in [-1.05,0,1.05]:
            prism("Painel refletor",[(x-.25,-.35,1.9),(x+.25,-.35,1.9),(x+.25,-1.28,2.04),(x-.25,-1.28,2.04)],.10,light)
        scarf(light)
    elif style==1:
        brow(mat("gold"),1.35,.095);goggles(mat("gold"))
        for j in range(4):
            prism("Defletor de calor",[(-1.45,-.28-j*.34,1.75+j*.05),(0,-.42-j*.34,2.20-j*.02),(1.45,-.28-j*.34,1.75+j*.05),(1.35,-.55-j*.34,1.77),(-1.35,-.55-j*.34,1.77)],.08,light if j%2 else m)
        collar(mat("dark"))
    else:
        brow(mat("dark"),1.35,.16);goggles(mat("dark"))
        for s in (-1,1):
            ball("Filtro termico",(s*1.27,1.52,1.15),(.30,.28,.23),mat("dark"))
            for j in range(3):line("Ranhura do filtro",[(s*1.27-.14,1.42+j*.09,1.36),(s*1.27+.14,1.42+j*.09,1.36)],.017,light)
        prism("Respirador central",[(-.42,1.24,1.23),(.42,1.24,1.23),(.28,1.76,1.29),(-.28,1.76,1.29)],.18,mat("dark"),.08)
        for s in (-1,1):line("Canal de ventilacao",[(s*1.2,-.2,1.84),(s*.9,-.85,2.12),(s*1,-1.5,1.91)],.06,light)
    root["design"]=["Capuz refletor ciano, paineis prateados e oculos protetores.","Manto violeta, quatro defletores de calor e oculos dourados.","Traje termico magenta com respirador, filtros e canais isolantes."][style]
BUILDERS={"earmuffs":earmuffs,"coat":coat,"winter_hat":winter_hat,"fur_hat":fur_hat,"turban":turban,"ninja":ninja,"pilot":pilot,
"diamond_protection":lambda:thermal("diamond_protection","3FD0E0",0),"amethyst_protection":lambda:thermal("amethyst_protection","9B5DE5",1),"reidite_protection":lambda:thermal("reidite_protection","D63384",2)}
def explorer():
    start("explorer");m=material("Explorador caqui","C49C59");dark=mat("leather")
    brim(m,2.40,2.18,1.37);fabric_cap("Copa do chapeu",m,2.16,1.63,-.40)
    brow(dark,1.61,.095)
    stitches([(x,-.53,2.16) for x in [-1.1,-.8,-.5,-.2,.2,.5,.8,1.1]],mat("cream"))
    for s in (-1,1):
        ball("Ilhos do chapeu",(s*1.50,-.64,1.85),(.065,.065,.045),dark,12)
    leaf("Pena verde",(1.73,-1.06,1.78),.52,mat("green"),-.3)
    line("Haste da pena",[(1.58,-.60,1.67),(1.82,-1.55,1.90)],.025,mat("cream"))
    root["design"]="Chapeu caqui de aba larga, costuras, faixa de couro e pena verde."
def hood(winter=False):
    id="winter_hood" if winter else "hood";start(id)
    m=material("Capuz inverno","557B91") if winter else material("Capuz bosque","44634B")
    cloak("Manto comprido",m,-.84,1.12);fabric_cap("Capuz pontudo",m,2.03)
    tube("Ponta do capuz",[(0,-1.22,1.96),(0,-1.80,2.25),(.15,-2.48,2.12)],[.52,.35,.015],m,12)
    if winter:
        furline("Borda do capuz",[(-1.9,.07,1.30),(-1.1,-.1,1.46),(0,-.18,1.52),(1.1,-.1,1.46),(1.9,.07,1.30)],.15)
        scarf(mat("cream"));ears(mat("fur"),True)
    else:
        brow(mat("dark"),1.30,.14);collar(mat("leather"))
        for s in (-1,1):line("Laco",[(s*.1,1.85,1.03),(s*.4,2.05,.70),(s*.32,2.12,.52)],.035,mat("cream"))
        ball("Fecho",(0,1.89,1.08),(.13,.09,.09),mat("gold"),12)
    root["design"]="Capuz azul com borda de pelo e cachecol claro." if winter else "Capuz verde pontudo com manto e laco de corda."
def peasant(winter=False):
    id="winter_peasant" if winter else "peasant";start(id)
    straw=material("Palha","CDAA65");dark=material("Palha trancada","93703E")
    cloak("Tunica",mat("blue") if winter else mat("green"))
    brim(straw,2.64,2.36,1.38);fabric_cap("Copa de palha",straw,1.89,1.63,-.40)
    brow(mat("blue") if winter else dark,1.61,.095)
    for j in range(15):
        a=math.pi*(.08+j*.84/14);x=2.4*math.cos(a);y=-.55-1.65*math.sin(a)
        line("Trama radial",[(x*.72,y*.72,1.49),(x,y,1.48)],.012,dark)
    for j in range(3):line("Palha da copa",[(-1.5,-.65-j*.28,1.78),(0,-.84-j*.2,1.97),(1.5,-.65-j*.28,1.78)],.014,dark)
    if winter:
        scarf(mat("blue"));furline("Pelo da aba",[(-1.90,-.02,1.48),(0,-.25,1.56),(1.90,-.02,1.48)],.14)
        prism("Remendo",[(.72,-1.20,1.97),(1.13,-1.15,1.92),(1.12,-.73,1.96),(.74,-.74,2.03)],.02,mat("cream"))
    else:
        collar(mat("cream"))
        for j in range(5):
            leaf("Espiga",(1.5,-.7-j*.18,1.90),.13,mat("gold"),(-1)**j*.65)
        line("Caule do trigo",[(1.5,-.4,1.86),(1.5,-1.5,1.92)],.02,dark)
    root["design"]="Chapeu de palha com remendo, forro de pelo e tunica azul." if winter else "Chapeu de palha trancada, espiga e tunica verde."
def diving(suit=False):
    id="diving_suit" if suit else "diving_mask";start(id)
    navy=material("Mergulho neoprene","233E51");rubber=mat("dark");teal=material("Mergulho turquesa","2EC4B6")
    if suit:
        fabric_cap("Capuz de neoprene",navy,1.88);cloak("Roupa de neoprene",navy);collar(teal)
        for s in (-1,1):
            # Bottles fixed behind the head, outside the face silhouette.
            tube("Cilindro de ar",[(s*.8,-2.1,.1),(s*.8,-2.1,1.70)],[.27,.27],mat("gold"),16,.04)
            line("Mangueira",[(s*.8,-2.13,1.55),(s*1.9,-1.50,1.60),(s*2.08,.60,1.18),(s*.42,1.61,1.21)],.075,rubber)
        goggles(mat("gold"))
        ball("Regulador",(0,1.56,1.18),(.30,.22,.15),rubber)
        line("Marca do regulador",[(-.14,1.66,1.31),(.14,1.66,1.31)],.025,teal)
    else:
        goggles(teal)
        line("Correia da mascara",[(-1.82,.48,1.14),(-1.91,-1,1.26),(0,-1.95,1.32),(1.91,-1,1.26),(1.82,.48,1.14)],.08,rubber)
        tube("Snorkel",[(1.45,1.27,1.12),(2.16,.94,1.24),(2.25,-.10,1.40),(2.25,-1.12,2.07),(2.10,-1.4,2.18)],[.10,.10,.11,.11,.13],teal,12)
        tube("Ponta do snorkel",[(2.10,-1.4,2.18),(1.89,-1.52,2.20)],[.15,.15],rubber,12)
    root["design"]="Roupa azul escura, oculos de latão, cilindros e mangueiras." if suit else "Mascara turquesa com aros abertos, correia e snorkel lateral."
def witch():
    start("witch");purple=mat("purple");dark=mat("black")
    brim(dark,2.60,2.45,1.40)
    tube("Cone torto",[(0,-.85,1.51),(0,-.85,2.08),(.05,-.88,2.85),(.40,-.92,3.45),(.90,-.88,3.70),(1.30,-.70,3.58)],[1.25,1.0,.59,.32,.16,.015],purple,16)
    # The broad cone is behind the eyes, not over them.
    brow(mat("leather"),1.71,.13)
    prism("Fivela",[(-.28,-.14,1.76),(.28,-.14,1.76),(.28,-.39,2.01),(-.28,-.39,2.01)],.07,mat("gold"))
    gem("Pedra da fivela",(0,-.23,1.9),mat("green"),.16,.22,4)
    for j in range(3):gem("Estrela do chapeu",(-.5+j*.4,-.23-j*.20,2.12+j*.35),mat("gold"),.07,.1,4)
    root["design"]="Chapeu violeta alto de ponta torta, aba larga e fivela dourada."
def santa():
    start("santa");red=mat("red")
    fabric_cap("Base do gorro",red,2.0)
    tube("Gorro caido",[(0,-.85,1.86),(0,-.80,2.35),(.50,-.80,2.77),(1.13,-.70,2.65),(1.55,-.50,2.20)],[.83,.64,.39,.26,.08],red,16)
    furline("Faixa branca",[(-1.90,.04,1.42),(-.95,-.12,1.53),(0,-.19,1.56),(.95,-.12,1.53),(1.90,.04,1.42)],.18)
    ball("Pom pom",(1.55,-.5,2.14),(.30,.30,.32),mat("fur"))
    root["design"]="Gorro vermelho tombado para o lado, faixa branca e pompom."
def elf():
    start("elf");green=material("Elfo verde","407552");red=mat("red")
    fabric_cap("Base do gorro de elfo",green,1.8)
    tube("Ponta curva",[(0,-.8,1.7),(-.15,-1,2.3),(-.50,-1.15,2.80),(-1.04,-1.12,3.02),(-1.45,-.85,2.78)],[.89,.66,.40,.18,.02],green,14)
    brow(red,1.4,.16)
    for x in [-1.50,-.75,0,.75,1.50]:
        prism("Dente da faixa",[(x-.26,-.08,1.52),(x+.26,-.08,1.52),(x,.23,1.25)],.04,red)
    ball("Guizo",(-1.47,-.85,2.72),(.18,.18,.18),mat("gold"))
    for s in (-1,1):
        prism("Orelha de elfo",[(s*1.78,.05,1.20),(s*2.40,-.25,1.74),(s*2.22,.55,1.22),(s*1.86,.65,.90)],.13,mat("cream"),.04)
    root["design"]="Gorro verde curvo com guizo, faixa dentada vermelha e orelhas pontudas."
def coronet(name,m,points=5):
    N=60;vs=[]
    for i in range(N):
        a=2*math.pi*i/N
        # Front is +Y; band stays behind the player's eye area.
        x=1.74*math.cos(a);y=-.93+.97*math.sin(a)
        tooth=max(0,math.cos(points*a))**7
        ztop=1.86+.46*tooth
        n=Vector((math.cos(a),math.sin(a)))*.13
        vs.extend([(x,y,1.38),(x,y,ztop),(x-n.x,y-n.y,ztop),(x-n.x,y-n.y,1.38)])
    fs=[]
    for i in range(N):
        for j in range(4):fs.append((4*i+j,4*((i+1)%N)+j,4*((i+1)%N)+(j+1)%4,4*i+(j+1)%4))
    return mesh(name,vs,fs,m,.023)
def crown(kind):
    id=kind+"_crown";start(id)
    gold=material("Coroas ouro","E8B84F",.6,.3);light=material("Coroas prata","E2E4DC",.6,.3)
    if kind=="life":
        coronet("Coroa folhada",gold,5)
        green=material("Gema da vida","38AB68",.3,.26)
        for s in (-1,1):
            for j in range(4):
                leaf("Folha da vida",(s*(.55+j*.32),-.12-j*.21,1.82+j*.04),.29,green,s*(.5+j*.12))
        gem("Esmeralda central",(0,.03,1.80),green,.32,.52,6)
        loop("Borda da coroa",(0,-.93,1.43),1.75,.98,gold,.06)
        root["design"]="Coroa dourada com folhas verdes e esmeralda central."
    elif kind=="angel":
        coronet("Diadema do anjo",light,3);cyan=material("Gema do anjo","66D7F4",.3,.22)
        for s in (-1,1):
            for j in range(4):
                p=[(s*1.30,-.65,1.65),(s*(2.05+j*.10),-.7-j*.15,2.0),(s*(2.28-j*.09),-1.20-j*.20,2.72+j*.07),(s*1.48,-1.0-j*.14,2.05)]
                prism("Pena da asa",p,.10,mat("fur"),.045)
        gem("Safira central",(0,.02,1.80),cyan,.30,.50,6)
        loop("Halo",(0,-1.18,2.75),.72,.50,gold,.055)
        root["design"]="Diadema prateado com asas claras, safira e pequeno halo."
    else:
        coronet("Coroa da fortuna",gold,7);amber=material("Gema da sorte","F39A37",.35,.25);green=mat("green")
        gem("Topazio central",(0,.02,1.80),amber,.32,.54,5)
        for s in (-1,1):
            for j in range(3):gem("Pedra lateral",(s*(.65+j*.35),-.16-j*.24,1.86),amber,.10,.18,5)
        # Four heart-like leaves form a clover on a raised medallion.
        ball("Medalhao",(0,-.96,2.13),(.43,.43,.08),gold)
        for x,y in [(-.15,-.15),(.15,-.15),(-.15,.15),(.15,.15)]:
            ball("Folha do trevo",(x,-.96+y,2.23),(.17,.17,.045),green,12)
        root["design"]="Coroa de sete pontas, topazio laranja e medalhao com trevo."
BUILDERS.update({"explorer":explorer,"hood":lambda:hood(False),"winter_hood":lambda:hood(True),
"peasant":lambda:peasant(False),"winter_peasant":lambda:peasant(True),
"diving_mask":lambda:diving(False),"diving_suit":lambda:diving(True),
"witch":witch,"santa":santa,"elf":elf,
"life_crown":lambda:crown("life"),"angel_crown":lambda:crown("angel"),"luck_crown":lambda:crown("luck")})

def build_many(ids):
    for id in ids:
        BUILDERS[id]();bpy.context.view_layer.update();print("CREATED",id,len(coll.objects),root.get("design"))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))

