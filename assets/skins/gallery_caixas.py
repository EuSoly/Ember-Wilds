"""Reúne os lotes em cenas independentes para revisão no Blender."""
import bpy,os,math
from mathutils import Vector
HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(HERE,'caixas')
bpy.ops.wm.read_factory_settings(use_empty=True)
initial=bpy.context.scene
titles=['01 - Materiais e aventura','02 - Floresta e neve','03 - Dragoes e oceano',
        '04 - Bichos e jardim','05 - Materiais organicos','06 - Fantasia e animais','07 - Madeira']
scenes=[]
for i,title in enumerate(titles,1):
    with bpy.data.libraries.load(os.path.join(OUT,f'caixas{i}.blend'),link=False) as (src,dst):
        dst.scenes=src.scenes
    sc=dst.scenes[0];sc.name=title;scenes.append(sc)
    for o in sc.objects:
        if o.type=='CAMERA':o.hide_viewport=True
    sc['review_note']='Caixas em desenvolvimento; frente +Y; escala em studs; pivô no chão.'
bpy.context.window.scene=scenes[1]
bpy.data.scenes.remove(initial)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            space=area.spaces.active
            space.shading.type='SOLID';space.shading.color_type='MATERIAL'
            space.shading.light='STUDIO';space.shading.show_shadows=False
            space.overlay.show_floor=False;space.overlay.show_axis_x=False;space.overlay.show_axis_y=False
            d=Vector((.35,1,1.7))
            space.region_3d.view_rotation=(-d).to_track_quat('-Z','Y')
            space.region_3d.view_location=(0,3,1)
            space.region_3d.view_distance=26
            space.region_3d.view_perspective='ORTHO'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'caixas-revisao.blend'))
