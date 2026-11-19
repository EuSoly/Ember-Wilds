"""Executar com Blender -b --factory-startup -P este_script."""
from math import pi, radians, sin
from pathlib import Path

import bpy


PASTA = Path(__file__).resolve().parent / "roblox" / "primeira_leva"
bpy.ops.wm.open_mainfile(filepath=str(PASTA / "primeira-leva-editavel.blend"))
cena = bpy.context.scene
cena.name = "Primeira leva · animações"
cena.render.fps = 24
cena.frame_start, cena.frame_end = 1, 145
for quadro, nome in [(1, "Repouso"), (49, "Deslocamento"), (81, "Parada"),
                     (89, "Revelar caixa"), (105, "Consultar livro"), (145, "Repouso")]:
    cena.timeline_markers.new(nome, frame=quadro)


def girar(nome, eixo, chaves):
    obj = bpy.data.objects[nome]
    for quadro, graus in chaves:
        obj.rotation_euler[eixo] = radians(graus)
        obj.keyframe_insert(data_path="rotation_euler", index=eixo, frame=quadro)


def brilho(nome, objetos, chaves):
    # Um controle por região. Cópias locais preservam os materiais compartilhados.
    objetos = list(objetos)
    assert objetos, nome
    ctrl = objetos[0].parent
    ctrl[nome] = chaves[0][1]
    ctrl.id_properties_ui(nome).update(min=0, max=5)
    materiais = {}
    for obj in objetos:
        original = obj.active_material
        if original not in materiais:
            mat = original.copy()
            mat.name = f"{ctrl.name}_{nome}_{original.name}"
            bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            driver = bsdf.inputs["Emission Strength"].driver_add("default_value").driver
            driver.type = "AVERAGE"
            alvo = driver.variables.new().targets[0]
            alvo.id = ctrl
            alvo.data_path = f'["{nome}"]'
            materiais[original] = mat
        obj.material_slots[obj.active_material_index].link = "OBJECT"
        obj.active_material = materiais[original]
    for quadro, valor in chaves:
        ctrl[nome] = valor
        ctrl.keyframe_insert(data_path=f'["{nome}"]', frame=quadro)


def objetos_neon(colecao):
    return [o for o in bpy.data.collections[colecao].objects
            if o.active_material and "neon" in o.active_material.name]


for i in range(1, 11):
    lado = 1 if i <= 5 else -1
    fase = (i - 1) * 2 * pi / 10
    chaves = [(f, 5 * sin(2*pi*(f-1)/48 + fase)) for f in range(1, 50, 4)]
    for f in (55, 61, 67, 73, 80):
        chaves.append((f, lado * (12 + 3*sin((f-49)*pi/12))))
    descanso = chaves[0][1]
    chaves.extend([(86, -3*lado), (94, descanso), (145, descanso)])
    girar(f"CTRL_lula_tentaculo_{i:02d}", 2, chaves)
    if i in (2, 9):
        girar(f"CTRL_lula_ponta_{i:02d}", 2,
              [(1, 0), (49, 0), (59, lado*8), (82, lado*8), (90, -lado*4), (98, 0), (145, 0)])

girar("Raiz_kraken", 1, [(1, 0), (89, 0), (94, 6), (99, -3), (104, 0)])
girar("Raiz_aventureiro", 1, [(1, 0), (89, 0), (92, -5), (97, 3), (103, 0)])
girar("Raiz_explorador", 0, [(1, 0), (105, 0), (112, 7), (130, 7), (141, 0)])
girar("CTRL_bussola_agulha", 2, [(1, 0), (105, 0), (112, -34), (118, -28),
                                 (134, -28), (144, 0)])
for i in (1, 2):
    ctrl = bpy.data.objects[f"CTRL_jardim_semente_{i:02d}"]
    brilho("brilho", ctrl.children, [(1, .3), (10+i*4, 2.4), (30+i*4, .3),
                                     (88+i*4, .3), (94+i*4, 2.4), (106+i*4, .3)])

def particula(origem, inicio, duracao, raio, deslocamento, cor):
    # Geometria de referência para o animador. No Studio, o marcador vira Attachment.
    ancora = bpy.data.objects["ORIGEM_" + origem]
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=raio)
    obj = bpy.context.object
    obj.name = f"PREVIA_FX_{origem}_{inicio}"
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    ancora.users_collection[0].objects.link(obj)
    obj.parent = ancora
    mat = bpy.data.materials.get("FX_" + origem) or bpy.data.materials.new("FX_" + origem)
    mat.diffuse_color = (*cor, 1)
    mat.use_nodes = True
    shader = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = (*cor, 1)
    shader.inputs["Emission Color"].default_value = (*cor, 1)
    shader.inputs["Emission Strength"].default_value = 1.2
    obj.data.materials.append(mat)
    for f, escala in [(inicio-1, 0), (inicio+2, 1), (inicio+duracao-3, .75), (inicio+duracao, 0)]:
        obj.scale = (escala,)*3
        obj.keyframe_insert(data_path="scale", frame=f)
    for f, loc in [(inicio, (0, 0, 0)), (inicio+duracao, deslocamento)]:
        obj.location = loc
        obj.keyframe_insert(data_path="location", frame=f)


for i in range(3):
    particula("cartografo_poeira", 81+2*i, 13, .08,
              ((i-1)*.38, -.45, .24), (.63, .41, .18))
    # Todos se apagam no frame 134 para que a rota completa possa ser lida.
    particula(f"bussola_rota_{i+1:02d}", 118+4*i, 16-4*i, .065,
              (0, 0, 0), (1, .68, .14))

cena.frame_set(1)
bpy.ops.object.select_all(action="DESELECT")
bpy.context.view_layer.objects.active = None
bpy.data.texts.load(str(PASTA / "ANIMACOES.md"))
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(PASTA / "primeira-leva-animacao.blend"))
