import bpy, json, os, re, hashlib, struct, datetime
from mathutils import Matrix
BASE=r"C:\Users\Elize\Desktop\Roblox\starve\assets\weapons"
scene=bpy.context.scene
assert scene.name=="Scene", "Inspect the active scene before running this organizer."
assert bpy.context.mode=="OBJECT", "Finish edit mode before organizing."
def walk(c):
    yield c
    for child in c.children:yield from walk(child)
active_cols=list(walk(scene.collection))
weapons=next(c for c in active_cols if c.name=="armas")
swords=next(c for c in weapons.children if "ESPADAS" in c.name)
spears=next(c for c in weapons.children if "LANCAS" in c.name)
tiermap={"Madeira":"wood","Pedra":"stone","Ouro":"gold","Diamante":"diamond","Ametista":"amethyst","Reidite":"reidite","Dragao":"dragon","Lava":"lava","Pirata":"pirate","Caranguejo":"crab"}
assets=[]
for group,kind in ((swords,"sword"),(spears,"spear")):
    for col in group.children:
        tier=col.name.split("_",1)[1].split(".")[0]
        key=tiermap[tier]+"_"+kind
        roots=[o for o in col.objects if o.type=="EMPTY"]
        assert len(roots)==1,(col.name,roots)
        assets.append({"id":key,"kind":kind,"col":col,"root":roots[0],"parts":[o for o in col.objects if o.type=="MESH"]})
assert len(assets)==18
assetmap={a["id"]:a for a in assets}
detached=[("Ouro__Encaixe.002","gold_spear","fittings"),("Diamante__Encaixe.002","diamond_spear","fittings"),("Ametista__Encaixe.002","amethyst_spear","pommel")]
overrides={"Cone":"tip","Pedra__Encaixe.001":"fittings","Reidite__Encaixe.001":"fittings","Espada_Reidite__simple_handle.002":"handle_studs"}
for name,key,role in detached:
    o=scene.objects.get(name);assert o and o.type=="MESH",name
    assetmap[key]["parts"].append(o);overrides[name]=role
extra_names=["Lanca_Pedra__ROOT.002","Lanca_Ouro__ROOT.002","Lanca_Diamante__ROOT.002","Lanca_Ametista__ROOT.002","Lanca_Reidite__ROOT.002","Lanca_Reidite__ROOT.003","Espada_Madeira__ROOT.001"]
extras=[scene.objects[n] for n in extra_names]
def role_for(o,kind):
    n=o.name
    if n in overrides:return overrides[n]
    tail=re.sub(r"\.\d+$","",n.split("__",1)[-1]).lower()
    roles={"simple_handle":"handle","cabo":"handle","haste":"shaft","straight_blade":"blade","curved_red_blade":"blade","lamina":"blade","small_crossguard":"guard","gray_crossguard":"guard","guarda":"guard","colored_pommel":"pommel","pomo":"pommel","purple_collar":"collar","open_knuckle_guard":"knuckle_guard","protecao_cabo":"knuckle_guard","detalhe_lamina":"blade_detail","ponta":"tip","ponta_central":"tip","encaixe":"collar","espora_-1":"prong_left","espora_1":"prong_right","garra_esquerda":"claw_left","garra_direita":"claw_right"}
    assert tail in roles,(n,tail)
    return roles[tail]
rename_plan=[]
for a in assets:
    roles=set()
    for o in a["parts"]:
        role=role_for(o,a["kind"]);assert role not in roles,(a["id"],role);roles.add(role)
        name=a["id"]+"_"+role
        assert bpy.data.objects.get(name) in (None,o),name
        rename_plan.append((a,o,name,role))
    assert bpy.data.collections.get(a["id"]) in (None,a["col"])
    assert bpy.data.objects.get(a["id"]+"_root") in (None,a["root"])
# Record all current meshes, including unrelated pickaxes, before hierarchy changes.
bpy.context.view_layer.update()
def mesh_hash(o):
    h=hashlib.sha256()
    for v in o.data.vertices:h.update(struct.pack("<3f",*v.co))
    for p in o.data.polygons:
        h.update(struct.pack("<II",len(p.vertices),p.material_index))
        for i in p.vertices:h.update(struct.pack("<I",i))
    return h.hexdigest()
before={}
deps=bpy.context.evaluated_depsgraph_get()
for o in scene.objects:
    if o.type!="MESH":continue
    ev=o.evaluated_get(deps);me=ev.to_mesh()
    coords=[tuple(ev.matrix_world@v.co) for v in me.vertices];ev.to_mesh_clear()
    before[o.as_pointer()]={"obj":o,"name":o.name,"hash":mesh_hash(o),"matrix":o.matrix_world.copy(),"coords":coords,"materials":[m.as_pointer() if m else None for m in o.data.materials],"modifiers":[(m.name,m.type) for m in o.modifiers]}
