# Exporta as skins de CORPO, LIVRO e MOCHILA para o Roblox (FBX), no padrão dos outros pacotes do projeto
# (assets/world-pack/export_world.py): cores chapadas viram uma textura de paleta compartilhada,
# uma malha por peça, triangulada, FBX -Z forward / Y up, arquivo geral + individuais,
# manifest.json e validation.json (reimportação no Blender).
#
# Rodar em SEGUNDO PLANO (não mexe no Blender aberto), a partir da raiz do projeto:
#   blender -b --factory-startup --python assets/skins/export_roblox.py
# Saída: assets/skins/roblox/{corpo,livros,mochilas}/
#
# Peças por skin de corpo (id = body_<nome>):
#   body_<nome>_corpo        corpo + contorno + enfeites; origem no centro do corpo (1 stud acima do chão)
#   body_<nome>_mao          mão direita (esfera + contorno + enfeites da mão); origem no centro da mão direita
#   body_<nome>_mao_esq      mão esquerda espelhada em X no Blender; origem no centro da mão esquerda
#   ..._neon / ..._translucido  partes que brilham (Material Neon) ou semitransparentes, separadas
#   Os olhos (PREVIEW_*) NÃO são exportados: vêm do código.
# Por livro (id = book_<nome>): book_<nome>_livro (+ _neon/_translucido); origem no centro do livro.
# Por mochila (id = bag_<nome>): bag_<nome>_mochila (+ _neon/_translucido); origem no centro do corpo do boneco (root),
#   já posicionada nas costas (+Z no Roblox) pronta para soldar no Body como no BagModel.luau.
# Eixos: Blender +Y (frente do boneco / topo do livro) vira Roblox -Z (frente); Blender Z vira Roblox Y.
import bpy, bmesh, os, sys, json, math, struct, zlib, glob, importlib
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
for p in (HERE, os.path.join(HERE, "lotes")):
    if p not in sys.path: sys.path.insert(0, p)
import skin_lib, livro_lib, mochila_lib, caixa_lib, skin_animacao

OUT = os.path.join(HERE, "roblox")
LOTES = {
    "corpo": ["lote1", "lote2", "lote3_a", "lote3_b", "lote3_c", "lote3_d", "lote3_e", "lote4", "lote5", "lote6", "lote7", "lote8", "lote9", "lote10", "lote11", "lote12", "lote13", "lote14", "lote15", "lote16"],
    "corpo_lotes11_16": ["lote11", "lote12", "lote13", "lote14", "lote15", "lote16"],
    "livros": ["livros1", "livros2"],
    "mochilas": ["mochilas1", "mochilas2", "mochilas3", "mochilas4", "mochilas5", "mochilas_variantes"],
    "caixas": ["caixas_catalogo"],
    # Skins com peças animadas (skin_animacao.py): um pacote pequeno só com elas, para importar
    # por cima das versões paradas (o gen-skin-manifest dá preferência a estas categorias).
    "corpo_animado": ["lote1", "lote3_e"],
    "livros_animados": ["livros1", "livros2"],
}
# Categorias que exportam só algumas skins dos lotes.
FILTRO = {"corpo_animado": set(skin_animacao.ANIM) & {"dragao", "polvo", "toco"},
          "livros_animados": set(skin_animacao.ANIM) & {"gelo", "tentaculo", "trepadeira"}}
PREFIXO = {"corpo": "body_", "corpo_lotes11_16": "body_", "corpo_animado": "body_", "livros": "book_", "livros_animados": "book_", "mochilas": "bag_", "caixas": "crate_"}
PAPEL_PADRAO = {"corpo": "corpo", "corpo_lotes11_16": "corpo", "corpo_animado": "corpo", "livros": "livro", "livros_animados": "livro", "mochilas": "mochila", "caixas": "caixa"}
RES_EXPORT = 4  # pontos por trecho de curva no export (o editável usa 8); metade dos triângulos, igual de cima
TETO = {"corpo": 5000, "mao": 1500, "mao_esq": 1500, "livro": 3000, "mochila": 3500}  # triângulos por peça; acima disso aplica Decimate (collapse)
TETO["caixa"] = 7500  # relevo do mob + caixa acabada nos quatro lados

def srgb(v):
    v = max(0, min(1, v)); return round(255 * (12.92 * v if v <= .0031308 else 1.055 * v ** (1 / 2.4) - .055))

