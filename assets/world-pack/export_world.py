import bpy, bmesh, os, json, math, struct, zlib
from mathutils import Matrix, Vector
BASE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(BASE,'roblox')
os.makedirs(os.path.join(OUT,'individual'),exist_ok=True)
os.makedirs(os.path.join(OUT,'categorias'),exist_ok=True)
specs=[]
for cat,cn in [('depositos','Icon_Inspired_Deposits'),('estruturas','Utility_Structures'),('construcoes','Builds_Catalog')]:
    parent=bpy.data.collections[cn]
    cols=list(parent.children) if cat=='depositos' else [c for g in parent.children for c in g.children]
    for c in cols:
        specs.append(dict(id=c.name,category=cat,col=c,root=bpy.data.objects[c.name+'_root']))
names=dict(madeira='wood',pedra='stone',ouro='gold',diamante='diamond',ametista='amethyst',reidite='reidite')
for c in bpy.data.collections['viewport'].children:
    specs.append(dict(id=names[c.name]+'_viewport',category='viewports',col=c,root=None))
emerald=bpy.data.collections.new('emerald_viewport_source')
emerald.objects.link(bpy.data.objects['Reference_emerald_proposal'])
specs.append(dict(id='emerald_viewport',category='viewports',col=emerald,root=None))
assert len(specs)==55,len(specs)
order=['depositos','viewports','estruturas','construcoes']
specs.sort(key=lambda a:(order.index(a['category']),a['id']))
scene=bpy.data.scenes.new('World_Assets_55_Editable')
bpy.context.window.scene=scene
groups={}
for cat in order:
    c=bpy.data.collections.new(cat);scene.collection.children.link(c);groups[cat]=c
row=0
for cat in order:
    assets=[a for a in specs if a['category']==cat]
    for i,a in enumerate(assets):
        c=a['col'];groups[cat].children.link(c)
        c.hide_viewport=False;c.hide_render=False;c.hide_select=False
        for o in c.objects:
            o.hide_viewport=False;o.hide_render=False;o.hide_select=False;o.hide_set(False)
        bpy.context.view_layer.update()
        root=a['root']
        if root is None:
            objs=list(c.objects)
            points=[o.matrix_world@v.co for o in objs if o.type=='MESH' for v in o.data.vertices]
            centre=Vector([(min(p[j] for p in points)+max(p[j] for p in points))/2 for j in range(3)])
            root=bpy.data.objects.new(a['id']+'_root',None);c.objects.link(root);root.location=centre
            bpy.context.view_layer.update()
            for o in objs:
                if o.parent not in objs:
                    world=o.matrix_world.copy();o.parent=root;o.matrix_world=world
            a['root']=root
        root.location=((i%8-3.5)*8,-(row+i//8)*8,0)
        root.rotation_euler=(0,0,0)
        root['item_id']=a['id']
        a['gallery']=list(root.location)
    row+=math.ceil(len(assets)/8)+1
bpy.context.view_layer.update()
# Isolate only requested assets in this background process.
wanted=set(scene.objects)
for s in list(bpy.data.scenes):
    if s!=scene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):
    if o not in wanted:bpy.data.objects.remove(o,do_unlink=True)
keep=set(groups.values())|{a['col'] for a in specs}
for c in list(bpy.data.collections):
    if c not in keep:bpy.data.collections.remove(c)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.overlay.show_extras=False
            area.spaces.active.region_3d.view_location=Vector((0,-40,0))
            area.spaces.active.region_3d.view_distance=90
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'mundo-editavel.blend'))
palette=[];indices={}
def srgb(v):
    v=max(0,min(1,v));return round(255*(12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055))
def color(mat):
    assert mat is not None
    node=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if mat.use_nodes else None
    assert not node or not node.inputs['Base Color'].is_linked,mat.name
    rgba=node.inputs['Base Color'].default_value if node else mat.diffuse_color
    key=tuple(srgb(v) for v in rgba[:3])+(255,)
    if key not in indices:indices[key]=len(palette);palette.append(key)
    return indices[key]
