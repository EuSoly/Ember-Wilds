import bpy, bmesh, json, os, math, struct, zlib, hashlib
from mathutils import Matrix, Vector
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
OUT=os.path.join(BASE,"roblox");IND=os.path.join(OUT,"individual")
os.makedirs(IND,exist_ok=True)
src_scene=bpy.context.scene
weapons=bpy.data.collections["Weapons"]
source_cols=[c for g in weapons.children for c in g.children]
assert len(source_cols)==18
def reveal(lc):
    lc.exclude=False;lc.hide_viewport=False
    for c in lc.children:reveal(c)
reveal(bpy.context.view_layer.layer_collection)
for c in [weapons]+list(weapons.children)+source_cols:c.hide_viewport=False;c.hide_render=False
for c in source_cols:
    for o in list(c.objects):
        assert o is not None, 'Invalid object in '+c.name
        o.hide_set(False);o.hide_viewport=False;o.hide_render=False
bpy.context.view_layer.update()
deps=bpy.context.evaluated_depsgraph_get()
palette=[];color_map={}
def srgb(x):
    x=max(0,min(1,x))
    return int(round(255*(12.92*x if x<=.0031308 else 1.055*x**(1/2.4)-.055)))
def color_index(material):
    assert material is not None
    node=next((n for n in material.node_tree.nodes if n.type=="BSDF_PRINCIPLED"),None) if material.use_nodes else None
    assert not node or not node.inputs["Base Color"].is_linked
    color=node.inputs["Base Color"].default_value if node else material.diffuse_color
    key=tuple(srgb(float(x)) for x in color[:3])+(255,)
    if key not in color_map:color_map[key]=len(palette);palette.append(key)
    return color_map[key]
prepared=[];source_world={}
for c in sorted(source_cols,key=lambda c:c.name):
    root=bpy.data.objects.get(c.name+"_root");assert root
    pose=Matrix.Translation(root.matrix_world.translation)@root.matrix_world.to_quaternion().to_matrix().to_4x4()
    inverse=pose.inverted()
    vertices=[];faces=[];swatches=[];smooth=[];sourceparts=[]
    for o in sorted(c.objects,key=lambda o:o.name):
        if o.type!="MESH":continue
        ev=o.evaluated_get(deps);m=ev.to_mesh(preserve_all_data_layers=True,depsgraph=deps)
        transform=inverse@ev.matrix_world
        offset=len(vertices)
        vertices.extend(tuple(transform@v.co) for v in m.vertices)
        mirrored=transform.to_3x3().determinant()<0
        for p in m.polygons:
            seq=list(p.vertices)
            if mirrored:seq.reverse()
            faces.append(tuple(offset+i for i in seq))
            swatches.append(color_index(m.materials[p.material_index]))
            smooth.append(p.use_smooth)
        sourceparts.append({"name":o.name,"evaluated_vertices":len(m.vertices),"modifiers_baked":[mod.name for mod in o.modifiers]})
        ev.to_mesh_clear()
    assert vertices and faces
    source_world[c.name]={"pose":[list(row) for row in pose],"vertex_count":len(vertices)}
    prepared.append({"id":c.name,"vertices":vertices,"faces":faces,"swatches":swatches,"smooth":smooth,"pose":pose,"parts":sourceparts})
assert len(palette)<=256
# Write exact sRGB colors to PNG; no color-management ambiguity from image.save().
def chunk(typ,data):
    return struct.pack(">I",len(data))+typ+data+struct.pack(">I",zlib.crc32(typ+data)&0xffffffff)