backup_dir=os.path.join(BASE,"backups");os.makedirs(backup_dir,exist_ok=True)
stamp=datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup=os.path.join(backup_dir,"antes-organizacao-"+stamp+".blend")
bpy.ops.wm.save_as_mainfile(filepath=backup,copy=True)
weapons.name="Weapons";swords.name="Swords";spears.name="Spears"
helper_col=bpy.data.collections.new("UnusedWeaponControls");scene.collection.children.link(helper_col)
helper_col["export"]=False
helper_col["description"]="Controles auxiliares preservados, sem malhas; nao exportar."
def move_to(o,col):
    if o.name not in col.objects:col.objects.link(o)
    for old in list(o.users_collection):
        if old!=col:old.objects.unlink(o)
renames=[]
for a in assets:
    oldcol=a["col"].name;a["col"].name=a["id"]
    a["col"]["item_id"]=a["id"];a["col"]["weapon_type"]=a["kind"];a["col"]["export"]=True
    root=a["root"];oldroot=root.name;root.name=a["id"]+"_root"
    root["item_id"]=a["id"];root["part_role"]="root"
    root.empty_display_size=.12
    renames.append({"old":oldroot,"new":root.name,"collection":a["id"],"role":"root"})
    a["old_collection"]=oldcol
    move_to(root,a["col"])
for a,o,name,role in rename_plan:
    old=o.name;world=o.matrix_world.copy()
    # Parenting with inverse compensation retains the user's world-space edits.
    if o.parent!=a["root"]:
        o.parent=a["root"]
        o.matrix_parent_inverse=a["root"].matrix_world.inverted_safe()
        o.matrix_world=world
    move_to(o,a["col"])
    o.name=name
    if o.data.users==1:o.data.name=name+"_mesh"
    o["item_id"]=a["id"];o["part_role"]=role
    renames.append({"old":old,"new":o.name,"collection":a["id"],"role":role})
helper_counts={}
for o in extras:
    assert not o.children,(o.name,[x.name for x in o.children])
    original=o.name
    kind="spear" if original.startswith("Lanca") else "sword"
    tier=original.split("_")[1]
    key=tiermap[tier]+"_"+kind
    helper_counts[key]=helper_counts.get(key,0)+1
    o.name=key+"_unused_root_"+str(helper_counts[key]).zfill(2)
    o["original_name"]=original;o["export"]=False
    move_to(o,helper_col)
bpy.context.view_layer.update()
# Verify that no surface, material assignment, modifier or placement changed.
deps=bpy.context.evaluated_depsgraph_get()
errors=[];max_delta=0.0
for state in before.values():
    o=state["obj"]
    if mesh_hash(o)!=state["hash"]:errors.append(o.name+": mesh data changed")
    if [m.as_pointer() if m else None for m in o.data.materials]!=state["materials"]:errors.append(o.name+": material assignments changed")
    if [(m.name,m.type) for m in o.modifiers]!=state["modifiers"]:errors.append(o.name+": modifiers changed")
    ev=o.evaluated_get(deps);me=ev.to_mesh();coords=[tuple(ev.matrix_world@v.co) for v in me.vertices];ev.to_mesh_clear()
    if len(coords)!=len(state["coords"]):errors.append(o.name+": evaluated vertex count changed")
    else:
        delta=max((max(abs(a-b) for a,b in zip(p,q)) for p,q in zip(coords,state["coords"])),default=0)
        max_delta=max(max_delta,delta)
        if delta>0.00002:errors.append(o.name+": world geometry changed")
assert not errors,errors
for a in assets:
    assert all(o.parent==a["root"] and list(o.users_collection)==[a["col"]] for o in a["parts"])
    assert set(a["col"].objects)==set(a["parts"]+[a["root"]])
leftovers=[o.name for o in scene.collection.objects if o.type=="MESH" or o.name.startswith(("Lanca_","Espada_"))]
assert not leftovers,leftovers
for ar in bpy.context.screen.areas:
    if ar.type=="VIEW_3D":
        ar.spaces.active.overlay.show_overlays=True
        ar.spaces.active.overlay.show_extras=False
        ar.spaces.active.overlay.show_relationship_lines=False
for o in bpy.context.selected_objects:o.select_set(False)
selected=assetmap["reidite_spear"]["root"];selected.select_set(True);bpy.context.view_layer.objects.active=selected
manifest={"schema_version":1,"blend_file":bpy.data.filepath,"scene":scene.name,"root_collection":"Weapons","backup":backup,"validation":{"assets":len(assets),"meshes_preserved":len(before),"geometry_unchanged":True,"materials_unchanged":True,"modifiers_unchanged":True,"max_world_vertex_delta":max_delta,"loose_weapon_meshes":0},"weapons":[{"item_id":a["id"],"type":a["kind"],"collection":a["col"].name,"root":a["root"].name,"parts":[{"name":o.name,"role":o["part_role"],"mesh":o.data.name} for o in a["parts"]]} for a in assets],"renamed":renames,"unused_controls":[o.name for o in extras]}
with open(os.path.join(BASE,"weapon-assets.json"),"w",encoding="utf8") as f:json.dump(manifest,f,indent=2,ensure_ascii=False)
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print(json.dumps({"file":bpy.data.filepath,"backup":backup,"validation":manifest["validation"],"detached_meshes_fixed":len(detached),"new_tip_parented":True,"unused_controls_preserved":len(extras),"assets":[{"id":a["id"],"parts":len(a["parts"])} for a in assets]}))