def frame(o):return Matrix.Translation(o.matrix_world.translation)@o.matrix_world.to_quaternion().to_matrix().to_4x4()
def props(o):
    out={}
    for k in o.keys():
        v=o[k]
        if hasattr(v,'to_list'):v=v.to_list()
        if isinstance(v,(str,int,float,bool,list)):out[k]=v
    return out
deps=bpy.context.evaluated_depsgraph_get()
prepared=[]
for a in specs:
    root=a['root'];base=frame(root);objects=list(a['col'].objects)
    movers=[o for o in objects if o!=root and (o.name.endswith(('_panel_left','_panel_right','_rotor','_lid_hinge','_flame_anchor','_core_anchor')))]
    groups2={None:[]};groups2.update({o:[] for o in movers})
    for o in objects:
        if o.type!='MESH':continue
        ancestor=o
        while ancestor is not None and ancestor not in movers:ancestor=ancestor.parent
        groups2[ancestor].append(o)
    asset=dict(id=a['id'],category=a['category'],gallery=a['gallery'],properties=props(root),parts=[],attachments=[])
    for o in objects:
        if o.type=='EMPTY' and o!=root and o not in movers:
            asset['attachments'].append(dict(name=o.name,matrix=[list(r) for r in base.inverted()@o.matrix_world],properties=props(o)))
    for anchor,objs in groups2.items():
        if not objs:continue
        pose=frame(anchor) if anchor else base
        role=anchor.name[len(a['id'])+1:] if anchor else 'body'
        role={'lid_hinge':'lid','flame_anchor':'flames','core_anchor':'core'}.get(role,role)
        part=dict(name=a['id']+'_'+role,vertices=[],faces=[],colors=[],smooth=[],source_parts=[],relative=base.inverted()@pose,properties=props(anchor) if anchor else {})
        for o in objs:
            ev=o.evaluated_get(deps);m=ev.to_mesh(preserve_all_data_layers=True,depsgraph=deps)
            transform=pose.inverted()@ev.matrix_world;offset=len(part['vertices'])
            part['vertices'].extend(tuple(transform@v.co) for v in m.vertices)
            for p in m.polygons:
                seq=list(p.vertices)
                if transform.to_3x3().determinant()<0:seq.reverse()
                part['faces'].append(tuple(offset+j for j in seq));part['colors'].append(color(m.materials[p.material_index]));part['smooth'].append(p.use_smooth)
            part['source_parts'].append(o.name);ev.to_mesh_clear()
        asset['parts'].append(part)
    prepared.append(asset)
assert sum(len(a['parts']) for a in prepared)==78
outscene=bpy.data.scenes.new('World_Assets_55_Export');bpy.context.window.scene=outscene
for s in list(bpy.data.scenes):
    if s!=outscene:bpy.data.scenes.remove(s)
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
for c in list(bpy.data.collections):bpy.data.collections.remove(c)
bpy.data.orphans_purge(do_recursive=True)
grid=16
while len(palette)>grid*grid:grid*=2
size=grid*16
def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
raw=bytearray()
for y in range(size):
    raw.append(0)
    for x in range(size):
        idx=(y//16)*grid+x//16;raw.extend(palette[idx] if idx<len(palette) else (255,255,255,255))
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b'')
texpath=os.path.join(OUT,'world_palette.png');open(texpath,'wb').write(png)
image=bpy.data.images.load(texpath);assert image.colorspace_settings.name=='sRGB'
mat=bpy.data.materials.new('world_palette');mat.use_nodes=True
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bsdf.inputs['Roughness'].default_value=.88
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
tex.interpolation=next(e.identifier for e in tex.bl_rna.properties['interpolation'].enum_items if e.identifier=='Closest')
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
records=[];roots={};objects_by_asset={}
for cat in order:
    c=bpy.data.collections.new(cat);outscene.collection.children.link(c);groups[cat]=c
