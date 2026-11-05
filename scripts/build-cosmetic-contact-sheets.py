# Monta as pranchas (dia) de acessórios, mochilas, livros e caixas no mesmo estilo das skins.
# Executar a partir da raiz do projeto, depois de scripts/catalog-cosmetic-references.mjs.
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE = Path("assets/skins/reference")
COLS, ROWS, CELL, LABEL = 9, 8, 120, 24
BG = (32, 36, 43, 255)
try:
    FONT = ImageFont.truetype("arial.ttf", 14)
except OSError:
    FONT = ImageFont.load_default()

for folder in ["acessorios", "mochilas", "livros", "caixas"]:
    root = BASE / folder
    catalog = json.loads((root / "catalog.json").read_text(encoding="utf8"))
    items = [i for i in catalog["items"] if any(a["variant"] == "day" for a in i["assets"])]
    for old in root.glob("contact-sheet-*.png"):
        old.unlink()
    per_sheet = COLS * ROWS
    for n, start in enumerate(range(0, len(items), per_sheet), 1):
        chunk = items[start:start + per_sheet]
        rows = (len(chunk) + COLS - 1) // COLS
        sheet = Image.new("RGBA", (COLS * CELL, rows * CELL), BG)
        draw = ImageDraw.Draw(sheet)
        for k, item in enumerate(chunk):
            x, y = (k % COLS) * CELL, (k // COLS) * CELL
            day = next(a for a in item["assets"] if a["variant"] == "day")
            im = Image.open(root / day["file"]).convert("RGBA")
            im.thumbnail((CELL - 16, CELL - LABEL - 8), Image.LANCZOS)
            sheet.alpha_composite(im, (x + (CELL - im.width) // 2, y + 4 + (CELL - LABEL - 8 - im.height) // 2))
            draw.text((x + 16, y + CELL - LABEL), f"ID {item['id']}", fill=(235, 235, 235, 255), font=FONT)
        sheet.save(root / f"contact-sheet-{n}.png")
        print(folder, n, chunk[0]["id"], chunk[-1]["id"])

# Mãos: cada célula mostra a skin de corpo (esquerda) e a mão dela (direita), com o mesmo ID.
HCELL_W, HCOLS, HROWS = 160, 8, 8
hands_root = BASE / "maos"
if (hands_root / "catalog.json").exists():
    hands = {i["id"]: i for i in json.loads((hands_root / "catalog.json").read_text(encoding="utf8"))["items"]}
    skins = json.loads((BASE / "catalog.json").read_text(encoding="utf8"))["skins"]
    ids = sorted({s["id"] for s in skins} | set(hands))
    skin_by_id = {s["id"]: s for s in skins}
    for old in hands_root.glob("contact-sheet-*.png"):
        old.unlink()
    per_sheet = HCOLS * HROWS
    for n, start in enumerate(range(0, len(ids), per_sheet), 1):
        chunk = ids[start:start + per_sheet]
        rows = (len(chunk) + HCOLS - 1) // HCOLS
        sheet = Image.new("RGBA", (HCOLS * HCELL_W, rows * CELL), BG)
        draw = ImageDraw.Draw(sheet)
        for k, sid in enumerate(chunk):
            x, y = (k % HCOLS) * HCELL_W, (k // HCOLS) * CELL
            box_h = CELL - LABEL - 8
            for side, (root, item) in enumerate([(BASE, skin_by_id.get(sid)), (hands_root, hands.get(sid))]):
                cx = x + 6 + side * 76
                if item is None:
                    draw.text((cx + 22, y + box_h // 2), "—", fill=(150, 150, 150, 255), font=FONT)
                    continue
                day = next(a for a in item["assets"] if a["variant"] == "day")
                im = Image.open(root / day["file"]).convert("RGBA")
                im.thumbnail((70 if side == 0 else 44, box_h), Image.LANCZOS)
                sheet.alpha_composite(im, (cx + (70 - im.width) // 2, y + 4 + (box_h - im.height) // 2))
            draw.text((x + 16, y + CELL - LABEL), f"ID {sid}", fill=(235, 235, 235, 255), font=FONT)
        sheet.save(hands_root / f"contact-sheet-{n}.png")
        print("maos", n, chunk[0], chunk[-1])
