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
├── defs.h            declaración de vmprint()
├── memlayout.h       USYSCALL y struct usyscall
├── proc.h            campo usyscall en struct proc
├── proc.c            reservar, mapear, desmapear y liberar USYSCALL; límite de growproc()
├── syscall.h         números de vmprint y pgaccess
├── syscall.c         registro de vmprint y pgaccess
├── sysproc.c         sys_vmprint, sys_pgaccess y límite de sys_sbrk()
└── vm.c              implementación de vmprint() y vmprint_walk()
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

La llamada al sistema `vmprint()` recorre e imprime recursivamente la tabla de
páginas Sv39 del proceso actual en sus tres niveles (directorios de nivel 2 y 1,
y páginas hoja de nivel 0).

### Implementación

- **Función recursiva auxiliar (`vmprint_walk` en `kernel/vm.c`):**
  Recibe la tabla a inspeccionar, el nivel actual (`level = 2, 1, 0`) y la
  dirección virtual base acumulada (`base_va`).
  - Itera sobre las 512 entradas (`pte_t`) de la tabla.
  - Filtra únicamente las entradas válidas (`pte & PTE_V`).
  - Reconstruye la dirección virtual representativa de cada entrada desplazando
    el índice según el nivel: `va = base_va | ((uint64)i << PXSHIFT(level))`.
  - Imprime la línea con la indentación requerida:
    - Nivel 2: ` ..<va>: pte <pte> pa <pa>`
    - Nivel 1: ` .. ..<va>: pte <pte> pa <pa>`
    - Nivel 0 (hojas): ` .. .. ..<va>: pte <pte> pa <pa>`
  - Si la entrada no es hoja (`(pte & (PTE_R | PTE_W | PTE_X)) == 0`), obtiene la
    dirección física de la subtabla hija con `PTE2PA(pte)` y desciende
    recursivamente con `level - 1`.
- **Punto de entrada (`vmprint` en `kernel/vm.c`):**
  Imprime la cabecera `page table <pagetable>` e inicia el recorrido recursivo
  en el nivel 2 con dirección base 0.
- **Llamada al sistema (`sys_vmprint` en `kernel/sysproc.c`):**
  Obtiene la tabla del proceso llamante con `myproc()->pagetable`, ejecuta
  `vmprint(myproc()->pagetable)` y retorna 0.

# Parte C: pgaccess()

_Pendiente._

---

# Preguntas

### 1. Explicación de la salida de `vmprint()`

Salida real obtenida durante la ejecución de la prueba `vmprint`:

```text
page table 0x0000000087f23000
 ..0x0000000000000000: pte 0x0000000021fd2001 pa 0x0000000087f48000
 .. ..0x0000000000000000: pte 0x0000000021fd0401 pa 0x0000000087f41000
 .. .. ..0x0000000000000000: pte 0x0000000021fc9c5b pa 0x0000000087f27000
 .. .. ..0x0000000000001000: pte 0x0000000021fc985b pa 0x0000000087f26000
 .. .. ..0x0000000000002000: pte 0x0000000021fc94d7 pa 0x0000000087f25000
 .. .. ..0x0000000000003000: pte 0x0000000021fd1407 pa 0x0000000087f45000
 .. .. ..0x0000000000004000: pte 0x0000000021fd08d7 pa 0x0000000087f42000
 .. .. ..0x0000000000008000: pte 0x000000002073b8d7 pa 0x0000000081cee000
 ..0x0000003fc0000000: pte 0x0000000021fca001 pa 0x0000000087f28000
 .. ..0x0000003fffe00000: pte 0x0000000021fd1c01 pa 0x0000000087f47000
 .. .. ..0x0000003fffffd000: pte 0x0000000021fc9013 pa 0x0000000087f24000
 .. .. ..0x0000003fffffe000: pte 0x0000000021fca4c7 pa 0x0000000087f29000
 .. .. ..0x0000003ffffff000: pte 0x000000002000184b pa 0x0000000080006000
```

**Interpretación de cada línea:**

1. `page table 0x0000000087f23000`:
   Dirección física de la página raíz de la tabla de páginas del proceso (nivel 2).

2. **Subárbol de espacio de usuario bajo (`va = 0x0`):**
   - `..0x0000000000000000: pte 0x...21fd2001 pa 0x...87f48000`:
     Entrada 0 de nivel 2. Apunta a la página de directorio de nivel 1 en `0x87f48000`.
   - `.. ..0x0000000000000000: pte 0x...21fd0401 pa 0x...87f41000`:
     Entrada 0 de nivel 1. Apunta a la página de tabla de nivel 0 (hojas) en `0x87f41000`.
   - `.. .. ..0x0000000000000000` y `.. .. ..0x0000000000001000`:
     Páginas de código del programa (`text`), con banderas `PTE_R | PTE_X | PTE_U` (flags `0x5b`).
   - `.. .. ..0x0000000000002000`:
     Página de datos globales y bss del programa, con permisos `PTE_R | PTE_W | PTE_U` (flags `0xd7`).
   - `.. .. ..0x0000000000003000`:
     Página de guarda (guard page) situada justo debajo del stack. No tiene el bit `PTE_U` (flags `0x07`), de modo que si el stack desborda hacia abajo, la CPU genera un fallo de página y el proceso termina.
   - `.. .. ..0x0000000000004000`:
     Página del stack de usuario, con permisos `PTE_R | PTE_W | PTE_U` (flags `0xd7`).
   - `.. .. ..0x0000000000008000`:
     Página del heap del proceso asignada mediante lazy allocation que fue accedida (`a[3 * PGSIZE] = 1`). Nótese que las páginas intermedias (`0x5000`, `0x6000`, `0x7000`) no aparecen porque al ser perezosas nunca se tocaron y por tanto no tienen memoria física asociada.

3. **Subárbol de espacio de usuario alto (`va = 0x3fc0000000`):**
   - `..0x0000003fc0000000: pte 0x...21fca001 pa 0x...87f28000`:
     Entrada 255 de nivel 2 (`255 << 30 = 0x3fc0000000`). Apunta a tabla de nivel 1 en `0x87f28000`.
   - `.. ..0x0000003fffe00000: pte 0x...21fd1c01 pa 0x...87f47000`:
     Entrada 511 de nivel 1 (`511 << 21 = 0x3fe00000`). Apunta a la tabla de hojas en `0x87f47000`.
   - `.. .. ..0x0000003fffffd000`:
     Página compartida `USYSCALL` con banderas `PTE_V | PTE_R | PTE_U` (flags `0x13`). Contiene el pid del proceso de solo lectura.
   - `.. .. ..0x0000003fffffe000`:
     Página `TRAPFRAME` con permisos `PTE_R | PTE_W` (flags `0xc7`, sin `PTE_U`, accesible solo por supervisor). Guarda el contexto de registros de usuario durante interrupciones y llamadas al sistema.
   - `.. .. ..0x0000003ffffff000`:
     Página `TRAMPOLINE` con permisos `PTE_R | PTE_X` (flags `0x4b`, sin `PTE_U`). Contiene el código de salto entre usuario y kernel.

2. _Pendiente._
3. _Pendiente._
4. _Pendiente._
5. _Pendiente._

---

# Decisiones de diseño

_Pendiente._

# Limitaciones conocidas

_Pendiente._
