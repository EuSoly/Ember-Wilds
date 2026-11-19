"""Build the missing inventory meshes and a five-fruit bush in background Blender.

Run: blender -b --factory-startup --python build_assets.py
Existing source .blend files are read only. All outputs stay beside this script.
"""
import bpy, bmesh, math, json, sys
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[2]
LIB = REPO / 'assets/resources/food/icons_lib.py'
g = {}
exec(compile(LIB.read_text(encoding='utf8'), str(LIB), 'exec'), g)
g['GROUP'] = 'Missing_Items'
slab, mat, offset, circle = [g[k] for k in ('slab', 'mat', 'offset', 'circle')]
OUT = '#1E2230'
LABELS = {}

def clean():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def start(iid, label):
    LABELS[iid] = label
    return g['item'](iid, label, 'crafting_ingredient')

def layer(c, e, name, pts, color, z=.08, h=.025):
    return slab(c.name+'_'+name, pts, z, h, mat(c.name+'_'+color.lstrip('#'), color), 0, e, c)

def silhouette(c, e, pts, color):
    layer(c,e,'outline',offset(pts,.038),OUT,0,.055)
    layer(c,e,'body',pts,color,.035,.065)

def ellipse(x,y,rx,ry,n=16):
    return circle(1,n,cx=x,cy=y,sx=rx,sy=ry)

def rect(x0,y0,x1,y1):
    return [(x0,y0),(x1,y0),(x1,y1),(x0,y1)]

def clone_collection(file, old, iid, label):
    with bpy.data.libraries.load(str(REPO/file), link=False) as (src,dst):
        dst.collections = [old]
    c=dst.collections[0]
    c.name=iid
    parent=bpy.data.collections.get('Missing_Items')
    if parent is None:
        parent=bpy.data.collections.new('Missing_Items');bpy.context.scene.collection.children.link(parent)
    parent.children.link(c)
    e=next(o for o in c.objects if o.type=='EMPTY' and o.parent is None)
    e.name=iid+'_root';e.location=(0,0,0)
    e['item_id']=iid;e['label']=label;e['purpose']='inventory_viewport_icon'
    LABELS[iid]=label
    for o in c.objects:
        o.hide_viewport=False;o.hide_render=False;o.hide_set(False)
        if o.type=='MESH':
            o.name=o.name.replace(old,iid)
            o.data=o.data.copy()
            for slot in o.material_slots:
                slot.material=slot.material.copy()
    return c,e

def normalize(c,e,flat=True):
    bpy.context.view_layer.update()
    meshes=[o for o in c.objects if o.type=='MESH']
    # Bake the displayed source pose; normalize only this new copy.
    transform=e.matrix_world.inverted()
    for o in meshes:
        m=transform @ o.matrix_world
        o.data.transform(m);o.parent=e;o.matrix_parent_inverse=Matrix.Identity(4)
        o.matrix_basis=Matrix.Identity(4)
    e.rotation_euler=(0,0,0);e.scale=(1,1,1)
    pts=[v.co for o in meshes for v in o.data.vertices]
    lo=[min(v[i] for v in pts) for i in range(3)]
    hi=[max(v[i] for v in pts) for i in range(3)]
    s=1.08/max(hi[0]-lo[0],hi[1]-lo[1])
    for o in meshes:
        for v in o.data.vertices:
            v.co.x=(v.co.x-(hi[0]+lo[0])/2)*s
            v.co.y=(v.co.y-(hi[1]+lo[1])/2)*s
            v.co.z=(v.co.z-lo[2])*(1 if flat else s)