def medir(categoria, res):
    """Só mede triângulos por peça com uma resolução de curva (sem exportar)."""
    skin_lib.RES_CURVA = res
    bpy.ops.wm.read_factory_settings(use_empty=True)
    montar(categoria, carregar(categoria)); skins, _ = coletar(categoria)
    tri = lambda p: sum(len(f) - 2 for f in p["faces"])
    return sorted(((sum(tri(p) for p in s["parts"]), s["id"], {p["name"].split(s["id"])[1] or PAPEL_PADRAO[categoria]: tri(p) for p in s["parts"]}) for s in skins), reverse=True)

def carregar(categoria):
    lote = []
    for nome in LOTES[categoria]:
        lote += importlib.import_module(nome).LOTE
    if categoria in FILTRO:
        lote = [i for i in lote if i[0] in FILTRO[categoria]]
        assert len(lote) == len(FILTRO[categoria]), (categoria, [i[0] for i in lote])
    nomes = [i[0] for i in lote]
    dup = {n for n in nomes if nomes.count(n) > 1}
    assert not dup, f"nomes repetidos em {categoria}: {dup}"
    return lote

def montar(categoria, lote):
    if categoria == "caixas":
        caixa_lib.build_caixas(lote, cols=10)
    elif categoria.startswith("livros"):
        livro_lib.build_livros(lote, cols=10)
    elif categoria == "mochilas":
        mochila_lib.build_mochilas(lote, cols=10)
    else:
        skin_lib.build(lote, cols=10)
    if categoria.startswith("corpo") or categoria.startswith("livros"):
        skin_animacao.prepare_all()  # separa as peças animadas (asas, tentáculos...) em grupos com pivô
    bpy.context.view_layer.update()

