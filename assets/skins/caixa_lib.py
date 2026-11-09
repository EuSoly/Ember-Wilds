"""Caixas: 1 unidade = 1 stud, frente +Y, pivô no chão.

Os relevos dos mobs vêm do .blend aprovado, não de imagens do catálogo.
Construir em processo separado: nunca descarta a cena aberta do artista.
"""
import os
import math
import bpy
import bmesh
from mathutils import Vector, Matrix
from skin_lib import Skin, mat, ellipse, clear_scene

HERE = os.path.dirname(os.path.abspath(__file__))
NPC_FILE = os.path.join(HERE, '..', 'npcs', 'rabbit', 'coelho-v1.blend')
TOP = 1.94
_npc_cache = {}


def npc_parts(key):
    """Snapshot evaluated geometry in world coordinates; never alter the source file."""
    if key in _npc_cache:
        return _npc_cache[key]
    with bpy.data.libraries.load(NPC_FILE, link=False) as (src, dst):
        dst.collections = [n for n in src.collections if n.startswith(key + ' | ')]
    assert len(dst.collections) == 1, key
    coll = dst.collections[0]
    bpy.context.scene.collection.children.link(coll)
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    parts = []
    for o in coll.all_objects:
        if o.type != 'MESH':
            continue
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        materials = []
        for m in me.materials:
            node = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            rgb = node.inputs['Base Color'].default_value[:3]
            srgb = lambda v: round(255 * (12.92*v if v <= .0031308 else 1.055*v**(1/2.4)-.055))
            materials.append('#' + ''.join(f'{srgb(v):02X}' for v in rgb))
        parts.append(dict(name=o.name.split('__')[-1],
                          vertices=[tuple(o.matrix_world @ v.co) for v in me.vertices],
                          faces=[tuple(p.vertices) for p in me.polygons],
                          indices=[p.material_index for p in me.polygons], colors=materials))
        ev.to_mesh_clear()
    for o in list(coll.all_objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.collections.remove(coll)
    assert parts, key
    _npc_cache[key] = parts
    return parts


class Caixa(Skin):
    def __init__(self, name, ox, oy, body, outline, accent):
        super().__init__(name, ox, oy, body, outline)
        self.accent = accent
        self.coll['pivot'] = (ox, oy, 0)

    def box(self, loc, size, color, kind='Frame', bevel=.045, emit=0):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=size, verts=bm.verts)
        if bevel:
            bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size)*.3), segments=2, affect='EDGES')
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        me = bpy.data.meshes.new(kind)
        bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(self._name(kind), me)
        self.coll.objects.link(o)
        o.location = (self.ox+loc[0], self.oy+loc[1], loc[2])
        me.materials.append(mat(color, emit))
        return o

    def disk(self, x, y, r, color, z=TOP+.025, ry=None, kind='LidDetail', emit=0):
        return self.flat(ellipse(x,y,r,ry or r,16), z, .045, color, smooth=False, kind=kind, emit=emit)

    def line(self, points, width, color, z=TOP+.025, kind='LidDetail', emit=0):
        for a,b in zip(points, points[1:]):
            dx,dy=b[0]-a[0],b[1]-a[1]
            length=math.hypot(dx,dy)
            if length < 1e-6: continue
            nx,ny=-dy/length*width/2,dx/length*width/2
            self.flat([(a[0]+nx,a[1]+ny),(b[0]+nx,b[1]+ny),(b[0]-nx,b[1]-ny),(a[0]-nx,a[1]-ny)],z,.045,color,smooth=False,kind=kind,emit=emit)

    def wall(self, side, pts, color, depth=.04, kind='SideDetail', emit=0):
        """Surface coordinates (horizontal, height), on each of the four walls."""
        o = self.flat(pts, 0, depth, color, smooth=False, kind=kind, emit=emit)
        for v in o.data.vertices:
            u,h,t=v.co.x-self.ox,v.co.y-self.oy,v.co.z
            xyz = ((u,1.215+t,h),(-1.215-t,u,h),(-u,-1.215-t,h),(1.215+t,-u,h))[side]
            v.co=(self.ox+xyz[0],self.oy+xyz[1],xyz[2])
        # Wall frames preserve outward normal; recalc also handles reflected walls.
        bm=bmesh.new(); bm.from_mesh(o.data)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(o.data); bm.free()
        return o

    def wall_line(self, side, points, width, color, emit=0, depth=.04):
        for a,b in zip(points,points[1:]):
            dx,dy=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dy)
            if length < 1e-6: continue
            nx,ny=-dy/length*width/2,dx/length*width/2
            self.wall(side,[(a[0]+nx,a[1]+ny),(b[0]+nx,b[1]+ny),(b[0]-nx,b[1]-ny),(a[0]-nx,a[1]-ny)],color,emit=emit,depth=depth)

    def base(self, planks=True, straps=False):
        self.box((0,0,.83),(2.4,2.4,1.66),self.body,'Body',.09)
        self.box((0,0,.11),(2.54,2.54,.22),self.outline,'Foot')
        self.box((0,0,1.67),(2.55,2.55,.10),self.outline,'LidSeam',.02)
        self.box((0,0,1.83),(2.62,2.62,.22),self.body,'Lid',.07)
        for s in (-1,1):
            self.box((s*1.22,0,1.965),(.16,2.60,.09),self.accent,'LidFrame')
            self.box((0,s*1.22,1.965),(2.30,.16,.09),self.accent,'LidFrame')
            for t in (-1,1):
                self.box((s*1.16,t*1.16,.92),(.20,.20,1.45),self.accent,'Corner')
        if planks:
            for x in (-.72,-.24,.24,.72):
                self.line([(x,-1.1),(x,1.1)],.028,self.outline,z=TOP+.008,kind='LidJoin')
            for side in range(4):
                for h in (.56,1.04):
                    self.wall_line(side,[(-1.05,h),(1.05,h)],.025,self.outline)
        if straps:
            for x in (-.77,.77):
                self.box((x,0,2.005),(.18,2.63,.08),self.accent,'StrapTop')
                for s in (-1,1):
                    self.box((x,s*1.235,.95),(.18,.09,1.55),self.accent,'StrapSide')
        # Lock, two rear hinges and recessed side handles: every box is finished in 360 degrees.
        self.box((0,1.28,1.48),(.32,.13,.48),self.accent,'Lock')
        self.box((0,1.355,1.48),(.075,.025,.15),self.outline,'Keyhole',.01)
        for x in (-.67,.67):
            self.box((x,-1.27,1.60),(.34,.13,.27),self.accent,'RearHinge')
        for s in (-1,1):
            self.box((s*1.23,0,1.2),(.08,.62,.25),self.outline,'HandleInset')
            self.box((s*1.29,0,1.26),(.10,.50,.09),self.accent,'Handle')
        for side in range(4):
            for u in (-.98,.98):
                self.wall(side,ellipse(u,.35,.045,.045,8),self.accent,kind='Rivet')

    def lid_npc(self, key, width=2.95, height=2.95, z=2.015):
        parts=npc_parts(key)
        pts=[v for p in parts for v in p['vertices']]
        lo=[min(v[j] for v in pts) for j in range(3)]
        hi=[max(v[j] for v in pts) for j in range(3)]
        sc=min(width/(hi[0]-lo[0]),height/(hi[1]-lo[1]))
        # Source NPCs face -Y, while crates face +Y: rotate 180 degrees, preserving handedness.
        for p in parts:
            verts=[(self.ox-(v[0]-(lo[0]+hi[0])/2)*sc,
                    self.oy-(v[1]-(lo[1]+hi[1])/2)*sc,
                    z+(v[2]-lo[2])*.48) for v in p['vertices']]
            me=bpy.data.meshes.new('MobRelief'); me.from_pydata(verts,[],p['faces']); me.update()
            for c in p['colors']: me.materials.append(mat(c))
            for poly,idx in zip(me.polygons,p['indices']): poly.material_index=idx
            o=bpy.data.objects.new(self._name('Mob_'+p['name']),me); self.coll.objects.link(o)
            o['source_npc']=key; o['source_part']=p['name']
        self.coll['source_npc']=key

    def finish(self):
        from caixa_ajustes import apply_edits
        apply_edits(self)
        from caixa_animacao import prepare_animation
        prepare_animation(self.coll)
        self.coll['front']='+Y'


