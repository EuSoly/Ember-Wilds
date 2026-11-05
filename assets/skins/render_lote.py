# Monta e renderiza um lote em SEGUNDO PLANO (não mexe no Blender aberto):
#   blender -b --factory-startup --python assets/skins/render_lote.py -- <arquivo em lotes/ ou glob> <pasta de saída>
#   ex.: ... -- lote3_a C:/.../scratchpad/prev
# Gera <saída>/<lote>-cima.png, <saída>/<lote>-65.png e <saída>/<lote>.blend.
import sys, os, glob, importlib
here = os.path.dirname(os.path.abspath(__file__))
for p in (here, os.path.join(here, "lotes")):
    if p not in sys.path: sys.path.insert(0, p)
args = sys.argv[sys.argv.index("--") + 1:]
pat, out_dir = args[0], args[1]
os.makedirs(out_dir, exist_ok=True)
import bpy, skin_lib
lote = []
for f in sorted(glob.glob(os.path.join(here, "lotes", pat + ".py"))):
    lote += importlib.import_module(os.path.splitext(os.path.basename(f))[0]).LOTE
if not lote: raise SystemExit(f"nenhum lote para {pat}")
skin_lib.build(lote, cols=min(5, len(lote)))
name = pat.replace("*", "")
print("prévias:", skin_lib.render_previews(os.path.join(out_dir, name)))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, name + ".blend"))
