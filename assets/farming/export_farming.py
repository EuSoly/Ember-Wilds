"""Export 49 farming assets with separately harvestable geometry, then round-trip every FBX."""
import bpy,bmesh,json,math,struct,zlib
from pathlib import Path
from mathutils import Matrix,Vector
BASE=Path(__file__).resolve().parent;OUT=BASE/'roblox';IND=OUT/'individual'
IND.mkdir(parents=True,exist_ok=True)
palette=[];swatches={};assets=[]

def color_index(m):
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    assert not n.inputs['Base Color'].is_linked
    def srgb(x):return round(255*(12.92*x if x<=.0031308 else 1.055*x**(1/2.4)-.055))
    key=tuple(srgb(max(0,min(1,x))) for x in n.inputs['Base Color'].default_value[:3])+(255,)
    if key not in swatches:swatches[key]=len(palette);palette.append(key)
    return swatches[key]

for file,group in [('farming-plants.blend','Plants'),('planter-box.blend','Planter'),('farming-icons.blend','FarmIcons')]:
    bpy.ops.wm.open_mainfile(filepath=str(BASE/file));bpy.context.view_layer.update()
    deps=bpy.context.evaluated_depsgraph_get()
    for c in bpy.data.collections[group].children:
        root=bpy.data.objects[c.name+'_root'];inv=root.matrix_world.inverted()
        parts={}
        for o in c.objects:
            if o.type!='MESH':continue
            key=o.get('part_group','Foliage')
            p=parts.setdefault(key,{'vertices':[],'faces':[],'colors':[]})
            ev=o.evaluated_get(deps);me=ev.to_mesh();transform=inv@ev.matrix_world;offset=len(p['vertices'])
            p['vertices'].extend(tuple(transform@v.co) for v in me.vertices)
            for face in me.polygons:
                p['faces'].append(tuple(offset+i for i in face.vertices));p['colors'].append(color_index(me.materials[face.material_index]))
            ev.to_mesh_clear()
        a={'id':c.name,'label':root.get('label',c.name),'kind':root.get('kind'),'crop':root.get('crop_id'),
           'stage':root.get('growth_stage'),'soil_height':root.get('soil_height'),'parts':parts}
        assets.append(a)
assert len(assets)==49,len(assets)
assert len(palette)<=256

