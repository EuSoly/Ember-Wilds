"""First editable wooden helmet fitted to the player's captured Studio geometry."""
import bpy, math, json
from mathutils import Vector
from pathlib import Path
OUT=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
scene=bpy.context.scene
assert bpy.data.objects.get("Player_Referencia"), "Open the player reference first."
assert not bpy.data.collections.get("04 Capacete de Madeira - v01"), "Helmet v01 already exists."
coll=bpy.data.collections.new("04 Capacete de Madeira - v01")
scene.collection.children.link(coll)
root=bpy.data.objects.new("wood_helmet",None)
coll.objects.link(root)
root["item_id"]="wood_helmet"
root["stage"]="Primeira proposta visual editavel"
root["attachment"]="Origem = centro do Body; frente +Y; 1 unidade = 1 stud"
def mat(name,h):
    vals=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in vals]
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*rgb,1)
    bs=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    bs.inputs["Base Color"].default_value=(*rgb,1)
    bs.inputs["Roughness"].default_value=.77
    return m
woods=[mat("Madeira - mel","AE703C"),mat("Madeira - clara","BC8148"),mat("Madeira - media","9A5B31"),mat("Madeira - dourada","B5763E")]
edge=mat("Bordas - madeira escura","422A20")
leather=mat("Tiras - couro castanho","603B27")
grain=mat("Veios - baixo contraste","84512C")
peg=mat("Pinos - madeira clara","D4A368")
def put(ob,name,m=None):
    ob.name=name
    for c in list(ob.users_collection):c.objects.unlink(ob)
    coll.objects.link(ob);ob.parent=root
    if m:ob.data.materials.append(m)
    return ob
def mesh(name,vs,fs,m,bevel=0):
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
    ob=bpy.data.objects.new(name,me);coll.objects.link(ob);ob.parent=root;me.materials.append(m)
    if bevel:
        mod=ob.modifiers.new("Cantos suaves","BEVEL");mod.width=bevel;mod.segments=2
    return ob
def ribbon(name,pts,width,thick,m):
    vs=[]
    for p in pts:vs.extend([(p[0]-width/2,p[1],p[2]),(p[0]+width/2,p[1],p[2])])
    n=len(pts);fs=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(n-1)]
    ob=mesh(name,vs,fs,m)
    sol=ob.modifiers.new("Espessura","SOLIDIFY");sol.thickness=thick
    bev=ob.modifiers.new("Bordas arredondadas","BEVEL");bev.width=.013;bev.segments=2
    return ob
def line(name,pts,r,m):
    cu=bpy.data.curves.new(name,"CURVE");cu.dimensions='3D';cu.resolution_u=1
    cu.bevel_depth=r;cu.bevel_resolution=1
    sp=cu.splines.new("POLY");sp.points.add(len(pts)-1)
    for p,co in zip(sp.points,pts):p.co=(*co,1)
    return put(bpy.data.objects.new(name,cu),name,m)
def top(x,y):
    return 1.30+.52*max(0,1-(x/2.05)**2)*max(.15,1-((y+.55)/1.72)**2)
def rear(x):
    ax=abs(x)
    return -1.93 if ax<=.96 else -.96-math.sqrt(max(0,.97**2-(ax-.96)**2))
def front(x):return -.12+.07*(abs(x)/1.93)**2
# Rounded U-shaped shell follows the back and sides of the body.
path=[(1.93,.98),(1.93,.35),(1.93,-.35),(1.93,-.96)]
for i in range(1,9):
    a=-math.pi/2*i/8
    path.append((.96+.97*math.cos(a),-.96+.97*math.sin(a)))
path.extend([(.48,-1.93),(0,-1.93),(-.48,-1.93),(-.96,-1.93)])
for i in range(1,9):
    a=-math.pi/2-math.pi/2*i/8
    path.append((-.96+.97*math.cos(a),-.96+.97*math.sin(a)))
