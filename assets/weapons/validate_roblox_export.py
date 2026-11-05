import bpy,json,os,math
from mathutils import Vector
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons\roblox"
WORK=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons\export-work"
manifest=json.load(open(os.path.join(BASE,"manifest.json"),encoding="utf8"))
expected={w["item_id"]:w for w in manifest["weapons"]}
def bounds(o):
    vv=[o.matrix_world@v.co for v in o.data.vertices]
    return [min(v[i] for v in vv) for i in range(3)]+[max(v[i] for v in vv) for i in range(3)]
source_bounds={o.name:bounds(o) for o in bpy.context.scene.objects if o.type=="MESH"}
assert len(source_bounds)==18
report={"combined":None,"individual":[],"errors":[]}
def check_mesh(o,e):
    o.data.calc_loop_triangles()
    assert len(o.data.loop_triangles)==e["triangles"],(o.name,"triangles",len(o.data.loop_triangles),e["triangles"])
    assert len(o.data.materials)==1,(o.name,"material count")
    assert len(o.data.uv_layers)>=1,(o.name,"UV missing")
    mats=o.data.materials
    textures=[n.image for n in mats[0].node_tree.nodes if n.type=="TEX_IMAGE" and n.image]
    assert textures,(o.name,"texture missing")
    assert any(list(im.size)==[256,256] for im in textures),(o.name,[(im.name,list(im.size)) for im in textures])
    return {"name":o.name,"triangles":len(o.data.loop_triangles),"materials":1,"uv":True,"texture":True}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(BASE,"espadas-e-lancas.fbx"))
objs=list(bpy.context.scene.objects)
assert len(objs)==18 and all(o.type=="MESH" for o in objs),[(o.name,o.type) for o in objs]
assert set(o.name for o in objs)==set(expected)
combined_error=0.0
for o in objs:
    check_mesh(o,expected[o.name])
    delta=max(abs(a-b) for a,b in zip(bounds(o),source_bounds[o.name]))
    combined_error=max(combined_error,delta)
assert combined_error<.0001,combined_error
report["combined"]={"meshes":18,"geometry_bounds_max_error":combined_error,"materials_and_textures_valid":True}
for name,e in expected.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(BASE,e["file"]))
    objs=list(bpy.context.scene.objects)
    assert len(objs)==1 and objs[0].type=="MESH",(name,[(o.name,o.type) for o in objs])
    o=objs[0];assert o.name==name
    item=check_mesh(o,e);bb=bounds(o)
    dims=[bb[i+3]-bb[i] for i in range(3)]
    delta=max(abs(a-b) for a,b in zip(dims,e["local_dimensions"]))
    assert delta<.0001,(name,delta,dims,e["local_dimensions"])
    assert o.matrix_world.translation.length<.0001,(name,"pivot",list(o.matrix_world.translation))
    item["scale_error"]=delta;item["pivot_at_origin"]=True
    report["individual"].append(item)
with open(os.path.join(BASE,"validation.json"),"w",encoding="utf8") as f:json.dump(report,f,indent=2)
print("VALIDATION_RESULT "+json.dumps({"combined":report["combined"],"individual_files_passed":len(report["individual"]),"errors":report["errors"]}))

