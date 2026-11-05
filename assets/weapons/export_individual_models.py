import bpy, os, json
from mathutils import Vector, Quaternion
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
out=os.path.join(BASE,"modelos-individuais");os.makedirs(out,exist_ok=True)
catalog=bpy.data.scenes["Weapons_Catalog_18"]
# Give the overview breathing room above the titles.
catalog.camera.data.ortho_scale=21.2
groups=[bpy.data.collections["01 | ESPADAS - 9 modelos"],bpy.data.collections["02 | LANCAS - 9 modelos"]]
files=[]
for group in groups:
    for src in group.children:
        sc=bpy.data.scenes.new(src.name+"__Individual")
        col=bpy.data.collections.new(src.name+"__EDITAR");sc.collection.children.link(col)
        copied={}
        for original in src.objects:
            obj=original.copy()
            if original.type=="MESH":obj.data=original.data.copy()
            col.objects.link(obj);copied[original]=obj
        for original,obj in copied.items():
            if original.parent in copied:obj.parent=copied[original.parent]
            elif original.type=="EMPTY":
                obj.location=(0,0,0);obj.rotation_euler=(0,0,0);obj.scale=(1,1,1)
        sc.world=catalog.world
        path=os.path.join(out,src.name+".blend")
        bpy.data.libraries.write(path,{sc},fake_user=True,compress=True)
        files.append({"name":src.name,"path":path,"bytes":os.path.getsize(path)})
        # Remove only the temporary copies made for this export.
        for obj in list(col.objects):
            data=obj.data if obj.type=="MESH" else None
            bpy.data.objects.remove(obj,do_unlink=True)
            if data and data.users==0:bpy.data.meshes.remove(data)
        bpy.data.scenes.remove(sc);bpy.data.collections.remove(col)
edit=bpy.data.scenes.get("Armas_Editar_18") or bpy.data.scenes.new("Armas_Editar_18")
for group in groups:
    if group.name not in edit.collection.children:edit.collection.children.link(group)
edit.world=catalog.world
bpy.context.window.scene=edit
bpy.context.view_layer.objects.active=None
for obj in edit.objects:obj.select_set(False)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=="VIEW_3D":
            sp=area.spaces.active
            sp.overlay.show_overlays=True
            sp.region_3d.view_rotation=Quaternion((1,0,0,0))
            sp.region_3d.view_location=Vector((0,.4,0))
            sp.region_3d.view_distance=20
            valid=[e.identifier for e in sp.region_3d.bl_rna.properties["view_perspective"].enum_items]
            sp.region_3d.view_perspective=next(v for v in valid if v=="ORTHO")
            sp.region_3d.view_camera_zoom=0
# Active project is the new catalog, so Ctrl+S saves the editable weapons file.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,"armas-colecao-editavel.blend"))
with open(os.path.join(BASE,"modelos-individuais.json"),"w",encoding="utf8") as f:json.dump(files,f,indent=2)
print(json.dumps({"active_scene":edit.name,"active_file":bpy.data.filepath,"individual_files":len(files),"minimum_bytes":min(x["bytes"] for x in files)}))

