"""Crown art revision in the original working scene; no delivery exports."""
import bpy, math, runpy
from pathlib import Path
from mathutils import Vector
BASE=Path(r'C:\Users\Elize\Desktop\Roblox\starve\assets\armor')
H=runpy.run_path(str(BASE/'build_helmet_tiers.py'))
G=H['mesh'].__globals__
mesh=H['mesh']; line=H['line']; ball=H['ball']; material=H['material']
sin=math.sin; cos=math.cos; pi=math.pi

def smooth(ob):
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def start(id):
    global root,coll
    root=bpy.data.objects['wear_'+id];coll=bpy.data.collections['VEST_'+id]
    assert root.get('revision')!='v02 aligned crowns', 'Already revised'
    ac=bpy.data.collections.new('ARCHIVE_'+id+'_v01');ac.use_fake_user=True
    for ob in list(root.children):
        mat=ob.matrix_world.copy()
        for old in list(ob.users_collection):old.objects.unlink(ob)
        ac.objects.link(ob);ob.parent=None;ob.matrix_world=mat;ob.name='OLD_'+ob.name
    G.update(root=root,coll=coll,tag=id)

def at(a,z,offset=0):
    return Vector(((1.74+offset)*sin(a),-.93+(.97+offset)*cos(a),z))

def basis(a):
    n=Vector((sin(a)/1.74,cos(a)/.97,0)).normalized()
    u=Vector((n.y,-n.x,0));v=Vector((0,0,1))
    return u,v,n

def setting(name,a,z,w,h,metal,stone,highlight,shape='diamond'):
    # Every bezel uses the band's own radial frame. The flat gem back is seated
    # on the tooth; the raised table faces outward, never along world Z.
    u,v,n=basis(a);c=at(a,z,.018)
    if shape=='emerald':outline=[(-.65,-1),(.65,-1),(1,-.65),(1,.65),(.65,1),(-.65,1),(-1,.65),(-1,-.65)]
    else:outline=[(0,-1),(.72,-.52),(1,0),(.72,.52),(0,1),(-.72,.52),(-1,0),(-.72,-.52)]
    rim=[c+u*x*w+v*y*h+n*.055 for x,y in outline]
    smooth(line(name+' engaste',rim+[rim[0]],.034,metal))
    verts=[];N=len(outline)
    for scale,depth in [(1,.035),(.87,.09),(.46,.18)]:
        verts.extend([tuple(c+u*x*w*scale+v*y*h*scale+n*depth) for x,y in outline])
    faces=[tuple(range(N))[::-1]]
    for k in range(2):
        for i in range(N):j=(i+1)%N;faces.append((k*N+i,k*N+j,(k+1)*N+j,(k+1)*N+i))
    faces.append(tuple(range(2*N,3*N)))
    ob=mesh(name+' lapidada',verts,faces,stone);ob.data.materials.append(highlight)
    for i,p in enumerate(ob.data.polygons):p.material_index=1 if i in (3,6,11,14) else 0
    for j in (0,4):
        x,y=outline[j];smooth(line(name+' garra '+str(j),[c+u*x*w+v*y*h+n*.02,c+u*x*w*.83+v*y*h*.83+n*.13],.027,metal))

def band(metal,edge,shadow,stone,highlight,kind):
    # Eight exact repeated teeth, with a front-centred peak and bilateral symmetry.
    profile=[(-.5,1.80),(-.38,1.82),(-.25,1.96),(-.14,2.23),(-.055,2.42),(0,2.48),(.055,2.42),(.14,2.23),(.25,1.96),(.38,1.82)]
    samples=[((k+t)*2*pi/8,z) for k in range(8) for t,z in profile]
    vs=[]
    for a,z in samples:vs.extend([at(a,1.36),at(a,z),at(a,z,-.14),at(a,1.36,-.14)])
    fs=[];N=len(samples)
    for i in range(N):
        j=(i+1)%N
        for q in range(4):r=(q+1)%4;fs.append((4*i+q,4*j+q,4*j+r,4*i+r))
    mesh('Diadema oito dentes regulares',vs,fs,metal,.017)
    smooth(line('Contorno dos oito dentes',[at(a,z,.012) for a,z in samples]+[at(*samples[0],.012)],.028,edge))
    for z,r,m in [(1.39,.048,edge),(1.53,.021,shadow),(1.73,.035,edge)]:
        smooth(line('Friso circular %.2f'%z,[at(i*2*pi/96,z,.025) for i in range(97)],r,m))
    for k in range(8):
        a=k*2*pi/8
        setting('Gema dente %02d'%k,a,2.035,.145 if k else .19,.21 if k else .26,edge,stone,highlight,'emerald' if kind=='life' else 'diamond')
        ball('Perola de ponta %02d'%k,at(a,2.49),(.055,.055,.055),edge,12)
        # Paired engraved scrolls fill the horizontal belt, all aligned to it.
        for s in (-1,1):
            pts=[at(a+s*t,1.61+.045*sin(pi*i/8),.035) for i,t in enumerate([.10+j*.025 for j in range(9)])]
            smooth(line('Arabesco %02d %s'%(k,s),pts,.018,edge))

