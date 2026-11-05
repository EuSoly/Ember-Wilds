import bpy,bmesh,math,os,json,hashlib,re
from mathutils import Vector,Matrix
BASE=os.path.dirname(os.path.abspath(__file__))
NAME='Icon_Inspired_Deposits_06'
assert NAME not in bpy.data.scenes
os.makedirs(BASE,exist_ok=True)
prior=list(bpy.data.objects)
def fingerprint():
    h=hashlib.sha256()
    for o in prior:
        h.update(repr((o.name,tuple(map(tuple,o.matrix_world)),[c.name for c in o.users_collection])).encode())
        if o.type=='MESH':h.update(repr(([tuple(v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons],[m.name if m else None for m in o.data.materials])).encode())
    return h.hexdigest()
before=fingerprint();source_file=bpy.data.filepath
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'before-icon-deposits.blend'),copy=True)
sources={'stone':'pedra','gold':'ouro','diamond':'diamante','amethyst':'ametista','reidite':'reidite'}
names={'stone':'PEDRA','gold':'OURO','diamond':'DIAMANTE','amethyst':'AMETISTA','reidite':'REIDITE','emerald':'ESMERALDA'}

def get_segments(obs,center):
    seg=[];pts=[]
    for o in obs:
        vv=[o.matrix_world@v.co-center for v in o.data.vertices]
        pts.extend([(v.x,v.y) for v in vv])
        for e in o.data.edges:
            a,b=[vv[i] for i in e.vertices]
            if (Vector((a.x,a.y))-Vector((b.x,b.y))).length>1e-7:seg.append(((a.x,a.y),(b.x,b.y)))
    return seg,pts

def ray_radius(a,segments):
    dx,dy=math.cos(a),math.sin(a);hits=[]
    for (ax,ay),(bx,by) in segments:
        ex,ey=bx-ax,by-ay;den=dx*ey-dy*ex
        if abs(den)<1e-10:continue
        t=(ax*ey-ay*ex)/den;u=(ax*dy-ay*dx)/den
        if t>0 and -.00001<=u<=1.00001:hits.append(t)
    assert hits,('empty silhouette ray',a)
    return max(hits)

def outline(segments,points):
    angles=sorted(set(round(math.atan2(y,x),6) for x,y in points))
    p=[(ray_radius(a,segments)*math.cos(a),ray_radius(a,segments)*math.sin(a)) for a in angles]
    # Simplify tiny bevel samples while retaining deep notches and broad lobes.
    changed=True
    while changed and len(p)>12:
        changed=False
        for i in range(len(p)):
            a,b,c=Vector(p[i-1]),Vector(p[i]),Vector(p[(i+1)%len(p)])
            ac=c-a
            if ac.length<1e-7:continue
            distance=abs(ac.x*(b.y-a.y)-ac.y*(b.x-a.x))/ac.length
            if distance<.0018 and (b-a).dot(c-b)>=0:
                p.pop(i);changed=True;break
    return p

