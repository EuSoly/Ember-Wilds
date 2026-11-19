"""Low-poly mesh helpers. All input geometry is Z-up; no live Blender changes."""
import bpy, bmesh, math
from mathutils import Vector

def material(name,h):
    name='Farm_'+name
    if name in bpy.data.materials:return bpy.data.materials[name]
    m=bpy.data.materials.new(name);m.use_nodes=True
    def lin(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    rgba=tuple(lin(int(h.lstrip('#')[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m.diffuse_color=rgba
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=rgba;n.inputs['Roughness'].default_value=.82
    return m

def palette(name,colors):return [material(name+str(i),h) for i,h in enumerate(colors)]

def mesh(c,root,name,vs,fs,mats,group='Foliage',indices=None):
    data=bpy.data.meshes.new(name);data.from_pydata(vs,[],fs);data.update()
    for m in mats:data.materials.append(m)
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    for i,p in enumerate(data.polygons):
        p.material_index=indices[i%len(indices)] if indices else min(len(mats)-1, 2 if p.normal.z>.4 else 0 if p.normal.x>.2 else 1)
    o=bpy.data.objects.new(name,data);c.objects.link(o);o.parent=root;o['part_group']=group
    return o

def box(c,r,name,loc,size,mats,group='Foliage'):
    x,y,z=loc;a,b,d=[k/2 for k in size]
    vs=[(x+sx*a,y+sy*b,z+sz*d) for sz in (-1,1) for sy in (-1,1) for sx in (-1,1)]
    fs=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
    return mesh(c,r,name,vs,fs,mats,group)

def stem(c,r,name,a,b,radius,mats,group='Foliage',tip=None,n=6):
    a,b=Vector(a),Vector(b);d=(b-a).normalized()
    u=d.cross(Vector((0,0,1)))
    if u.length<.001:u=d.cross(Vector((0,1,0)))
    u.normalize();v=d.cross(u).normalized();top=tip if tip is not None else radius*.72
    vs=[tuple(p+(u*math.cos(2*math.pi*i/n)+v*math.sin(2*math.pi*i/n))*rad) for p,rad in ((a,radius),(b,top)) for i in range(n)]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(c,r,name,vs,fs,mats,group)

def ellipsoid(c,r,name,loc,size,mats,group='Foliage',n=10,rings=5,lobes=0):
    x,y,z=loc;sx,sy,sz=size;vs=[(x,y,z+sz)]
    for j in range(1,rings):
        p=math.pi*j/rings
        for i in range(n):
            a=2*math.pi*i/n
            l=1+lobes*math.cos(a*5)
            vs.append((x+sx*math.sin(p)*math.cos(a)*l,y+sy*math.sin(p)*math.sin(a)*l,z+sz*math.cos(p)))
    vs.append((x,y,z-sz));bot=len(vs)-1
    fs=[(0,1+i,1+(i+1)%n) for i in range(n)]
    for j in range(rings-2):
        for i in range(n):
            a=1+j*n+i;b=1+j*n+(i+1)%n
            fs.append((a,a+n,b+n,b))
    fs += [(bot,1+(rings-2)*n+(i+1)%n,1+(rings-2)*n+i) for i in range(n)]
    return mesh(c,r,name,vs,fs,mats,group)

def leaf(c,r,name,a,b,width,mats,group='Foliage',thick=.018):
    a,b=Vector(a),Vector(b);d=b-a
    side=Vector((-d.y,d.x,0)).normalized()
    if side.length<.01:side=Vector((1,0,0))
    center=a+d*.48;ridge=center+Vector((0,0,width*.16))
    top=[a,center+side*width/2,b,center-side*width/2,ridge]
    vs=[tuple(p) for p in top]+[tuple(p-Vector((0,0,thick))) for p in top]
    fs=[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(5,9,6),(6,9,7),(7,9,8),(8,9,5),(0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,5,0)]
    return mesh(c,r,name,vs,fs,mats,group,[1,2,1,0,0,0,0,0,0,0,0,0])

def slab(c,r,name,pts,z,h,mats,group='Icon'):
    n=len(pts);vs=[(x,y,k) for k in (z,z+h) for x,y in pts]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(c,r,name,vs,fs,mats,group)

def oval(x,y,rx,ry,n=10,angle=0):
    co,si=math.cos(angle),math.sin(angle)
    return [(x+rx*math.cos(2*math.pi*i/n)*co-ry*math.sin(2*math.pi*i/n)*si,y+rx*math.cos(2*math.pi*i/n)*si+ry*math.sin(2*math.pi*i/n)*co) for i in range(n)]
