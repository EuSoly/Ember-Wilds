import bpy,bmesh,os,json,math
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\catalog'
scene=bpy.data.scenes['Tools_Catalog_23'];bpy.context.window.scene=scene
assert not scene.get('visual_fixes_applied')
for tier in ['stone','gold','diamond','amethyst']:
    o=bpy.data.objects[tier+'_shovel_scoop']
    for v in o.data.vertices:v.co.z*=1.2
    o.data.update()
for name,r0,r1,y0,y1,t in [('watering_can_top_rim',.55,.55,.38,.48,.075),('bucket_rim',.59,.59,.33,.46,.08),('bucket_bottom_band',.435,.46,-.62,-.45,.055)]:
    o=bpy.data.objects[name];n=12
    loops=[(r0,y0),(r1,y1),(r1-t,y1),(r0-t,y0+t)]
    verts=[(r*math.cos(2*math.pi*i/n),y,r*math.sin(2*math.pi*i/n)) for r,y in loops for i in range(n)]
    faces=[];ids=[]
    for l in range(4):
        for i in range(n):
            j=(i+1)%n;k=(l+1)%4;faces.append((l*n+i,l*n+j,k*n+j,k*n+i));ids.append([0,1,2,2][l])
    old=o.data;data=bpy.data.meshes.new(name+'_open');data.from_pydata(verts,[],faces);data.update()
    for m in old.materials:data.materials.append(m)
    for p,mi in zip(data.polygons,ids):p.material_index=mi
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges);bm.to_mesh(data);bm.free()
    o.data=data
    if old.users==0:bpy.data.meshes.remove(old)
scene['visual_fixes_applied']=True
with open(os.path.join(BASE,'manifest.json'),encoding='utf8') as f:report=json.load(f)
from collections import Counter
def key(v):return tuple(round(float(x),5) for x in v)
for item in report['models']:
    tris=0
    for name in item['parts']:
        o=bpy.data.objects[name];bm=bmesh.new();bm.from_mesh(o.data);assert all(e.is_manifold for e in bm.edges);bm.free()
        def sig(p,flip=False):return (p.material_index,tuple(sorted(key((o.data.vertices[i].co.x,o.data.vertices[i].co.y,-o.data.vertices[i].co.z) if flip else o.data.vertices[i].co) for i in p.vertices)))
        assert Counter(sig(p) for p in o.data.polygons)==Counter(sig(p,True) for p in o.data.polygons),name
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    item['triangles']=tris
with open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8') as f:json.dump(report,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'tools-session.blend'),copy=True)
print('Scoop intersections and open container rims fixed; all meshes validated')
