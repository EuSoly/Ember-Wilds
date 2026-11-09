"""Edições do artista preservadas após a construção procedural das caixas."""
import json
from functools import lru_cache
from pathlib import Path
import bpy
from mathutils import Vector

@lru_cache(maxsize=1)
def load_edits():
    path=Path(__file__).parent/'caixas'/'ajustes-elize.json'
    return json.loads(path.read_text(encoding='utf8'))['skins']

def apply_edits(caixa):
    for edit in load_edits().get(caixa.name,[]):
        name=caixa.name+'_'+edit['piece']
        obj=caixa.coll.objects.get(name)
        if obj is None:
            raise ValueError(f'Peça editada pelo artista não encontrada: {name}; revisar os ajustes antes de exportar.')
        if edit.get('remove'):
            bpy.data.objects.remove(obj,do_unlink=True)
        else:
            obj.location+=Vector(edit['translate'])