def finish(c,e,index):
    if c.name!='water_bucket':
        g['strip_bottoms'](c);g['optimize_item'](c)
    normalize(c,e,flat=c.name!='water_bucket')
    e.location=((index%5-2)*1.7,-(index//5)*1.95,0)

def make_icons():
    clean()
    # Priority: clean cream sheet, folded corner and low-relief edge.
    c,e=start('paper','Papel')
    p=[(-.35,-.48),(.31,-.48),(.39,-.39),(.39,.28),(.19,.49),(-.35,.49)]
    silhouette(c,e,p,'#C8BBA1')
    layer(c,e,'sheet',[(-.31,-.41),(.31,-.41),(.34,-.34),(.34,.27),(.16,.44),(-.31,.44)],'#F5EACF',.10)
    layer(c,e,'fold_shadow',[(.12,.45),(.12,.23),(.35,.23)],'#A99577',.12)
    layer(c,e,'fold',[(.14,.43),(.15,.27),(.32,.27)],'#FFF8E4',.145,.018)
    finish(c,e,0)

    c,e=clone_collection('assets/resources/mob-drops/mob-drops.blend','thread','blue_thread','Linha azul')
    for o in c.objects:
        if o.type!='MESH':continue
        for slot in o.material_slots:
            hx=g['colhex'](slot.material)
            if hx==OUT:continue
            rgb=tuple(int(hx[k:k+2],16) for k in (1,3,5))
            color='#8FD4FA' if min(rgb)>225 else '#367FBE' if min(rgb)>180 else '#23598E'
            slot.material=mat('blue_thread_'+color[1:],color)
    finish(c,e,1)
    for idx,(iid,label,tones) in enumerate([
        ('black_wolf_fur','Pele de lobo negro',('#242735','#35394B','#636C86')),
        ('white_wolf_fur','Pele de lobo branco',('#A4B5C5','#E2EDF3','#FFFFFF'))],2):
        c,e=g['pelt_item'](iid,label,0,0,tones)
        LABELS[iid]=label;e['category']='crafting_ingredient';finish(c,e,idx)

    for idx,(iid,label,colors) in enumerate([
        ('blue_cube','Cubo azul',('#64C9F1','#3087C3','#20548E')),
        ('lava_cube','Cubo de lava',('#FFCA63','#F37A39','#AF352D'))],4):
        c,e=start(iid,label)
        p=[(0,.53),(.45,.27),(.45,-.26),(0,-.52),(-.45,-.26),(-.45,.27)]
        silhouette(c,e,p,colors[2])
        layer(c,e,'top',[(-.45,.27),(0,.53),(.45,.27),(0,0)],colors[0],.10)
        layer(c,e,'left',[(-.45,.27),(0,0),(0,-.52),(-.45,-.26)],colors[1],.10)
        layer(c,e,'glint',[(-.34,.27),(0,.46),(.11,.40),(-.23,.21)],'#DCF7FE' if idx==4 else '#FFF0B7',.128,.018)
        finish(c,e,idx)

    for idx,(iid,label,colors) in enumerate([
        ('dragon_orb','Orbe azul',('#245E9D','#3AADE0','#B2EDFF')),
        ('lava_orb','Orbe de lava',('#A63730','#F17737','#FFE29A'))],6):
        c,e=start(iid,label);silhouette(c,e,ellipse(0,0,.48,.48),colors[0])
        layer(c,e,'core',ellipse(-.055,.055,.39,.39),colors[1],.10)
        layer(c,e,'glint',ellipse(-.19,.22,.085,.12,8),colors[2],.13,.025)
        layer(c,e,'shine',ellipse(-.05,.33,.04,.035,8),colors[2],.13,.025)
        finish(c,e,idx)

    for idx,(iid,label,colors) in enumerate([
        ('blue_gem','Gema azul',('#2868A3','#64BFE6','#C5F2FA')),
        ('green_gem','Gema verde',('#287949','#69BE70','#C7F0A0')),
        ('orange_gem','Gema laranja',('#B75A2E','#F5A348','#FFE6A2'))],8):
        c,e=start(iid,label)
        p=[(-.28,.40),(.28,.40),(.48,.12),(0,-.48),(-.48,.12)]
        silhouette(c,e,p,colors[0])
        layer(c,e,'crown',[(-.28,.40),(.28,.40),(.19,.12),(-.19,.12)],colors[2],.10)
        layer(c,e,'facet',[(-.19,.12),(.19,.12),(0,-.48)],colors[1],.115)
        layer(c,e,'left',[(-.28,.40),(-.19,.12),(-.48,.12)],colors[1],.10)
        layer(c,e,'right',[(.28,.40),(.48,.12),(.19,.12)],colors[1],.10)
        finish(c,e,idx)

    c,e=start('firefly','Vaga-lume')
    for side in (-1,1):
        pts=ellipse(side*.23,.10,.23,.31,10)
        pts=g['xform'](pts,rot=-side*.35)
        layer(c,e,'wing_edge',offset(pts,.025),OUT,.025,.035)
        layer(c,e,'wing',pts,'#A7D6CD',.065,.025)
        layer(c,e,'wing_glint',ellipse(side*.25,.23,.065,.10,8),'#DCEFE0',.095,.025)
        line=g['line']((side*.04,.30),(side*.16,.49),.028)
        layer(c,e,'antenna',line,OUT,.04,.03)
    layer(c,e,'body_edge',ellipse(0,-.10,.145,.36,12),OUT,.09,.025)
    layer(c,e,'glow',ellipse(0,-.21,.115,.22,12),'#D9DC60',.115,.035)
    layer(c,e,'glow_glint',ellipse(-.025,-.16,.045,.095,8),'#FFF6AE',.15,.017)
    layer(c,e,'head',ellipse(0,.20,.11,.12,10),'#454C44',.12,.025)
    layer(c,e,'thorax',rect(-.105,-.03,.105,.11),'#454C44',.13,.025)
    finish(c,e,11)

    c,e=start('pilot_glasses','Óculos de piloto')
    silhouette(c,e,[(-.61,-.12),(-.53,.15),(-.30,.24),(-.09,.13),(.09,.13),(.30,.24),(.53,.15),(.61,-.12),(.39,-.26),(.16,-.22),(0,-.06),(-.16,-.22),(-.39,-.26)],'#77503A')
    layer(c,e,'bridge',rect(-.13,-.015,.13,.08),'#D6BB80',.105)
    for x in (-.30,.30):
        lens=ellipse(x,-.015,.205,.177,10)
        layer(c,e,'rim',offset(lens,.026),'#D6BB80',.105)
        layer(c,e,'lens',lens,'#397C9C',.132,.02)
        layer(c,e,'glint',[(x-.13,.075),(x-.06,.125),(x+.07,-.10),(x+.005,-.14)],'#A5DCE4',.155,.012)
    finish(c,e,12)

    c,e=start('pitchfork_part','Peça do forcado')
    p=[(-.10,-.52),(.10,-.52),(.10,-.16),(.36,-.02),(.42,.14),(.39,.51),(.28,.51),(.27,.15),(.085,.05),(.07,.53),(-.07,.53),(-.085,.05),(-.27,.15),(-.28,.51),(-.39,.51),(-.42,.14),(-.36,-.02),(-.10,-.16)]
    silhouette(c,e,p,'#AD7833')
    layer(c,e,'metal',g['xform'](p,s=.88,dy=.025),'#E6BB5A',.105)
    for x in (-.33,0,.33):
        layer(c,e,'edge',rect(x-.022,.20,x+.016,.45),'#FFF0A4',.135,.018)
    finish(c,e,13)

    # Existing wooden bucket already includes a water mesh; preserve its design.
    c,e=clone_collection('assets/tools/catalog/ferramentas-23-editaveis.blend','bucket','water_bucket','Balde com água')
    e.rotation_euler=(0,0,0);e.scale=(1,1,1)
    bpy.context.view_layer.update()
    # The tool is authored Y-up; convert mesh data to Blender Z-up.
    inv=e.matrix_world.inverted()
    rot=Matrix.Rotation(math.pi/2,4,'X')
    for o in list(c.objects):
        if o.type!='MESH':continue
        o.data.transform(rot @ inv @ o.matrix_world)
        o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=Matrix.Identity(4)
    finish(c,e,14)
    assert len(bpy.data.collections['Missing_Items'].children)==15
    presentation('Missing_Items', 'ITENS DE RECEITA', '15 modelos • Ember Wilds', BASE/'missing-items-preview.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'missing-items.blend'))
    bpy.context.scene.render.filepath=str(BASE/'missing-items-preview.png')
    bpy.ops.render.render(write_still=True)

def text_object(text,loc,size,material,collection):
    data=bpy.data.curves.new('Label','FONT');data.body=text;data.align_x='CENTER';data.size=size
    obj=bpy.data.objects.new('Label',data);collection.objects.link(obj);obj.location=loc
    data.materials.append(material)
    return obj

def setup_render(camloc,target,scale,res):
    scene=bpy.context.scene
    scene.render.engine='CYCLES';scene.cycles.samples=32
    scene.cycles.use_denoising=True
    scene.render.resolution_x=res[0];scene.render.resolution_y=res[1];scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.world=bpy.data.worlds.new('Studio_World');scene.world.use_nodes=True
    bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs['Color'].default_value=(.30,.36,.46,1);bg.inputs['Strength'].default_value=.7
    scene.view_settings.view_transform='Standard'
    cd=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',cd);scene.collection.objects.link(cam)
    cam.location=camloc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cd.type='ORTHO';cd.ortho_scale=scale;scene.camera=cam
    ld=bpy.data.lights.new('Softbox','AREA');lo=bpy.data.objects.new('Softbox',ld);scene.collection.objects.link(lo)
    lo.location=(-3,2,9);ld.energy=1100;ld.shape='DISK';ld.size=7
    lo.rotation_euler=(Vector(target)-lo.location).to_track_quat('-Z','Y').to_euler()
    for screen in bpy.data.screens:
        for a in screen.areas:
            if a.type=='VIEW_3D':
                a.spaces.active.region_3d.view_perspective='CAMERA'
                a.spaces.active.shading.type='MATERIAL'

def presentation(group,title,subtitle,path):
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    light=mat('Label_light','#E8E9E1');muted=mat('Label_muted','#99AAB4')
    for c in bpy.data.collections[group].children:
        e=bpy.data.objects[c.name+'_root'];x,y,_=e.location
        text_object(LABELS[c.name],(x,y-.80,.02),.115,light,pc)
        text_object(c.name,(x,y-.98,.02),.074,muted,pc)
    text_object(title,(0,1.45,.01),.30,light,pc)
    text_object(subtitle,(0,1.13,.01),.12,muted,pc)
    layer(pc,None,'backdrop',rect(-5.5,-6,5.5,2.5),'#303D48',-.11,.02)
    setup_render((0,-7.2,19),(0,-1.9,0),9.2,(1700,1460))

def poly_ellipsoid(name,loc,scale,materials,c,n=10,rings=5):
    # Low-poly closed surface with deliberately broad, flat facets.
    vs=[(0,0,1)]
    for j in range(1,rings):
        p=math.pi*j/rings
        for i in range(n):
            a=2*math.pi*i/n+(j%2)*.14
            vs.append((math.sin(p)*math.cos(a),math.sin(p)*math.sin(a),math.cos(p)))
    vs.append((0,0,-1));bot=len(vs)-1
    fs=[]
    for i in range(n):fs.append((0,1+i,1+(i+1)%n))
    for j in range(rings-2):
        for i in range(n):
            a=1+j*n+i;b=1+j*n+(i+1)%n
            fs.append((a,a+n,b+n,b))
    for i in range(n):fs.append((bot,1+(rings-2)*n+(i+1)%n,1+(rings-2)*n+i))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.update()
    for m in materials:mesh.materials.append(m)
    o=bpy.data.objects.new(name,mesh);c.objects.link(o)
    for v in mesh.vertices:v.co=Vector((v.co.x*scale[0]+loc[0],v.co.y*scale[1]+loc[1],v.co.z*scale[2]+loc[2]))
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    for p in mesh.polygons:
        nrm=p.normal
        p.material_index=2 if nrm.z>.35 and nrm.x<.25 else 0 if nrm.z<-.25 or nrm.x>.4 else 1
    return o

def make_bush():
    clean()
    # Read exact berry materials from the icon used by BonecoModel.holdFood.
    with bpy.data.libraries.load(str(REPO/'assets/resources/food/food.blend'),link=False) as (src,dst):
        dst.collections=['berry']
    ref=dst.collections[0]
    colors={o.name:g['colhex'](o.data.materials[0]) for o in ref.objects if o.type=='MESH'}
    berry_base=colors['berry_part'];berry_hi=colors['berry_shine'];leaf_base=colors['berry_body']
    # Two fruit colors only: the same base and highlight as the held item.
    bmats=[mat('Berry_base',berry_base),mat('Berry_base',berry_base),mat('Berry_highlight',berry_hi)]
    lmats=[mat('Leaf_shadow','#175A38'),mat('Leaf_base',leaf_base),mat('Leaf_highlight','#399969')]
    parent=bpy.data.collections.new('BushParts');bpy.context.scene.collection.children.link(parent)
    def part(name):
        c=bpy.data.collections.new(name);parent.children.link(c)
        e=bpy.data.objects.new(name+'_root',None);c.objects.link(e);e['item_id']=name;e['label']=name
        return c,e
    c,e=part('Foliage')
    lobes=[(-1.55,0,1.35,(1.35,1.18,1.20)),(1.4,.13,1.38,(1.45,1.22,1.25)),(0,.85,1.65,(1.6,1.25,1.4)),(0,-.72,1.30,(1.7,1.22,1.20)),(-.55,-.02,2.2,(1.48,1.32,1.35)),(.9,-.25,2.02,(1.32,1.22,1.25))]
    for i,(x,y,z,s) in enumerate(lobes):poly_ellipsoid('Foliage_%02d'%i,(x,y,z),s,lmats,c)
    # Join leaves as one export mesh, retaining materials.
    bpy.ops.object.select_all(action='DESELECT')
    for o in c.objects:
        if o.type=='MESH':o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.join();o=bpy.context.object;o.name='Foliage';o.parent=e
    foliage=o
    bpy.context.view_layer.update()
    berries=[]
    for x,y in [(-1.85,-.35),(-.65,-1.35),(1.20,-1.15),(-.55,.25),(1.55,.50)]:
        hit,point,normal,face=foliage.ray_cast(Vector((x,y,10)),Vector((0,0,-1)))
        assert hit, (x,y)
        berries.append((x,y,point.z+.20))
    for i,p in enumerate(berries,1):
        c,e=part('Berry_%02d'%i)
        o=poly_ellipsoid('Berry_%02d'%i,p,(.39,.39,.40),bmats,c,n=10,rings=5)
        o.parent=e;o['roblox_name']='Berry';o['harvest_index']=i
    # Shared pivot at the centre of the ground plane, all parts retain offsets.
    meshes=[o for c in parent.children for o in c.objects if o.type=='MESH']
    min_z=min(v.co.z for o in meshes for v in o.data.vertices)
    for o in meshes:
        for v in o.data.vertices:v.co.z-=min_z
    # Remove reference objects only from this new background document.
    for o in list(ref.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.collections.remove(ref)
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    layer(pc,None,'ground',rect(-200,-200,200,200),'#303D48',-.09,.02)
    setup_render((7,-11,13),(0,0,1.5),8.3,(1350,1350))
    bpy.context.scene.render.filepath=str(BASE/'berry-bush-preview.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'berry-bush.blend'))
    bpy.ops.render.render(write_still=True)
    metadata={'model':'berry_bush_1','fruit_count':5,'fruit_base':berry_base,'fruit_highlight':berry_hi,'leaf_base':leaf_base,'color_source':'assets/resources/food/food.blend > berry_part / berry_shine','held_item_source':'src/client/Boneco/BonecoModel.luau: holdFood uses Assets.Icons/<id>','parts':['Foliage']+['Berry_%02d'%i for i in range(1,6)],'roblox_note':'Rename each Berry_XX MeshPart to Berry; keep all five separate. Visual count does not change resource yield.'}
    (BASE/'berry-bush-manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf8')

def make_empty_bucket():
    clean()
    c,e=clone_collection('assets/resources/missing-items/missing-items.blend',
                         'water_bucket','bucket','Balde vazio')
    water=[o for o in c.objects if o.name=='bucket_water']
    assert len(water)==1, [o.name for o in c.objects]
    bpy.data.objects.remove(water[0],do_unlink=True)
    bpy.data.collections['Missing_Items'].name='Empty_Bucket'
    e.location=(0,0,0)
    assert all('water' not in o.name.lower() for o in c.objects)
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    layer(pc,None,'ground',rect(-20,-20,20,20),'#303D48',-.09,.02)
    setup_render((2,-3,3.6),(0,0,.45),2.1,(1000,1000))
    bpy.context.scene.render.filepath=str(BASE/'empty-bucket-preview.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'empty-bucket.blend'))
    bpy.ops.render.render(write_still=True)
    print('EMPTY_BUCKET_COMPLETE: existing bucket geometry, water mesh removed')

if __name__=='__main__':
    BASE.mkdir(parents=True,exist_ok=True)
    if '--empty-only' not in sys.argv:
        make_icons()
        make_bush()
    make_empty_bucket()
    print('BUILD_COMPLETE: 16 inventory assets + bush with 5 purple fruits')