def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
raw=bytearray()
for y in range(256):
    raw.append(0)
    for x in range(256):raw.extend(palette[(y//16)*16+x//16] if (y//16)*16+x//16<len(palette) else (255,255,255,255))
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',256,256,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b'')
(OUT/'farming_palette.png').write_bytes(png)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
image=bpy.data.images.load(str(OUT/'farming_palette.png'));image.pack()
mat=bpy.data.materials.new('Farming_Palette');mat.use_nodes=True
n=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Roughness'].default_value=.82
t=mat.node_tree.nodes.new('ShaderNodeTexImage');t.image=image;t.interpolation='Closest';mat.node_tree.links.new(t.outputs['Color'],n.inputs['Base Color'])
scene=bpy.context.scene;records=[];roots=[]

def make_mesh(name,p,root):
    me=bpy.data.meshes.new(name);me.from_pydata(p['vertices'],[],p['faces']);me.materials.append(mat);me.update()
    uv=me.uv_layers.new(name='UVMap')
    for face,idx in zip(me.polygons,p['colors']):
        x=((idx%16)*16+8)/256;y=1-((idx//16)*16+8)/256
        for j,li in enumerate(face.loop_indices):
            a=2*math.pi*j/len(face.loop_indices);uv.data[li].uv=(x+3/256*math.cos(a),y+3/256*math.sin(a))
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
    o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);o.parent=root
    lo=[min(v.co[i] for v in me.vertices) for i in range(3)];hi=[max(v.co[i] for v in me.vertices) for i in range(3)]
    me.calc_loop_triangles()
    return o,{'name':name,'triangles':len(me.loop_triangles),'local_bounds':lo+hi}

for i,a in enumerate(assets):
    root=bpy.data.objects.new(a['id'],None);scene.collection.objects.link(root);root.location=((i%7)*5,-(i//7)*5,0);roots.append(root)
    record={k:v for k,v in a.items() if k!='parts'};record['parts']=[];record['file']='individual/'+a['id']+'.fbx'
    for key,p in a['parts'].items():
        obj,rec=make_mesh(a['id']+'__'+key,p,root);rec['role']=key;record['parts'].append(rec)
    # Small temporary pivot marker: the installer reads and removes it.
    # This prevents different crop silhouettes from shifting between stages.
    vs=[(x*.02,y*.02,z*.02) for z in (-1,1) for y in (-1,1) for x in (-1,1)]
    fs=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
    obj,rec=make_mesh(a['id']+'__Origin',{'vertices':vs,'faces':fs,'colors':[0]*6},root);rec['role']='Origin';record['parts'].append(rec)
    records.append(record)

bpy.context.view_layer.update()
kwargs=dict(use_selection=True,global_scale=1.0,apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='Z',axis_up='Y',object_types={'MESH','EMPTY'},use_mesh_modifiers=True,mesh_smooth_type='FACE',bake_anim=False,add_leaf_bones=False,path_mode='COPY',embed_textures=True,use_triangles=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=str(OUT/'farming-pack.fbx'),**kwargs)
for root,record in zip(roots,records):
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in root.children:o.select_set(True)
    loc=root.location.copy();root.location=(0,0,0);bpy.context.view_layer.update()
    bpy.ops.export_scene.fbx(filepath=str(OUT/record['file']),**kwargs)
    root.location=loc
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'farming-export.blend'))
manifest={'model_count':49,'plant_stages':36,'seed_icons':9,'supplies':3,'planter':1,'palette_colors':len(palette),
          'combined_file':'farming-pack.fbx','texture':'farming_palette.png','models':records,
          'note':'Origin meshes are temporary markers removed by import-farming.luau. Keep all other parts separate.',
          'final_mesh_count':sum(len(r['parts'])-1 for r in records),'total_triangles':sum(p['triangles'] for r in records for p in r['parts'] if p['role']!='Origin')}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')

def bounds(o):
    vs=[o.matrix_world@v.co for v in o.data.vertices]
    return [min(v[i] for v in vs) for i in range(3)]+[max(v[i] for v in vs) for i in range(3)]
original={o.name:bounds(o) for o in scene.objects if o.type=='MESH'}
expected={p['name']:p for r in records for p in r['parts']}
def check(o):
    p=expected[o.name];o.data.calc_loop_triangles()
    assert len(o.data.loop_triangles)==p['triangles'],o.name
    assert len(o.data.materials)==1 and len(o.data.uv_layers)==1,o.name
    assert any(n.type=='TEX_IMAGE' and n.image and tuple(n.image.size)==(256,256) for n in o.data.materials[0].node_tree.nodes),o.name

bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(OUT/'farming-pack.fbx'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert set(o.name for o in meshes)==set(expected)
err=0
for o in meshes:
    check(o);err=max(err,max(abs(a-b) for a,b in zip(bounds(o),original[o.name])))
assert err<.0001,err
report={'combined_mesh_count_with_origins':len(meshes),'combined_bounds_error':err,'individual':[]}
for record in records:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(OUT/record['file']))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert {o.name for o in meshes}=={p['name'] for p in record['parts']},record['id']
    assert len({o.data.as_pointer() for o in meshes})==len(meshes),'shared harvest mesh'
    for o in meshes:
        check(o);delta=max(abs(a-b) for a,b in zip(bounds(o),expected[o.name]['local_bounds']))
        assert delta<.0001,(o.name,delta)
    origin=bpy.data.objects[record['id']+'__Origin'];bb=bounds(origin)
    assert max(abs(bb[i]+bb[i+3]) for i in range(3))<.0001
    harvest=[o for o in meshes if '__Harvest_' in o.name]
    if harvest:
        harvest[0].hide_set(True)
        assert all(not o.hide_get() for o in meshes if o!=harvest[0])
    report['individual'].append({'id':record['id'],'parts':len(meshes)-1,'independent_harvest_parts':len(harvest),'pivot_at_origin':True,'passed':True})
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('FARM_VALIDATED '+json.dumps({'models':49,'meshes':manifest['final_mesh_count'],'triangles':manifest['total_triangles'],'roundtrips':50}))
