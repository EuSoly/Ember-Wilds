"""Gera src/shared/Defs/SkinManifest.luau a partir dos manifest.json das skins
exportadas (assets/skins/roblox/<categoria>/manifest.json, saída do
export_roblox.py).

Lote novo: exporte, acrescente a pasta em CATEGORIAS e rode na raiz do projeto:
    python scripts/gen-skin-manifest.py

Guarda, para cada MeshPart, o centro da caixa (bounds) em relação ao pivô da
peça já nos eixos do Roblox (X = +X, Y = +Z do Blender, Z = -Y do Blender),
o papel, o tipo e o alpha. Nas caixas (crate_*), o centro é relativo ao
pivô da caixa (veja MONTADAS).
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKINS = os.path.join(ROOT, "assets", "skins", "roblox")
OUT = os.path.join(ROOT, "src", "shared", "Defs", "SkinManifest.luau")

# Ordem do arquivo gerado (a mesma da exportação).
CATEGORIAS = ["corpo", "corpo_lotes11_16", "livros", "mochilas", "caixas"]

# Categorias montadas como um modelo só (Assets.Crates/<id>, clonado inteiro
# pelo CrateModel): o centro de cada peça soma o deslocamento do pivô dela
# (as peças animadas têm o pivô no centro do grupo) e fica relativo ao pivô
# da skin (o chão, no meio da caixa). Nas outras, o centro é relativo ao pivô
# da própria peça (a mão é posicionada pelo pivô dela, em tempo de jogo).
MONTADAS = {"caixas"}

# Pacotes que substituem skins das categorias acima (mesmo id, no mesmo lugar
# da lista): as skins com peças animadas (assets/skins/skin_animacao.py).
SUBSTITUTAS = ["corpo_animado", "livros_animados"]

# Skin sem malha própria que usa a de outra (entra logo antes da original).
APELIDOS = {"book_default": "book_pergaminho"}

HEADER = """--!strict
-- Gerado por scripts/gen-skin-manifest.py a partir de assets/skins/roblox/<categoria>/manifest.json
-- (não editar à mão: rode o script de novo).
-- Guarda o centro da caixa (bounds) de cada MeshPart em relação ao pivô da peça
-- já convertido para os eixos do Roblox (X = +X, Y = +Z do Blender, Z = -Y do Blender),
-- além do papel (corpo/mao/mao_esq/mochila/livro), tipo (solido/neon/translucido) e alpha.

export type PartInfo = {
\tskinId: string,
\tpapel: string,
\ttipo: string,
\talpha: number,
\tcenter: { number },
\t-- Só nas peças animadas (papel anim_*) de corpo e livro: onde fica o pivô
\t-- (a junta) em relação ao pivô da skin, nos eixos do Roblox. O `center`
\t-- dessas peças é relativo a este pivô.
\tpivot: { number }?,
}
"""


def center(bounds):
    min_x, min_y, min_z, max_x, max_y, max_z = bounds
    return (
        round((min_x + max_x) / 2, 4),
        round((min_z + max_z) / 2, 4),
        round(-(min_y + max_y) / 2, 4),
    )


def main():
    parts_lines = []
    by_skin_lines = []
    seen = set()
    substitutas = {}
    for categoria in SUBSTITUTAS:
        with open(os.path.join(SKINS, categoria, "manifest.json"), encoding="utf-8") as f:
            for skin in json.load(f)["skins"]:
                substitutas[skin["id"]] = skin
    usadas = set()
    for categoria in CATEGORIAS:
        with open(os.path.join(SKINS, categoria, "manifest.json"), encoding="utf-8") as f:
            manifest = json.load(f)
        for skin in manifest["skins"]:
            if skin["id"] in substitutas:
                skin = substitutas[skin["id"]]
                usadas.add(skin["id"])
            names = []
            for part in skin["parts"]:
                name = part["name"]
                if name in seen:
                    raise SystemExit(f"peça repetida: {name}")
                seen.add(name)
                names.append(name)
                cx, cy, cz = center(part["bounds"])
                if categoria in MONTADAS:
                    ox, oy, oz = part["offset_do_pivo_do_skin"]
                    cx, cy, cz = round(cx + ox, 4), round(cy + oz, 4), round(cz - oy, 4)
                pivot = ""
                if part.get("animation_group") and categoria not in MONTADAS:
                    ox, oy, oz = part["offset_do_pivo_do_skin"]
                    pivot = f"\t\tpivot = {{ {round(ox, 4)}, {round(oz, 4)}, {round(-oy, 4)} }},\n"
                parts_lines.append(
                    f'\t["{name}"] = {{\n'
                    f'\t\tskinId = "{skin["id"]}",\n'
                    f'\t\tpapel = "{part["papel"]}",\n'
                    f'\t\ttipo = "{part["tipo"]}",\n'
                    f'\t\talpha = {float(part["alpha"])},\n'
                    f"\t\tcenter = {{ {cx}, {cy}, {cz} }},\n" + pivot + "\t},"
                )
            quoted = ", ".join(f'"{n}"' for n in names)
            for alias, original in APELIDOS.items():
                if original == skin["id"]:
                    by_skin_lines.append(f'\t["{alias}"] = {{ {quoted} }},')
            by_skin_lines.append(f'\t["{skin["id"]}"] = {{ {quoted} }},')

    sobrando = set(substitutas) - usadas
    if sobrando:
        raise SystemExit(f"skins substitutas sem original: {sorted(sobrando)}")

    text = (
        HEADER
        + "\nlocal PARTS: { [string]: PartInfo } = {\n"
        + "\n".join(parts_lines)
        + "\n}\n\nlocal PARTS_BY_SKIN: { [string]: { string } } = {\n"
        + "\n".join(by_skin_lines)
        + "\n}\n\nreturn table.freeze({\n\tPARTS = table.freeze(PARTS),\n\tPARTS_BY_SKIN = table.freeze(PARTS_BY_SKIN),\n})\n"
    )
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(f"{len(by_skin_lines)} skins, {len(parts_lines)} peças -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