def coletar(categoria):
    """Lê a cena montada e devolve, por skin, as peças (vértices/faces/cores) relativas ao pivô."""
    from livro_lib import LT
    from skin_lib import BH, HX, HY, HZ
    deps = bpy.context.evaluated_depsgraph_get()
    paleta, indice = [], {}
    def cor(m):
        b = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        rgba = b.inputs["Base Color"].default_value if b else m.diffuse_color
        k = tuple(srgb(v) for v in rgba[:3]) + (255,)
        if k not in indice: indice[k] = len(paleta); paleta.append(k)
        return indice[k]
    skins = []
    for coll in list(bpy.context.scene.collection.children):
        if categoria.startswith("corpo"):
            # Inclui PREVIEW_L_* (mão esquerda espelhada em X) e ignora os olhos (PREVIEW_*)
            objs = [o for o in coll.objects if o.type == "MESH" and (not o.name.startswith("PREVIEW") or o.name.startswith("PREVIEW_L_"))]
        else:
            objs = [o for o in coll.objects if o.type == "MESH" and not o.name.startswith("PREVIEW")]
        if not objs: continue
        nome = coll.name; sid = PREFIXO[categoria] + nome
        # pivô: centro do corpo / centro do livro / centro do boneco fantasma da mochila
        corpo = bpy.data.objects.get(f"{nome}_Body") or bpy.data.objects.get(f"{nome}_CapaBaixo")
        ghost = bpy.data.objects.get(f"PREVIEW_{nome}_GhostBody")
        pivo_mao = None
        pivo_mao_esq = None
        if categoria == "caixas":
            centro = Vector(coll['pivot'])
        elif categoria.startswith("corpo"):
            bb = [corpo.matrix_world @ Vector(c) for c in corpo.bound_box]
            centro = Vector(((min(v.x for v in bb) + max(v.x for v in bb)) / 2, (min(v.y for v in bb) + max(v.y for v in bb)) / 2, BH / 2))
            pivo_mao = centro + Vector((HX, HY, HZ - BH / 2))
            pivo_mao_esq = centro + Vector((-HX, HY, HZ - BH / 2))
        elif categoria == "mochilas" and ghost is not None:
            bb = [ghost.matrix_world @ Vector(c) for c in ghost.bound_box]
            centro = Vector(((min(v.x for v in bb) + max(v.x for v in bb)) / 2, (min(v.y for v in bb) + max(v.y for v in bb)) / 2, BH / 2))
        else:
            pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
            if corpo is not None:
                bb = [corpo.matrix_world @ Vector(c) for c in corpo.bound_box]
                centro = Vector(((min(v.x for v in bb) + max(v.x for v in bb)) / 2, (min(v.y for v in bb) + max(v.y for v in bb)) / 2, LT / 2))
            else:
                centro = Vector(((min(p.x for p in pts) + max(p.x for p in pts)) / 2, (min(p.y for p in pts) + max(p.y for p in pts)) / 2, LT / 2))
        grupos = {}
        for o in objs:
            m = o.active_material
            mn = m.name if m else ""
            alpha = m.diffuse_color[3] if m else 1.0
            if categoria.startswith("corpo"):
                if o.name.startswith("PREVIEW_L_"):
                    papel = "mao_esq"
                elif "_Hand" in o.name:
                    papel = "mao"
                else:
                    papel = "corpo"
            else:
                papel = PAPEL_PADRAO[categoria]
            if o.get('animation_group'):
                papel = 'anim_' + o['animation_group']
            sufixo = "_neon" if mn.endswith("_neon") else ("_translucido" if mn.endswith("_a") else "")
            chave = (papel, sufixo)
            g = grupos.setdefault(chave, dict(objs=[], alpha=alpha))
            g["objs"].append(o)
        partes = []
        for (papel, sufixo), g in sorted(grupos.items()):
            pivo = pivo_mao if papel == "mao" else (pivo_mao_esq if papel == "mao_esq" else centro)
            animation_group = None
            if papel.startswith('anim_'):
                animation_group = papel[5:]
                # caixas: pivô relativo ao centro; corpo/livro (skin_animacao): pivô no mundo
                offsets = [Vector(o['animation_pivot_world']) - centro if 'animation_pivot_world' in o else Vector(o['animation_pivot']) for o in g['objs']]
                assert all((v-offsets[0]).length < .00001 for v in offsets)
                pivo = centro + offsets[0]
            rel = Matrix.Translation(pivo)
            nome_parte = sid + f"_{papel}" + sufixo  # nunca igual ao nome da raiz (o Blender renomearia para .001)
            parte = dict(name=nome_parte, papel=papel, tipo=(sufixo[1:] if sufixo else "solido"),
                         alpha=round(g["alpha"], 3), relative=rel, vertices=[], faces=[], colors=[], smooth=[], source_parts=[])
            parte['animation_group'] = animation_group
            for o in g["objs"]:
                ev = o.evaluated_get(deps); me = ev.to_mesh(preserve_all_data_layers=True, depsgraph=deps)
                tr = rel.inverted() @ ev.matrix_world; off = len(parte["vertices"])
                parte["vertices"].extend(tuple(tr @ v.co) for v in me.vertices)
                for p in me.polygons:
                    seq = list(p.vertices)
                    if tr.to_3x3().determinant() < 0: seq.reverse()
                    parte["faces"].append(tuple(off + j for j in seq))
                    parte["colors"].append(cor(me.materials[p.material_index] or o.active_material))
                    parte["smooth"].append(p.use_smooth)
                parte["source_parts"].append(o.name); ev.to_mesh_clear()
            partes.append(parte)
        skins.append(dict(id=sid, nome=nome, gallery=list(centro), parts=partes))
    return skins, paleta

