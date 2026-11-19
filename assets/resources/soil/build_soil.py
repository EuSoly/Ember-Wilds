"""Create sand and ground low-relief inventory icons without editing prior assets."""
import bpy,json,importlib.util
from pathlib import Path
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[2]
spec=importlib.util.spec_from_file_location('icon_helpers',REPO/'assets/resources/missing-items/build_assets.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
h.g['GROUP']='Soil_Icons'

def item(iid,label,outline,base):
    c,r=h.g['item'](iid,label,'resource')
    h.silhouette(c,r,outline,base)
    return c,r

# Sand: broad, rounded heap and soft, sweeping strata.
sand=[(-.50,-.25),(-.57,-.12),(-.53,.035),(-.39,.13),(-.27,.30),(-.08,.40),(.10,.37),(.24,.23),(.43,.14),(.55,-.02),(.53,-.18),(.37,-.29),(.10,-.35),(-.21,-.33)]
c,r=item('sand','Areia',sand,'#B99759')
h.layer(c,r,'sand_body',[(-.49,-.13),(-.44,.015),(-.32,.13),(-.23,.29),(-.08,.35),(.08,.32),(.22,.19),(.38,.12),(.47,-.015),(.40,-.13),(.21,-.21),(-.04,-.25),(-.28,-.22)],'#DFC184',.10,.025)
h.layer(c,r,'sand_crest',[(-.32,.11),(-.23,.27),(-.09,.33),(.06,.30),(.17,.20),(.02,.17),(-.12,.12),(-.25,.06)],'#F3DEAA',.128,.018)
for i,(x,y,rx,ry) in enumerate([(-.30,-.10,.036,.022),(.25,-.11,.030,.019),(.08,-.16,.025,.018)]):
    h.layer(c,r,'grain_'+str(i),h.ellipse(x,y,rx,ry,6),'#F3DEAA',.13,.014)
h.g['strip_bottoms'](c);h.g['optimize_item'](c);h.normalize(c,r);r.location=(-.85,0,0)

# Ground: irregular clods with a dark crack and warm brown top faces.
ground=[(-.50,-.21),(-.56,-.08),(-.48,.04),(-.49,.17),(-.32,.23),(-.21,.38),(-.04,.35),(.11,.42),(.25,.29),(.41,.25),(.44,.09),(.56,-.02),(.48,-.19),(.30,-.25),(.18,-.35),(-.01,-.31),(-.21,-.35),(-.30,-.25)]
c,r=item('ground','Terra',ground,'#4A3323')
h.layer(c,r,'earth_body',[(-.45,-.10),(-.41,.06),(-.40,.13),(-.27,.18),(-.17,.31),(-.03,.28),(.10,.34),(.22,.22),(.34,.19),(.37,.04),(.46,-.03),(.39,-.14),(.23,-.20),(.13,-.28),(-.03,-.24),(-.20,-.27),(-.28,-.18)],'#795439',.10,.024)
h.layer(c,r,'large_clod',[(-.38,.07),(-.24,.16),(-.17,.28),(-.05,.25),(.01,.11),(-.09,-.02),(-.25,-.06)],'#A67B50',.126,.024)
h.layer(c,r,'right_clod',[(.04,.13),(.10,.29),(.23,.17),(.30,.15),(.33,.04),(.20,-.03),(.06,.02)],'#A67B50',.127,.024)
h.layer(c,r,'front_clod',[(-.17,-.11),(-.06,-.06),(.08,-.08),(.16,-.18),(.08,-.22),(-.07,-.20)],'#936746',.129,.024)
h.layer(c,r,'crack',[(-.04,.26),(.02,.14),(-.035,.03),(.045,-.05),(.015,-.095),(-.085,.025),(-.025,.14),(-.07,.24)],'#4A3323',.151,.009)
for i,(x,y) in enumerate([(-.37,-.12),(.31,-.10)]):
    h.layer(c,r,'small_clod_'+str(i),h.ellipse(x,y,.05,.034,5),'#A67B50',.13,.025)
h.g['strip_bottoms'](c);h.g['optimize_item'](c);h.normalize(c,r);r.location=(.85,0,0)

stage=bpy.data.collections.new('Presentation');bpy.context.scene.collection.children.link(stage)
h.layer(stage,None,'background',h.rect(-4,-3,4,3),'#303D48',-.09,.015)
for iid,label in [('sand','Areia'),('ground','Terra')]:
    r=bpy.data.objects[iid+'_root'];x=r.location.x
    h.text_object(label,(x,-.73,.01),.17,h.mat('Text','#EEE8D8'),stage)
    h.text_object(iid,(x,-.94,.01),.095,h.mat('Subtext','#A6B8BF'),stage)
h.setup_render((0,-3,10),(0,-.20,0),3.65,(1350,850))
for path in [Path(__file__),REPO/'assets/resources/food/icons_lib.py']:
    txt=bpy.data.texts.new(path.name);txt.write(path.read_text(encoding='utf8'))
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'areia-e-terra.blend'))
bpy.context.scene.render.filepath=str(BASE/'areia-e-terra.png');bpy.ops.render.render(write_still=True)
print('SOIL_ICONS_READY: sand, ground')
