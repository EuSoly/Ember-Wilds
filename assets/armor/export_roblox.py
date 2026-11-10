"""Export only the 32 approved armor roots from a live snapshot. Run in background Blender."""
import bpy,bmesh,json,math,struct,zlib,hashlib
from pathlib import Path
from mathutils import Matrix,Vector
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
OUT=BASE/"roblox";IND=OUT/"individual"
IND.mkdir(parents=True,exist_ok=True)
hc=json.loads((BASE/"helmet-catalog.json").read_text(encoding="utf-8"))
wc=json.loads((BASE/"wearable-catalog.json").read_text(encoding="utf-8"))
assets=[(r["id"],r["id"],r["design"]) for r in hc]+[(r["id"],"wear_"+r["id"],r["design"]) for r in wc]
assert len(assets)==32 and len(set(x[0] for x in assets))==32
assert bpy.data.objects["wear_ninja"]["revision"]=="v02 mouth wrap"
assert bpy.data.objects["wear_witch"]["revision"]=="v02 fluid brim and crown"
palette=[];lookup={}
def srgb(v):
    v=max(0,min(1,v));return round(255*(12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055))
def swatch(mat):
    bs=next((n for n in mat.node_tree.nodes if n.type=="BSDF_PRINCIPLED"),None)
    assert bs and not bs.inputs["Base Color"].is_linked,mat.name
    rgba=tuple(srgb(v) for v in bs.inputs["Base Color"].default_value[:3])+(255,)
    rough=round(255*bs.inputs["Roughness"].default_value)
    metal=round(255*bs.inputs["Metallic"].default_value)
    key=rgba+(rough,metal)
    if key not in lookup:lookup[key]=len(palette);palette.append(key)
    return lookup[key],bs.inputs["Emission Strength"].default_value>0
prepared=[]
for id,rootname,design in assets:
    root=bpy.data.objects[rootname]
    source_scene=next(s for s in bpy.data.scenes if rootname in s.objects and not s.name.startswith("Revisao"))
    bpy.context.window.scene=source_scene
    bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
    inv=root.matrix_world.inverted();groups={}
    source_count=0
    for ob in sorted(root.children_recursive,key=lambda x:x.name):
        if ob.type not in {"MESH","CURVE"}:continue
        assert not ob.name.startswith(("OLD_","REF_")),ob.name
        ev=ob.evaluated_get(deps);me=ev.to_mesh(preserve_all_data_layers=True,depsgraph=deps)
        xf=inv@ev.matrix_world;vv=[tuple(xf@v.co) for v in me.vertices]
        mirrored=xf.to_3x3().determinant()<0
        # Keep luminous faces as separate meshes for Roblox Neon.
        for face in me.polygons:
            idx,emits=swatch(me.materials[face.material_index])
            kind="neon" if emits else "body"
            g=groups.setdefault(kind,dict(vertices=[],faces=[],colors=[],smooth=[],parts=set()))
            # Reuse source vertices per object and group.
            marker=(ob.name,kind)
            if not hasattr(swatch,"offsets"):swatch.offsets={}
            if marker not in swatch.offsets:
                swatch.offsets[marker]=len(g["vertices"]);g["vertices"].extend(vv)
            off=swatch.offsets[marker]
            inds=list(face.vertices)
            if mirrored:inds.reverse()
            g["faces"].append(tuple(off+i for i in inds));g["colors"].append(idx);g["smooth"].append(face.use_smooth);g["parts"].add(ob.name)
        ev.to_mesh_clear();source_count+=1
    prepared.append(dict(id=id,design=design,groups=groups,source_count=source_count,revision=root.get("revision","approved")))
    print("PREPARED",id,source_count)
grid=math.ceil(math.sqrt(len(palette)));grid=2**math.ceil(math.log2(grid));tile=16;size=grid*tile
def chunk(t,d):return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
def png(name,mode):
    raw=bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            i=(y//tile)*grid+x//tile
            p=palette[i] if i<len(palette) else (255,255,255,255,180,0)
            color=p[:4] if mode=="color" else (p[4],p[4],p[4],255) if mode=="roughness" else (p[5],p[5],p[5],255)
            raw.extend(color)
    data=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(raw),9))+chunk(b"IEND",b"")
    (OUT/name).write_bytes(data)
png("armaduras_palette.png","color");png("armaduras_roughness.png","roughness");png("armaduras_metalness.png","metalness")
images={}
for mode,name in [("color","armaduras_palette.png"),("roughness","armaduras_roughness.png"),("metalness","armaduras_metalness.png")]:
    im=bpy.data.images.load(str(OUT/name),check_existing=False)
    if mode!="color":im.colorspace_settings.name="Non-Color"
    images[mode]=im
