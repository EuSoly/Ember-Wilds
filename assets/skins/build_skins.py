# Monta um lote de skins no Blender ABERTO (pelo MCP ou no console do Blender):
#   LOTE_ESCOLHIDO = "lote2"            # um arquivo em lotes/
#   LOTE_ESCOLHIDO = "lote3_*"          # vários arquivos juntos (glob)
#   exec(open(r"<raiz>/assets/skins/build_skins.py", encoding="utf8").read())
# Regras em docs/guia/skins-modelagem.md.
import sys, os, glob, importlib
_here = os.path.dirname(os.path.abspath(r"C:\Users\Elize\Desktop\Roblox\starve\assets\skins\build_skins.py"))
for p in (_here, os.path.join(_here, "lotes")):
    if p not in sys.path: sys.path.insert(0, p)
import skin_lib; importlib.reload(skin_lib)
_pat = globals().get("LOTE_ESCOLHIDO", "lote2")
_lote, _tipo = [], "corpo"
for f in sorted(glob.glob(os.path.join(_here, "lotes", _pat + ".py"))):
    m = importlib.import_module(os.path.splitext(os.path.basename(f))[0]); importlib.reload(m)
    _lote += m.LOTE; _tipo = getattr(m, "TIPO", _tipo)
if _tipo == "caixa":
    import caixa_lib; importlib.reload(caixa_lib)
    print("caixas:", len(_lote), "objetos:", caixa_lib.build_caixas(_lote))
elif _tipo == "livro":
    import livro_lib; importlib.reload(livro_lib)
    print("livros:", len(_lote), "objetos:", livro_lib.build_livros(_lote))
elif _tipo == "mochila":
    import mochila_lib; importlib.reload(mochila_lib)
    print("mochilas:", len(_lote), "objetos:", mochila_lib.build_mochilas(_lote))
else:
    print("skins:", len(_lote), "objetos:", skin_lib.build(_lote))
