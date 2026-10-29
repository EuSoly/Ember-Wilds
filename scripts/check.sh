#!/usr/bin/env bash
# Verificação completa do projeto: formatação, lint, build, tipos e testes.
# Uso (na raiz do repo, Git Bash): bash scripts/check.sh
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

# Pacotes do Wally: instala só se faltar. O wally-package-types reescreve os
# arquivos de link para o luau-lsp entender os tipos, e só pode rodar uma vez
# depois de cada `wally install` (numa segunda vez ele falha).
FRESH_PACKAGES=0
if [ ! -d Packages ]; then
	echo "== Wally (instalando pacotes)"
	wally install
	FRESH_PACKAGES=1
fi

echo "== Blink (gerando código de rede)"
blink net/game > /dev/null

echo "== StyLua (formatação)"
stylua --check src tests

echo "== selene (lint)"
selene src tests

echo "== Rojo build"
mkdir -p build
rojo build -o build/check.rbxlx

echo "== luau-lsp (tipos)"
rojo sourcemap default.project.json -o sourcemap.json
if [ "$FRESH_PACKAGES" = 1 ]; then
	wally-package-types --sourcemap sourcemap.json Packages/ > /dev/null
fi
DEFS=.luau-lsp/globalTypes.d.luau
if [ ! -f "$DEFS" ]; then
	mkdir -p .luau-lsp
	curl -sSfL -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=@roblox="$DEFS" src

echo "== Testes (Lune)"
lune run tests/run
