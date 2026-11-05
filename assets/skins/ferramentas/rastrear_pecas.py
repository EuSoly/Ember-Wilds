# Diz qual linha do arquivo do lote cria cada peça (pelos nomes <skin>_Extra_NN etc.).
#   blender -b --factory-startup --python assets/skins/ferramentas/rastrear_pecas.py -- lote5 cogumelo_Extra_07 vela_Extra_10 ...
import sys, os, importlib, traceback
here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for p in (here, os.path.join(here, "lotes")):
    if p not in sys.path: sys.path.insert(0, p)
import skin_lib
args = sys.argv[sys.argv.index("--") + 1:]
lote, want = args[0], set(args[1:])
orig = skin_lib.Skin._name
def traced(self, kind):
    name = orig(self, kind)
    if name in want:
        fr = [f for f in traceback.extract_stack() if os.path.basename(f.filename) == lote + ".py"]
        print("PECA", name, "linha", fr[-1].lineno if fr else "?", "|", fr[-1].line if fr else "")
    return name
skin_lib.Skin._name = traced
skin_lib.build(importlib.import_module(lote).LOTE)
