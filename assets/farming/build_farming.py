"""Create the farming art pack in background Blender; never edit original assets.
49 models: 36 growth stages, 9 loose seed icons, 1 planter, 3 water/ice icons.
"""
import bpy,math,json,sys,importlib.util
from pathlib import Path
from mathutils import Vector,Matrix
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[1]
sys.path.insert(0,str(BASE))
from geometry import *
spec=importlib.util.spec_from_file_location('approved_helpers',REPO/'assets/resources/missing-items/build_assets.py')
helpers=importlib.util.module_from_spec(spec);spec.loader.exec_module(helpers)
CROPS=[('berry','Frutinha'),('wheat','Trigo'),('pumpkin','Abóbora'),('thorn','Espinho'),('carrot','Cenoura'),('tomato','Tomate'),('watermelon','Melancia'),('aloe_vera','Babosa'),('garlic','Alho')]
RECORDS=[]

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0

def colors():
    global LEAF,WOOD,SOIL,METAL,CREAM,BERRY,UNRIPE,TOMATO,PUMPKIN,MELON,WHEAT,CARROT,GARLIC,ALOE,OUT
    LEAF=palette('leaf',['#205838','#34844D','#68A65E'])
    WOOD=palette('wood',['#79502F','#AA7748','#C99B66'])
    SOIL=palette('soil',['#352721','#49372A','#604631'])
    METAL=palette('iron',['#202D34','#36434A','#71848B'])
    CREAM=palette('cream',['#A68D64','#D5BE8D','#F0DFB4'])
    BERRY=palette('berry',['#4A3A8C','#4A3A8C','#8565C4'])
    UNRIPE=palette('unripe',['#376A32','#659B4B','#9FBD66'])
    TOMATO=palette('tomato',['#A32B1E','#D2361A','#F07A5A'])
    PUMPKIN=palette('pumpkin',['#A9552A','#C96D38','#E79B58'])
    MELON=palette('melon',['#1E5A2A','#4C9E58','#8FD07E'])
    WHEAT=palette('wheat',['#8A7444','#B39A63','#D6C589'])
    CARROT=palette('carrot',['#A85700','#D27000','#EEA044'])
    GARLIC=palette('garlic',['#A8A8A0','#EAE9E4','#FFFCED'])
    ALOE=palette('aloe',['#6E9246','#7FA552','#A9C77E'])
    OUT=palette('outline',['#1E2230']*3)

def item(group,iid,label,kind,crop=None,stage=None):
    parent=bpy.data.collections.get(group)
    if parent is None:
        parent=bpy.data.collections.new(group);bpy.context.scene.collection.children.link(parent)
    c=bpy.data.collections.new(iid);parent.children.link(c)
    r=bpy.data.objects.new(iid+'_root',None);c.objects.link(r)
    r['item_id']=iid;r['label']=label;r['kind']=kind;r['pivot']='soil_surface' if kind=='plant' else 'ground_center'
    if crop:r['crop_id']=crop
    if stage:r['growth_stage']=stage
    RECORDS.append({'id':iid,'label':label,'kind':kind,'crop':crop,'stage':stage})
    return c,r

def sprout(c,r,crop,stage):
    h=.26
    if crop in ('wheat','aloe_vera','garlic'):
        for i in range(3):
            a=i*2.1
            leaf(c,r,'sprout',(.0,0,0),(.17*math.cos(a),.17*math.sin(a),.30+i*.06),.09,LEAF)
    else:
        stem(c,r,'sprout_stem',(0,0,0),(0,0,h),.035,LEAF)
        leaf(c,r,'cotyledon',(0,0,h),(-.32,.06,.38),.18,LEAF)
        leaf(c,r,'cotyledon',(0,0,h),(.32,-.04,.40),.18,LEAF)

def vine_leaf(c,r,x,y,z,a,size=.75,group='Foliage'):
    leaf(c,r,'leaf',(x,y,z),(x+size*math.cos(a),y+size*math.sin(a),z+.18),size*.65,LEAF,group)