def build_caixas(lote, cols=5, dx=5.7, dy=6.0, clear=True):
    if clear: clear_scene()
    for i,(name,fn,body,outline,accent) in enumerate(lote):
        s=Caixa(name,-(i%cols-(cols-1)/2)*dx,(i//cols)*dy,body,outline,accent)
        fn(s); s.finish()
    bpy.context.view_layer.update()
    return len(bpy.data.objects)


def render_caixas(prefix, size=420, color_type='MATERIAL'):
    """Orthographic top, game 65 degrees, front-right and rear-left inspection."""
    sc=bpy.context.scene
    sc.render.engine='BLENDER_WORKBENCH'
    sc.display.shading.light='STUDIO'
    sc.display.shading.color_type=color_type
    sc.display.shading.show_shadows=False
    sc.display.shading.show_cavity=True
    sc.display.shading.cavity_type='WORLD'
    sc.display.shading.curvature_ridge_factor=1.2
    sc.view_settings.view_transform='Standard'
    sc.view_settings.exposure=.65
    sc.render.film_transparent=False
    sc.world=sc.world or bpy.data.worlds.new('CrateWorld')
    sc.display.shading.background_type='WORLD'
    sc.world.color=(.055,.07,.085)
    meshes=[o for o in sc.objects if o.type=='MESH']
    pts=[o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector(tuple(min(v[j] for v in pts) for j in range(3)))
    hi=Vector(tuple(max(v[j] for v in pts) for j in range(3)))
    center=(lo+hi)/2
    cam=bpy.data.objects.new('CrateCamera',bpy.data.cameras.new('CrateCamera'))
    sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO'
    for tag,d in [('cima',Vector((0,0,1))),('65',Vector((0,math.cos(math.radians(65)),math.sin(math.radians(65))))),('lados',Vector((.8,1,1.05))),('costas',Vector((-.8,-1,1.05)))]:
        cam.location=center+d.normalized()*70
        cam.rotation_euler=(0,0,math.pi) if tag=='cima' else (-d).to_track_quat('-Z','Y').to_euler()
        inv=cam.rotation_euler.to_matrix().transposed()
        projected=[inv@(v-center) for v in pts]
        w=max(v.x for v in projected)-min(v.x for v in projected)+1.2
        h=max(v.y for v in projected)-min(v.y for v in projected)+1.2
        sc.render.resolution_x=int(size*w/5.7)
        sc.render.resolution_y=int(size*h/5.7)
        cam.data.ortho_scale=max(w,h)
        sc.render.filepath=prefix+'-'+tag+'.png'
        bpy.ops.render.render(write_still=True)