path.extend([(-1.93,-.35),(-1.93,.35),(-1.93,.98)])
def shell(name,z0,z1,thick,m,offset=0):
    vs=[]
    for x,y in path:
        norm=Vector((x,y)).normalized()
        for d,z in [(offset,z0),(offset,z1),(offset-thick,z0),(offset-thick,z1)]:
            vs.append((x+norm.x*d,y+norm.y*d,z))
    fs=[]
    for i in range(len(path)-1):
        a=i*4;b=a+4
        fs.extend([(a,b,b+1,a+1),(a+2,a+3,b+3,b+2),(a+1,b+1,b+3,a+3),(a,a+2,b+2,b)])
    fs.extend([(0,1,3,2),tuple(range(len(vs)-4,len(vs)))])
    return mesh(name,vs,fs,m,.025)
shell("Interior escuro do capacete",.04,1.32,.105,edge)
shell("Aro inferior de couro",.03,.22,.14,leather,.055)
# Individual rear and side staves.
for i in range(len(path)-1):
    p=Vector(path[i]);q=Vector(path[i+1]);a=p.lerp(q,.045);b=p.lerp(q,.955)
    n=((p+q)/2).normalized()
    corners=[a,b,b-n*.095,a-n*.095]
    zlo=.22 if i not in (0,len(path)-2) else .16
    vs=[(v.x,v.y,z) for z in (zlo,1.31) for v in corners]
    mesh("Tabua lateral %02d"%i,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],woods[i%4],.025)
# Dark continuous lining keeps the body from showing between crown planks.
lining_vs=[];lining_faces=[];LX=25;LY=14
for ix in range(LX):
    x=-1.92+3.84*ix/(LX-1)
    for iy in range(LY):
        y=rear(x)+(front(x)-rear(x))*iy/(LY-1)
        lining_vs.append((x,y,top(x,y)-.075))
for ix in range(LX-1):
    for iy in range(LY-1):
        a=ix*LY+iy;lining_faces.append((a,a+LY,a+LY+1,a+1))
lining=mesh("Forro continuo sob as tabuas",lining_vs,lining_faces,edge)
lining.modifiers.new("Espessura do forro","SOLIDIFY").thickness=.07
# Seven shaped longitudinal crown planks.
for j in range(7):
    x0=-1.90+j*(3.80/7)+.018
    x1=-1.90+(j+1)*(3.80/7)-.018
    vs=[];NX=3;NY=12
    for layer in (0,1):
        for ix in range(NX):
            x=x0+(x1-x0)*ix/(NX-1)
            for iy in range(NY):
                y=rear(x)+(front(x)-rear(x))*iy/(NY-1)
                vs.append((x,y,top(x,y)-layer*.16))
    N=NX*NY;fs=[]
    for ix in range(NX-1):
        for iy in range(NY-1):
            a=ix*NY+iy
            fs.extend([(a,a+NY,a+NY+1,a+1),(a+N+1,a+N+NY+1,a+N+NY,a+N)])
    loop=list(range(NY))+[i*NY+NY-1 for i in range(1,NX)]+list(range((NX-1)*NY+NY-2,(NX-1)*NY-1,-1))+[i*NY for i in range(NX-2,0,-1)]
    for a,b in zip(loop,loop[1:]+loop[:1]):fs.append((a,b,b+N,a+N))
    mesh("Coroa - tabua %02d"%(j+1),vs,fs,woods[j%4],.024)
    # Broken woodgrain, restrained enough to read at game scale.
    xc=(x0+x1)/2
    for k in range(2):
        pts=[]
        ya=rear(xc)+.22+k*.53
        yb=min(ya+.48,front(xc)-.13)
        if yb>ya:
            for t in range(7):
                y=ya+(yb-ya)*t/6
                x=xc+.08*math.sin(t*.7+j)+(.08 if k else -.07)
                pts.append((x,y,top(x,y)+.016))
            line("Veio %02d_%d"%(j,k),pts,.009,grain)
# Front lip: dark backing and warm wood edge, following the crown arch.
xs=[-1.92+i*3.84/32 for i in range(33)]
for name,rad,ma,zoff in [("Contorno da testa",.095,edge,-.025),("Borda arredondada da testa",.058,woods[1],.018)]:
    line(name,[(x,front(x)-.005,top(x,front(x))+zoff) for x in xs],rad,ma)
