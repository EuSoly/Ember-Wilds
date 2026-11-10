"""Reinforced equipment art, keeping the original scene, roots and attachment origin."""
import bpy, math, runpy
from mathutils import Vector
from pathlib import Path
BASE=Path(r'C:\Users\Elize\Desktop\Roblox\starve\assets\armor')
H=runpy.run_path(str(BASE/'build_helmet_tiers.py'));G=H['mesh'].__globals__
mesh=H['mesh'];tube=H['tube'];line=H['line'];ball=H['ball'];crystal=H['crystal'];material=H['material']

def mat(name):return bpy.data.materials['ARM_'+name]
def start(tier,remove=()):
    global root,coll
    root=bpy.data.objects[tier+'_helmet'];coll=bpy.data.collections['CAP_'+tier]
    assert root.get('revision')!='v02 reinforced',tier+' already revised'
    G.update(root=root,coll=coll,tag=tier)
    old=[o for o in root.children if any(k in o.name for k in remove)]
    if old:
        arc=bpy.data.collections.new('ARCHIVE_'+tier+'_ornaments_v01');arc.use_fake_user=True
        for ob in old:
            m=ob.matrix_world.copy()
            for c in list(ob.users_collection):c.objects.unlink(ob)
            arc.objects.link(ob);ob.parent=None;ob.matrix_world=m;ob.name='OLD_'+ob.name

def panel(name,poly,base,edge,normal=(0,0,1),thick=.17,lift=.10,inset=.80):
    # Solid closed plate: deep sidewall, bevel rim, inset faceted face.
    p=[Vector(v) for v in poly];n=Vector(normal).normalized();c=sum(p,Vector())/len(p);N=len(p)
    vs=[v-n*thick for v in p]+p+[c+(v-c)*inset+n*lift for v in p]+[c+n*(lift+.055)]
    fs=[tuple(range(N))[::-1]];indices=[0]
    for i in range(N):
        j=(i+1)%N
        fs.extend([(i,j,N+j,N+i),(N+i,N+j,2*N+j,2*N+i),(2*N+i,2*N+j,3*N)])
        indices.extend([0,1,0])
    ob=mesh(name,vs,fs,base,.018);ob.data.materials.append(edge)
    for f,idx in zip(ob.data.polygons,indices):f.material_index=idx
    return ob

def mirrored(poly,s):return [(s*x,y,z) for x,y,z in poly]
def rim(name,poly,material,r=.04):return line(name,poly,r,material)

def cheeks(base,edge,shadow,kind='heavy'):
    for s in (-1,1):
        p=[(1.77,-.17,1.50),(2.12,-.11,1.48),(2.23,.46,1.14),(2.12,1.13,.55),(1.82,1.32,.60),(1.75,.59,1.04)]
        panel('Guarda facial blindada '+str(s),mirrored(p,s),shadow,edge,(s,.05,.12),.19,.09)
        q=[(1.90,-.08,1.44),(2.13,.12,1.35),(2.20,.51,1.08),(2.09,.91,.79),(1.91,.98,.82),(1.84,.51,1.17)]
        panel('Placa externa da guarda '+str(s),mirrored(q,s),base,edge,(s,.05,.10),.10,.07)
        ball('Pino da articulacao '+str(s),(s*2.15,.22,1.38),(.082,.078,.082),edge,12)
        if kind=='heavy':
            for j in range(3):rim('Ranhura lateral',[(s*2.24,.41+j*.12,1.18-j*.09),(s*2.15,.68+j*.12,1.09-j*.09)],shadow,.022)

def brow(base,edge,shadow):
    for s in (-1,1):
        panel('Sobretesta reforcada '+str(s),mirrored([(.16,-.22,1.91),(.85,-.33,1.98),(1.60,-.37,1.77),(1.91,-.09,1.42),(1.17,-.10,1.56),(.32,-.04,1.62)],s),base,edge,(0,.18,1),.15,.06)
    rim('Junta inferior da viseira',[(-1.90,-.055,1.40),(-1.15,-.045,1.49),(0,.08,1.43),(1.15,-.045,1.49),(1.90,-.055,1.40)],shadow,.065)

def finish(design):
    root['revision']='v02 reinforced';root['design']=design