def berry(c,r,stage):
    if stage==4:
        # Reuse the approved 5-berry bush geometry and its exact fruit materials.
        with bpy.data.libraries.load(str(REPO/'assets/resources/missing-items/berry-bush.blend'),link=False) as (src,dst):
            dst.collections=['BushParts']
        old=dst.collections[0]
        for sub in list(old.children):
            for source in list(sub.objects):
                if source.type!='MESH':continue
                o=source.copy();o.data=source.data.copy();c.objects.link(o);o.parent=r
                o.matrix_basis.identity();o.matrix_parent_inverse.identity()
                for v in o.data.vertices:v.co*=.48
                o['part_group']='Harvest_'+sub.name.split('_')[-1] if sub.name.startswith('Berry_') else 'Foliage'
        for sub in list(old.children):
            for o in list(sub.objects):bpy.data.objects.remove(o,do_unlink=True)
            bpy.data.collections.remove(sub)
        bpy.data.collections.remove(old)
        return
    factor=.42 if stage==2 else .70
    for i,(x,y,z,sz) in enumerate([(-.65,0,.55,.65),(.60,.04,.60,.68),(0,-.25,.83,.76)]):
        ellipsoid(c,r,'berry_leaves',(x*factor,y*factor,z*factor),(sz*factor,sz*.85*factor,sz*.9*factor),LEAF)
    if stage==3:
        for i,(x,y,z) in enumerate([(-.4,-.3,.85),(.4,-.2,.95),(0,.0,1.15)]):
            ellipsoid(c,r,'green_berry',(x,y,z),(.13,.13,.13),UNRIPE)

def wheat(c,r,stage):
    scale={2:.50,3:.80,4:1}[stage]
    pal=WHEAT if stage==4 else LEAF
    for i,(x,y,h) in enumerate([(-.43,0,1.75),(.05,.20,2.05),(.43,-.12,1.85)]):
        x*=scale;y*=scale;h*=scale
        stem(c,r,'stalk',(x,y,0),(x+.06,y,h),.026,pal)
        for sign,z in [(-1,h*.32),(1,h*.50)]:
            leaf(c,r,'wheat_leaf',(x,y,z),(x+sign*.55*scale,y+.08,z+.30*scale),.12*scale,pal)
        if stage>=3:
            group='Harvest_%02d'%(i+1) if stage==4 else 'Foliage'
            for k in range(4):
                for side in (-1,1):
                    z=h-.10+k*.18*scale
                    cen=Vector((x+side*.095*scale,y,z))
                    grain=ellipsoid(c,r,'grain',tuple(cen),(.065*scale,.065*scale,.125*scale),pal,group,n=6,rings=3)
                    grain.data.transform(Matrix.Translation(cen) @ Matrix.Rotation(side*.8,4,'Y') @ Matrix.Translation(-cen))
            stem(c,r,'ear_core',(x,y,h-.15*scale),(x,y,h+.53*scale),.018,pal,group)
            stem(c,r,'awn',(x,y,h+.53*scale),(x+.03,y,h+.70*scale),.012,pal,group)

def pumpkin_or_melon(c,r,crop,stage):
    s={2:.44,3:.75,4:1}[stage]
    for i,a in enumerate([.3,2.35,4.4]):
        x,y=1.05*s*math.cos(a),1.05*s*math.sin(a)
        stem(c,r,'vine',(0,0,.035),(x,y,.08),.045*s,LEAF)
        vine_leaf(c,r,x*.58,y*.58,.14*s,a+.6,.72*s)
        vine_leaf(c,r,x,y,.1,a+1.4,.60*s)
    if stage>=3:
        fruitpal=(PUMPKIN if crop=='pumpkin' else MELON) if stage==4 else UNRIPE
        size=.60 if stage==4 else .30;group='Harvest_01' if stage==4 else 'Foliage'
        o=ellipsoid(c,r,'fruit',(.08,-.40,size*.81),(size*(1 if crop=='pumpkin' else 1.3),size,size*.81),fruitpal,group,n=20,rings=6,lobes=.06 if crop=='pumpkin' else 0)
        if crop=='watermelon':
            for p in o.data.polygons:
                angle=math.atan2(p.center.y+.40,p.center.x-.08)
                p.material_index=0 if int((angle+math.pi)/(math.pi/5))%2==0 else 1
        stem(c,r,'fruit_stem',(.08,-.4,size*1.6),(.17,-.36,size*1.6+.16),.055,LEAF,group)