for a in prepared:
    col=bpy.data.collections.new(a['id']);groups[a['category']].children.link(col)
    root=bpy.data.objects.new(a['id']+'_root',None);col.objects.link(root);root.location=a['gallery'];root['item_id']=a['id']
    roots[a['id']]=root;objects_by_asset[a['id']]=[root]
    record={k:a[k] for k in ('id','category','gallery','properties','attachments')};record['parts']=[];record['file']='individual/'+a['id']+'.fbx'
    for p in a['parts']:
        m=bpy.data.meshes.new(p['name']);m.from_pydata(p['vertices'],[],p['faces']);m.materials.append(mat);m.update()
        uv=m.uv_layers.new(name='UVMap')
        for face,idx,smooth in zip(m.polygons,p['colors'],p['smooth']):
            cx=((idx%grid)*16+8)/size;cy=1-((idx//grid)*16+8)/size
            for j,li in enumerate(face.loop_indices):
                ang=2*math.pi*j/len(face.loop_indices);uv.data[li].uv=(cx+3/size*math.cos(ang),cy+3/size*math.sin(ang))
            face.use_smooth=smooth
        bm=bmesh.new();bm.from_mesh(m);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(m);bm.free();m.update();m.calc_loop_triangles()
        assert len(m.loop_triangles)<20000
        o=bpy.data.objects.new(p['name'],m);col.objects.link(o);o.parent=root;o.matrix_basis=p['relative'];o['item_id']=a['id']
        objects_by_asset[a['id']].append(o)
        pts=[p['relative']@v.co for v in m.vertices]
        bb=[min(v[j] for v in pts) for j in range(3)]+[max(v[j] for v in pts) for j in range(3)]
        record['parts'].append(dict(name=o.name,triangles=len(m.loop_triangles),vertices=len(m.vertices),bounds=bb,pivot=list(p['relative'].translation),relative_matrix=[list(r) for r in p['relative']],properties=p['properties'],source_parts=p['source_parts']))
    records.append(record)
bpy.context.view_layer.update()
rna=bpy.ops.export_scene.fbx.get_rna_type()
def choice(k,v):return next(e.identifier for e in rna.properties[k].enum_items if e.identifier==v)
kw=dict(use_selection=True,global_scale=1.0,apply_unit_scale=True,apply_scale_options=choice('apply_scale_options','FBX_SCALE_UNITS'),axis_forward=choice('axis_forward','Z'),axis_up=choice('axis_up','Y'),object_types={choice('object_types','MESH'),choice('object_types','EMPTY')},use_mesh_modifiers=True,mesh_smooth_type=choice('mesh_smooth_type','FACE'),bake_anim=False,add_leaf_bones=False,path_mode=choice('path_mode','COPY'),embed_textures=True,use_triangles=True,use_custom_props=True)
exports=[]
def export(path,ids,individual=False):
    for o in outscene.objects:o.select_set(False)
    for name in ids:
        for o in objects_by_asset[name]:o.select_set(True)
    if individual:roots[ids[0]].location=(0,0,0)
    bpy.context.view_layer.update();bpy.context.view_layer.objects.active=roots[ids[0]]
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,path),**kw)
    exports.append(dict(file=path,assets=ids,individual=individual))
    if individual:roots[ids[0]].location=next(a['gallery'] for a in records if a['id']==ids[0])
export('mundo-completo.fbx',[a['id'] for a in records])
for cat in order:export('categorias/'+cat+'.fbx',[a['id'] for a in records if a['category']==cat])
for a in records:export(a['file'],[a['id']],True)
bpy.context.view_layer.update()
for o in outscene.objects:o.select_set(False)
image.pack();image.filepath='//world_palette.png'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'mundo-export.blend'))
manifest=dict(asset_count=len(records),mesh_count=sum(len(a['parts']) for a in records),total_triangles=sum(p['triangles'] for a in records for p in a['parts']),palette_colors=len(palette),texture='world_palette.png',texture_size=size,coordinate_system='Blender Z-up; FBX forward Z, up Y. Pivot coordinates and bounds below are Blender coordinates.',assets=records,exports=exports)
json.dump(manifest,open(os.path.join(OUT,'manifest.json'),'w',encoding='utf8'),indent=2,ensure_ascii=False)
print('EXPORT_RESULT',json.dumps({k:v for k,v in manifest.items() if k not in ('assets','exports')}))

