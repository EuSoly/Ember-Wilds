import bpy, math, os, json, bmesh
from mathutils import Vector
BASE = r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
os.makedirs(BASE, exist_ok=True)
NAME = "Weapons_Stone_Preview_v1"
if NAME in bpy.data.scenes:
    raise RuntimeError("Preview already exists; inspect before rebuilding")
scene = bpy.data.scenes.new(NAME)
bpy.context.window.scene = scene
models = bpy.data.collections.new("WEAPONS | Stone prototypes")
scene.collection.children.link(models)
stage = bpy.data.collections.new("PRESENTATION | excluded from export")
scene.collection.children.link(stage)

def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4
colors = ["#85929B","#BBC8CF","#53616A","#382A26","#79513A","#A47449","#C2A57B","#21303B","#E7E6DF","#8EA4AF"]
palette = bpy.data.images.new("Weapons_Palette_256",width=256,height=256,alpha=True)
pixels=[]
for y in range(256):
    for x in range(256):
        h=colors[min(x//16,len(colors)-1)].lstrip("#")
        pixels.extend([int(h[i:i+2],16)/255 for i in (0,2,4)]+[1])
palette.pixels=pixels
palette.filepath_raw=os.path.join(BASE,"weapons-palette.png")
palette.file_format=next(e.identifier for e in palette.bl_rna.properties["file_format"].enum_items if e.identifier=="PNG")
palette.save()
palette.pack()
mat=bpy.data.materials.new("WEAPONS | shared palette")
mat.use_nodes=True
bsdf=next(n for n in mat.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value=.8
tex=mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image=palette
tex.interpolation=next(e.identifier for e in tex.bl_rna.properties["interpolation"].enum_items if e.identifier=="Closest")
mat.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])

def mesh(name,verts,faces,swatches,col,parent=None):
    m=bpy.data.meshes.new(name)
    m.from_pydata(verts,[],faces)
    m.update()
    o=bpy.data.objects.new(name,m)
    col.objects.link(o)
    if parent: o.parent=parent
    m.materials.append(mat)
    uv=m.uv_layers.new(name="PaletteUV")
    for i,p in enumerate(m.polygons):
        idx=swatches[i%len(swatches)]
        for li in p.loop_indices: uv.data[li].uv=((idx*16+8)/256,.5)
    bm=bmesh.new(); bm.from_mesh(m)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(m); bm.free()
    return o

def prism(name,outline,z0,z1,swatches,col,parent=None):
    n=len(outline)
    verts=[(x,y,z) for z in (z0,z1) for x,y in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,swatches,col,parent)

def rod(name,y0,y1,radius,swatches,col,parent):
    n=8
    verts=[(radius*math.cos(2*math.pi*i/n+math.pi/8),y,.22+radius*math.sin(2*math.pi*i/n+math.pi/8)) for y in (y0,y1) for i in range(n)]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,swatches,col,parent)

def blade(name,outline,ridge_y,ridge_z,col,parent):
    n=len(outline)
    verts=[(x,y,.22) for x,y in outline]+[(0,ridge_y,.22+ridge_z),(0,ridge_y,.22-ridge_z)]
    faces=[(i,(i+1)%n,n) for i in range(n)]+[((i+1)%n,i,n+1) for i in range(n)]
    return mesh(name,verts,faces,[0,1,1,0,2,2,0,2],col,parent)

def root(name,x,angle):
    col=bpy.data.collections.new(name)
    models.children.link(col)
    r=bpy.data.objects.new(name+" | GRIP_ROOT",None)
    col.objects.link(r)
    r.location=(x,0,0)
    r.rotation_euler.z=math.radians(angle)
    return col,r
scol,sroot=root("Sword_Stone",-1.05,-13)
rod("Sword | wooden grip",-.3,.30,.105,[3,4,5,4],scol,sroot)
for i in range(4):
    rod("Sword | leather binding "+str(i),-.23+i*.115,-.17+i*.115,.112,[3,4],scol,sroot)
prism("Sword | octagonal pommel",[(-.10,-.42),(.10,-.42),(.15,-.36),(.15,-.29),(.10,-.24),(-.1,-.24),(-.15,-.29),(-.15,-.36)],.10,.34,[3,5,4],scol,sroot)
guard=[(-.46,.21),(-.39,.40),(-.21,.44),(.21,.44),(.39,.40),(.46,.21),(.36,.16),(.18,.25),(-.18,.25),(-.36,.16)]
prism("Sword | carved wooden guard",guard,.105,.335,[3,4,5,4],scol,sroot)
blade("Sword | faceted stone blade",[(-.17,.36),(.17,.36),(.285,.56),(.24,1.60),(0,1.94),(-.24,1.60),(-.285,.56)],1.02,.135,scol,sroot)
rod("Sword | collar",.37,.49,.125,[6,5],scol,sroot)
lcol,lroot=root("Spear_Stone",1.06,-13)
rod("Spear | wooden shaft",-1.20,1.55,.067,[3,4,5,4,4,5,4,3],lcol,lroot)
rod("Spear | butt cap",-1.24,-1.08,.082,[3,4],lcol,lroot)
for i in range(4):
    rod("Spear | grip wrap "+str(i),-.18+i*.13,-.09+i*.13,.079,[3,4],lcol,lroot)