# Two leather reinforcing straps over the crown.
for side in (-1,1):
    x=side*1.17
    ys=[rear(x)+.02+i*(front(x)-rear(x)-.02)/16 for i in range(17)]
    ribbon("Cinta de couro "+str(side),[(x,y,top(x,y)+.045) for y in ys],.18,.045,leather)
    for y in (ys[1],ys[-2]):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=(x,y,top(x,y)+.10))
        ob=put(bpy.context.object,"Pino de madeira",peg);ob.scale=(.07,.07,.035)
# Front cheek pieces frame the face without crossing the eye discs.
for side in (-1,1):
    # Small tapered wooden guards extend along each outside corner.
    vs=[(side*1.76,.35,.45),(side*2.04,.35,.45),(side*2.04,1.14,.64),(side*1.76,1.14,.64),
        (side*1.76,.35,1.37),(side*2.04,.35,1.37),(side*2.04,1.14,1.15),(side*1.76,1.14,1.15)]
    mesh("Protecao lateral "+str(side),vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],woods[2],.065)
# Small wooden central crest with a darker inset.
y=-.66;z=top(0,y)
mesh("Marca central - losango",[(0,y+.22,z+.07),(.17,y,z+.09),(0,y-.23,z+.075),(-.17,y,z+.09)],[(0,1,2,3)],edge)
mesh("Marca central - folha",[(0,y+.15,z+.083),(.10,y,z+.105),(0,y-.15,z+.09),(-.10,y,z+.105)],[(0,1,2,3)],peg)
# Keep the already-equipped accessories, hidden for a clear fitting review.
access=bpy.data.collections.get("03 Mochila e livro equipados")
access.hide_render=True
for ob in access.objects: ob.hide_set(True)
# Presentation camera and soft lights, in their own collection.
stage=bpy.data.collections.new("05 Apresentacao");scene.collection.children.link(stage)
def staging(ob):
    for c in list(ob.users_collection):c.objects.unlink(ob)
    stage.objects.link(ob)
bpy.ops.object.camera_add(location=(6.2,10,14))
cam=bpy.context.object;cam.name="Camera - capacete no personagem";staging(cam)
target=Vector((0,0,.25));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=8.5;scene.camera=cam
for name,loc,power,size in [("Luz principal",(-4,5,9),900,5),("Preenchimento",(5,1,6),550,4),("Recorte",(-1,-5,6),750,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc)
    ob=bpy.context.object;ob.name=name;ob.data.energy=power;ob.data.shape='DISK';ob.data.size=size
    ob.rotation_euler=(Vector((0,0,.5))-ob.location).to_track_quat('-Z','Y').to_euler();staging(ob)
scene.world.color=(.10,.10,.10)
if scene.world.use_nodes:
    bg=next(n for n in scene.world.node_tree.nodes if n.type=="BACKGROUND")
    bg.inputs['Color'].default_value=(.18,.21,.25,1);bg.inputs['Strength'].default_value=.45
scene.render.resolution_x=1200;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.film_transparent=False
scene.render.filepath=str(OUT/"capacete-madeira-v01.png")
# Show a useful near-top game angle in the user's viewport.
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True);bpy.context.view_layer.objects.active=root
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        s=area.spaces.active;s.region_3d.view_location=Vector((0,0,.4));s.region_3d.view_distance=9
        s.region_3d.view_rotation=(Vector((0,0,.4))-Vector((4,8,13))).to_track_quat('-Z','Y')
        s.region_3d.view_perspective='ORTHO';s.shading.type='MATERIAL'
        s.overlay.show_extras=False;s.overlay.show_floor=False
bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get()
tri=0
for ob in coll.objects:
    if ob.type in {'MESH','CURVE'}:
        ev=ob.evaluated_get(deps);me=ev.to_mesh()
        tri+=sum(len(p.vertices)-2 for p in me.polygons)
        ev.to_mesh_clear()
root["triangles_preview"]=tri
scene["helmet_v01"]="Capacete de madeira: coroa de sete tabuas, laterais, cintas de couro e pinos de madeira; olhos desobstruidos."
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"capacete-madeira-v01.blend"))
print(json.dumps({"file":bpy.data.filepath,"helmet_objects":len(coll.objects),"triangles_preview":tri}))

