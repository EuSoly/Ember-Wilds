# Resumo de todas as peças de uma cena (nome, coleção, material, caixa no mundo) em JSON.
# Serve para descobrir o que o Elizeu mudou à mão no Blender e levar para o script do lote.
#   No Blender ABERTO (MCP/console): RESUMO_SAIDA = r"...\vivo.json"; exec(open(r"...\resumo_cena.py").read())
#   Em segundo plano, montando um lote pelo script:
#     blender -b --factory-startup --python assets/skins/ferramentas/resumo_cena.py -- lote5 <saida.json>
#   Depois: python assets/skins/ferramentas/comparar_resumos.py <script.json> <vivo.json>
import sys, os, json, importlib
import bpy
from mathutils import Vector
here = os.path.dirname(os.path.dirname(os.path.abspath(r"C:\Users\Elize\Desktop\Roblox\starve\assets\skins\ferramentas\resumo_cena.py")))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:  # segundo plano: monta o lote pelo script
    for p in (here, os.path.join(here, "lotes")):
        if p not in sys.path: sys.path.insert(0, p)
    import skin_lib
    skin_lib.build(importlib.import_module(args[0]).LOTE)
    saida = args[1]
else:
    saida = globals()["RESUMO_SAIDA"]
out = {}
for o in bpy.data.objects:
    if o.type != "MESH": continue
    m = o.active_material
    bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
    out[o.name] = dict(n=len(o.data.vertices), mat=m.name if m else None,
        col=[round(c, 3) for c in m.diffuse_color[:3]] if m else None,
        lo=[round(min(v[i] for v in bb), 3) for i in range(3)], hi=[round(max(v[i] for v in bb), 3) for i in range(3)],
        coll=o.users_collection[0].name if o.users_collection else None, hide=bool(o.hide_get() or o.hide_render))
json.dump(out, open(saida, "w"))
print("peças:", len(out), "->", saida)
