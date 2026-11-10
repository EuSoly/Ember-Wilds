"""Round-trip validation of all FBXs, texture slots, geometry, bounds and pivots."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector
BASE=Path(r"C:\Users\Elize\Desktop\Roblox\starve\assets\armor")
OUT=BASE/"roblox"
manifest=json.loads((OUT/"manifest.json").read_text(encoding="utf-8"))
expected={p["name"]:(a,p) for a in manifest["assets"] for p in a["parts"]}
report={"ok":False,"files":[],"errors":[]}
def bounds(ob):
    ps=[ob.matrix_world@v.co for v in ob.data.vertices]
    return [min(v[i] for v in ps) for i in range(3)]+[max(v[i] for v in ps) for i in range(3)]
def check(path,assets,combined):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT/path))
    obs=list(bpy.context.scene.objects)
    assert all(ob.type in {"MESH","EMPTY"} for ob in obs)
    expected_meshes={p["name"] for a in assets for p in a["parts"]}
    got={ob.name for ob in obs if ob.type=="MESH"}
    assert got==expected_meshes,(path,got^expected_meshes)
    maxerror=0;checked=[]
    for ob in obs:
        if ob.type!="MESH":continue
        a,e=expected[ob.name];me=ob.data;me.calc_loop_triangles()
        assert len(me.loop_triangles)==e["triangles"],(path,ob.name,"triangles")
        assert len(me.uv_layers)==1 and len(me.materials)==1
        mat=me.materials[0]
        images=[n.image for n in mat.node_tree.nodes if n.type=="TEX_IMAGE" and n.image]
        assert images,(path,ob.name,"missing images")
        assert any(list(im.size)==[manifest["texture_size"]]*2 and "palette" in im.name for im in images)
        for im in images:
            assert all(im.size),im.name
        shift=a["gallery"] if combined else [0,0,0]
        want=[e["bounds"][i]+shift[i%3] for i in range(6)]
        err=max(abs(x-y) for x,y in zip(bounds(ob),want))
        assert err<.0001,(path,ob.name,"bounds",err)
        maxerror=max(err,maxerror)
        assert max(abs(ob.matrix_world.translation[i]-shift[i]) for i in range(3))<.0001,(path,ob.name,"origin")
        for uv in me.uv_layers[0].data:
            assert all(0<=v<=1 for v in uv.uv)
        checked.append({"mesh":ob.name,"triangles":e["triangles"],"texture_files":[im.name for im in images]})
    return {"file":path,"ok":True,"meshes":len(got),"max_geometry_error":maxerror,"checks":checked}
for path,assets,combined in [(manifest["combined_file"],manifest["assets"],True)]+[(a["file"],[a],False) for a in manifest["assets"]]:
    try:report["files"].append(check(path,assets,combined))
    except Exception as ex:
        report["errors"].append({"file":path,"error":repr(ex)})
report["ok"]=not report["errors"] and len(report["files"])==33
report["sha256"]={str(p.relative_to(OUT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [OUT/manifest["combined_file"]]+[OUT/a["file"] for a in manifest["assets"]]}
(OUT/"validation.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print("VALIDATION_RESULT",json.dumps({"ok":report["ok"],"files":len(report["files"]),"errors":report["errors"]}))
assert report["ok"],report["errors"]
# Visual QA from the actual round-tripped FBX, with embedded palette images.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(OUT/manifest["combined_file"]))
scene=bpy.context.scene
wanted={"amethyst_helmet":(0,0,0),"reidite_helmet":(-7,0,0),"dragon_helmet":(-14,0,0),"life_crown":(0,7,0),"angel_crown":(-7,7,0),"lava_helmet":(-14,7,0)}
for a in manifest["assets"]:
    for p in a["parts"]:
        ob=bpy.data.objects[p["name"]];ob.hide_render=a["id"] not in wanted
        if a["id"] in wanted:
            ob.parent=None;ob.location=wanted[a["id"]]
            if p["kind"]=="neon":
                bs=next(n for n in ob.active_material.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
                tex=next(n for n in ob.active_material.node_tree.nodes if n.type=="TEX_IMAGE" and n.image and "palette" in n.image.name)
                ob.active_material.node_tree.links.new(tex.outputs["Color"],bs.inputs["Emission Color"]);bs.inputs["Emission Strength"].default_value=1.4
center=Vector((-7,3.5,1.4))
bpy.ops.object.camera_add(location=center+Vector((0,9,16)));cam=bpy.context.object
cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=22;scene.camera=cam
for pos,power in [((-13,6,12),3000),((0,4,10),2300),((-7,-5,9),2400)]:
    bpy.ops.object.light_add(type='AREA',location=pos);ob=bpy.context.object;ob.data.energy=power;ob.data.size=7
    ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler()
scene.world=bpy.data.worlds.new('QA background')
scene.world.color=(.15,.15,.15)
scene.render.resolution_x=1500;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(BASE/"export-work/fbx-roundtrip-preview.png")
bpy.ops.render.render(write_still=True)

