"""Pacote sobreposto de 12 itens. Gerar com export_roblox.py -- primeira_leva."""
import importlib
import math

import bpy
from mathutils import Vector

import caixa_lib
import livro_lib
import mochila_lib
import skin_animacao
import skin_lib
from livros1 import trilha


# Uma linha por conjunto, da esquerda para a direita na galeria Blender.
ITENS = (
    ("corpo", "lote3_e", "lula"), ("caixas", "caixas_catalogo", "kraken"),
    ("mochilas", "mochilas2", "caranguejo"), ("livros", "livros2", "tentaculo"),
    ("corpo", "lote3_e", "toco"), ("caixas", "caixas_catalogo", "jardim"),
    ("mochilas", "mochilas5", "cubos_esmeralda"), ("livros", "livros2", "trepadeira"),
    ("corpo", "lote10", "explorador"), ("caixas", "caixas_catalogo", "aventureiro"),
    ("mochilas", "mochilas4", "cartografo"), ("livros", "livros2", "bussola"),
)
BUILD = {"corpo": skin_lib.build, "livros": livro_lib.build_livros,
         "mochilas": mochila_lib.build_mochilas, "caixas": caixa_lib.build_caixas}

# Coordenadas de modelagem medidas a partir da origem da coleção.
MAPA = (-.51 + 1.7 * math.cos(math.radians(50)), -.62 + 1.7 * math.sin(math.radians(50)))
ROTA = ((-.34, -.20), (-.06, .11), (.30, .22))
ANCORAS = {
    "cartografo": {"poeira": (0, -2.38, .29)},
    "bussola": {f"rota_{i:02d}": (MAPA[0] + x, MAPA[1] + y, .235)
                for i, (x, y) in enumerate(ROTA, 1)},
}


def grupo(obj, nome, pivo):
    obj["animation_group"] = nome
    obj["animation_pivot_world"] = pivo


def preparar_lula(s):
    # Índices originais, de uma raiz frontal em volta da cabeça até sua vizinha.
    bracos = [
        ((25, 26, 27), (.32, 1.4)), ((40, 41), (.62, 1.45)),
        ((28, 29, 30), (1, 1.35)), ((31, 32), (1.4, .35)),
        ((33, 34), (1.4, -.25)), ((23, 24), (-1.4, -.25)),
        ((21, 22), (-1.4, .35)), ((18, 19, 20), (-1, 1.35)),
        ((35, 36), (-.62, 1.45)), ((15, 16, 17), (-.32, 1.4)),
    ]
    bpy.context.view_layer.update()
    for i, (indices, xy) in enumerate(bracos, 1):
        longo = i in (2, 9)
        pivo = (*xy, 1.4 if longo else 1.32)
        for n in indices:
            obj = s.coll.objects[f"lula_Extra_{n:02d}"]
            if longo:
                lado = 1 if i == 2 else -1
                ponta = (1.8 * lado, 3.55, 1.40)
                distal = skin_animacao._cortar(obj, ponta[:2], (lado, .35))
                grupo(distal, f"ponta_{i:02d}", ponta)
            grupo(obj, f"tentaculo_{i:02d}", pivo)
        if longo:
            for n in range(indices[-1] + 1, indices[-1] + 4):
                grupo(s.coll.objects[f"lula_Extra_{n:02d}"], f"ponta_{i:02d}", ponta)


def preparar_bussola(s):
    # Dois lados coloridos, contornos e rebite em torno do mesmo eixo vertical.
    for n in range(16, 21):
        grupo(s.coll.objects[f"bussola_Extra_{n:02d}"], "agulha", (-.51, -.62, .35))
    x, y = MAPA
    def local(pontos):
        return [(x + px, y + py) for px, py in pontos]
    s.flat(skin_lib.ellipse(x, y, .54, .54, 24), .195, .012, "#BE9D68", smooth=False)
    for pts in ([(-.47, .06), (-.33, .12), (-.27, .27), (-.14, .32)],
                [(.10, -.40), (.21, -.28), (.37, -.27), (.46, -.12)]):
        s.flat(trilha(local(pts), .036, .023), .208, .006, "#9D804F", smooth=False)
    s.flat(trilha(local(ROTA), .025, .025), .208, .007, "#80643C", smooth=False)
    # A ponta fixa indica o norte (+Y), acima da rota no mapa da tampa.
    s.flat(local([(-.065, .32), (0, .49), (.065, .32), (0, .36)]),
           .212, .009, "#713723", smooth=False)