refs={}
for kind,source in sources.items():
    obs=list(bpy.data.collections[source].objects)
    coords=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    seg,pts=get_segments(obs,center)
    inner=[o for o in obs if o.name.startswith('topo')]
    innerseg,_=get_segments(inner,center)
    base=next(o for o in obs if o.name.startswith('base'))
    mat=base.data.materials[0]
    color=tuple(next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value)
    mat2=inner[0].data.materials[0]
    top=tuple(next(n for n in mat2.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value)
    refs[kind]={'objects':obs,'center':center,'outline':outline(seg,pts),'segments':seg,'inner_segments':innerseg,'color':color,'top':top,'width':max(hi.x-lo.x,hi.y-lo.y)}
# No emerald icon exists in the user's viewport collection: a separate, clearly labelled proposal.
points=[];segments=[]
for x,y,r in [(-.20,.10,.30),(.19,.16,.29),(.01,-.22,.30)]:
    poly=[(x+r*math.cos(i*math.pi/3+.15),y+r*math.sin(i*math.pi/3+.15)) for i in range(6)]
    points.extend(poly);segments.extend([(poly[i],poly[(i+1)%6]) for i in range(6)])
for ia,(aa,ab) in enumerate(segments):
    ax,ay=aa;ex,ey=ab[0]-ax,ab[1]-ay
    for ba,bb in segments[ia+1:]:
        bx,by=ba;fx,fy=bb[0]-bx,bb[1]-by;den=ex*fy-ey*fx
        if abs(den)<1e-10:continue
        u=((bx-ax)*fy-(by-ay)*fx)/den;v=((bx-ax)*ey-(by-ay)*ex)/den
        if 0<=u<=1 and 0<=v<=1:points.append((ax+u*ex,ay+u*ey))
refs['emerald']={'objects':[],'center':Vector((0,0,0)),'outline':outline(segments,points),'segments':segments,'inner_segments':[], 'color':(.025,.30,.075,1),'top':(.15,.65,.24,1),'width':1.0}

scene=bpy.data.scenes.new(NAME);bpy.context.window.scene=scene
catalog=bpy.data.collections.new('Icon_Inspired_Deposits');scene.collection.children.link(catalog)
references=bpy.data.collections.new('Inventory_References');scene.collection.children.link(references);references.hide_select=True
stage=bpy.data.collections.new('Icon_Deposits_Presentation');scene.collection.children.link(stage);stage.hide_select=True
def enum(o,p,v):setattr(o,p,next(e.identifier for e in o.bl_rna.properties[p].enum_items if e.identifier==v))
def mat(name,color):
    m=bpy.data.materials.new('IconOre_'+name);m.use_nodes=True;m.diffuse_color=color
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Base Color'].default_value=color;n.inputs['Roughness'].default_value=.78
    return m
def mix(a,b,t):return tuple(a[i]*(1-t)+b[i]*t for i in range(3))+(1,)
records=[]
for idx,(kind,ref) in enumerate(refs.items()):
    cx=(idx%3-1)*11.5;cy=5.5 if idx<3 else -5.5
    ID=kind+'_deposit_icon';col=bpy.data.collections.new(ID);catalog.children.link(col)
    root=bpy.data.objects.new(ID+'_root',None);col.objects.link(root);root.location=(cx+1.15,cy,0);root.empty_display_size=.10
    root['item_id']=ID;root['resource_type']=kind;root['purpose']='harvestable_world_deposit';root['reference_collection']=sources.get(kind,'new_emerald_proposal');root['pivot']='ground_center'
    color,top=ref['color'],ref['top']
    if kind in ['amethyst','reidite']:
        upper=mix(color,(1,1,1,1),.13);dark=top
    else:upper=top;dark=mix(color,(0,0,0,1),.22)
    pal=[mat(kind+'_body',color),mat(kind+'_crown',upper),mat(kind+'_shadow',dark),mat(kind+'_light',mix(upper,(1,1,1,1),.12)),mat(kind+'_slope',mix(color,upper,.36))]
    poly=ref['outline'];maxwidth=max(max(x for x,y in poly)-min(x for x,y in poly),max(y for x,y in poly)-min(y for x,y in poly));scale=4.0/maxwidth
    n=len(poly);maxr=max(math.hypot(x,y) for x,y in poly);height={'stone':1.45,'gold':1.55,'diamond':1.87,'amethyst':2.06,'reidite':2.20,'emerald':1.98}[kind]
    vertices=[];rays=[]
    for x,y in poly:
        a=math.atan2(y,x);r=math.hypot(x,y);rays.append((a,r))
    # Rock flanks lean inward toward the ground; maximum footprint matches the icon.
    for level in range(4):
        for i,(x,y) in enumerate(poly):
            a,r=rays[i];rn=r/maxr
            if level==0:q=.84;z=0
            elif level==1:q=1.0;z=.21*height
            elif level==2:q=.98;z=height*(.68+.09*math.sin(a+.7))
            else:
                q=.77 if kind in ['stone','gold'] else .83
                if kind in ['stone','gold','diamond']:
                    q=min(.9,ray_radius(a,ref['inner_segments'])/r)
                z=height*(.78+.22*rn)
                if kind in ['stone','gold','diamond']:z=height*.98+.04*height*(x*scale*q)/4
                if kind in ['amethyst','reidite']:z+=height*.07*math.sin(3*a+.7)
            vertices.append((x*scale*q,y*scale*q,z))
    center_z=height*(.98 if kind in ['stone','gold','diamond'] else .77)
    vertices.append((0,0,center_z));top_center=len(vertices)-1
    faces=[tuple(reversed(range(n)))];ids=[2]
    for level in range(3):
        for i in range(n):
            j=(i+1)%n;faces.append((level*n+i,level*n+j,(level+1)*n+j,(level+1)*n+i))
            ids.append(2 if level==0 else (0 if level==1 else 4))
    for i in range(n):
        j=(i+1)%n;faces.append((3*n+i,3*n+j,top_center))
        a,r=rays[i]
        if kind in ['amethyst','reidite']:
            # Wide dark mineral facets reproduce the characteristic inset wedges.
            ids.append(2 if math.sin(3*a+.5)>.35 else 1)
        else:ids.append(1)
    me=bpy.data.meshes.new(ID+'_body');me.from_pydata(vertices,[],faces);me.update()
    for m in pal:me.materials.append(m)
    for p,mi in zip(me.polygons,ids):p.material_index=mi
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    body=bpy.data.objects.new(ID+'_body',me);col.objects.link(body);body.parent=root;body['item_id']=ID;body['resource_type']=kind
    assert not me.validate(verbose=False),ID
    bm=bmesh.new();bm.from_mesh(me);assert all(e.is_manifold for e in bm.edges),ID;assert bm.calc_volume()>0,ID;assert all(f.calc_area()>1e-9 for f in bm.faces),ID;bm.free()
    # Compare 360 silhouette radii to the exact projected source mesh.
    polyseg=[(poly[i],poly[(i+1)%n]) for i in range(n)]
    errs=[abs(ray_radius(i*math.pi/180,ref['segments'])-ray_radius(i*math.pi/180,polyseg))/maxwidth for i in range(360)]
    assert max(errs)<.012,(kind,max(errs))
    me.calc_loop_triangles()
    records.append({'item_id':ID,'resource':kind,'source_collection':sources.get(kind),'new_reference_proposal':kind=='emerald','triangles':len(me.loop_triangles),'silhouette_max_error_fraction':max(errs),'silhouette_vertices':n,'height':max(v.co.z for v in me.vertices),'width':4.0,'closed_mesh':True})
    # Reference copies, unmodified shape and material; never exported as deposits.
    if ref['objects']:
        for src in ref['objects']:
            data=src.data.copy();data.transform(Matrix.Scale(1.35/ref['width'],4)@Matrix.Translation(-ref['center'])@src.matrix_world)
            ob=bpy.data.objects.new('Reference_'+src.name,data);references.objects.link(ob);ob.location=(cx-3.35,cy,.03)
    else:
        data=me.copy();data.transform(Matrix.Diagonal((.32,.32,.32,1)))
        ob=bpy.data.objects.new('Reference_emerald_proposal',data);references.objects.link(ob);ob.location=(cx-3.35,cy,.03)
assert fingerprint()==before,'Original objects changed'

def text(body,x,y,size,m):
    d=bpy.data.curves.new('Icon_Deposit_Label','FONT');d.body=body;d.size=size;ob=bpy.data.objects.new('label_'+body,d);stage.objects.link(ob);ob.location=(x,y,.015);d.materials.append(m)
bg=mat('presentation_background',(.022,.043,.051,1));white=mat('presentation_white',(.80,.88,.86,1));muted=mat('presentation_muted',(.35,.49,.51,1))
me=bpy.data.meshes.new('Icon_Deposit_Backdrop');me.from_pydata([(-100,-100,-.05),(100,-100,-.05),(100,100,-.05),(-100,100,-.05)],[],[(0,1,2,3)]);ob=bpy.data.objects.new(me.name,me);stage.objects.link(ob);me.materials.append(bg)
text('DO INVENTARIO PARA O MAPA',-16.9,13.8,.61,white)
text('6 DEPOSITOS  /  CONTORNOS DOS SEUS VIEWPORTS  /  MALHAS EDITAVEIS',-16.9,12.8,.21,muted)
for idx,kind in enumerate(refs):
    cx=(idx%3-1)*11.5;cy=5.5 if idx<3 else -5.5
    text(names[kind],cx-4.8,cy+4.7,.38,white)
    text('PROPOSTA DE ICONE' if kind=='emerald' else 'SEU ICONE',cx-4.3,cy-1.55,.16,muted)
    text('DEPOSITO',cx-.9,cy-2.9,.20,white)
    text(kind+'_deposit_icon',cx-.9,cy-3.3,.15,muted)
cd=bpy.data.cameras.new('Icon_Deposits_Camera');cam=bpy.data.objects.new(cd.name,cd);stage.objects.link(cam)
target=Vector((0,2.2,.3));cam.location=(0,-30,52);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();enum(cd,'type','ORTHO');cd.ortho_scale=36;scene.camera=cam
for name,loc,power,size in [('Key',(-14,-10,26),7000,16),('Fill',(15,12,24),5000,18)]:
    d=bpy.data.lights.new('Icon_Deposits_'+name,'AREA');o=bpy.data.objects.new(d.name,d);stage.objects.link(o);o.location=loc;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=size
w=bpy.data.worlds.new('Icon_Deposits_World');w.use_nodes=True;node=next(n for n in w.node_tree.nodes if n.type=='BACKGROUND');node.inputs['Color'].default_value=(.4,.4,.4,1);node.inputs['Strength'].default_value=.65;scene.world=w
try:scene.render.engine='CYCLES'
except TypeError:pass
if scene.render.engine=='CYCLES':scene.cycles.samples=32
try:scene.view_settings.view_transform='__INSPECT__'
except TypeError as e:
    value=next((v for v in re.findall(r"'([^']+)'",str(e)) if v.lower()=='standard'),None)
    if value:scene.view_settings.view_transform=value
scene.render.resolution_x=2400;scene.render.resolution_y=1800;scene.render.resolution_percentage=100;enum(scene.render.image_settings,'file_format','PNG');scene.render.filepath=os.path.join(BASE,'comparacao-preview.png')
for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type=='VIEW_3D':
            sp=a.spaces.active;sp.overlay.show_overlays=True;sp.overlay.show_extras=False;sp.overlay.show_floor=False;sp.overlay.show_axis_x=False;sp.overlay.show_axis_y=False
            enum(sp.shading,'type','MATERIAL');enum(sp.region_3d,'view_perspective','CAMERA')
json.dump({'source_file':source_file,'originals_preserved':True,'models':records},open(os.path.join(BASE,'manifest.json'),'w',encoding='utf8'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'minerios-icones-trabalho.blend'))
print(json.dumps(records))