def gold():
    start('gold',('Abas douradas','Friso dourado','Rebite'))
    g=mat('Ouro');e=mat('Ouro claro');d=mat('Ouro bronze')
    cheeks(g,e,d,'royal');brow(g,e,d)
    for s in (-1,1):
        panel('Placa da calota real '+str(s),mirrored([(.24,-.40,2.01),(.27,-1.51,2.05),(.72,-1.78,1.97),(1.47,-1.34,1.89),(1.42,-.66,1.92),(.85,-.35,2.03)],s),g,d,thick=.13,lift=.08)
        rim('Gravura da calota '+str(s),mirrored([(.45,-.60,2.18),(.51,-1.28,2.20),(.78,-1.50,2.14),(1.11,-1.27,2.10)],s),e,.025)
        for j in range(3):ball('Cravo real',(s*(.67+j*.38),-.22,1.82-j*.09),(.047,.047,.047),e,12)
    finish('Elmo real reforcado; calota segmentada, bordas douradas, guardas duplas articuladas e gravuras.')

def diamond():
    start('diamond',('Placas de cristal','Aresta branca'))
    ice=mat('Diamante');e=mat('Diamante claro');d=mat('Diamante sombra');mid=mat('Diamante azul')
    cheeks(ice,e,mid,'crystal');brow(mid,e,d)
    for s in (-1,1):
        panel('Placa glacial encaixada '+str(s),mirrored([(.25,-.54,1.99),(.56,-1.84,1.98),(1.25,-1.72,1.87),(1.75,-1.30,1.81),(1.45,-.63,1.96),(.83,-.39,2.02)],s),ice,e,thick=.22,lift=.12)
        panel('Suporte cristal lateral '+str(s),mirrored([(1.30,-.75,1.82),(1.70,-.86,1.94),(1.94,-1.23,1.90),(1.64,-1.50,1.92),(1.24,-1.30,1.92)],s),mid,e,thick=.22,lift=.12)
        crystal('Fragmento glacial lateral '+str(s),(s*1.84,-1.26,1.84),(s*2.18,-1.75,2.27),.23,ice,e,5)
    finish('Coroa glacial com placas espessas facetadas, cristais engastados e guardas duplas.')

def amethyst():
    start('amethyst',('Asa lunar','Aresta lunar','Faces alongadas','Cristal central alto','Diadema losango'))
    p=mat('Ametista');e=mat('Ametista clara');d=mat('Ametista sombra');mid=mat('Ametista profunda')
    metal=material('Ametista engaste escuro','4B3B66',.65,.32)
    cheeks(mid,e,metal);brow(mid,e,d)
    panel('Cume lunar blindado',[(-.68,-.32,1.97),(-.75,-1.18,2.18),(-.40,-1.94,2.14),(0,-2.10,2.04),(.40,-1.94,2.14),(.75,-1.18,2.18),(.68,-.32,1.97),(0,-.10,1.80)],mid,e,thick=.24,lift=.14)
    crystal('Cristal imperial central',(0,-.74,2.18),(0,-1.02,3.18),.39,p,e,6)
    for s in (-1,1):
        for j in range(3):
            q=[(1.38,-.25-j*.43,1.68),(1.95,-.32-j*.38,1.76),(2.47-j*.10,-1.03-j*.44,2.65-j*.08),(2.13-j*.08,-1.43-j*.38,2.79-j*.09),(1.54,-1.23-j*.32,2.03)]
            panel('Aleta lunar laminada %s %s'%(s,j),mirrored(q,s),p if j!=1 else mid,metal,(s*.25,0,1),.23,.16)
            inner=[(1.68,-.61-j*.37,1.98),(2.21-j*.1,-1.06-j*.40,2.55-j*.08),(2.05-j*.08,-1.25-j*.36,2.58-j*.08),(1.64,-1.02-j*.32,2.14)]
            panel('Lapidacao da aleta %s %s'%(s,j),mirrored(inner,s),p,e,(s*.25,0,1),.07,.065)
        panel('Engaste da aleta '+str(s),mirrored([(1.41,-.13,1.52),(1.99,-.29,1.55),(2.04,-.66,1.78),(1.68,-.97,1.89),(1.40,-.67,1.79)],s),metal,e,thick=.22,lift=.10)
    panel('Brasao lunar lapidado',[(-.31,-.17,1.91),(0,.04,1.58),(.31,-.17,1.91),(0,-.51,2.17)],p,e,thick=.16,lift=.15)
    finish('Elmo imperial de ametista; aletas grossas laminadas com engastes escuros, cristal alto e calota reforcada.')

