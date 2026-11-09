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
    for categoria in CATEGORIAS:
        with open(os.path.join(SKINS, categoria, "manifest.json"), encoding="utf-8") as f:
            manifest = json.load(f)
        for skin in manifest["skins"]:
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
                parts_lines.append(
                    f'\t["{name}"] = {{\n'
                    f'\t\tskinId = "{skin["id"]}",\n'
                    f'\t\tpapel = "{part["papel"]}",\n'
                    f'\t\ttipo = "{part["tipo"]}",\n'
                    f'\t\talpha = {float(part["alpha"])},\n'
                    f"\t\tcenter = {{ {cx}, {cy}, {cz} }},\n"
                    "\t},"
                )
            quoted = ", ".join(f'"{n}"' for n in names)
            for alias, original in APELIDOS.items():
                if original == skin["id"]:
                    by_skin_lines.append(f'\t["{alias}"] = {{ {quoted} }},')
            by_skin_lines.append(f'\t["{skin["id"]}"] = {{ {quoted} }},')

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
