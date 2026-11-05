import bpy, os, json, math, tempfile, shutil
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__));OUT=os.path.join(BASE,'roblox')
manifest=json.load(open(os.path.join(OUT,'manifest.json'),encoding='utf8'))
assets={a['id']:a for a in manifest['assets']}
report=dict(files=[],errors=[],tested_in='Blender FBX round trip; not uploaded to Roblox Studio')
def bounds(o):
    points=[o.matrix_world@v.co for v in o.data.vertices]
    return [min(p[j] for p in points) for j in range(3)]+[max(p[j] for p in points) for j in range(3)]
with tempfile.TemporaryDirectory(prefix='world_fbx_',dir=os.path.join(BASE,'work')) as temp:
    for item in manifest['exports']:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        source=os.path.join(OUT,item['file']);dest=os.path.join(temp,os.path.basename(source))
        shutil.copy2(source,dest)
        bpy.ops.import_scene.fbx(filepath=dest)
        expected={p['name']:(a,p) for name in item['assets'] for a in [assets[name]] for p in a['parts']}
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        assert set(o.name for o in meshes)==set(expected),(item['file'],'mesh names')
        max_error=0.;pivot_error=0.
        for o in meshes:
            a,p=expected[o.name];o.data.calc_loop_triangles()
            assert len(o.data.loop_triangles)==p['triangles'],(o.name,'triangles')
            assert len(o.data.materials)==1 and len(o.data.uv_layers)==1,(o.name,'material/UV')
            images=[n.image for n in o.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
            assert images and list(images[0].size)==[manifest['texture_size']]*2,(o.name,'embedded texture')
            assert all(math.isfinite(v) for vertex in o.data.vertices for v in vertex.co)
            assert all(0<=v<=1 for loop in o.data.uv_layers[0].data for v in loop.uv)
            offset=[0,0,0] if item['individual'] else a['gallery']
            bb=[v+offset[i%3] for i,v in enumerate(p['bounds'])]
            error=max(abs(v-w) for v,w in zip(bb,bounds(o)));max_error=max(max_error,error)
            assert error<.0001,(item['file'],o.name,'bounds',error)
            pivot=Vector(p['pivot'])+Vector(offset)
            error=(o.matrix_world.translation-pivot).length;pivot_error=max(pivot_error,error)
            assert error<.0001,(item['file'],o.name,'pivot',error)
            assert o.parent and o.parent.name==a['id']+'_root',(o.name,'parent')
        report['files'].append(dict(file=item['file'],assets=len(item['assets']),meshes=len(meshes),max_bounds_error=max_error,max_pivot_error=pivot_error,texture=True,uv=True,hierarchy=True))
assert len(report['files'])==60
report['passed']=True;report['files_passed']=len(report['files'])
report['max_bounds_error']=max(f['max_bounds_error'] for f in report['files'])
report['max_pivot_error']=max(f['max_pivot_error'] for f in report['files'])
json.dump(report,open(os.path.join(OUT,'validation.json'),'w',encoding='utf8'),indent=2)
print('VALIDATION_RESULT',json.dumps({k:v for k,v in report.items() if k!='files'}))