def preparar_jardim(s):
    # Dois miolos sobre as flores existentes; a cobertura de neon pulsa sobre a base.
    for i, (x, y, raio) in enumerate(((-.45, -.35, .10), (.65, -.40, .09)), 1):
        obj = s.disk(x, y, raio, "#C3FF79", z=2.227, emit=1)
        grupo(obj, f"semente_{i:02d}", (x, y, 2.227))


AJUSTES = {"lula": preparar_lula, "bussola": preparar_bussola, "jardim": preparar_jardim}

def montar_item(categoria, modulo, nome, limpar):
    item = next(t for t in importlib.import_module(modulo).LOTE if t[0] == nome)
    def montar(s):
        item[1](s)
        if nome in ("tentaculo", "toco", "trepadeira"):
            skin_animacao.prepare_animation(s.coll, 0, 0)
        if nome in AJUSTES:
            AJUSTES[nome](s)
    BUILD[categoria]([(nome, montar, *item[2:])], cols=1, clear=limpar)
    bpy.context.view_layer.update()


def preparar(coletar):
    skins, paleta, indices = [], [], {}
    for indice, (categoria, modulo, nome) in enumerate(ITENS):
        montar_item(categoria, modulo, nome, limpar=True)
        (skin,), cores = coletar(categoria)
        remap = []
        for cor in cores:
            if cor not in indices:
                indices[cor] = len(paleta)
                paleta.append(cor)
            remap.append(indices[cor])
        origem = Vector(skin["gallery"])
        destino = Vector(((indice % 4) * 8., -(indice // 4) * 10., origem.z))
        for p in skin["parts"]:
            p["colors"] = [remap[c] for c in p["colors"]]
            p["relative"].translation += destino - origem
        skin["gallery"] = list(destino)
        skin["anchors"] = {key: [round(v, 5) for v in Vector(pos) - origem]
                           for key, pos in ANCORAS.get(nome, {}).items()}
        skins.append(skin)
    return skins, paleta, sorted({modulo for _, modulo, _ in ITENS})


def salvar_editavel(caminho):
    """As coleções conservam as peças, materiais e subdivisões dos modelos-fonte."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    skin_lib.clear_scene()
    skin_lib.RES_CURVA = 8
    cena = bpy.context.scene
    cena.name = "Primeira leva"
    for i, (categoria, modulo, nome) in enumerate(ITENS):
        if i % 4 == 0:
            conjunto = bpy.data.collections.new(("Maré Profunda", "Bosque Desperto", "Norte Perdido")[i // 4])
            cena.collection.children.link(conjunto)
        montar_item(categoria, modulo, nome, limpar=False)
        col = bpy.data.collections[nome]
        conjunto.children.link(col)
        cena.collection.children.unlink(col)
        controles = {o["animation_group"]: o for o in col.objects
                     if o.type == "EMPTY" and o.get("animation_group")}
        for obj in list(col.objects):
            g = obj.get("animation_group")
            if obj.type != "MESH" or not g or obj.parent:
                continue
            if g not in controles:
                ctrl = bpy.data.objects.new(f"CTRL_{nome}_{g}", None)
                ctrl.empty_display_size = .15
                ctrl.location = obj["animation_pivot_world"]
                col.objects.link(ctrl)
                controles[g] = ctrl
                bpy.context.view_layer.update()
            obj.parent = controles[g]
            obj.matrix_parent_inverse = controles[g].matrix_world.inverted()
        if nome == "lula":
            juntas = [("ponta_02", "tentaculo_02"), ("ponta_09", "tentaculo_09")]
        else:
            juntas = []
        for filha, pai in juntas:
            controles[filha].parent = controles[pai]
            controles[filha].matrix_parent_inverse = controles[pai].matrix_world.inverted()
        for chave, pos in ANCORAS.get(nome, {}).items():
            marker = bpy.data.objects.new(f"ORIGEM_{nome}_{chave}", None)
            marker.empty_display_type = "SPHERE"
            marker.empty_display_size = .05
            col.objects.link(marker)
            marker.location = pos
        raiz = bpy.data.objects.new(f"Raiz_{nome}", None)
        col.objects.link(raiz)
        for obj in list(col.objects):
            if categoria == "mochilas" and "PREVIEW" in obj.name:
                obj.hide_viewport = obj.hide_render = True
            if obj != raiz and not obj.parent:
                obj.parent = raiz
        ajuste_y = -mochila_lib.BAG_Y if categoria == "mochilas" else 0.
        raiz.location = ((i % 4 - 1.5)*7, (1 - i // 4)*8.5 + ajuste_y, 0)
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            space = area.spaces.active
            space.region_3d.view_rotation = (1., 0., 0., 0.)
            space.region_3d.view_distance = 29.
            space.region_3d.view_location = (0., 0., 1.)
            space.region_3d.view_perspective = "ORTHO"
            space.shading.color_type = "MATERIAL"
            space.overlay.show_overlays = False
    bpy.context.view_layer.update()
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=caminho)


def validar_fbx(man, arquivo, erros):
    """Confere nomes, juntas, marcadores e desenho da rota depois da reimportação."""
    for skin in man["skins"]:
        if arquivo not in (man["arquivo_geral"], skin["file"]):
            continue
        sid = skin["id"]
        raiz = bpy.data.objects.get(sid)
        if raiz is None:
            erros.append(f"raiz ausente: {sid}")
            continue
        pontos = {p["name"]: p["offset_do_pivo_do_skin"] for p in skin["parts"]}
        for nome, pos in skin.get("anchors_blender", {}).items():
            pontos[f"{sid}_{nome}"] = pos
        for nome, pos in pontos.items():
            obj = bpy.data.objects.get(nome)
            if obj is None or obj.parent != raiz:
                erros.append(f"peça ou marcador ausente da raiz: {nome}")
            elif (obj.location - Vector(pos)).length > .001:
                erros.append(f"pivô deslocado: {nome}")
        if sid == "book_bussola":
            pagina = bpy.data.objects[f"{sid}_livro"]
            for pos in skin["anchors_blender"].values():
                ponto = Vector(pos)
                hit, face, _, _ = pagina.ray_cast(ponto, Vector((0, 0, -1)))
                if not hit or (ponto - face).length > .04:
                    erros.append("ponto da rota fora da página da bússola")
        if sid == "body_lula":
            corpo = bpy.data.objects[f"{sid}_corpo"]
            for i in range(1, 11):
                pos = bpy.data.objects[f"{sid}_anim_tentaculo_{i:02d}"].location
                hit, _, _, _ = corpo.ray_cast(pos + Vector((0, 0, 3)), Vector((0, 0, -1)))
                if not hit:
                    erros.append(f"raiz do tentáculo {i} fora da cabeça")


def validar_lote(man, val):
    assert val["ok"], val
    assert len(man["skins"]) == len(ITENS) == 12
    for skin, resultado in zip(man["skins"], val["resultados"][1:], strict=True):
        assert resultado["file"] == skin["file"] and resultado["malhas"] == len(skin["parts"])
        if skin.get("anchors_blender"):
            assert skin["id"].startswith(("bag_", "book_"))
    grupos = {s["id"]: {p.get("animation_group") for p in s["parts"]} for s in man["skins"]}
    assert grupos["body_lula"] == {None, "ponta_02", "ponta_09",
                                   *(f"tentaculo_{i:02d}" for i in range(1, 11))}
    assert grupos["book_bussola"] == {None, "agulha"}
    assert grupos["book_tentaculo"] == {None, "espiral", "ponta"}
    assert grupos["crate_jardim"] == {None, "semente_01", "semente_02"}