def tomato(c,r,stage):
    s={2:.42,3:.72,4:1}[stage];h=1.75*s
    stem(c,r,'stem',(0,0,0),(.04,0,h),.055*s,LEAF)
    for i in range(5):
        a=i*2.4;z=h*(.30+i*.12)
        tip=(math.cos(a)*.62*s,math.sin(a)*.62*s,z+.08)
        stem(c,r,'branch',(0,0,z),tip,.025*s,LEAF)
        vine_leaf(c,r,*tip,a+.4,.52*s)
    if stage>=3:
        pal=TOMATO if stage==4 else UNRIPE
        for i,(x,y,z) in enumerate([(-.55,-.34,.86),(.55,-.28,1.05),(-.05,.14,1.66)],1):
            x*=s;y*=s;z*=s;rad=.28*s;group='Harvest_%02d'%i if stage==4 else 'Foliage'
            stem(c,r,'fruit_branch',(0,0,z+.15),(x,y,z+.10),.025,LEAF)
            ellipsoid(c,r,'tomato',(x,y,z),(rad,rad,rad*.85),pal,group)
            for j in range(5):
                a=j*2*math.pi/5
                leaf(c,r,'calyx',(x,y,z+rad*.85),(x+.16*s*math.cos(a),y+.16*s*math.sin(a),z+rad*.67),.065*s,LEAF,group)

def roots(c,r,crop,stage):
    s={2:.45,3:.72,4:1}[stage]
    for i,(x,y) in enumerate([(-.5,-.20),(.5,-.20),(0,.45)],1):
        x*=s;y*=s;group='Harvest_%02d'%i if stage==4 else 'Foliage'
        z=.26*s if stage>=3 else .03
        if stage>=3:
            if crop=='carrot':
                stem(c,r,'carrot_root',(x,y,.005),(x,y,.43*s),.045*s,CARROT,group,tip=.20*s,n=8)
                ellipsoid(c,r,'carrot_shoulder',(x,y,.38*s),(.20*s,.20*s,.16*s),CARROT,group,n=8,rings=3)
                z=.52*s
            else:
                ellipsoid(c,r,'garlic_bulb',(x,y,.20*s),(.27*s,.25*s,.23*s),GARLIC,group,n=16,rings=5,lobes=.08)
                z=.40*s
        for j in range(5):
            a=j*2.4+i;end=(x+.40*s*math.cos(a),y+.40*s*math.sin(a),z+(.62+(j%2)*.22)*s)
            leaf(c,r,'root_leaves',(x,y,z),end,(.17 if crop=='carrot' else .12)*s,LEAF,group)
            if crop=='carrot':
                mid=Vector((x,y,z)).lerp(Vector(end),.55)
                for k in (-1,1):
                    leaf(c,r,'carrot_leaflet',tuple(mid),(mid.x+k*.20*s,mid.y+.09*s,mid.z+.16*s),.14*s,LEAF,group)

def aloe(c,r,stage):
    s={2:.40,3:.70,4:1}[stage]
    group='Harvest_01' if stage==4 else 'Foliage'
    for ring,count,rad,h in [(0,7,1.00,.65),(1,5,.60,1.25),(2,3,.20,1.65)]:
        for j in range(count):
            a=2*math.pi*j/count+ring*.6
            leaf(c,r,'aloe_leaf',(.06*math.cos(a),.06*math.sin(a),0),
                 (rad*s*math.cos(a),rad*s*math.sin(a),h*s),.40*s,ALOE,group,thick=.065*s)

def thorn(c,r,stage):
    s={2:.38,3:.67,4:1}[stage]
    for i,a in enumerate([0,2.1,4.2]):
        tip=(.8*s*math.cos(a),.8*s*math.sin(a),1.05*s)
        stem(c,r,'thorn_branch',(0,0,0),tip,.11*s,WOOD,tip=.035*s)
        for k in range(3):
            t=(k+1)/4;p=Vector(tip)*t
            off=Vector((math.cos(a+1.3)*.30*s,math.sin(a+1.3)*.30*s,.21*s))
            stem(c,r,'thorn',tuple(p),tuple(p+off),.065*s,CREAM,tip=.002)
        vine_leaf(c,r,*tip,a+1.5,.38*s)

