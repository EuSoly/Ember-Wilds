# Biblioteca de NPCs

O arquivo único continua sendo `rabbit/coelho-v1.blend`, ampliado após a aprovação do coelho.
Abra a cena `NPC_Catalog_23` para ver os 23 modelos. A cena `Rabbit_Prototype_v1` preserva a apresentação original do coelho.

Cada NPC está em uma coleção própria dentro de `NPCS | 23 models`, agrupada por bioma. A coleção `STUDIO | cameras lights labels` contém apenas a apresentação e não deve ser exportada para o jogo.

Modelos estáticos com formas baixas, contornos volumétricos e detalhes superiores. Não incluem rig, animações, colisores, LODs ou integração no Roblox. Os materiais são cores sólidas, sem dependências de texturas externas. A escala relativa é uma proposta visual.

## Conteúdo

- Floresta: Rabbit, Wolf, Spider, Boar, Hawk.
- Neve: Penguin, Arctic Fox, Polar Bear, Baby Mammoth, Mammoth, Baby Dragon, Dragon.
- Praia e oceano: Crab, King Crab, GMO Piranha, Kraken.
- Lava: Lava Monster, Baby Lava Dragon, Lava Dragon.
- Deserto: Vulture, Sandworm.
- Dourados: Golden Hen, Golden Chick.

Lista e referências: [Mobs — Starve.io Wiki](https://starveiopro.fandom.com/wiki/Mobs). As aves douradas também estão documentadas na [página de ideias antigas](https://starveiopro.fandom.com/wiki/Non_used_ideas_in_starve.io), que informa sua adição ao jogo. Firefly removido, Scorpion não lançado e transformações de jogador ficaram fora da coleção principal.

## Organização técnica

Z para cima, frente em -Y. Cada modelo possui um ROOT com origem no centro horizontal, ao nível do chão. As posições dos ROOTs servem para organizar a galeria. As partes têm origens próprias para facilitar edição. Para exportação individual, selecionar apenas a coleção do NPC e centralizar uma cópia do ROOT; converter os eixos para o destino no exportador.

`catalog.json` registra nomes, coleções, partes, triângulos e dimensões. As malhas foram verificadas quanto a bordas abertas, faces degeneradas e presença de materiais. Essa checagem não substitui testes após a futura importação no Roblox.

`build_catalog.py` documenta a construção inicial e exige que a cena de catálogo ainda não exista. Não executar por cima da coleção editada. `finalize_catalog.py` valida, organiza as origens, salva o mesmo arquivo e renderiza a visão geral em `build/previews/npcs-colecao-v1.png`.
