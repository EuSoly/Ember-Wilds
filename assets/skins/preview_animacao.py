# Prévia no Blender das skins animadas (Dragão, Polvo, Toco e os tomos de Gelo, Abissal e Trepadeira).
# Monta as 6 skins, separa as peças animadas (skin_animacao.py) e põe keyframes nos controles CTRL_*
# com o MESMO movimento do jogo: as poses vêm de assets/skins/animadas/movimentos.json, gerado do
# src/shared/Models/SkinMotion.luau por `lune run scripts/skin-motion-preview`.
# Linha do tempo: quadros 1–144 PARADO, 145–240 ANDANDO (24 qps). Os livros não mudam ao andar.
# No Blender aberto (pelo MCP ou no console):
#   exec(open(r"<raiz>/assets/skins/preview_animacao.py", encoding="utf8").read())
# Salva em assets/skins/animadas/skins-animadas.blend.
import sys, os, json, importlib
import bpy
from mathutils import Vector

_here = r"C:\Users\Elize\Desktop\Roblox\starve\assets\skins"
for p in (_here, os.path.join(_here, "lotes")):
    if p not in sys.path: sys.path.insert(0, p)
import skin_lib, livro_lib, skin_animacao
for m in (skin_lib, livro_lib, skin_animacao): importlib.reload(m)
import lote1, lote3_e, livros1, livros2

def _pick(lote, nomes): return [i for i in lote if i[0] in nomes]

skin_lib.build(_pick(lote1.LOTE, {"dragao", "polvo"}) + _pick(lote3_e.LOTE, {"toco"}), cols=3)
livro_lib.build_livros(_pick(livros1.LOTE, {"gelo"}) + _pick(livros2.LOTE, {"tentaculo", "trepadeira"}), cols=3, clear=False)
for c in bpy.data.collections:  # livros numa fileira abaixo dos corpos
    if c.name in ("gelo", "tentaculo", "trepadeira"):
        for o in c.objects:
            if o.parent is None: o.location.y -= 8
skin_animacao.prepare_all()

dados = json.load(open(os.path.join(_here, "animadas", "movimentos.json"), encoding="utf8"))
PREFIXO = {"dragao": "body_", "polvo": "body_", "toco": "body_", "gelo": "book_", "tentaculo": "book_", "trepadeira": "book_"}
cena = bpy.context.scene
cena.render.fps = dados["fps"]; cena.frame_start = 1
cena.frame_end = dados["quadros_parado"] + dados["quadros_andando"]
for ctrl in [o for o in bpy.data.objects if o.get("animation_control")]:
    skin = ctrl.users_collection[0].name
    quadros = dados["skins"][PREFIXO[skin] + skin].get("anim_" + ctrl["animation_group"])
    if not quadros: continue
    base = ctrl.location.copy()
    # Roblox (X, Y, Z) = Blender (X, Z, -Y); CFrame.Angles(x, y, z) = Rx·Ry·Rz → euler 'YZX' do Blender
    ctrl.rotation_mode = "YZX"
    for f, (rx, ry, rz, px, py, pz) in enumerate(quadros, start=1):
        ctrl.location = base + Vector((px, -pz, py))
        ctrl.rotation_euler = (rx, -rz, ry)
        ctrl.keyframe_insert("location", frame=f); ctrl.keyframe_insert("rotation_euler", frame=f)

# marcadores e uma câmera no ângulo do jogo (de cima, inclinada)
cena.timeline_markers.clear()
cena.timeline_markers.new("PARADO", frame=1); cena.timeline_markers.new("ANDANDO", frame=dados["quadros_parado"] + 1)
cam = bpy.data.objects.get("CamJogo") or bpy.data.objects.new("CamJogo", bpy.data.cameras.new("CamJogo"))
if cam.name not in cena.collection.objects: cena.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = 30
import math
p = math.radians(65); alvo = Vector((-0.5, -3.5, 1)); d = Vector((0, math.cos(p), math.sin(p)))
cam.location = alvo + d * 40; cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
cena.camera = cam; cena.render.resolution_x, cena.render.resolution_y = 1600, 1000
cena.frame_set(1)
os.makedirs(os.path.join(_here, "animadas"), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(_here, "animadas", "skins-animadas.blend"))
print("prévia salva:", bpy.data.filepath, "quadros:", cena.frame_end)