def build_plants():
    reset();colors()
    for row,(crop,label) in enumerate(CROPS):
        for stage in range(1,5):
            iid=f'{crop}_stage_{stage:02d}'
            c,r=item('Plants',iid,label+' / '+str(stage),'plant',crop,stage)
            if stage==1:sprout(c,r,crop,stage)
            elif crop=='berry':berry(c,r,stage)
            elif crop=='wheat':wheat(c,r,stage)
            elif crop in ('pumpkin','watermelon'):pumpkin_or_melon(c,r,crop,stage)
            elif crop=='tomato':tomato(c,r,stage)
            elif crop in ('carrot','garlic'):roots(c,r,crop,stage)
            elif crop=='aloe_vera':aloe(c,r,stage)
            else:thorn(c,r,stage)
            r.location=((stage-2.5)*3.6,-row*4.0,0)
    presentation_grid('Plants')
    helpers.setup_render((0,-29,42),(0,-16,0),42,(1550,2900))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'farming-plants.blend'))
    # Three legible growth sheets, three crops each.
    for page in range(3):
        cy=-(page*3+1)*4.0
        page_crops={crop for crop,label in CROPS[page*3:page*3+3]}
        for c in bpy.data.collections['Plants'].children:
            r=bpy.data.objects[c.name+'_root'];c.hide_render=r.get('crop_id') not in page_crops
        for o in bpy.data.collections['Presentation'].objects:
            if o.type=='FONT':
                o.hide_render=not (cy-6.1 < o.location.y < cy+4.1)
        cam=bpy.context.scene.camera;cam.location=(0,cy-8,20)
        cam.rotation_euler=(Vector((0,cy,0))-cam.location).to_track_quat('-Z','Y').to_euler()
        cam.data.ortho_scale=16.2
        bpy.context.scene.render.resolution_x=1750;bpy.context.scene.render.resolution_y=1400
        bpy.context.scene.render.filepath=str(BASE/f'growth-{page+1}.png');bpy.ops.render.render(write_still=True)
    for c in bpy.data.collections['Plants'].children:c.hide_render=False
    for o in bpy.data.collections['Presentation'].objects:o.hide_render=False

def presentation_grid(group):
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    light=material('label','#E9E4D2');muted=material('muted','#A4B4BC')
    box(pc,None,'ground',(0,-15,-.10),(100,100,.1),palette('ground',['#303D48']*3),'Presentation')
    for c in bpy.data.collections[group].children:
        r=bpy.data.objects[c.name+'_root'];x,y,z=r.location
        label=r.get('label',c.name)
        helpers.text_object(label,(x,y-1.52,.01),.19,light,pc)
        helpers.text_object(c.name,(x,y-1.80,.01),.105,muted,pc)

def build_planter():
    reset();colors();c,r=item('Planter','planter_box','Caixa de plantação','structure')
    for y in (-1.80,1.80):
        box(c,r,'long_plank',(0,y,.34),(3.9,.20,.54),WOOD,'Frame')
        box(c,r,'rim',(0,y,.64),(3.98,.28,.12),WOOD,'Frame')
    for x in (-1.80,1.80):
        box(c,r,'end_plank',(x,0,.34),(.20,3.6,.54),WOOD,'Frame')
        box(c,r,'rim',(x,0,.64),(.28,3.6,.12),WOOD,'Frame')
    for x in (-1.79,1.79):
        for y in (-1.79,1.79):
            box(c,r,'corner_post',(x,y,.38),(.32,.32,.76),WOOD,'Frame')
            box(c,r,'iron_corner',(x,y,.36),(.34,.34,.16),METAL,'Frame')
    box(c,r,'soil',(0,0,.31),(3.40,3.40,.46),SOIL,'Soil')
    for x in (-.95,0,.95):
        box(c,r,'furrow',(x,0,.552),(.10,2.96,.024),[SOIL[0]]*3,'Soil')
    r['soil_height']=.54;r['plant_area_width']=3.4
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    box(pc,None,'ground',(0,0,-.1),(100,100,.1),palette('ground',['#303D48']*3),'Presentation')
    helpers.setup_render((6,-8,10),(0,0,.2),6.3,(1200,1000))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'planter-box.blend'))
    bpy.context.scene.render.filepath=str(BASE/'planter-preview.png');bpy.ops.render.render(write_still=True)

