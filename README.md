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
├── proc.h            campo usyscall en struct proc
├── proc.c            reservar, mapear, desmapear y liberar USYSCALL; límite de growproc()
├── syscall.h         números de vmprint y pgaccess
├── syscall.c         registro de vmprint y pgaccess
└── sysproc.c         sys_vmprint, sys_pgaccess y límite de sys_sbrk()
user/
├── ulib.c            ugetpid()
├── user.h            declaraciones de ugetpid, vmprint y pgaccess
├── usys.pl           entradas de vmprint y pgaccess
├── pgtbltest.c       pruebas del curso
└── usertests.c       versión del curso de usertests
ejecutar_pruebas.py   script del curso que genera la evidencia
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

---

# Parte A: página compartida y ugetpid()

Cada proceso tiene una página física propia, `p->usyscall`, mapeada en la
dirección virtual `USYSCALL` (`0x3fffffd000`), justo debajo de `TRAPFRAME`:

```text
0x3ffffff000  TRAMPOLINE   R X       (solo el kernel)
0x3fffffe000  TRAPFRAME    R W       (solo el kernel)
0x3fffffd000  USYSCALL     R     U   struct usyscall { int pid; }
     ...      heap (crece hasta USYSCALL como máximo)
```

| Paso | Dónde | Qué se hace |
|---|---|---|
| Reservar | `allocproc()` en `kernel/proc.c` | `kalloc()` de una página, `memset` a cero y `p->usyscall->pid = p->pid`. Se hace antes de `proc_pagetable()`, que necesita la página para mapearla. |
| Mapear | `proc_pagetable()` | `mappages(..., USYSCALL, ..., PTE_R \| PTE_U)`. Si falla, se desmapean `TRAPFRAME` y `TRAMPOLINE` antes de liberar la tabla. |
| Desmapear | `proc_freepagetable()` | `uvmunmap(pagetable, USYSCALL, 1, 0)`, sin liberar la página física. Sin esto, `freewalk()` entra en pánico (`freewalk: leaf`). |
| Liberar | `freeproc()` | `kfree(p->usyscall)`, igual que el trapframe. |
| Limitar el heap | `growproc()` y `sys_sbrk()` | El tope pasa de `TRAPFRAME` a `USYSCALL`, para que ni `sbrk()` ni `sbrklazy()` crezcan encima de la página. |
| Leer el pid | `ugetpid()` en `user/ulib.c` | Lee `((struct usyscall *)USYSCALL)->pid`, sin `ecall`. |

La página física pertenece a `struct proc` y no a la tabla de páginas. Por eso
`proc_freepagetable()` la desmapea con `do_free = 0` y la libera `freeproc()`.
`exec()` crea una tabla nueva con `proc_pagetable(p)`, que vuelve a mapear la
misma página, y luego destruye la vieja con `proc_freepagetable()`. Si esa
función liberara la página, el proceso perdería su pid después de `exec()`.

La página se llena de ceros porque el proceso puede leerla completa.
`kalloc()` la entrega con basura (el byte 5), y así lo que el proceso ve fuera
de `pid` es siempre cero.

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