def reidite():
    start('reidite',('Lamina escalonada','Mandibulas de reidite','Respiradouro','Espinha dorsal','Escudo hexagonal'))
    p=mat('Reidite');e=mat('Reidite clara');d=mat('Reidite aco');mid=mat('Reidite escura')
    cheeks(p,d,mid);brow(p,d,mid)
    for s in (-1,1):
        for j in range(3):
            q=[(.34,-.38-j*.49,2.14),(1.02,-.28-j*.46,2.15),(1.63,-.48-j*.43,2.02),(1.79,-.83-j*.40,1.85),(1.12,-1.00-j*.42,2.11),(.34,-.91-j*.45,2.28)]
            panel('Calota hexagonal %s %s'%(s,j),mirrored(q,s),p,d,thick=.24,lift=.12)
        for j in range(2):
            q=[(1.72,-.12-j*.70,1.51),(2.21,-.21-j*.65,1.56),(2.43,-.61-j*.62,1.93),(2.22,-1.02-j*.60,2.23),(1.81,-1.01-j*.61,2.19),(1.63,-.51-j*.63,1.96)]
            panel('Bastiao lateral %s %s'%(s,j),mirrored(q,s),p,d,(s*.5,0,1),.28,.16)
            for k in range(2):rim('Friso do bastiao',mirrored([(2.22,-.39-j*.65-k*.15,1.98),(2.19,-.58-j*.65-k*.15,2.14)],s),e,.026)
        for j in range(3):ball('Parafuso hexagonal',(s*(.58+j*.4),-.29-j*.035,2.23-j*.05),(.060,.06,.042),e,8)
    for j in range(3):
        y=-.42-j*.57
        panel('Vertebra central '+str(j),[(-.27,y+.16,2.27),(-.29,y-.21,2.35),(0,y-.39,2.40),(.29,y-.21,2.35),(.27,y+.16,2.27),(0,y+.26,2.22)],d,e,thick=.19,lift=.14)
    panel('Selo hexagonal da testa',[(-.30,-.17,1.80),(-.30,-.40,2.04),(0,-.53,2.12),(.30,-.40,2.04),(.30,-.17,1.80),(0,.02,1.57)],p,e,thick=.15,lift=.12)
    finish('Bastiao pesado de reidite; placas hexagonais sobrepostas, estruturas laterais macicas, juntas escuras e vertebras centrais.')

def dragon():
    start('dragon',('Chifre longo','Escama ','Espinha do cranio','Maxilares do dragao'))
    blue=mat('Dragao escamas');e=mat('Dragao escamas claras');d=mat('Dragao sombra');bone=mat('Dragao chifres')
    cheeks(blue,e,d,'scale')
    for s in (-1,1):
        for j in range(3):
            for k in range(2):
                x=.44+k*.61;y=-.55-j*.47;z=2.12-k*.16
                q=[(x-.30,y+.10,z),(x-.25,y-.30,z+.08),(x,y-.48,z+.13),(x+.34,y-.26,z),(x+.32,y+.12,z-.05),(x,y+.28,z-.08)]
                panel('Escama blindada %s %s %s'%(s,j,k),mirrored(q,s),blue,e,thick=.15,lift=.11)
        pts=[(s*1.43,-.87,1.99),(s*1.93,-1.12,2.17),(s*2.31,-1.49,2.58),(s*2.39,-1.89,3.02),(s*2.21,-2.28,3.44),(s*1.94,-2.44,3.67)]
        tube('Chifre ancestral '+str(s),pts,[.41,.37,.28,.19,.10,.012],bone,10,.018)
        tube('Raiz blindada do chifre '+str(s),pts[:2],[.46,.41],d,10,.025)
        # Growth ridges around the lower horn, attached to its surface.
        for j,t in enumerate((.12,.37,.62)):
            a=Vector(pts[1]);b=Vector(pts[2]);c=a.lerp(b,t);rot=(b-a).to_track_quat('Z','Y');r=.37*(1-t)+.28*t
            ring=[c+rot@Vector((r*math.cos(i*2*math.pi/16),r*math.sin(i*2*math.pi/16),0)) for i in range(17)]
            rim('Anel do chifre %s %s'%(s,j),ring,bone,.035)
        for j in range(2):
            tube('Espora mandibular %s %s'%(s,j),[(s*1.93,-.52-j*.58,1.15),(s*2.34,-.80-j*.58,1.28),(s*2.56,-1.18-j*.58,1.62)],[.21,.15,.012],blue,7)
    for j in range(3):
        y=-.50-j*.56
        crystal('Crista draconica '+str(j),(0,y,2.14),(0,y-.29,2.75+j*.06),.25,blue,e,5)
    panel('Testa do cranio',[(-.36,-.13,1.79),(0,.08,1.47),(.36,-.13,1.79),(.27,-.50,2.14),(0,-.69,2.30),(-.27,-.50,2.14)],blue,e,thick=.17,lift=.11)
    finish('Cranio ancestral com escamas macicas sobrepostas, chifres espessos anelados, crista e esporas mandibulares.')

