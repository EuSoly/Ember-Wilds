
import bpy, bmesh, math
from mathutils import Vector

def srgb(h):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(((x/12.92) if x<=0.04045 else ((x+0.055)/1.055)**2.4) for x in c)+(1.0,)

def mat(name, hexcol, rough=0.65):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes=True
    b=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value=srgb(hexcol); b.inputs['Roughness'].default_value=rough
    m.diffuse_color=srgb(hexcol)
    return m

def chaikin(pts, it=2):
    for _ in range(it):
        out=[]
        n=len(pts)
        for i in range(n):
            a=Vector(pts[i]); b=Vector(pts[(i+1)%n])
            out += [a*0.75+b*0.25, a*0.25+b*0.75]
        pts=[tuple(p) for p in out]
    return pts

def circle(r=0.5, n=24, cx=0, cy=0, sx=1, sy=1, rot=0, wob=None):
    pts=[]
    for i in range(n):
        a=2*math.pi*i/n
        rr=r*(1+(wob(a) if wob else 0))
        x,y=rr*math.cos(a)*sx, rr*math.sin(a)*sy
        c,s=math.cos(rot),math.sin(rot)
        pts.append((cx+x*c-y*s, cy+x*s+y*c))
    return pts

def xform(pts, dx=0, dy=0, s=1.0, rot=0):
    c,si=math.cos(rot),math.sin(rot)
    return [(dx+(x*c-y*si)*s, dy+(x*si+y*c)*s) for x,y in pts]

def slab(name, pts, z0, h, mat_, bevel=0.03, parent=None, coll=None):
    # garantir sentido anti-horário
    area=sum(pts[i][0]*pts[(i+1)%len(pts)][1]-pts[(i+1)%len(pts)][0]*pts[i][1] for i in range(len(pts)))
    if area<0: pts=list(reversed(pts))
    bm=bmesh.new()
    vb=[bm.verts.new((x,y,z0)) for x,y in pts]
    vt=[bm.verts.new((x,y,z0+h)) for x,y in pts]
    n=len(pts)
    bm.faces.new(list(reversed(vb)))
    top=bm.faces.new(vt)
    for i in range(n):
        j=(i+1)%n
        bm.faces.new([vb[i],vb[j],vt[j],vt[i]])
    bm.normal_update()
    if bevel>0:
        edges=[e for e in top.edges]
        bmesh.ops.bevel(bm, geom=edges, offset=min(bevel,h*0.9), segments=1, affect='EDGES', profile=0.5, clamp_overlap=True)
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth=False
    o=bpy.data.objects.new(name, me)
    o.data.materials.append(mat_)
    (coll or bpy.context.scene.collection).objects.link(o)
    if parent: o.parent=parent
    return o