def png_paleta(paleta, caminho):
    grid = 16
    while len(paleta) > grid * grid: grid *= 2
    size = grid * 16
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            idx = (y // 16) * grid + x // 16
            raw.extend(paleta[idx] if idx < len(paleta) else (255, 255, 255, 255))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    open(caminho, "wb").write(png)
    return grid, size

def exportar(categoria):
    out = os.path.join(OUT, categoria); os.makedirs(os.path.join(out, "individual"), exist_ok=True)
    skin_lib.RES_CURVA = RES_EXPORT
    lote = carregar(categoria); montar(categoria, lote)
    skins, paleta = coletar(categoria)
    textura = f"{categoria}_palette.png"; grid, size = png_paleta(paleta, os.path.join(out, textura))
    # cena limpa só com as malhas de exportação
    cena = bpy.context.scene; cena.name = f"Skins_{categoria}_Export"
    for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
    for c in list(bpy.data.collections): bpy.data.collections.remove(c)
    bpy.data.orphans_purge(do_recursive=True)
    img = bpy.data.images.load(os.path.join(out, textura))
    mat = bpy.data.materials.new(f"{categoria}_palette"); mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"); bsdf.inputs["Roughness"].default_value = .85
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage"); tex.image = img
    tex.interpolation = next(e.identifier for e in tex.bl_rna.properties["interpolation"].enum_items if e.identifier == "Closest")
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    registros, raizes, objs_por = [], {}, {}
    for sk in skins:
        col = bpy.data.collections.new(sk["id"]); cena.collection.children.link(col)
        raiz = bpy.data.objects.new(sk["id"], None); col.objects.link(raiz); raiz.location = sk["gallery"]; raiz["item_id"] = sk["id"]
        raizes[sk["id"]] = raiz; objs_por[sk["id"]] = [raiz]
        rec = dict(id=sk["id"], nome=sk["nome"], file=f"individual/{sk['id']}.fbx", parts=[])
        for p in sk["parts"]:
            me = bpy.data.meshes.new(p["name"]); me.from_pydata(p["vertices"], [], p["faces"]); me.materials.append(mat); me.update()
            uv = me.uv_layers.new(name="UVMap")
            for face, idx, sm in zip(me.polygons, p["colors"], p["smooth"]):
                cx = ((idx % grid) * 16 + 8) / size; cy = 1 - ((idx // grid) * 16 + 8) / size
                for j, li in enumerate(face.loop_indices):
                    a = 2 * math.pi * j / len(face.loop_indices); uv.data[li].uv = (cx + 3 / size * math.cos(a), cy + 3 / size * math.sin(a))
                face.use_smooth = sm
            bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=list(bm.faces)); bm.to_mesh(me); bm.free(); me.update(); me.calc_loop_triangles()
            o = bpy.data.objects.new(p["name"], me); col.objects.link(o); o.parent = raiz
            teto = TETO.get(p["papel"], 5000); antes = len(me.loop_triangles)
            if antes > teto:
                mod = o.modifiers.new("dec", "DECIMATE"); mod.decimate_type = "COLLAPSE"; mod.ratio = teto / antes
                bpy.context.view_layer.update(); ev = o.evaluated_get(bpy.context.evaluated_depsgraph_get())
                novo = bpy.data.meshes.new_from_object(ev); o.modifiers.remove(mod); o.data = novo; me = novo
                bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.triangulate(bm, faces=list(bm.faces)); bm.to_mesh(me); bm.free(); me.update(); me.calc_loop_triangles()
            p["tri_antes"] = antes
            assert len(me.loop_triangles) < 20000, (p["name"], len(me.loop_triangles))  # limite do Roblox por MeshPart
            o.matrix_basis = Matrix.Translation(p["relative"].translation - Vector(sk["gallery"]))
            o["item_id"] = sk["id"]; o["papel"] = p["papel"]; o["tipo"] = p["tipo"]
            if p.get('animation_group'):
                o['animation_group'] = p['animation_group']
            objs_por[sk["id"]].append(o)
            pts = [v.co for v in me.vertices]
            bb = [round(min(v[j] for v in pts), 3) for j in range(3)] + [round(max(v[j] for v in pts), 3) for j in range(3)]
            rec["parts"].append(dict(name=p["name"], papel=p["papel"], tipo=p["tipo"], alpha=p["alpha"],
                                     offset_do_pivo_do_skin=[round(x, 3) for x in (p["relative"].translation - Vector(sk["gallery"]))],
                                     triangles=len(me.loop_triangles), triangles_antes_decimate=p["tri_antes"], vertices=len(me.vertices), bounds=bb, source_parts=len(p["source_parts"])))
            if p.get('animation_group'):
                rec['parts'][-1]['animation_group'] = p['animation_group']
        registros.append(rec)
    bpy.context.view_layer.update()
    rna = bpy.ops.export_scene.fbx.get_rna_type()
    def op(k, v): return next(e.identifier for e in rna.properties[k].enum_items if e.identifier == v)
    kw = dict(use_selection=True, global_scale=1.0, apply_unit_scale=True, apply_scale_options=op("apply_scale_options", "FBX_SCALE_UNITS"),
              axis_forward=op("axis_forward", "-Z"), axis_up=op("axis_up", "Y"),  # "-Z": frente do boneco (+Y no Blender) vira -Z no Roblox; com "Z" saía virado 180°
              object_types={op("object_types", "MESH"), op("object_types", "EMPTY")}, use_mesh_modifiers=True,
              mesh_smooth_type=op("mesh_smooth_type", "FACE"), bake_anim=False, add_leaf_bones=False,
              path_mode=op("path_mode", "COPY"), embed_textures=True, use_triangles=True, use_custom_props=True)
    geral = f"skins-{categoria}.fbx"
    def exp(caminho, ids, individual=False):
        for o in cena.objects: o.select_set(False)
        for i in ids:
            for o in objs_por[i]: o.select_set(True)
        guard = None
        if individual: guard = raizes[ids[0]].location.copy(); raizes[ids[0]].location = (0, 0, 0)
        bpy.context.view_layer.update(); bpy.context.view_layer.objects.active = raizes[ids[0]]
        bpy.ops.export_scene.fbx(filepath=os.path.join(out, caminho), **kw)
        if individual: raizes[ids[0]].location = guard
    exp(geral, [r["id"] for r in registros])
    for r in registros: exp(r["file"], [r["id"]], True)
    for o in cena.objects: o.select_set(False)
    img.pack(); img.filepath = "//" + textura
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f"skins-{categoria}-export.blend"))
    manifesto = dict(categoria=categoria, lotes=LOTES[categoria], skin_count=len(registros),
                     mesh_count=sum(len(r["parts"]) for r in registros),
                     total_triangles=sum(p["triangles"] for r in registros for p in r["parts"]),
                     palette_colors=len(paleta), texture=textura, texture_size=size, arquivo_geral=geral,
                     eixos="Blender Z-up; FBX forward -Z, up Y (Blender +Y = Roblox -Z = frente; Blender +X = Roblox +X). Bounds em coordenadas do Blender, relativas ao pivô da peça.",
                     skins=registros)
    json.dump(manifesto, open(os.path.join(out, "manifest.json"), "w", encoding="utf8"), indent=2, ensure_ascii=False)
    return manifesto

