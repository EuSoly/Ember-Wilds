"""Rabbit silhouette prototype. Run in Blender's Python context; Z up, front -Y.

Reference: https://starveiopro.fandom.com/wiki/Rabbit
Creates an isolated scene, preserving existing scenes and objects.
"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'C:\Users\Elize\Desktop\Roblox\starve')
OUT = ROOT / 'assets/npcs/rabbit'
PREVIEW = ROOT / 'build/previews'
OUT.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)

scene = bpy.data.scenes.new('Rabbit_Prototype_v1')
bpy.context.window.scene = scene
model = bpy.data.collections.new('RABBIT | editable meshes')
stage = bpy.data.collections.new('PRESENTATION | not for export')
scene.collection.children.link(model)
scene.collection.children.link(stage)

def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def mat(name, hex_color):
    rgb = tuple(linear(int(hex_color[i:i+2], 16) / 255) for i in (0, 2, 4))
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    node = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*rgb, 1)
    node.inputs['Roughness'].default_value = .83
    node.inputs['Specular IOR Level'].default_value = .12
    return m

rim = mat('Rabbit | warm ivory border', 'FFF4F5')
pink = mat('Rabbit | strawberry pink', 'EEA7CD')
earpink = mat('Rabbit | ear pink', 'E98DBA')
ink = mat('Rabbit | eyes', '171822')
white = mat('Rabbit | eye sparkle', 'FFFFFF')
underside = mat('Rabbit | lower edge', 'AA718F')
ground = mat('Stage | muted forest', '567F79')

root = bpy.data.objects.new('Rabbit_ROOT', None)
model.objects.link(root)
root['front_axis'] = '-Y (Blender); convert to -Z in Roblox'
root['style'] = 'Top-down silhouette extruded into shallow 3D, matching Boneco'
root['status'] = 'Visual prototype for approval; not rigged'
root['reference'] = 'https://starveiopro.fandom.com/wiki/Rabbit'

def ellipse(rx, ry, n=48):
    return [(rx*math.cos(i*2*math.pi/n), ry*math.sin(i*2*math.pi/n)) for i in range(n)]

def solid(name, outline, rings, material, xy=(0,0), angle=0):
    # Explicit bevel rings keep the mesh predictable and exportable without modifiers.
    n = len(outline)
    ca, sa = math.cos(angle), math.sin(angle)
    verts = []
    for scale, z in rings:
        for x,y in outline:
            x,y = scale*x, scale*y
            verts.append((xy[0]+ca*x-sa*y, xy[1]+sa*x+ca*y, z))
    faces = [tuple(reversed(range(n)))]
    for j in range(len(rings)-1):
        for i in range(n):
            k = (i+1)%n
            faces.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
    faces.append(tuple((len(rings)-1)*n+i for i in range(n)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    model.objects.link(obj)
    obj.parent = root
    obj.data.materials.append(material)
    for p in mesh.polygons:
        p.use_smooth = len(p.vertices) == 4
    return obj

# A circular face and two splayed ears preserve the original readable silhouette.
for side, sign in [('L',-1),('R',1)]:
    shape = []
    for i in range(32):
        t = i*2*math.pi/32
        shape.append((.29*math.cos(t)*(.87-.13*math.sin(t)), .86*math.sin(t)))
    pos = (sign*.76, 1.22)
    a = math.radians(-sign*19)
    solid('Ear_'+side+'_lower_edge', shape, [(1,.22),(1.03,.29),(1.03,.38)], underside,pos,a)
    solid('Ear_'+side+'_ivory', shape, [(.92,.30),(1,.38),(1,.69),(.91,.77)],rim,pos,a)
    inner = [(x*.57,y*.81) for x,y in shape]
    solid('Ear_'+side+'_pink', inner, [(.94,.772),(1,.784),(.96,.803)],earpink,pos,a)

body = ellipse(1.13,1.06)
solid('Body_lower_edge', body, [(.94,.06),(1.02,.14),(1.02,.22),(.99,.27)],underside)
solid('Body_ivory', body, [(.91,.18),(1,.28),(1,.70),(.95,.82)],rim)
solid('Face_pink', ellipse(.99,.92), [(.98,.814),(1,.835),(.98,.875)],pink)

for side, sign in [('L',-1),('R',1)]:
    pos = (sign*.47,-.37)
    solid('Eye_'+side,ellipse(.282,.289,32),[(.92,.874),(1,.895),(.97,.927)],ink,pos)
    solid('Eye_'+side+'_sparkle',ellipse(.085,.085,20),[(1,.928),(1,.941)],white,(pos[0]-.080,pos[1]+.095))

def stage_obj(name, data):
    ob = bpy.data.objects.new(name, data)
    stage.objects.link(ob)
    return ob

mesh = bpy.data.meshes.new('Backdrop_mesh')
mesh.from_pydata([(-200,-200,0),(200,-200,0),(200,200,0),(-200,200,0)],[],[(0,1,2,3)])
floor = stage_obj('Backdrop',mesh)
floor.data.materials.append(ground)

camera = stage_obj('Camera_65deg',bpy.data.cameras.new('Camera_65deg'))
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 5.15
target = Vector((0,.47,.35))
camera.location = target + Vector((1.2,-5.4,12))
camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera = camera

for name,position,power,size in [('Key',(-3,-4,7),650,5),('Fill',(4,1,5),300,4)]:
    light = stage_obj(name,bpy.data.lights.new(name,'AREA'))
    light.location = position
    light.data.energy = power
    light.data.shape = next(i.identifier for i in light.data.bl_rna.properties['shape'].enum_items if i.identifier == 'DISK')
    light.data.size = size
    light.rotation_euler = (Vector((0,.4,0))-light.location).to_track_quat('-Z','Y').to_euler()

scene.world = bpy.data.worlds.new('Rabbit_preview_world')
scene.world.use_nodes = True
bg = next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND')
bg.inputs['Color'].default_value = (.55,.65,.7,1)
bg.inputs['Strength'].default_value = .45
scene.render.resolution_x = 1200
scene.render.resolution_y = 1200
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = str(PREVIEW / 'coelho-v1.png')
scene.render.film_transparent = False

# Leave the live viewport looking through the prepared camera.
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        area.spaces.active.region_3d.view_perspective = 'CAMERA'
        area.spaces.active.overlay.show_overlays = False
        area.spaces.active.shading.color_type = next(i.identifier for i in area.spaces.active.shading.bl_rna.properties['color_type'].enum_items if i.identifier == 'MATERIAL')

bpy.context.view_layer.objects.active = bpy.data.objects.get('Body_ivory')
for obj in bpy.context.selected_objects:
    obj.select_set(False)
print({'scene':scene.name,'meshes':len([o for o in model.objects if o.type=='MESH']),'engine':scene.render.engine,'preview':scene.render.filepath})