blade("Spear | stone arrowhead",[(0,1.30),(.26,1.56),(.19,1.91),(0,2.39),(-.19,1.91),(-.26,1.56)],1.73,.115,lcol,lroot)
for i in range(3):
    rod("Spear | rope collar "+str(i),1.32+i*.09,1.39+i*.09,.094,[6,5],lcol,lroot)
# All meshes use a single packed 256px palette with per-face UVs.
def plain(name,h,rough=1):
    m=bpy.data.materials.new(name);m.use_nodes=True
    b=next(n for n in m.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    rgba=tuple(linear(int(h[i:i+2],16)/255) for i in (0,2,4))+(1,)
    b.inputs["Base Color"].default_value=rgba
    b.inputs["Roughness"].default_value=rough
    m.diffuse_color=rgba
    return m
floor=plain("Stage | slate","263744")
textmat=plain("Stage | ivory","E8E5DD")
muted=plain("Stage | muted","9EADB2")
m=bpy.data.meshes.new("Backdrop");m.from_pydata([(-200,-200,-.04),(200,-200,-.04),(200,200,-.04),(-200,200,-.04)],[],[(0,1,2,3)])
o=bpy.data.objects.new("Backdrop",m);stage.objects.link(o);m.materials.append(floor)
def label(name,body,loc,size,material):
    c=bpy.data.curves.new(name,"FONT");c.body=body;c.size=size;c.space_character=1.15
    o=bpy.data.objects.new(name,c);stage.objects.link(o);o.location=loc;c.materials.append(material)
    return o
label("Title","PEDRA / 01",(-2.10,3.02,0),.24,textmat)
label("Subtitle","ESPADA + LANCA   /   ESTUDO LOW-POLY",(-2.10,2.75,0),.105,muted)
label("Sword label","ESPADA",(-1.68,-1.72,0),.16,textmat)
label("Sword detail","LAMINA LARGA / CORTE",(-1.68,-1.93,0),.075,muted)
label("Spear label","LANCA",(.57,-1.72,0),.16,textmat)
label("Spear detail","HASTE LONGA / ESTOCADA",(.57,-1.93,0),.075,muted)
camera_data=bpy.data.cameras.new("Weapons Preview Camera")
cam=bpy.data.objects.new("Weapons Preview Camera",camera_data);stage.objects.link(cam)
cam.location=(.15,-4.5,11.5)
target=Vector((.15,.50,0))
cam.rotation_euler=(target-cam.location).to_track_quat("-Z","Y").to_euler()
camera_data.type=next(e.identifier for e in camera_data.bl_rna.properties["type"].enum_items if e.identifier=="ORTHO")
camera_data.ortho_scale=6.0
scene.camera=cam
def area(name,loc,energy,size):
    ld=bpy.data.lights.new(name,"AREA");o=bpy.data.objects.new(name,ld);stage.objects.link(o)
    o.location=loc;o.rotation_euler=(Vector((0,.5,0))-o.location).to_track_quat("-Z","Y").to_euler()
    ld.energy=energy;ld.shape=next(e.identifier for e in ld.bl_rna.properties["shape"].enum_items if e.identifier=="DISK");ld.size=size
area("Key",(-3,1,7),750,5)
area("Fill",(4,-2,5),350,4)
world=bpy.data.worlds.new("Weapons Preview World");world.use_nodes=True
bg=next(n for n in world.node_tree.nodes if n.type=="BACKGROUND")
bg.inputs["Color"].default_value=(.20,.25,.30,1);bg.inputs["Strength"].default_value=.4;scene.world=world
try: scene.render.engine="CYCLES"
except TypeError: pass
if scene.render.engine=="CYCLES": scene.cycles.samples=32
scene.render.resolution_x=1300;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
vt=[e.identifier for e in scene.view_settings.bl_rna.properties["view_transform"].enum_items]
if "Standard" in vt: scene.view_settings.view_transform="Standard"
scene.render.image_settings.file_format=next(e.identifier for e in scene.render.image_settings.bl_rna.properties["file_format"].enum_items if e.identifier=="PNG")
scene.render.filepath=os.path.join(BASE,"espada-lanca-pedra-v1.png")
report=[]
for col in (scol,lcol):
    tris=0;boundaries=0;bad=0
    for obj in col.objects:
        if obj.type!="MESH":continue
        obj.data.calc_loop_triangles();tris+=len(obj.data.loop_triangles)
        bm=bmesh.new();bm.from_mesh(obj.data)
        boundaries+=sum(not e.is_manifold for e in bm.edges)
        bad+=sum(f.calc_area()<1e-9 for f in bm.faces)
        bm.free()
    report.append({"collection":col.name,"triangles":tris,"non_manifold_edges":boundaries,"degenerate_faces":bad})
with open(os.path.join(BASE,"preview-validation.json"),"w",encoding="utf-8") as f:json.dump(report,f,indent=2)
for screen in bpy.data.screens:
    for ar in screen.areas:
        if ar.type=="VIEW_3D":
            ar.spaces.active.region_3d.view_perspective="CAMERA"
            ar.spaces.active.overlay.show_overlays=False
# Save a separate copy; the existing tools file is not overwritten.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,"espada-lanca-pedra-v1.blend"),copy=True)
print(json.dumps(report))
print("Created preview scene and saved separate blend copy.")

