# Proyecto de Sistemas Operativos
## Proyecto 3: Tablas de páginas en acción

### Integrantes

- Pablo Alvarez Restrepo
- Jose Andres Mendoza Hernandez
- Sara Ruiz Ospina

### Curso

Sistemas Operativos

### Semestre

2026-2

---

# Descripción

Este proyecto agrega a xv6 (commit `06aad25`) tres mecanismos que usan la
tabla de páginas de cada proceso:

- **Parte A.** Una página de solo lectura, `USYSCALL`, que el kernel mapea en
  cada proceso justo debajo del trapframe. Guarda el pid, así que
  `ugetpid()` lo lee de la memoria sin hacer una llamada al sistema.
- **Parte B.** La llamada `vmprint()`, que imprime la tabla de páginas del
  proceso en sus tres niveles.
- **Parte C.** La llamada `pgaccess()`, que informa qué páginas de un rango se
  leyeron o escribieron desde la última consulta, usando el bit `PTE_A`.

---

# Estructura de archivos

El repositorio contiene solo los archivos de xv6 que se modificaron o se
agregaron, en la misma ruta que tienen dentro de xv6.

```text
Makefile              pgtbltest agregado a UPROGS
kernel/
├── memlayout.h       USYSCALL y struct usyscall
├── syscall.h         números de vmprint y pgaccess
├── syscall.c         registro de vmprint y pgaccess
└── sysproc.c         sys_vmprint y sys_pgaccess
user/
├── ulib.c            ugetpid()
├── user.h            declaraciones de ugetpid, vmprint y pgaccess
├── usys.pl           entradas de vmprint y pgaccess
├── pgtbltest.c       pruebas del curso
└── usertests.c       versión del curso de usertests
ejecutar_pruebas.py   script del curso que genera la evidencia
probar.sh             copia los archivos sobre un xv6 limpio y corre las pruebas
pruebas/              evidencia generada por ejecutar_pruebas.py
```

---

# Integración con xv6

## Paso 1. Obtener xv6 en el commit base

```bash
git clone https://github.com/mit-pdos/xv6-riscv.git
cd xv6-riscv
git switch -c proyecto3 06aad25
```

## Paso 2. Copiar los archivos

Copiar `Makefile`, `ejecutar_pruebas.py` y las carpetas `kernel/` y `user/` de
este repositorio sobre la carpeta de xv6, reemplazando los archivos que ya
existen.

## Paso 3. Compilar y ejecutar

```bash
make qemu
```

Dentro de xv6: `pgtbltest` y `usertests -q`.

## Atajo: probar.sh

Desde WSL o Linux, en la carpeta de este repositorio, `bash probar.sh` hace los
pasos 1 a 3 en `~/proyecto3-xv6`, corre las dos suites y copia la evidencia a
`pruebas/`. También acepta `pgtbltest`, `usertests` o `qemu` como argumento.

xv6 no compila en una ruta con espacios (por ejemplo `C:\Users\Sara Ruiz\...`),
por eso el script compila en el directorio personal de WSL.

---

# Parte A: página compartida y ugetpid()

_Pendiente._

# Parte B: vmprint()

_Pendiente._

# Parte C: pgaccess()

_Pendiente._

---

# Preguntas

1. _Pendiente._
2. _Pendiente._
3. _Pendiente._
4. _Pendiente._
5. _Pendiente._

---

# Decisiones de diseño

_Pendiente._

# Limitaciones conocidas

_Pendiente._

---

# Declaración de uso de IA

_Pendiente._