materials={}
for kind in ("body","neon"):
    mat=bpy.data.materials.new("armaduras_"+kind);mat.use_nodes=True
    bs=next(n for n in mat.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
    for mode,inputname in [("color","Base Color"),("roughness","Roughness"),("metalness","Metallic")]:
        tex=mat.node_tree.nodes.new("ShaderNodeTexImage");tex.image=images[mode];tex.interpolation="Closest"
        mat.node_tree.links.new(tex.outputs["Color"],bs.inputs[inputname])
        if kind=="neon" and mode=="color":
            mat.node_tree.links.new(tex.outputs["Color"],bs.inputs["Emission Color"]);bs.inputs["Emission Strength"].default_value=1.4
    materials[kind]=mat
scene=bpy.data.scenes.new("Armaduras - exportacao 32")
bpy.context.window.scene=scene
scene.unit_settings.system="NONE";scene.unit_settings.scale_length=1
records=[];roots=[];mesh_objs=[]
for ai,asset in enumerate(prepared):
    id=asset["id"]
    col=bpy.data.collections.new("EXPORT_"+id);scene.collection.children.link(col)
    root=bpy.data.objects.new(id,None);col.objects.link(root);root.location=((ai%8)*7.5,(ai//8)*8,0)
    # Object names of source roots may collide; explicitly free only datablock names in background snapshot.
    source=bpy.data.objects.get(id)
    if source and source is not root:source.name="SOURCE_"+id
    root.name=id;root["item_id"]=id;roots.append(root)
    rec=dict(id=id,title=asset["design"],revision=asset["revision"],file="individual/"+id+".fbx",gallery=list(root.location),parts=[])
    for kind,g in asset["groups"].items():
        name=id+("_neon" if kind=="neon" else "_armor")
        me=bpy.data.meshes.new(name);me.from_pydata(g["vertices"],[],g["faces"]);me.materials.append(materials[kind]);me.update()
        uv=me.uv_layers.new(name="UVMap")
        for p,idx,smooth in zip(me.polygons,g["colors"],g["smooth"]):
            cx=((idx%grid)*tile+8)/size;cy=1-((idx//grid)*tile+8)/size
            for j,li in enumerate(p.loop_indices):
                a=2*math.pi*j/len(p.loop_indices);uv.data[li].uv=(cx+3/size*math.cos(a),cy+3/size*math.sin(a))
            p.use_smooth=smooth
        bm=bmesh.new();bm.from_mesh(me)
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context="VERTS")
        bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update();me.calc_loop_triangles()
        assert len(me.loop_triangles)<20000,(id,len(me.loop_triangles))
        assert all(math.isfinite(c) for v in me.vertices for c in v.co)
        ob=bpy.data.objects.new(name,me);col.objects.link(ob);ob.parent=root;mesh_objs.append(ob)
        ob["item_id"]=id;ob["part_type"]=kind;ob["roblox_material"]="Neon" if kind=="neon" else "SmoothPlastic"
        bounds=[min(v.co[i] for v in me.vertices) for i in range(3)]+[max(v.co[i] for v in me.vertices) for i in range(3)]
        rec["parts"].append(dict(name=name,kind=kind,triangles=len(me.loop_triangles),vertices=len(me.vertices),bounds=bounds,source_parts=len(g["parts"]),roblox_material=ob["roblox_material"]))
    records.append(rec)
bpy.context.view_layer.update()
rna=bpy.ops.export_scene.fbx.get_rna_type()
def enum(k,v):return next(e.identifier for e in rna.properties[k].enum_items if e.identifier==v)
kw=dict(use_selection=True,global_scale=1.0,apply_unit_scale=True,apply_scale_options=enum("apply_scale_options","FBX_SCALE_UNITS"),axis_forward=enum("axis_forward","-Z"),axis_up=enum("axis_up","Y"),object_types={enum("object_types","MESH"),enum("object_types","EMPTY")},use_mesh_modifiers=True,mesh_smooth_type=enum("mesh_smooth_type","FACE"),bake_anim=False,add_leaf_bones=False,path_mode=enum("path_mode","COPY"),embed_textures=True,use_triangles=True,use_custom_props=True)
def exp(path,selected):
    for ob in scene.objects:ob.select_set(False)
    for root in selected:
        root.select_set(True)
        for ob in root.children:ob.select_set(True)
    bpy.context.view_layer.objects.active=selected[0]
    bpy.ops.export_scene.fbx(filepath=str(path),**kw)
exp(OUT/"armaduras-32.fbx",roots)
for root,rec in zip(roots,records):
    old=root.location.copy();root.location=(0,0,0);bpy.context.view_layer.update()
    exp(OUT/rec["file"],[root])
    root.location=old
# Make an export-only scene, keeping the user-facing source file untouched.
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
wanted=set(scene.objects)
for ob in list(bpy.data.objects):
    if ob not in wanted:bpy.data.objects.remove(ob,do_unlink=True)
keep=set(scene.collection.children_recursive)
for c in list(bpy.data.collections):
    if c not in keep:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
for mode,im in images.items():im.pack();im.filepath="//"+Path(im.filepath).name
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"armaduras-export.blend"))
manifest=dict(source="approved-snapshot.blend",count=len(records),mesh_count=len(mesh_objs),format="FBX",combined_file="armaduras-32.fbx",textures=["armaduras_palette.png","armaduras_roughness.png","armaduras_metalness.png"],texture_size=size,palette_swatches=len(palette),axis_forward="-Z",axis_up="Y",scale=1,import_scale_unit="Stud",origin="Body centre; Blender +Y front / +Z up; Roblox front -Z / up +Y",assets=records)
(OUT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding="utf-8")
print("EXPORT_RESULT",json.dumps({"items":len(records),"meshes":len(mesh_objs),"triangles":sum(p["triangles"] for r in records for p in r["parts"]),"swatches":len(palette),"folder":str(OUT)}))

