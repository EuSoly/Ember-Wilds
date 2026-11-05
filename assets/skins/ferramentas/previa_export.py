# Prévia de um .blend de exportação (cores vindas da textura de paleta), para conferir o Decimate.
#   blender -b assets/skins/roblox/corpo/skins-corpo-export.blend --python assets/skins/ferramentas/previa_export.py -- <prefixo_saida> [px_por_skin]
import sys, os
here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, here)
import skin_lib
args = sys.argv[sys.argv.index("--") + 1:]
print("prévias:", skin_lib.render_previews(args[0], size_per_skin=int(args[1]) if len(args) > 1 else 360, cor="TEXTURE"))