def shape(c,r,name,pts,col,z=.06,h=.04):return slab(c,r,name,pts,z,h,[material(col,col)]*3)
def bordered(c,r,name,pts,col,z=0):
    expanded=helpers.g['offset'](pts,.025)
    slab(c,r,name+'_outline',expanded,z,.055,OUT)
    shape(c,r,name,pts,col,z+.025,.065)

def build_icons():
    reset();colors()
    seedpal={'berry':('#4A3A8C','#8565C4'),'wheat':('#B39A63','#D6C589'),'pumpkin':('#C7B183','#F4E3BC'),
             'thorn':('#614432','#AE8160'),'carrot':('#A85700','#D27000'),'tomato':('#D6AA58','#F7D585'),
             'watermelon':('#203323','#68794B'),'aloe_vera':('#5D7136','#A9C77E'),'garlic':('#C8C7BF','#FFFCED')}
    for idx,(crop,label) in enumerate(CROPS):
        c,r=item('FarmIcons',crop+'_seeds','Sementes de '+label,'seed',crop)
        for k,(x,y,a) in enumerate([(-.26,.19,-.5),(.20,.23,.4),(.03,-.23,-.1)]):
            rx,ry=(.13,.23) if crop in ('wheat','pumpkin','watermelon','garlic') else (.14,.18)
            pts=oval(x,y,rx,ry,10,a)
            if crop=='garlic':
                pts=[(x-.13,y-.18),(x+.12,y-.18),(x+.17,y-.02),(x+.02,y+.25),(x-.08,y+.13),(x-.16,y-.02)]
            bordered(c,r,'seed',pts,seedpal[crop][0])
            shape(c,r,'seed_highlight',oval(x-.035,y+.025,rx*.28,ry*.55,8,a),seedpal[crop][1],.10,.025)
        r.location=((idx%4-1.5)*1.65,-(idx//4)*1.85,0)
    bottle=[(-.15,.48),(.15,.48),(.15,.24),(.32,.10),(.34,-.38),(.26,-.49),(-.26,-.49),(-.34,-.38),(-.32,.10),(-.15,.24)]
    for idx,(iid,label,full) in enumerate([('bottle_empty','Garrafa vazia',False),('bottle_full','Garrafa com água',True)],9):
        c,r=item('FarmIcons',iid,label,'supply')
        bordered(c,r,'glass',bottle,'#7DA7AD')
        inner=[(-.24,-.37),(-.24,.05),(-.10,.19),(-.10,.36),(.10,.36),(.10,.19),(.24,.05),(.24,-.37),(.17,-.42),(-.17,-.42)]
        shape(c,r,'glass_inner',inner,'#BCD9D8',.09,.024)
        if full:
            shape(c,r,'water',[(-.24,-.37),(-.24,-.02),(-.08,0),(.09,-.035),(.24,-.005),(.24,-.37),(.17,-.42),(-.17,-.42)],'#318EB9',.115,.025)
            shape(c,r,'water_shine',[(-.19,-.08),(.17,-.09),(.17,-.045),(-.19,-.04)],'#76CEEA',.14,.014)
        shape(c,r,'glass_shine',[(-.21,-.29),(-.16,-.29),(-.16,.05),(-.21,.02)],'#E8F7F0',.145,.014)
        bordered(c,r,'cork',[(-.16,.38),(.16,.38),(.16,.52),(-.16,.52)],'#B58C57',.06)
        r.location=((idx%4-1.5)*1.65,-(idx//4)*1.85,0)
    c,r=item('FarmIcons','ice_cube','Cubo de gelo','supply')
    p=[(0,.49),(.43,.24),(.43,-.26),(0,-.49),(-.43,-.26),(-.43,.24)]
    bordered(c,r,'ice',p,'#619DB9')
    shape(c,r,'ice_top',[(-.43,.24),(0,.49),(.43,.24),(0,-.01)],'#C7F0F4',.10)
    shape(c,r,'ice_left',[(-.43,.24),(0,-.01),(0,-.49),(-.43,-.26)],'#92CADC',.10)
    shape(c,r,'ice_glint',[(-.35,.23),(-.06,.40),(.04,.34),(-.26,.17)],'#F4FFFF',.14,.018)
    shape(c,r,'ice_crack',[(.12,.13),(.16,.02),(.10,-.12),(.13,-.25),(.10,-.25),(.07,-.11),(.12,.03),(.09,.11)],'#C5EDF4',.14,.018)
    r.location=((11%4-1.5)*1.65,-(11//4)*1.85,0)
    # Keep the icon contour thin and remove unseen bottoms, like the prior packs.
    for c in bpy.data.collections['FarmIcons'].children:helpers.g['strip_bottoms'](c)
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    box(pc,None,'ground',(0,-2,-.1),(20,20,.1),palette('ground',['#303D48']*3),'Presentation')
    for c in bpy.data.collections['FarmIcons'].children:
        r=bpy.data.objects[c.name+'_root'];x,y,_=r.location
        helpers.text_object(r['label'],(x,y-.74,.01),.105,material('label','#E9E4D2'),pc)
        helpers.text_object(c.name,(x,y-.92,.01),.074,material('muted','#A4B4BC'),pc)
    helpers.setup_render((0,-4.9,17),(0,-1.9,0),7.4,(1550,1400))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'farming-icons.blend'))
    bpy.context.scene.render.filepath=str(BASE/'seeds-water-ice.png');bpy.ops.render.render(write_still=True)

def build_mature_preview():
    reset();colors()
    with bpy.data.libraries.load(str(BASE/'farming-plants.blend'),link=False) as (src,dst):
        dst.collections=[crop+'_stage_04' for crop,label in CROPS]
    for idx,c in enumerate(dst.collections):
        bpy.context.scene.collection.children.link(c)
        r=next(o for o in c.objects if o.type=='EMPTY')
        r.location=((idx%3-1)*5.0,-(idx//3)*5.4,.54)
    plantcols=list(dst.collections)
    with bpy.data.libraries.load(str(BASE/'planter-box.blend'),link=False) as (src,dst):dst.collections=['planter_box']
    source=dst.collections[0]
    for idx,plant in enumerate(plantcols):
        x,y=(idx%3-1)*5.,-(idx//3)*5.4
        group=bpy.data.collections.new('Display_Planter_'+str(idx));bpy.context.scene.collection.children.link(group)
        root=bpy.data.objects.new('Display_Planter_root',None);group.objects.link(root);root.location=(x,y,0)
        for o in source.objects:
            if o.type=='MESH':
                clone=o.copy();group.objects.link(clone);clone.parent=root
        helpers.text_object(CROPS[idx][1],(x,y-2.43,.02),.28,material('label','#E9E4D2'),group)
    for o in list(source.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.collections.remove(source)
    pc=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(pc)
    box(pc,None,'ground',(0,-5,-.11),(100,100,.1),palette('ground',['#303D48']*3),'Presentation')
    helpers.setup_render((7,-22,25),(0,-5.4,.4),20,(1800,1800))
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'farming-preview.blend'))
    bpy.context.scene.render.filepath=str(BASE/'farming-preview.png');bpy.ops.render.render(write_still=True)

if __name__=='__main__':
    BASE.mkdir(parents=True,exist_ok=True)
    build_plants();build_planter();build_icons();build_mature_preview()
    assert len(RECORDS)==49,len(RECORDS)
    (BASE/'source-manifest.json').write_text(json.dumps({'models':RECORDS,'soil_height':.54,'stages':4,'seed_style':'loose','fruit_colors_source':'existing food.blend materials'},ensure_ascii=False,indent=2),encoding='utf8')
    print('FARM_BUILD_COMPLETE: 49 models')
