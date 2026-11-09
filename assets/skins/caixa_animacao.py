"""Controles de peças rígidas; preserva a pose e a geometria aprovadas."""
import re
import bpy
from mathutils import Vector


def prepare_animation(coll):
    name=coll.name
    if name not in ('vento','vortice'):
        return []
    existing=[o for o in coll.objects if o.type=='EMPTY' and o.get('animation_control')]
    if existing:
        return existing
    bpy.context.view_layer.update()
    center=Vector(coll['pivot'])
    groups={}
    feather=cloud=crystal=0
    objects=sorted((o for o in coll.objects if o.type=='MESH'),
                   key=lambda o:int(re.search(r'_(\d+)(?:\.\d+)?$',o.name).group(1)))
    for o in objects:
        kind=o.name[len(name)+1:].rsplit('_',1)[0]
        group=None
        if name=='vento':
            if kind in ('WindSpiral','CycloneEye'):group='rotor'
            elif kind=='CloudLobe':
                group=f'nuvem_{cloud//3+1:02d}';cloud+=1
            elif kind=='WindFeather':
                feather+=1;group=f'pena_{feather:02d}'
            elif kind in ('OrganicBranch','BranchTip'):
                assert feather
                group=f'pena_{feather:02d}'
        else:
            if kind in ('OrganicBranch','BranchTip','CurvedDetail'):group='espiral'
            elif kind in ('PortalStone','PortalGlyph'):group='anel'
            elif kind=='Crystal':
                crystal+=1;group=f'cristal_{crystal:02d}'
        if group:groups.setdefault(group,[]).append(o)
    assert len(groups)==(5 if name=='vento' else 4), (name,groups.keys())
    controls=[]
    for group,objs in groups.items():
        if group in ('rotor','espiral','anel'):
            pivot=center+Vector((0,0,2.20 if group!='anel' else 2.10))
        else:
            points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
            pivot=Vector(tuple((min(v[i] for v in points)+max(v[i] for v in points))/2 for i in range(3)))
        ctrl=bpy.data.objects.new(f'CTRL_{name}_{group}',None)
        coll.objects.link(ctrl)
        ctrl.location=pivot;ctrl.empty_display_size=.22
        ctrl['animation_control']=True
        ctrl['animation_group']=group
        ctrl['hint']='Z: girar; mover Z: flutuar. Exportado em malhas independentes.'
        # Use matrix_parent_inverse so creation does not alter the resting pose.
        bpy.context.view_layer.update()
        for o in objs:
            world=o.matrix_world.copy()
            o.parent=ctrl
            o.matrix_parent_inverse=ctrl.matrix_world.inverted()
            o.matrix_world=world
            o['animation_group']=group
            o['animation_pivot']=list(pivot-center)
        controls.append(ctrl)
    coll['animation_ready']=True
    bpy.context.view_layer.update()
    return controls
