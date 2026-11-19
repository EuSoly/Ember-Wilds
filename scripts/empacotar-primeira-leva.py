"""Monta o ZIP para Studio a partir das artes e dos FBX já exportados."""
from importlib import util
from pathlib import Path
from tempfile import TemporaryDirectory
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
modelos = root / "assets/skins/roblox/primeira_leva"
arte = root / "assets/ui/shop/bundles"
colecoes = ("mare_profunda", "bosque_desperto", "norte_perdido")
camadas = ("fundo", "personagem", "caixa", "mochila", "livro", "particula", "ambiente")


def objeto(pai, classe, nome):
    item = ET.SubElement(pai, "Item", {"class": classe})
    props = ET.SubElement(item, "Properties")
    ET.SubElement(props, "string", name="Name").text = nome
    if classe == "StringValue":
        ET.SubElement(props, "string", name="Value")
    return item


with TemporaryDirectory() as temp:
    tmp = Path(temp)
    xml = ET.Element("roblox", version="4")
    pasta = objeto(xml, "Folder", "ArteBundles")
    for slug in colecoes:
        entrada = objeto(pasta, "Folder", slug)
        for nome in camadas:
            objeto(entrada, "StringValue", nome)
    ET.indent(xml)
    ET.ElementTree(xml).write(tmp / "ArteBundles.rbxmx", encoding="utf-8", xml_declaration=True)
    spec = util.spec_from_file_location("gerador", root / "scripts/gen-skin-manifest.py")
    gerador = util.module_from_spec(spec)
    spec.loader.exec_module(gerador)
    gerador.OUT = str(tmp / "SkinManifest.luau")
    if "primeira_leva" not in gerador.SUBSTITUTAS:
        gerador.SUBSTITUTAS.append("primeira_leva")
    gerador.main()
    arquivo = modelos / "importar-primeira-leva.zip"
    with ZipFile(arquivo, "w", ZIP_DEFLATED) as z:
        for nome in ("IMPORTAR.md", "ANIMACOES.md", "pacotes.json"):
            z.write(modelos / nome, nome)
        for nome in ("manifest.json", "primeira_leva_palette.png", "skins-primeira_leva.fbx"):
            z.write(modelos / nome, "modelos/" + nome)
        z.write(tmp / "SkinManifest.luau", "modelos/SkinManifest.luau")
        z.write(root / "scripts/studio/import-skins.luau", "modelos/import-skins.luau")
        for module in ("src/shared/Models/CrateMotion.luau", "src/client/World/CrateAnimator.luau"):
            z.write(root / module, "modelos/codigo/" + Path(module).name)
        for f in sorted((modelos / "movimentos").glob("*.fbx")):
            z.write(f, "movimentos/" + f.name)
        z.write(tmp / "ArteBundles.rbxmx", "vitrine/ArteBundles.rbxmx")
        for nome in ("Featured.luau", "BundleBanner.luau"):
            z.write(root / "src/client/Menu/Shop" / nome, "vitrine/codigo/" + nome)
        for slug in colecoes:
            for nome in camadas:
                prefixo = "" if nome in ("fundo", "particula", "ambiente") else "loja-"
                z.write(arte / slug / (prefixo + nome + ".png"),
                        f"vitrine/imagens/{slug}/{slug}_{nome}.png")
    with ZipFile(arquivo) as z:
        assert z.testzip() is None
        assert len([f for f in z.namelist() if f.startswith("movimentos/")]) == 6
        assert len([f for f in z.namelist() if f.startswith("vitrine/imagens/")]) == len(colecoes) * len(camadas)
    print(arquivo)
