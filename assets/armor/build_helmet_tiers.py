"""Distinct helmet silhouettes, all retained in the approved .blend.
Run build_many([...]) then present_gallery(). Coordinates: +Y front, +Z up.
"""
import bpy,bmesh,math,json
from mathutils import Vector,Matrix
from pathlib import Path
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
ORDER=["wood","stone","gold","diamond","amethyst","reidite","dragon","crab","lava"]
LABELS=["MADEIRA","PEDRA","OURO","DIAMANTE","AMETISTA","REIDITE","DRAGAO","CARANGUEJO","LAVA"]
POS={k:Vector(((i%3)*7.6,-(i//3)*8.6,0)) for i,k in enumerate(ORDER)}
def material(name,h,metal=0,rough=.65,emit=0):
    name="ARM_"+name
    if bpy.data.materials.get(name):return bpy.data.materials[name]
    rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    rgb=[x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4 for x in rgb]
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*rgb,1)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=(*rgb,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    if emit:bs.inputs['Emission Color'].default_value=(*rgb,1);bs.inputs['Emission Strength'].default_value=emit
    return m
def start(tier):
    global coll,root,tag
    assert not bpy.data.objects.get(tier+"_helmet"),tier+" already modeled"
    tag=tier
    coll=bpy.data.collections.new("CAP_"+tier);bpy.context.scene.collection.children.link(coll)
    root=bpy.data.objects.new(tier+"_helmet",None);coll.objects.link(root)
    root.location=POS[tier];root["item_id"]=tier+"_helmet";root["attachment"]="Body local origin; 1 unit=1 stud; +Y front"
    root["status"]="Proposta visual - sem integracao no jogo"
    mannequin=bpy.data.collections.new("REF_"+tier+" - personagem");bpy.context.scene.collection.children.link(mannequin)
    for src in bpy.data.collections['01 Personagem - copia do Studio'].objects:
        ob=src.copy();ob.data=src.data;ob.name=tier+"_"+src.name
        mannequin.objects.link(ob);ob.parent=None;ob.matrix_world=Matrix.Translation(POS[tier])@src.matrix_world
        ob.hide_render=False;ob.hide_set(False)
    return root
def mesh(name,vs,fs,mat,bevel=0):
    me=bpy.data.meshes.new(tag+"_"+name);me.from_pydata(vs,[],fs);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(tag+"_"+name,me);coll.objects.link(ob);ob.parent=root;me.materials.append(mat)
    if bevel:
        md=ob.modifiers.new("Arredondamento","BEVEL");md.width=bevel;md.segments=2
    return ob
def prism(name,poly,depth,mat,bevel=.025):
    vs=list(poly)+[(x,y,z-depth) for x,y,z in poly];n=len(poly)
    return mesh(name,vs,[tuple(range(n)),tuple(range(n,2*n))[::-1]]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],mat,bevel)
def tube(name,points,radii,mat,sides=8,bevel=0):
    vs=[]
    for i,p in enumerate(points):
        p=Vector(p);direction=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        rot=direction.to_track_quat('Z','Y')
        for j in range(sides):
            a=j*2*math.pi/sides
            v=p+rot@Vector((radii[i]*math.cos(a),radii[i]*math.sin(a),0));vs.append(tuple(v))
    fs=[]
    for i in range(len(points)-1):
        for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
    fs+=[tuple(range(sides))[::-1],tuple(range(len(vs)-sides,len(vs)))]
    return mesh(name,vs,fs,mat,bevel)
def line(name,points,r,mat):
    return tube(name,points,[r]*len(points),mat,6)
def ball(name,pos,scale,mat,segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=8,radius=1)
    ob=bpy.context.object
    for c in list(ob.users_collection):c.objects.unlink(ob)
    coll.objects.link(ob);ob.name=tag+"_"+name;ob.parent=root;ob.location=pos;ob.scale=scale;ob.data.materials.append(mat)
    for f in ob.data.polygons:f.use_smooth=True
    return ob
def crystal(name,base,tip,r,mat,light=None,sides=5):
    a=Vector(base);b=Vector(tip);q=(b-a).to_track_quat('Z','Y');vs=[]
    for z,rad in ((0,r*.72),(.64,r)):
        center=a+(b-a)*z
        for i in range(sides):
            angle=2*math.pi*i/sides
            vs.append(tuple(center+q@Vector((rad*math.cos(angle),rad*math.sin(angle),0))))
    vs.append(tuple(b));fs=[tuple(range(sides))[::-1]]
    for i in range(sides):j=(i+1)%sides;fs.extend([(i,j,j+sides,i+sides),(i+sides,j+sides,2*sides)])
    ob=mesh(name,vs,fs,mat,.012)
    if light:
        ob.data.materials.append(light)
        for i,p in enumerate(ob.data.polygons):p.material_index=1 if i%3==1 else 0
    return ob
DEFAULT=[(-1.93,-.05),(-1.93,-.95),(-1.65,-1.65),(-.95,-1.93),(0,-1.93),(.95,-1.93),(1.65,-1.65),(1.93,-.95),(1.93,-.05),(.95,-.10),(0,-.17),(-.95,-.10)]
def cap(name,mats,outline,peak=1.9,foot=None,edge_z=1.28,facet=False):
    poly=foot or DEFAULT;n=len(poly);center=Vector((0,-.8))
    # Broad, closed armor dome. Each tier supplies its own edge and mass.
    rings=[]
    for t,z in [(1,edge_z),(.63,peak-.12),(.12,peak)]:
        rings.append([(center.x+(x-center.x)*t,center.y+(y-center.y)*t,z) for x,y in poly])
    vs=sum(rings,[]);fs=[]
    for k in range(2):
        for i in range(n):j=(i+1)%n;fs.append((k*n+i,k*n+j,(k+1)*n+j,(k+1)*n+i))
    fs.append(tuple(range(2*n,3*n)));fs.append(tuple(range(n))[::-1])
    ob=mesh(name,vs,fs,mats[0],.045 if not facet else .022)
    for ma in mats[1:]:ob.data.materials.append(ma)
    for i,p in enumerate(ob.data.polygons):p.material_index=(i%len(mats))
    # Rear skirt; leave the face open across the last four edge segments.
    for i in range(8):
        x,y=poly[i];xx,yy=poly[(i+1)%n]
        inward=Vector((xx-x,yy-y)).orthogonal().normalized()*.13
        middle=Vector(((x+xx)/2,(y+yy)/2))
        if inward.dot(-middle)<0:inward=-inward
        v=[(x,y,.16),(xx,yy,.16),(xx,yy,edge_z),(x,y,edge_z)]
        v += [(a+inward.x,b+inward.y,c) for a,b,c in v[:]]
        mesh(name+"_lateral_%d"%i,v,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],mats[i%len(mats)],.025)
    brow=[(*poly[i],edge_z+.015) for i in [0,11,10,9,8]]
    line(name+"_contorno_testa",brow,.085,outline)
    return ob
def guards(name,mat,style="angular"):
    for side in (-1,1):
        if style=="angular":
            p=[(side*1.72,.08,1.34),(side*2.10,.05,1.38),(side*2.14,1.10,.95),(side*1.84,1.32,.52),(side*1.72,.65,.75)]
        elif style=="leaf":
            p=[(side*1.70,.05,1.39),(side*2.14,-.05,1.56),(side*2.20,.60,1.22),(side*1.90,1.38,.68),(side*1.69,.57,.92)]
        else:
            p=[(side*1.73,.1,1.33),(side*2.12,.14,1.3),(side*2.08,1.05,1.05),(side*1.76,1.17,.82)]
        prism(name+str(side),p,.18,mat,.045)
def stone():
    start("stone")
    dark=material("Pedra sombra","353D47");stone=material("Pedra","8A8F98");light=material("Pedra face clara","AAB0B6");mid=material("Pedra face azul","707B88")
    cap("Elmo rochoso",[stone,mid,stone,light],dark,1.87,facet=True)
    guards("Protetores grossos",stone,"block")
    # Blunt stone horns are low and broad, giving a rugged silhouette.
    for s in (-1,1):
        tube("Chifre de rocha "+str(s),[(s*1.62,-.65,1.48),(s*2.15,-.9,1.66),(s*2.48,-1.03,2.06),(s*2.43,-1.02,2.42)],[.36,.32,.19,.035],stone,6)
        line("Fratura"+str(s),[(s*.42,-.25,1.78),(s*.61,-.50,1.83),(s*.51,-.68,1.88),(s*.79,-.91,1.82)],.016,dark)
    prism("Testa pedra central",[(-.37,-.06,1.46),(0,.08,1.65),(.37,-.06,1.46),(0,-.38,1.79)],.16,light,.035)
    root["design"]="Elmo baixo de rocha facetada; chifres curtos de pedra; placas grossas."
def gold():
    start("gold")
    dark=material("Ouro sombra","68401B",.35);gold=material("Ouro","F2B632",.65,.32);light=material("Ouro claro","FFE09A",.55,.3);bronze=material("Ouro bronze","B47821",.55)
    cap("Elmo real",[gold,gold,bronze,gold],dark,2.02)
    guards("Abas douradas",gold,"leaf")
    # A tall forged sagittal crest, unlike stone horns and wood planks.
    prism("Crista longitudinal",[(-.16,-1.8,1.58),(-.16,-1.3,2.38),(-.16,-.65,2.62),(-.16,-.12,2.05),(.16,-.12,2.05),(.16,-.65,2.62),(.16,-1.3,2.38),(.16,-1.8,1.58)],.13,bronze,.045)
    tube("Topo da crista",[(0,-1.72,1.76),(0,-1.25,2.45),(0,-.65,2.65),(0,-.15,2.14)],[.10,.10,.12,.065],light,6)
    for s in (-1,1):
        line("Friso dourado "+str(s),[(s*1.85,-.1,1.35),(s*1.15,-.32,1.81),(s*.28,-.29,1.94)],.055,light)
        ball("Rebite", (s*1.9,.36,1.33),(.085,.085,.07),light,12)
    prism("Brasao da testa",[(-.27,-.15,1.74),(0,.03,1.42),(.27,-.15,1.74),(0,-.40,1.94)],.12,light)
    root["design"]="Elmo metalico com crista alta central e abas em folha."
def diamond():
    start("diamond")
    dark=material("Diamante sombra","165D78",.25);ice=material("Diamante","3FD0E0",.35,.23);light=material("Diamante claro","B7F6F5",.3,.2);mid=material("Diamante azul","228FAF",.35)
    foot=[(-1.98,0),(-1.98,-1.16),(-1.5,-1.85),(-.85,-2.10),(0,-2.18),(.85,-2.10),(1.5,-1.85),(1.98,-1.16),(1.98,0),(.96,-.14),(0,.04),(-.96,-.14)]
    cap("Coroa glacial",[ice,light,ice,mid],dark,1.85,foot,facet=True)
    guards("Placas de cristal",ice,"angular")
    for i,(x,y,h,r) in enumerate([(-1.46,-1.10,2.55,.30),(0,-1.45,2.90,.38),(1.46,-1.10,2.55,.30)]):
        crystal("Ponta glacial %d"%i,(x,y,1.6),(x*1.20,y-.25,h),r,ice,light,5)
    crystal("Gema frontal",(0,-.15,1.5),(0,-.25,2.18),.30,mid,light,4)
    for s in (-1,1):
        line("Aresta branca"+str(s),[(s*1.88,-.06,1.38),(s*1.2,-.35,1.77),(s*.42,-.4,1.82)],.035,light)
    root["design"]="Coroa glacial angular; tres espigoes cristalinos e lapidacao azul."
def amethyst():
    start("amethyst")
    dark=material("Ametista sombra","352052",.25);pur=material("Ametista","9B5DE5",.3,.34);light=material("Ametista clara","D8AFF4",.25);mid=material("Ametista profunda","6940A0",.35)
    cap("Elmo lunar",[mid,pur,pur],dark,1.80)
    guards("Faces alongadas",mid,"leaf")
    # Swept crescent wings form a wide silhouette, with layered gem plates.
    for s in (-1,1):
        for j in range(3):
            p=[(s*(1.38+j*.08),-.15-j*.29,1.45),(s*(2.0+j*.12),-.65-j*.32,1.75),
               (s*(2.40-j*.12),-1.62-j*.23,2.40-j*.05),(s*1.48,-1.15-j*.22,1.95)]
            prism("Asa lunar %s_%s"%(s,j),p,.16,pur if j%2==0 else mid,.035)
            line("Aresta lunar %s_%s"%(s,j),[p[1],p[2]],.028,light)
    crystal("Cristal central alto",(0,-.65,1.65),(0,-.95,2.84),.31,pur,light,6)
    prism("Diadema losango",[(-.38,-.08,1.5),(0,.04,1.32),(.38,-.08,1.5),(0,-.5,1.95)],.10,light)
    root["design"]="Elmo lunar com asas de ametista varridas para tras e cristal alongado."
def reidite():
    start("reidite")
    dark=material("Reidite sombra","371D32",.5);pink=material("Reidite","D63384",.6,.28);light=material("Reidite clara","FF85B9",.45,.28);steel=material("Reidite aco","513749",.65);mid=material("Reidite escura","8C245D",.5)
    foot=[(-2.04,.08),(-2.04,-1.30),(-1.54,-1.96),(-.8,-1.96),(0,-2.12),(.8,-1.96),(1.54,-1.96),(2.04,-1.3),(2.04,.08),(1.0,-.18),(0,.12),(-1,-.18)]
    cap("Bastiao hexagonal",[pink,mid,pink,steel],dark,2.10,foot,facet=True)
    guards("Mandibulas de reidite",pink,"angular")
    for s in (-1,1):
        for j in range(2):
            p=[(s*1.60,-.25-j*.65,1.6),(s*2.15,-.5-j*.6,1.64),(s*2.22,-1.02-j*.5,2.02),(s*1.65,-.95-j*.6,2.12)]
            prism("Lamina escalonada %s_%s"%(s,j),p,.18,pink,.035)
        for j in range(3):
            line("Respiradouro %s_%s"%(s,j),[(s*1.85,.22+j*.17,1.36-j*.08),(s*2.02,.25+j*.17,1.36-j*.08)],.027,dark)
    for i in range(3):
        crystal("Espinha dorsal "+str(i),(0,-.35-i*.52,1.95),(0,-.58-i*.52,2.48+i*.08),.23,steel,light,4)
    prism("Escudo hexagonal frontal",[(-.30,-.17,1.7),(-.30,-.39,1.96),(0,-.50,2.14),(.30,-.39,1.96),(.30,-.17,1.7),(0,.04,1.5)],.12,light)
    root["design"]="Bastiao hexagonal magenta, placas sobrepostas, ventilacao e tres espinhas."
def dragon():
    start("dragon")
    dark=material("Dragao sombra","152335",.1);blue=material("Dragao escamas","365A80",.2);light=material("Dragao escamas claras","4E81A6",.25);bone=material("Dragao chifres","E8D9AB");eye=material("Dragao olhos","5DDDD7",.25,.25,.8)
    cap("Cranio draconico",[blue,light,blue],dark,2.04,facet=True)
    guards("Maxilares do dragao",blue,"leaf")
    for s in (-1,1):
        tube("Chifre longo "+str(s),[(s*1.42,-.75,1.85),(s*1.95,-1.10,2.02),(s*2.22,-1.61,2.44),(s*2.15,-2.02,2.84),(s*1.96,-2.2,3.02)],[.28,.26,.18,.10,.012],bone,8)
        for j in range(3):
            x=s*(.55+j*.37);y=-.78-j*.15;z=2.05-j*.12
            prism("Escama "+str(s)+str(j),[(x-.26,y,z),(x,y+.36,z-.07),(x+.26,y,z),(x,y-.36,z+.05)],.09,light if j%2==0 else blue,.018)
        prism("Sobrancelha feroz "+str(s),[(s*.38,-.12,1.6),(s*.95,.02,1.44),(s*1.55,-.23,1.6),(s*.88,-.55,1.91)],.12,dark)
        prism("Olho do elmo "+str(s),[(s*.67,-.15,1.66),(s*1.03,-.12,1.58),(s*1.3,-.25,1.69),(s*.94,-.33,1.79)],.035,eye,.012)
    for j in range(3):crystal("Espinha do cranio "+str(j),(0,-.5-j*.53,2.0),(0,-.72-j*.53,2.42),.16,blue,bone,4)
    root["design"]="Cranio draconico azul, escamas, olhos do elmo e chifres osseos curvos."
def crab():
    start("crab")
    dark=material("Caranguejo sombra","733026");red=material("Caranguejo","DE5939",.1,.45);light=material("Caranguejo coral","F29158",.1,.42);black=material("Caranguejo olhos","181E25");white=material("Caranguejo brilho","FFF0CC")
    foot=[(-2.10,.05),(-2.20,-.85),(-1.95,-1.6),(-1.05,-2.04),(0,-2.15),(1.05,-2.04),(1.95,-1.6),(2.2,-.85),(2.1,.05),(.95,-.20),(0,-.05),(-.95,-.20)]
    cap("Carapaca larga",[red,red,light],dark,1.95,foot)
    for s in (-1,1):
        tube("Braco da pinca "+str(s),[(s*1.7,-.5,1.55),(s*2.35,-.5,1.74),(s*2.65,-.18,1.88)],[.22,.20,.19],red,8)
        ball("Palma da pinca "+str(s),(s*2.65,-.02,1.96),(.38,.43,.28),red)
        tube("Pinca externa "+str(s),[(s*2.85,.10,2.03),(s*3.02,.40,2.10),(s*2.77,.68,2.15)],[.22,.17,.025],light,7)
        tube("Pinca interna "+str(s),[(s*2.46,.10,2.03),(s*2.38,.41,2.10),(s*2.61,.61,2.15)],[.19,.14,.025],red,7)
        tube("Haste ocular "+str(s),[(s*.92,-.35,1.82),(s*.98,-.22,2.23),(s*1.08,-.1,2.48)],[.10,.08,.07],red,8)
        ball("Olho do caranguejo "+str(s),(s*1.08,-.1,2.48),(.17,.17,.19),black)
        ball("Brilho do olho "+str(s),(s*1.10,.02,2.57),(.053,.044,.05),white,12)
        for j in range(3):
            line("Sulco da carapaca %s_%s"%(s,j),[(s*.45,-.65-j*.35,1.96),(s*1,-.75-j*.32,1.90),(s*1.6,-.85-j*.25,1.62)],.018,dark)
    root["design"]="Carapaca coral larga com duas pincas abertas e hastes oculares."
def lava():
    start("lava")
    dark=material("Lava contorno","1C1921",.2);rock=material("Lava basalto","3A2B2E",.25,.7);mid=material("Lava face","594047",.2);orange=material("Lava fissura","FF5A1F",.1,.4,1.5);yellow=material("Lava nucleo","FFB84D",.1,.35,2)
    foot=[(-2.03,.10),(-2.10,-1.12),(-1.7,-1.82),(-.90,-2.06),(0,-2.2),(.90,-2.06),(1.7,-1.82),(2.10,-1.12),(2.03,.10),(1,-.18),(0,.08),(-1,-.18)]
    cap("Cranio de obsidiana",[rock,mid,rock],dark,2.12,foot,facet=True)
    guards("Mandibulas de basalto",rock,"angular")
    for s in (-1,1):
        tube("Chifre vulcanico "+str(s),[(s*1.5,-.72,1.83),(s*2.02,-1,2.05),(s*2.38,-1.38,2.53),(s*2.28,-1.80,3.05),(s*2.05,-2.03,3.32)],[.34,.30,.23,.13,.015],rock,5)
        line("Chifre incandescente "+str(s),[(s*1.58,-.48,1.96),(s*2.1,-.79,2.15),(s*2.48,-1.24,2.56),(s*2.34,-1.70,2.94)],.034,orange)
        line("Fenda lateral "+str(s),[(s*.35,-.25,1.91),(s*.65,-.52,2.08),(s*.88,-.44,2.03),(s*1.08,-.98,2.0),(s*1.60,-1.25,1.70)],.038,orange)
        line("Fenda secundaria "+str(s),[(s*.9,-.45,2.06),(s*1.25,-.19,1.74),(s*1.7,-.10,1.43)],.023,yellow)
        crystal("Espora negra "+str(s),(s*1.9,-1.35,1.3),(s*2.64,-1.85,1.85),.26,rock,mid,4)
    crystal("Coracao vulcanico",(0,-.40,1.83),(0,-.68,2.60),.33,orange,yellow,5)
    line("Cicatriz frontal",[(-.65,-.10,1.5),(0,.05,1.43),(.65,-.10,1.5)],.036,orange)
    root["design"]="Obsidiana irregular, chifres altos, nucleo e fissuras incandescentes."
BUILDERS={k:globals()[k] for k in ORDER if k!="wood"}
def build_many(tiers):
    for tier in tiers:
        BUILDERS[tier]()
        bpy.context.view_layer.update()
        print("CREATED",tier,root["design"],"objects",len(coll.objects))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/"capacete-madeira-v01.blend"))