def feather(name,start,end,width,mat,quill,side):
    # Closed, softly ridged lens along a curved centre line, with a tapered tip.
    a=Vector(start);b=Vector(end);d=b-a
    transverse=Vector((-d.z,0,d.x)).normalized();vs=[];centers=[]
    steps=10
    for i in range(steps+1):
        t=i/steps;c=a+d*t+Vector((side*.13*sin(pi*t),-.11*sin(pi*t),.12*sin(pi*t)))
        centers.append(c)
        w=width*(sin(pi*(.05+.95*t))**.8) if i<steps else .006
        thick=.025+.055*sin(pi*t)
        for p in [c-transverse*w,c+Vector((0,thick,0)),c+transverse*w,c-Vector((0,thick*.7,0))]:vs.append(tuple(p))
    fs=[]
    for i in range(steps):
        for q in range(4):r=(q+1)%4;fs.append((4*i+q,4*i+r,4*(i+1)+r,4*(i+1)+q))
    fs+=[(3,2,1,0),tuple(range(steps*4,(steps+1)*4))]
    smooth(mesh(name,vs,fs,mat))
    smooth(line(name+' nervura',[c+Vector((0,.065,.005)) for c in centers[:9]],.014,quill))

def wings(silver,edge):
    pearl=material('Coroa penas perola','F5F0DD',.15,.48)
    shade=material('Coroa penas sombra','A9C1CE',.22,.48)
    bright=material('Coroa penas luz','FFFFFF',.12,.4)
    for s in (-1,1):
        # Primaries fan along a continuous upward sweep, mirrored exactly.
        ends=[(2.42,-1.04,3.56),(2.82,-.94,3.40),(3.04,-.79,3.13),(3.12,-.60,2.82),(3.02,-.43,2.52),(2.79,-.29,2.27)]
        for j,e in enumerate(ends):
            a=(s*(1.60+.10*j),-.62+.035*j,1.77+.05*j)
            feather('Asa %s primaria %02d'%(s,j),a,(s*e[0],e[1],e[2]),.18,pearl if j%2==0 else bright,shade,s)
        for j in range(4):
            feather('Asa %s cobertura %02d'%(s,j),(s*1.65,-.35+j*.025,1.81),(s*(2.26+.13*j),-.45+j*.065,2.76-.17*j),.145,silver if j==3 else pearl,bright,s)
        smooth(line('Asa %s borda curva'%s,[(s*1.63,-.49,1.74),(s*1.78,-.51,2.14),(s*1.94,-.66,2.62),(s*2.18,-.87,3.13),(s*2.42,-1.04,3.56)],.055,edge))
        ball('Asa %s articulacao'%s,(s*1.68,-.37,1.86),(.18,.10,.22),edge,16)
    # Halo with a physical rear support, sized to leave the teeth readable.
    smooth(line('Suporte da aureola',[(0,-1.86,2.21),(0,-1.98,2.61),(0,-1.81,2.97)],.045,silver))
    smooth(line('Aureola continua',[(.65*cos(i*2*pi/64),-1.35+.46*sin(i*2*pi/64),2.98) for i in range(65)],.052,edge))

def build():
    bpy.context.window.scene=bpy.data.scenes['Armaduras - 03 Coroas']
    gold=material('Coroas ouro acetinado','DCA63A',.65,.32)
    goldlight=material('Coroas friso champanhe','FFE3A0',.55,.3)
    bronze=material('Coroas sulco ouro','956019',.5,.45)
    silver=material('Coroas prata acetinada','C4D5E0',.65,.3)
    silverlight=material('Coroas prata clara','EFF7FA',.55,.26)
    silverdark=material('Coroas sulco prata','657C94',.5,.4)
    green=material('Coroas esmeralda','15935D',.3,.23);greenlight=material('Coroas esmeralda faceta','68E7AF',.22,.22)
    blue=material('Coroas safira celeste','28AACC',.3,.2);bluelight=material('Coroas safira faceta','A5F4FF',.22,.2)
    amber=material('Coroas topazio mel','DB701A',.3,.23);amberlight=material('Coroas topazio faceta','FFD66D',.25,.2)
    for id,kind,m,e,d,g,h in [('life_crown','life',gold,goldlight,bronze,green,greenlight),('angel_crown','angel',silver,silverlight,silverdark,blue,bluelight),('luck_crown','luck',gold,goldlight,bronze,amber,amberlight)]:
        start(id);band(m,e,d,g,h,kind)
        if kind=='angel':wings(silver,silverlight)
        if kind=='life':
            for s in (-1,1):
                smooth(line('Ramo da vida '+str(s),[at(s*(.38+i*.075),1.83+i*.035,.08) for i in range(8)],.028,e))
                for j in range(4):
                    a=s*(.43+j*.13);u,v,n=basis(a);c=at(a,1.88+j*.055,.08)
                    for sign in (-1,1):
                        tip=c+u*s*.13+v*sign*.13+n*.01
                        mid=(c+tip)/2
                        mesh('Folha cinzelada', [c,mid+u*.07,tip,mid-u*.07,mid+n*.045],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)],e)
        if kind=='luck':
            # Four-leaf crest mounted to the rear tooth, rather than floating.
            for x,z in [(-.10,2.30),(.10,2.30),(-.10,2.48),(.10,2.48)]:
                ball('Trevo folha',(x,-1.95,z),(.135,.055,.135),green,12)
            smooth(line('Trevo haste',[(0,-1.96,2.12),(0,-1.96,2.38)],.028,e))
        root['revision']='v02 aligned crowns'
        root['design']='Oito dentes simetricos; gemas lapidadas assentadas em engastes radiais; frisos e arabescos. '+({'life':'Ramos cinzelados e esmeraldas.','angel':'Asas espelhadas com penas curvas em duas camadas e aureola apoiada.','luck':'Topazios alinhados e trevo montado na coroa.'}[kind])
    bpy.context.view_layer.update()
    print('Revised three crowns; import files untouched.')

if __name__=='__main__':build()
