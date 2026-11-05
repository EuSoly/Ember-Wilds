import bpy,bmesh,os,json
from collections import Counter
BASE=r'C:\Users\Elize\Desktop\Roblox\starve\assets\tools\pickaxes'
scene=bpy.data.scenes['Pickaxes_Preview_06'];bpy.context.window.scene=scene
plane=.15
assert not scene.get('pickaxes_two_sided'), 'Already made symmetric'
source=bpy.data.filepath
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'pickaxes-before-two-sides.blend'),copy=True)
pending=[];report=[]
for col in bpy.data.collections['Pickaxes'].children:
    summary={'item_id':col.name,'triangles':0,'parts':[]}
    for obj in col.objects:
        if obj.type!='MESH':continue
        bm=bmesh.new();bm.from_mesh(obj.data)
        # Cut at the common centre plane. Keep the approved front surfaces.
        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-6,plane_co=(0,0,plane),plane_no=(0,0,1))
        lower=[v for v in bm.verts if v.co.z<plane-1e-6]
        bmesh.ops.delete(bm,geom=lower,context='VERTS')
        bm.verts.ensure_lookup_table();bm.verts.index_update()
        vertices=[tuple(v.co) for v in bm.verts]
        faces=[tuple(v.index for v in f.verts) for f in bm.faces]
        mids=[f.material_index for f in bm.faces]
        bm.free()
        reflected={}
        for i,(x,y,z) in enumerate(list(vertices)):
            if abs(z-plane)<1e-6:
                vertices[i]=(x,y,plane);reflected[i]=i
            else:
                reflected[i]=len(vertices);vertices.append((x,y,2*plane-z))
        initial_faces=list(faces);initial_mids=list(mids)
        for face,mi in zip(initial_faces,initial_mids):
            mirrored=tuple(reflected[i] for i in reversed(face))
            if set(mirrored)!=set(face):faces.append(mirrored);mids.append(mi)
        data=bpy.data.meshes.new(obj.name+'_two_sided')
        data.from_pydata(vertices,[],faces);data.update()
        for m in obj.data.materials:data.materials.append(m)
        for f,mi in zip(data.polygons,mids):f.material_index=mi
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bad=sum(not e.is_manifold for e in bm.edges)
        bm.to_mesh(data);bm.free();assert bad==0,(obj.name,bad)
        assert not data.validate(verbose=False),obj.name
        def key(v):return tuple(round(float(x),5) for x in v)
        actual=Counter(key(v.co) for v in data.vertices)
        mirrored=Counter(key((v.co.x,v.co.y,2*plane-v.co.z)) for v in data.vertices)
        assert actual==mirrored,('Asymmetric vertices',obj.name)
        # Check reflected faces carry the same materials, including bevels.
        def signature(f,reflect=False):
            return (f.material_index,tuple(sorted(key((data.vertices[i].co.x,data.vertices[i].co.y,2*plane-data.vertices[i].co.z) if reflect else data.vertices[i].co) for i in f.vertices)))
        assert Counter(signature(f) for f in data.polygons)==Counter(signature(f,True) for f in data.polygons),obj.name
        data.calc_loop_triangles();summary['triangles']+=len(data.loop_triangles)
        summary['parts'].append({'name':obj.name,'geometry_and_materials_symmetric':True,'non_manifold_edges':bad})
        pending.append((obj,data))
    report.append(summary)
# Commit only after every part passes checks.
for obj,data in pending:
    old=obj.data;obj.data=data
    if old.users==0:bpy.data.meshes.remove(old)
    obj['symmetry_plane_local_z']=plane
for col in bpy.data.collections['Pickaxes'].children:
    root=bpy.data.objects[col.name+'_root'];root.location.z+=.15
scene['pickaxes_two_sided']=True
for obj in scene.objects:
    if obj.type=='FONT' and obj.data.body.startswith('PREVIA 02'):
        obj.data.body='PREVIA 03  /  ACABAMENTO IGUAL NAS DUAS FACES'
scene.render.filepath=os.path.join(BASE,'picaretas-preview-v3.png')
with open(os.path.join(BASE,'validation-v3.json'),'w',encoding='utf8') as f:json.dump(report,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=source)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'pickaxes-session-v3.blend'),copy=True)
print(json.dumps(report))
