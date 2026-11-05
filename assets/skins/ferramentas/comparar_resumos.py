# Compara dois resumos (script x Blender aberto) e lista peças apagadas, novas e mudadas.
#   python assets/skins/ferramentas/comparar_resumos.py <script.json> <vivo.json>
# As peças são casadas pela forma (coleção + material + nº de vértices + caixa), não pelo nome:
# apagar uma peça renumera as seguintes (<skin>_Extra_NN), então o nome não serve.
# Os nomes listados são os do lado do SCRIPT; para achar a linha do lote que cria cada uma,
# use ferramentas/rastrear_pecas.py com esses nomes.
import json, sys
from collections import defaultdict

a, b = (json.load(open(p)) for p in sys.argv[1:3])
sig = lambda v: (v["coll"], v["mat"], v["n"], tuple(round(x, 2) for x in v["lo"] + v["hi"]))
pool = defaultdict(list)
for k, v in b.items():
    pool[sig(v)].append(k)
so_script = []
for k, v in a.items():
    s = pool.get(sig(v))
    if s: s.pop()
    else: so_script.append(k)
so_vivo = [k for lst in pool.values() for k in lst]
# parear "mudou" = mesma coleção, material e nº de vértices, caixa diferente
mudadas = []
for k in list(so_script):
    for j in so_vivo:
        if (a[k]["coll"], a[k]["mat"], a[k]["n"]) == (b[j]["coll"], b[j]["mat"], b[j]["n"]):
            mudadas.append((k, a[k]["lo"] + a[k]["hi"], b[j]["lo"] + b[j]["hi"]))
            so_script.remove(k); so_vivo.remove(j)
            break
print(f"peças: script {len(a)}, Blender {len(b)}")
print("apagadas no Blender:", len(so_script)); [print("  -", k, a[k]["coll"], a[k]["mat"]) for k in sorted(so_script)]
print("novas no Blender:", len(so_vivo)); [print("  +", k, b[k]["coll"], b[k]["mat"], b[k]["lo"], b[k]["hi"]) for k in sorted(so_vivo)]
print("mudadas (caixa antes -> depois):", len(mudadas)); [print("  *", k, x, "->", y) for k, x, y in mudadas]
ocultas = [k for k, v in b.items() if v.get("hide")]
if ocultas: print("ocultas no Blender:", ocultas)
