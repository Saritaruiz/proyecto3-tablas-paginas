#!/bin/bash
# probar.sh: copia los archivos del proyecto sobre un xv6 limpio
# (commit 06aad25), compila y corre las pruebas.
#
# Uso, desde WSL o Linux, en la carpeta del repositorio:
#   bash probar.sh              pgtbltest y usertests -q; guarda la evidencia en pruebas/
#   bash probar.sh pgtbltest    solo pgtbltest
#   bash probar.sh usertests    solo usertests -q
#   bash probar.sh qemu         compila y abre xv6 para probar a mano (salir: Ctrl-a x)
#
# El xv6 limpio queda en ~/proyecto3-xv6 (se cambia con XV6=/otra/ruta).
# No se compila dentro del repositorio porque el Makefile de xv6 falla
# cuando la ruta tiene espacios, como C:\Users\Sara Ruiz\...

set -e
REPO="$(cd "$(dirname "$0")" && pwd)"
XV6="${XV6:-$HOME/proyecto3-xv6}"
BASE=06aad25

if [ ! -d "$XV6/.git" ]; then
  git clone -q https://github.com/mit-pdos/xv6-riscv.git "$XV6"
  git -C "$XV6" switch -q -c proyecto3 "$BASE"
fi

# Volver a la versión limpia de xv6 y copiar encima los archivos del proyecto.
git -C "$XV6" checkout -q "$BASE" -- .
cd "$REPO"
cp Makefile ejecutar_pruebas.py "$XV6/"
cp kernel/* "$XV6/kernel/"
cp user/* "$XV6/user/"
cd "$XV6"

if [ "$1" = qemu ]; then
  exec make qemu
fi

# GIT_DIR hace que el encabezado de la evidencia muestre el commit del
# repositorio del grupo y no el de xv6.
set +e
GIT_DIR="$REPO/.git" python3 ejecutar_pruebas.py "$@"
resultado=$?
mkdir -p "$REPO/pruebas"
for n in ${@:-pgtbltest usertests}; do
  [ -f "pruebas/$n.txt" ] && cp "pruebas/$n.txt" "$REPO/pruebas/"
done
exit $resultado