raw=bytearray()
for y in range(256):
    raw.append(0)
    for x in range(256):
        index=(y//16)*16+x//16
        raw.extend(palette[index] if index<len(palette) else (255,255,255,255))
png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",256,256,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(raw),9))+chunk(b"IEND",b"")
texpath=os.path.join(OUT,"weapons_palette.png")
with open(texpath,"wb") as f:f.write(png)
image=bpy.data.images.load(texpath,check_existing=False)
image.name="weapons_palette"
# Loaded PNG uses sRGB automatically.
assert image.colorspace_settings.name=="sRGB", image.colorspace_settings.name
mat=bpy.data.materials.new("weapons_palette_material");mat.use_nodes=True
bsdf=next(n for n in mat.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value=.88
tex=mat.node_tree.nodes.new("ShaderNodeTexImage");tex.image=image
tex.interpolation=next(e.identifier for e in tex.bl_rna.properties["interpolation"].enum_items if e.identifier=="Closest")
mat.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
outscene=bpy.data.scenes.new("Roblox_Weapons_18")
bpy.context.window.scene=outscene
collection=bpy.data.collections.new("Weapons_Roblox")
outscene.collection.children.link(collection)
records=[]
for asset in prepared:
    name=asset["id"]
    m=bpy.data.meshes.new(name+"_export_mesh")
    m.from_pydata(asset["vertices"],[],asset["faces"]);m.update()
    m.materials.append(mat)
    uv=m.uv_layers.new(name="UVMap")
    for p,index,smooth in zip(m.polygons,asset["swatches"],asset["smooth"]):
        cx=((index%16)*16+8)/256
        cy=1-((index//16)*16+8)/256
        for j,li in enumerate(p.loop_indices):
            angle=2*math.pi*j/len(p.loop_indices)
            uv.data[li].uv=(cx+3/256*math.cos(angle),cy+3/256*math.sin(angle))
        p.use_smooth=smooth
    obj=bpy.data.objects.new(name,m);collection.objects.link(obj);obj.matrix_world=asset["pose"]
    obj["item_id"]=name
    # Triangulate only the export copy.
    bm=bmesh.new();bm.from_mesh(m)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bm.to_mesh(m);bm.free();m.update()
    m.calc_loop_triangles()
    assert len(m.materials)==1 and len(m.uv_layers)==1
    assert len(m.loop_triangles)<20000,(name,len(m.loop_triangles))
    assert all(math.isfinite(v) for p in m.vertices for v in p.co)
    dims=[max(v.co[i] for v in m.vertices)-min(v.co[i] for v in m.vertices) for i in range(3)]
    records.append({"item_id":name,"triangles":len(m.loop_triangles),"vertices":len(m.vertices),"local_dimensions":dims,"palette_materials":1,"source_parts":asset["parts"],"file":"individual/"+name+".fbx"})
bpy.context.view_layer.update()
export_rna=bpy.ops.export_scene.fbx.get_rna_type()
def choice(prop,value):
    return next(e.identifier for e in export_rna.properties[prop].enum_items if e.identifier==value)
kwargs={"use_selection":True,"global_scale":1.0,"apply_unit_scale":True,"apply_scale_options":choice("apply_scale_options","FBX_SCALE_UNITS"),"axis_forward":choice("axis_forward","Z"),"axis_up":choice("axis_up","Y"),"object_types":{choice("object_types","MESH")},"use_mesh_modifiers":True,"mesh_smooth_type":choice("mesh_smooth_type","FACE"),"bake_anim":False,"add_leaf_bones":False,"path_mode":choice("path_mode","COPY"),"embed_textures":True,"use_triangles":True}
for o in outscene.objects:o.select_set(True)
bpy.context.view_layer.objects.active=next(iter(outscene.objects))
combined=os.path.join(OUT,"espadas-e-lancas.fbx")
bpy.ops.export_scene.fbx(filepath=combined,**kwargs)
for o in list(outscene.objects):
    for x in outscene.objects:x.select_set(False)
    o.select_set(True);bpy.context.view_layer.objects.active=o
    pose=o.matrix_world.copy()
    o.matrix_world=Matrix.Identity(4)
    bpy.context.view_layer.update()
    bpy.ops.export_scene.fbx(filepath=os.path.join(IND,o.name+".fbx"),**kwargs)
    o.matrix_world=pose
for o in outscene.objects:o.select_set(True)
bpy.context.view_layer.update()
# Save a clean export-only blend from this background process.
# The user-facing Blender and its original editable file are never modified.
for s in list(bpy.data.scenes):
    if s!=outscene:bpy.data.scenes.remove(s)
wanted=set(outscene.objects)
for o in list(bpy.data.objects):
    if o not in wanted:bpy.data.objects.remove(o,do_unlink=True)
for c in list(bpy.data.collections):
    if c!=collection:bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
image.pack()
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=="VIEW_3D":
            area.spaces.active.overlay.show_overlays=True
            area.spaces.active.overlay.show_extras=False
            area.spaces.active.region_3d.view_location=Vector((0,0,0))
            area.spaces.active.region_3d.view_distance=23
blendpath=os.path.join(OUT,"espadas-e-lancas-export.blend")
bpy.ops.wm.save_as_mainfile(filepath=blendpath)
manifest={"format":"FBX","source":"armas-colecao-recuperada.blend (live snapshot)","combined_file":"espadas-e-lancas.fbx","texture":"weapons_palette.png","color_swatches":len(palette),"mesh_count":len(records),"total_triangles":sum(a["triangles"] for a in records),"settings":{"axis_forward":"Z","axis_up":"Y","scale":1,"apply_scalings":"FBX_SCALE_UNITS","embedded_textures":True},"individual_origin":"original weapon ROOT, rotation removed; modeled scale retained","weapons":records}
with open(os.path.join(OUT,"manifest.json"),"w",encoding="utf8") as f:json.dump(manifest,f,indent=2,ensure_ascii=False)
print("EXPORT_RESULT "+json.dumps({"weapons":len(records),"colors":len(palette),"triangles":manifest["total_triangles"],"combined":combined,"blend":blendpath}))