def crab():
    start('crab')
    red=mat('Caranguejo');e=mat('Caranguejo coral');d=mat('Caranguejo sombra')
    for s in (-1,1):
        for j in range(3):
            q=[(.23,-.55-j*.41,2.03),(.67,-.42-j*.40,2.06),(1.46,-.62-j*.35,1.94),(1.80,-.87-j*.32,1.76),(1.43,-1.05-j*.34,1.86),(.57,-.98-j*.40,2.03)]
            panel('Carapaca segmentada %s %s'%(s,j),mirrored(q,s),red,e,thick=.19,lift=.07)
        for j in range(3):
            crystal('Espinho da carapaca',(s*1.94,-.72-j*.42,1.49),(s*(2.32-j*.07),-1.0-j*.43,1.72),.16,red,e,5)
        tube('Articulacao reforcada da pinca',[(s*1.72,-.50,1.55),(s*2.03,-.50,1.66)],[.29,.27],d,10)
        panel('Escudo da pinca '+str(s),mirrored([(2.39,-.28,2.08),(2.69,-.37,2.17),(2.92,-.13,2.16),(2.82,.16,2.19),(2.52,.22,2.15)],s),red,e,thick=.12,lift=.06)
    finish('Carapaca espessa segmentada, espinhos laterais e articulacoes reforcadas das pincas.')