def validar(categoria, manifesto):
    """Reimporta cada FBX numa cena limpa e confere nomes, triângulos, UV, textura e dimensões."""
    out = os.path.join(OUT, categoria); res = []
    arquivos = [manifesto["arquivo_geral"]] + [s["file"] for s in manifesto["skins"]]
    esperado = {p["name"]: p for s in manifesto["skins"] for p in s["parts"]}
    for arq in arquivos:
        for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.orphans_purge(do_recursive=True)
        bpy.ops.import_scene.fbx(filepath=os.path.join(out, arq))
        malhas = [o for o in bpy.data.objects if o.type == "MESH"]
        erros = []
        for o in malhas:
            e = esperado.get(o.name)
            if not e: erros.append(f"malha inesperada {o.name}"); continue
            o.data.calc_loop_triangles()
            if abs(len(o.data.loop_triangles) - e["triangles"]) > max(2, e["triangles"] // 100): erros.append(f"{o.name}: triângulos {len(o.data.loop_triangles)} != {e['triangles']}")
            if not o.data.uv_layers: erros.append(f"{o.name}: sem UV")
            m = o.active_material
            if not m or not any(n.type == "TEX_IMAGE" and n.image for n in m.node_tree.nodes): erros.append(f"{o.name}: sem textura")
            dims = [e["bounds"][j + 3] - e["bounds"][j] for j in range(3)]
            got = sorted(round(d, 2) for d in o.dimensions); want = sorted(round(d, 2) for d in dims)
            if any(abs(a - b) > 0.02 for a, b in zip(got, want)): erros.append(f"{o.name}: dimensões {got} != {want}")
        if arq == manifesto["arquivo_geral"] and len(malhas) != manifesto["mesh_count"]:
            erros.append(f"geral com {len(malhas)} malhas, esperado {manifesto['mesh_count']}")
        res.append(dict(file=arq, malhas=len(malhas), ok=not erros, erros=erros))
    val = dict(categoria=categoria, arquivos=len(res), ok=all(r["ok"] for r in res), resultados=res)
    json.dump(val, open(os.path.join(out, "validation.json"), "w", encoding="utf8"), indent=2, ensure_ascii=False)
    return val

resumo = {}
# Optional category avoids rebuilding other artists' finished assets.
# blender -b --factory-startup --python assets/skins/export_roblox.py -- caixas
categorias = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(LOTES)
for cat in categorias:
    if cat not in LOTES: raise ValueError(f'categoria desconhecida: {cat}')
    bpy.ops.wm.read_factory_settings(use_empty=True)
    man = exportar(cat)
    val = validar(cat, man)
    resumo[cat] = dict(skins=man["skin_count"], malhas=man["mesh_count"], triangulos=man["total_triangles"], max_por_skin=max(sum(p["triangles"] for p in s["parts"]) for s in man["skins"]), decimadas=sum(1 for s in man["skins"] for p in s["parts"] if p["triangles"] < p["triangles_antes_decimate"]),
                       cores=man["palette_colors"], textura=man["texture_size"], validacao_ok=val["ok"],
                       falhas=[r for r in val["resultados"] if not r["ok"]][:5])
print("EXPORT_RESULT", json.dumps(resumo, ensure_ascii=False))