GROUP='Mob_Drops'
def item(item_id, label, category='mob_drop'):
    root_coll=bpy.data.collections.get(GROUP) or bpy.data.collections.new(GROUP)
    if root_coll.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(root_coll)
    old=bpy.data.collections.get(item_id)
    if old:
        for o in list(old.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(old)
    c=bpy.data.collections.new(item_id); root_coll.children.link(c)
    e=bpy.data.objects.new(item_id+'_root', None); e.empty_display_size=0.3; e.empty_display_type='PLAIN_AXES'
    c.objects.link(e)
    e['item_id']=item_id; e['label']=label; e['category']=category; e['purpose']='inventory_viewport_icon'
    e.hide_viewport=False
    return c,e

def lobed(R=0.48, lobes=9, depth=0.12, sx=1, sy=1, rot=0, cx=0, cy=0, it=2, jitter=None, tip=None):
    pts=[]
    n=lobes*2
    for i in range(n):
        a=2*math.pi*i/n+rot
        r=R*(1.0 if i%2==0 else 1.0-depth)
        if jitter: r*=1+jitter[i%len(jitter)]
        if tip: r*=1+tip(a)
        pts.append((cx+r*math.cos(a)*sx, cy+r*math.sin(a)*sy))
    return chaikin(pts,it)

def arc_band(cx,cy,r,w,a0,a1,n=8,taper=True):
    outer=[];inner=[]
    for i in range(n+1):
        t=i/n; a=a0+(a1-a0)*t
        ww=w*(math.sin(math.pi*t)**0.7 if taper else 1)+0.004
        outer.append((cx+(r+ww/2)*math.cos(a), cy+(r+ww/2)*math.sin(a)))
        inner.append((cx+(r-ww/2)*math.cos(a), cy+(r-ww/2)*math.sin(a)))
    pts=outer+list(reversed(inner))
    # remove pontos duplicados nas pontas
    out=[]
    for p in pts:
        if not out or (abs(out[-1][0]-p[0])+abs(out[-1][1]-p[1]))>1e-4: out.append(p)
    return out

def strand(p0,p1,p2,w,n=8):
    # faixa curva (bezier quadrática) afinando nas pontas
    L=[];Rr=[]
    for i in range(n+1):
        t=i/n
        x=(1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t*t*p2[0]; y=(1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t*t*p2[1]
        dx=2*(1-t)*(p1[0]-p0[0])+2*t*(p2[0]-p1[0]); dy=2*(1-t)*(p1[1]-p0[1])+2*t*(p2[1]-p1[1])
        l=math.hypot(dx,dy) or 1; nx,ny=-dy/l,dx/l
        ww=w*(math.sin(math.pi*t)**0.6)/2+0.003
        L.append((x+nx*ww,y+ny*ww)); Rr.append((x-nx*ww,y-ny*ww))
    return L+list(reversed(Rr[1:-1]))

def offset(pts, d):
    # desloca contorno para fora (d>0) ao longo da normal média dos vértices (anti-horário)
    area=sum(pts[i][0]*pts[(i+1)%len(pts)][1]-pts[(i+1)%len(pts)][0]*pts[i][1] for i in range(len(pts)))
    if area<0: pts=list(reversed(pts))
    n=len(pts); out=[]
    for i in range(n):
        a=Vector(pts[i-1]+(0,)); b=Vector(pts[i]+(0,)); c=Vector(pts[(i+1)%n]+(0,))
        e1=(b-a).normalized(); e2=(c-b).normalized()
        n1=Vector((e1.y,-e1.x,0)); n2=Vector((e2.y,-e2.x,0))
        m=(n1+n2); 
        if m.length<1e-6: m=n1
        m.normalize()
        k=max(0.5, m.dot(n1))
        p=b+m*(d/k)
        out.append((p.x,p.y))
    return out

def prism(name, pts, z0, h, mat_=None, coll=None, parent=None):
    o=slab(name, pts, z0, h, mat_ or bpy.data.materials.get('outline') , 0.0, parent, coll)
    return o

def boolean(o, cutter_pts, op, z0=-1, h=3):
    cut=slab('_cutter', cutter_pts, z0, h, o.data.materials[0], 0.0)
    m=o.modifiers.new('b','BOOLEAN'); m.operation=op; m.object=cut; m.solver='EXACT'
    dg=bpy.context.evaluated_depsgraph_get()
    me=bpy.data.meshes.new_from_object(o.evaluated_get(dg))
    o.modifiers.remove(m); old=o.data; o.data=me; bpy.data.meshes.remove(old)
    bpy.data.objects.remove(cut)
    return o

def layer(name, pts, z0, h, mat_, e, c, intersect=None, subtract=None, bevel=0.0):
    o=slab(name, pts, z0, h, mat_, bevel, e, c)
    for s in (intersect or []): boolean(o, s, 'INTERSECT')
    for s in (subtract or []): boolean(o, s, 'DIFFERENCE')
    return o

OUT='#1E2230'
def sticker(iid, label, body, tones, e=None, c=None, outline=0.045, shadow_shift=(0.06,-0.07), hl=None, extra=None):
    """body: contorno principal. tones: (sombra, base, brilho). hl: lista de contornos de brilho."""
    if c is None: c,e=item(iid,label)
    mo=mat(iid+'_outline', OUT, 0.8); ms=mat(iid+'_01',tones[0]); mb=mat(iid+'_02',tones[1]); mh=mat(iid+'_03',tones[2])
    layer(iid+'_outline', offset(body,outline), 0.0, 0.08, mo, e, c)
    layer(iid+'_shade', body, 0.0, 0.11, ms, e, c)
    sh=xform(body, dx=-shadow_shift[0], dy=-shadow_shift[1])
    layer(iid+'_body', body, 0.0, 0.14, mb, e, c, intersect=[sh])
    for k,h in enumerate(hl or []):
        layer(f'{iid}_hl_{k+1}', h, 0.0, 0.16, mh, e, c, intersect=[offset(body,-0.02)])
    return c,e

def parse(s, scale=1/52.0, dx=0, dy=0):
    pts=[tuple(float(v) for v in p.split()) for p in s.split(',')]
    return [(x*scale+dx, y*scale+dy) for x,y in pts]

def smooth(pts, it=2):
    for _ in range(it):
        n=len(pts); pts=[((pts[i-1][0]+2*pts[i][0]+pts[(i+1)%n][0])/4,(pts[i-1][1]+2*pts[i][1]+pts[(i+1)%n][1])/4) for i in range(n)]
    return pts

PELT_O="21 0,19 4,19 6,19 10,19 13,17 17,13 20,11 21,7 24,5 26,0 28,-6 28,-8 25,-11 20,-13 19,-17 17,-20 13,-20 11,-21 6,-21 4,-21 0,-23 -4,-22 -7,-22 -12,-22 -14,-17 -17,-13 -20,-11 -20,-7 -24,-5 -25,0 -25,5 -25,7 -25,12 -22,13 -20,18 -18,21 -14,23 -12,23 -7,23 -5"
PELT_I="16 0,15 3,14 4,14 8,14 10,13 13,10 16,9 17,6 20,4 22,0 24,-4 23,-6 20,-9 16,-10 15,-13 13,-15 10,-15 8,-17 5,-16 3,-16 0,-17 -3,-17 -5,-18 -10,-17 -12,-14 -14,-10 -16,-9 -17,-6 -18,-4 -20,0 -21,4 -21,6 -20,9 -17,11 -17,14 -14,17 -12,18 -10,19 -6,18 -4"

def pelt():
    o=chaikin(smooth(parse(PELT_O, dy=-1.5/52),2),2)
    i=chaikin(smooth(parse(PELT_I, dy=-1.5/52),2),2)
    return o,i

def sticker2(iid, label, outer, body, tones, hl=None, shadow_shift=(0.05,-0.06), out_col=None):
    c,e=item(iid,label)
    mo=mat(iid+'_outline', out_col or OUT, 0.8); ms=mat(iid+'_01',tones[0]); mb=mat(iid+'_02',tones[1]); mh=mat(iid+'_03',tones[2])
    layer(iid+'_outline', outer, 0.0, 0.08, mo, e, c)
    layer(iid+'_shade', body, 0.0, 0.11, ms, e, c)
    sh=xform(body, dx=-shadow_shift[0], dy=-shadow_shift[1])
    layer(iid+'_body', body, 0.0, 0.14, mb, e, c, intersect=[sh])
    for k,h in enumerate(hl or []):
        layer(f'{iid}_hl_{k+1}', h, 0.0, 0.16, mh, e, c, intersect=[offset(body,-0.02)])
    return c,e

PELT_O64="21.3 0,20.2 2,19.4 3.9,19.4 5.9,19.2 7.9,19.2 10.3,19.3 12.9,18.4 15.1,17.2 17.2,14.9 18.2,13.3 20,11.3 21.2,9.4 22.6,7.3 24.2,5.2 26.2,2.8 28.1,0 28.3,-2.8 28.1,-5.6 28.2,-7.6 25.1,-9.6 23.1,-10.8 20.3,-12.8 19.1,-14.6 17.8,-16.6 16.6,-18.5 15.2,-19.5 13.1,-20.5 11,-20.6 8.5,-20.6 6.2,-20.6 4.1,-20.4 2,-21.5 0,-21.4 -2.1,-22.6 -4.5,-22.5 -6.8,-22.4 -9.3,-22.5 -12,-21.6 -14.4,-19.5 -16,-17.5 -17.5,-15.2 -18.5,-13.1 -19.5,-11 -20.5,-9.4 -22.6,-7.2 -23.7,-4.9 -24.5,-2.5 -25.6,0 -25.5,2.5 -25.6,5.1 -25.5,7.5 -24.6,9.4 -22.6,11.6 -21.6,13.3 -20,15.2 -18.5,17.7 -17.7,19.3 -15.9,21.2 -14.2,23.4 -12.5,23.3 -9.7,23.2 -7,23.3 -4.6,22.1 -2.2"
PELT_I64="16.5 0,15.5 1.5,15.5 3,14.5 4.5,14.5 6,14.5 7.5,14.5 9.5,14.5 11.5,13.5 13.5,12.5 15,10.5 15.5,9 17,7.5 18.5,6 20.5,4.5 22.5,2.5 23,0 24.5,-2.5 24,-4.5 22.5,-6 20.5,-7.5 18,-8.5 16.5,-10 15,-11.5 14.5,-13.5 13.5,-15 12,-15.5 10.5,-15.5 8.5,-16.5 7,-16.5 5,-16.5 3.5,-16.5 1.5,-16.5 0,-17.5 -1.5,-17.5 -3.5,-17.5 -5.5,-18.5 -7.5,-18.5 -10,-17.5 -11.5,-15.5 -12.5,-13.5 -13.5,-12 -14.5,-10.5 -15.5,-9 -16.5,-7.5 -17.5,-5.5 -18.5,-4 -19.5,-2 -20.5,0 -21.5,2 -21.5,4 -20.5,6 -19.5,7.5 -18.5,9.5 -17.5,11 -16.5,12.5 -15,14.5 -14.5,15.5 -12.5,17.5 -11.5,18.5 -10,19.5 -8,19.5 -6,18.5 -3.5,17.5 -1.5"
def pelt(sm=1, ch=2):
    o=chaikin(smooth(parse(PELT_O64, dy=-1.5/52),sm),ch)
    i=chaikin(smooth(parse(PELT_I64, dy=-1.5/52),sm),ch)
    return o,i

PX=1/52.0
def P(s):
    pts=[tuple(float(v) for v in p.split()) for p in s.strip().split(',')]
    out=[]
    for p in pts:
        if not out or abs(out[-1][0]-p[0])+abs(out[-1][1]-p[1])>0.05: out.append(p)
    if len(out)>2 and abs(out[0][0]-out[-1][0])+abs(out[0][1]-out[-1][1])<0.05: out.pop()
    return out

def rdp(pts, eps):
    if len(pts)<3: return pts
    a,b=Vector(pts[0]),Vector(pts[-1]); L=(b-a).length or 1e-9
    di=[abs((b.x-a.x)*(a.y-p[1])-(a.x-p[0])*(b.y-a.y))/L for p in pts[1:-1]]
    i=max(range(len(di)),key=lambda k:di[k])+1
    if di[i-1]>eps: return rdp(pts[:i+1],eps)[:-1]+rdp(pts[i:],eps)
    return [pts[0],pts[-1]]

def rdp_closed(pts, eps):
    h=len(pts)//2
    A=rdp(pts[:h+1],eps); B=rdp(pts[h:]+[pts[0]],eps)
    return A[:-1]+B[:-1]

def U(pts, c): return [((x-c[0])*PX,(y-c[1])*PX) for x,y in pts]
def bbc(pts):
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]; return ((min(xs)+max(xs))/2,(min(ys)+max(ys))/2)

def circ(cx,cy,r,n=10,sx=1,sy=1): return [(cx+r*sx*math.cos(2*math.pi*i/n), cy+r*sy*math.sin(2*math.pi*i/n)) for i in range(n)]
def hexa(cx,cy,r): return [(cx+r*math.cos(math.pi/2+i*math.pi/3), cy+r*math.sin(math.pi/2+i*math.pi/3)) for i in range(6)]
def line(p0,p1,w): # faixa reta com pontas afinadas (6 verts)
    d=Vector((p1[0]-p0[0],p1[1]-p0[1])); n=Vector((-d.y,d.x)).normalized()*w/2
    m1=Vector(p0)+d*0.15; m2=Vector(p0)+d*0.85
    return [tuple(p0),tuple(m1+n),tuple(m2+n),tuple(p1),tuple(m2-n),tuple(m1-n)]

GRID={}
def place(e,row,col,sp=1.4): e.location=(col*sp,-row*sp,0)

def build(iid,label,row,col,S,body_col,regions=(),mode='add',ow=0.05,extra=None,body_pts=None):
    """S e regiões em px da wiki (y para cima). mode add: contorno = S expandido; own: contorno = S."""
    c,e=item(iid,label)
    cen=bbc(P(S))
    s=U(P(S),cen)
    mo=mat(iid+'_outline',OUT,0.8)
    z=0.0
    if mode=='add':
        slab(iid+'_outline',offset(s,ow),0.0,0.06,mo,0.0,e,c); body=s
    else:
        slab(iid+'_outline',s,0.0,0.06,mo,0.0,e,c); body=body_pts if body_pts else offset(s,-ow)
    slab(iid+'_body',body,0.03,0.07,mat(iid+'_01',body_col),0.0,e,c)
    top=0.10
    for k,r in enumerate(regions):
        col_,pts=r.split('|')
        rp=U(P(pts),cen)
        slab(f'{iid}_part_{k+1}',rp,top-0.02,0.04,mat(f'{iid}_{k+2:02d}',col_),0.0,e,c); top+=0.02
    if extra: extra(c,e,cen,top)
    place(e,row,col)
    return c,e

def pelt_lp(eps=0.5):
    o=rdp_closed(P(PELT_O64),eps)
    return [(x*PX,(y-1.5)*PX) for x,y in o]

def pelt_item(iid,label,row,col,tones,hl=True):
    o=pelt_lp()
    i=offset(o,-0.07)
    h=[(-0.21,0.08),(-0.15,0.22),(-0.06,0.27),(-0.08,0.17),(-0.15,0.06)] if hl else None
    c,e=sticker2(iid,label,o,i,tones,hl=[h] if hl else None,shadow_shift=(0.03,-0.035))
    place(e,row,col)
    return c,e

def strip_bottoms(c):
    for o in c.objects:
        if o.type!='MESH': continue
        bm=bmesh.new(); bm.from_mesh(o.data)
        bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
        bot=[f for f in bm.faces if f.normal.z<-0.9]
        bmesh.ops.delete(bm, geom=bot, context='FACES_ONLY')
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bm.to_mesh(o.data); bm.free()

def tris(c):
    n=0
    for o in c.objects:
        if o.type=='MESH': o.data.calc_loop_triangles(); n+=len(o.data.loop_triangles)
    return n

def pelt_item(iid,label,row,col,tones,hl=True):
    o=pelt_lp(0.75)
    i=offset(o,-0.07)
    h=circ(-0.13,0.17,0.075,8,sx=0.75,sy=1.25)
    h=xform(h,rot=0)
    c,e=sticker2(iid,label,o,i,tones,hl=[h] if hl else None,shadow_shift=(0.03,-0.035))
    strip_bottoms(c); place(e,row,col)
    return c,e

def leaf(tip,base,w,n=5,round_base=0.35):
    t=Vector(tip); b=Vector(base); d=t-b; nrm=Vector((-d.y,d.x)).normalized()
    L=[];R=[]
    for i in range(1,n):
        s=i/n; p=b+d*s; ww=w/2*(math.sin(math.pi*min(1,(s+round_base)/(1+round_base)))**0.7)
        L.append(tuple(p+nrm*ww)); R.append(tuple(p-nrm*ww))
    return [tuple(b)]+L+[tuple(t)]+list(reversed(R))

def colhex(m):
    b=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'); c=b.inputs['Base Color'].default_value
    f=lambda x: round(255*((x*12.92) if x<=0.0031308 else (1.055*x**(1/2.4)-0.055)))
    return '#%02X%02X%02X'%(f(c[0]),f(c[1]),f(c[2]))

def optimize_item(c):
    """Une as malhas da mesma cor numa só e limpa a geometria."""
    bpy.context.view_layer.update()
    meshes=[o for o in c.objects if o.type=='MESH']
    groups={}
    for o in meshes: groups.setdefault(colhex(o.material_slots[0].material),[]).append(o)
    for hx,objs in groups.items():
        objs.sort(key=lambda o:(0 if o.name.endswith('_outline') else 1, len(o.name)))
        keep=objs[0]
        if len(objs)>1:
            bm=bmesh.new()
            for o in objs:
                me=o.data.copy(); me.transform(keep.matrix_world.inverted() @ o.matrix_world)
                bm.from_mesh(me); bpy.data.meshes.remove(me)
            bm.to_mesh(keep.data); bm.free()
            for o in objs[1:]: bpy.data.objects.remove(o)
        bm=bmesh.new(); bm.from_mesh(keep.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
        bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
        bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(1.0), verts=bm.verts, edges=bm.edges, use_dissolve_boundaries=False)
        bm.to_mesh(keep.data); bm.free()
        import re
        base=re.sub(r'(_\d+)+(?=(_outline)?$)','',keep.name)
        if keep.name.endswith('_outline'): base=c.name+'_outline'
        if base!=keep.name and not bpy.data.objects.get(base): keep.name=base
        keep.data.name=keep.name

def oval(tip,base,w,n=6,p=0.5):
    t=Vector(tip); b=Vector(base); d=t-b; nrm=Vector((-d.y,d.x)).normalized(); L=[];R=[]
    for i in range(1,n):
        s=i/n; q=b+d*s; ww=w/2*(math.sin(math.pi*s)**p)*(1.0-0.25*s)
        L.append(tuple(q+nrm*ww)); R.append(tuple(q-nrm*ww))
    return [tuple(b)]+L+[tuple(t)]+list(reversed(R))

def spiky(p0,p1,w,n=11,inner=0.45):
    a=Vector(p0); b=Vector(p1); d=b-a; nrm=Vector((-d.y,d.x)).normalized(); L=[];R=[]
    for i in range(n+1):
        s=i/n; p=a+d*s; ww=w/2*math.sin(math.pi*(0.12+0.88*s))**0.6
        k=1 if i%2==0 else inner
        L.append(tuple(p+nrm*ww*k)); R.append(tuple(p-nrm*ww*(1 if i%2==0 else inner*1.6)))
    return L+list(reversed(R[1:-1]))

def feather_set(iid,label,col,cen,blades,blade_col,rim_col,rachis_col,shape='leaf',stems=(),stem_col='#E6EAEC',fluff=None,fluff_col='#E4E9EA',stripe=None):
    c,e=item(iid,label)
    OM=mat(iid+'_outline',OUT,0.8); BM=mat(iid+'_blade',blade_col); RM=mat(iid+'_rim',rim_col); QM=mat(iid+'_rachis',rachis_col)
    for k,(a,b) in enumerate(stems):
        slab(f'{iid}_stem_{k+1}_outline',U(offset(line(a,b,2.2),1.6),cen),0.0,0.03,OM,0.0,e,c)
        slab(f'{iid}_stem_{k+1}',U(line(a,b,2.2),cen),0.01,0.03,mat(iid+'_stem',stem_col),0.0,e,c)
    z=0.03
    for k,(tp,bs,w) in enumerate(blades):
        bp=oval(tp,bs,w) if shape=='oval' else leaf(tp,bs,w)
        slab(f'{iid}_blade_{k+1}_outline',U(offset(bp,2.6),cen),z,0.03,OM,0.0,e,c)
        slab(f'{iid}_rim_{k+1}',U(offset(bp,1.1),cen),z+0.01,0.03,RM,0.0,e,c)
        slab(f'{iid}_blade_{k+1}',U(bp,cen),z+0.02,0.03,BM,0.0,e,c)
        t=Vector(tp); b=Vector(bs); d=t-b
        if stripe:
            nrm=Vector((-d.y,d.x)).normalized()
            sp=U(line(tuple(b+d*0.1+nrm*w*0.22),tuple(b+d*0.92+nrm*w*0.12),w*0.28),cen)
            o=slab(f'{iid}_stripe_{k+1}',sp,z+0.04,0.025,mat(iid+'_stripe',stripe),0.0,e,c); boolean(o,U(bp,cen),'INTERSECT')
        slab(f'{iid}_rachis_{k+1}',U(line(tuple(b+d*0.02),tuple(b+d*0.86),1.3),cen),z+0.045,0.025,QM,0.0,e,c)
        z+=0.03
    if fluff:
        slab(f'{iid}_fluff_outline',U(offset(fluff,1.8),cen),z,0.03,OM,0.0,e,c)
        slab(f'{iid}_fluff',U(fluff,cen),z+0.01,0.03,mat(iid+'_fluff',fluff_col),0.0,e,c)
    strip_bottoms(c); place(e,2,col,1.4); e.location.y=-2*1.85
    return c,e