def lava():
    start('lava',('Chifre vulcanico','Chifre incandescente','Fenda lateral','Fenda secundaria','Mandibulas de basalto','Coracao vulcanico','Espora negra','Cicatriz frontal'))
    rock=material('Lava obsidiana reforcada','292D36',.4,.45);edge=material('Lava aresta de rocha','56606B',.4,.5);dark=mat('Lava contorno');fire=mat('Lava fissura');yellow=mat('Lava nucleo')
    cheeks(rock,edge,dark)
    for s in (-1,1):
        for j in range(3):
            q=[(.32,-.30-j*.54,2.13),(.84,-.25-j*.52,2.21),(1.39,-.50-j*.47,2.06),(1.70,-.79-j*.44,1.86),(1.14,-.91-j*.47,2.13),(.40,-.83-j*.52,2.31)]
            panel('Basalto blindado %s %s'%(s,j),mirrored(q,s),rock,edge,thick=.27,lift=.15,inset=.88)
            if j<2:rim('Magma entre placas %s %s'%(s,j),mirrored([(.37,-.87-j*.52,2.28),(.70,-.95-j*.50,2.25),(1.13,-.97-j*.47,2.12),(1.48,-.85-j*.44,1.99)],s),fire,.047)
        pts=[(s*1.51,-.85,2.04),(s*2.05,-1.08,2.27),(s*2.46,-1.48,2.82),(s*2.40,-1.97,3.37),(s*2.15,-2.31,3.74)]
        tube('Corno de obsidiana '+str(s),pts,[.48,.43,.31,.17,.012],rock,7,.016)
        tube('Raiz vulcanica '+str(s),pts[:2],[.54,.47],dark,7,.022)
        for j in range(2):
            a=Vector(pts[j]);b=Vector(pts[j+1]);c=a.lerp(b,.73);rot=(b-a).to_track_quat('Z','Y');r=[.443,.342][j]
            rim('Fenda anelar '+str(s)+str(j),[c+rot@Vector((r*math.cos(i*2*math.pi/14),r*math.sin(i*2*math.pi/14),0)) for i in range(15)],fire,.029)
        panel('Sobreolho vulcanico '+str(s),mirrored([(.26,-.15,1.94),(.73,-.37,2.09),(1.28,-.35,1.97),(1.79,-.18,1.57),(1.13,-.06,1.63),(.35,.01,1.58)],s),rock,edge,thick=.21,lift=.15)
        rim('Magma sob viseira '+str(s),mirrored([(.24,.0,1.63),(.75,-.04,1.70),(1.24,-.08,1.68),(1.75,-.12,1.48)],s),fire,.045)
        for j in range(2):crystal('Espora de basalto',(s*1.91,-.82-j*.63,1.32),(s*2.63,-1.21-j*.65,2.13),.32,rock,edge,5)
    panel('Engaste do nucleo',[(-.48,-.22,1.98),(-.46,-.76,2.29),(0,-1.01,2.44),(.46,-.76,2.29),(.48,-.22,1.98),(0,.0,1.68)],dark,edge,thick=.24,lift=.10)
    crystal('Nucleo vulcanico lapidado',(0,-.52,2.15),(0,-.74,2.95),.32,fire,yellow,6)
    for s in (-1,1):tube('Garra do nucleo '+str(s),[(s*.31,-.30,2.13),(s*.34,-.50,2.43),(s*.21,-.63,2.63)],[.095,.075,.025],rock,6)
    finish('Elmo de obsidiana macico, placas separadas por magma, cornos grossos fraturados e nucleo preso por garras.')

def finish_shells():
    palettes={'amethyst':('Ametista profunda','Ametista engaste escuro'),'reidite':('Reidite escura','Reidite aco'),'dragon':('Dragao escamas','Dragao escamas claras'),'lava':('Lava obsidiana reforcada','Lava aresta de rocha')}
    for tier,(base,edge) in palettes.items():
        root=bpy.data.objects[tier+'_helmet'];G.update(root=root,coll=bpy.data.collections['CAP_'+tier],tag=tier)
        for s in (-1,1):
            for j in range(2):
                # Contoured flank armor closes the plain wall between the crest and jaw.
                y=-.27-j*.64
                poly=[(1.99,y,1.55),(2.04,y-.47,1.59),(2.03,y-.65,1.35),(2.02,y-.59,.51),(2.01,y-.20,.35),(1.99,y,.57)]
                panel('Blindagem da nuca %s %s'%(s,j),mirrored(poly,s),mat(base),mat(edge),(s,0,.06),.13,.085)
        if tier=='lava':
            for ob in root.children:
                if ob.type!='MESH':continue
                for idx,m in enumerate(ob.data.materials):
                    if m and m.name in ('ARM_Lava basalto','ARM_Lava face'):ob.data.materials[idx]=mat(base)
            # Trace the actual horn cross-section, so the hot seams stay continuous
            # on its faceted surface rather than intersecting it as circular wires.
            for ob in list(root.children):
                if 'Fenda anelar' in ob.name:bpy.data.objects.remove(ob,do_unlink=True)
            for s in (-1,1):
                horn=bpy.data.objects['lava_Corno de obsidiana '+str(s)]
                for j in range(2):
                    p=[horn.data.vertices[j*7+i].co.lerp(horn.data.vertices[(j+1)*7+i].co,.73) for i in range(7)]
                    c=sum(p,Vector())/7;p=[v+(v-c).normalized()*.012 for v in p]
                    rim('Fenda anelar continua %s %s'%(s,j),p+[p[0]],mat('Lava fissura'),.026)

def build(tiers):
    bpy.context.window.scene=bpy.data.scenes['Armaduras - 9 capacetes']
    for tier in tiers:globals()[tier]();bpy.context.view_layer.update();print('REFINED',tier,len(root.children))
    if all(t in tiers for t in ['amethyst','reidite','dragon','lava']):finish_shells()

if __name__=='__main__':build(['gold','diamond','amethyst','reidite','dragon','crab','lava'])
