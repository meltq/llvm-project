# REQUIRES: loongarch
# RUN: rm -rf %t && split-file %s %t

## LoongArch psABI doesn't specify TLS relaxation. It can be handled the same way as gcc:
## (a) code sequence can be converted from `pcalau12i+addi.[wd]` to `pcaddi`.
## (b) dynamic relocations can be omitted for LD->LE relaxation.

# RUN: llvm-mc --filetype=obj --triple=loongarch32 --position-independent %t/a.s -o %t/a.32.o
# RUN: llvm-mc --filetype=obj --triple=loongarch32 --position-independent -mattr=+relax %t/a.s -o %t/a.32.relax.o
# RUN: llvm-mc --filetype=obj --triple=loongarch32 %t/tga.s -o %t/tga.32.o
# RUN: llvm-mc --filetype=obj --triple=loongarch64 --position-independent %t/a.s -o %t/a.64.o
# RUN: llvm-mc --filetype=obj --triple=loongarch64 --position-independent -mattr=+relax %t/a.s -o %t/a.64.relax.o
# RUN: llvm-mc --filetype=obj --triple=loongarch64 %t/tga.s -o %t/tga.64.o

## LA32 LD
# RUN: ld.lld -shared %t/a.32.o -o %t/ld.32.so
# RUN: llvm-readobj -r %t/ld.32.so | FileCheck --check-prefix=LD32-REL %s
# RUN: llvm-readelf -x .got %t/ld.32.so | FileCheck --check-prefix=LD32-GOT %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/ld.32.so | FileCheck --check-prefixes=LD32 %s
# RUN: ld.lld -shared %t/a.32.relax.o -o %t/ld.32.relax.so
# RUN: llvm-objdump -d --no-show-raw-insn %t/ld.32.relax.so | FileCheck --check-prefixes=LD32-RELAX %s

## LA32 LD -> LE
# RUN: ld.lld %t/a.32.o %t/tga.32.o -o %t/le.32
# RUN: llvm-readelf -r %t/le.32 | FileCheck --check-prefix=NOREL %s
# RUN: llvm-readelf -x .got %t/le.32 | FileCheck --check-prefix=LE32-GOT %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/le.32 | FileCheck --check-prefixes=LE32 %s
# RUN: ld.lld %t/a.32.relax.o %t/tga.32.o -o %t/le.32.relax
# RUN: llvm-readelf -x .got %t/le.32.relax | FileCheck --check-prefix=LE32-GOT-RELAX %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/le.32.relax | FileCheck --check-prefixes=LE32-RELAX %s

## LA64 LD
# RUN: ld.lld -shared %t/a.64.o -o %t/ld.64.so
# RUN: llvm-readobj -r %t/ld.64.so | FileCheck --check-prefix=LD64-REL %s
# RUN: llvm-readelf -x .got %t/ld.64.so | FileCheck --check-prefix=LD64-GOT %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/ld.64.so | FileCheck --check-prefixes=LD64 %s
# RUN: ld.lld -shared %t/a.64.relax.o -o %t/ld.64.relax.so
# RUN: llvm-objdump -d --no-show-raw-insn %t/ld.64.relax.so | FileCheck --check-prefixes=LD64-RELAX %s

## LA64 LD -> LE
# RUN: ld.lld %t/a.64.o %t/tga.64.o -o %t/le.64
# RUN: llvm-readelf -r %t/le.64 | FileCheck --check-prefix=NOREL %s
# RUN: llvm-readelf -x .got %t/le.64 | FileCheck --check-prefix=LE64-GOT %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/le.64 | FileCheck --check-prefixes=LE64 %s
# RUN: ld.lld %t/a.64.relax.o %t/tga.64.o -o %t/le.64.relax
# RUN: llvm-readelf -x .got %t/le.64.relax | FileCheck --check-prefix=LE64-GOT-RELAX %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/le.64.relax | FileCheck --check-prefixes=LE64-RELAX %s

## a@dtprel = st_value(a) = 0 is a link-time constant.
# LD32-REL:      .rela.dyn {
# LD32-REL-NEXT:   0x20280 R_LARCH_TLS_DTPMOD32 - 0x0
# LD32-REL-NEXT: }
# LD32-GOT:      section '.got':
# LD32-GOT-NEXT: 0x00020280 00000000 00000000

# LD64-REL:      .rela.dyn {
# LD64-REL-NEXT:   0x20400 R_LARCH_TLS_DTPMOD64 - 0x0
# LD64-REL-NEXT: }
# LD64-GOT:      section '.got':
# LD64-GOT-NEXT: 0x00020400 00000000 00000000 00000000 00000000

## LA32: &DTPMOD(a) - . = 0x20280 - 0x101cc: 0x10 pages, page offset 0x280
# LD32:      101cc: pcalau12i $a0, 16
# LD32-NEXT:        addi.w $a0, $a0, 640
# LD32-NEXT:        bl 44

## LA64: &DTPMOD(a) - . = 0x20400 - 0x102e0: 0x10 pages, page offset 0x400
# LD64:      102e0: pcalau12i $a0, 16
# LD64-NEXT:        addi.d $a0, $a0, 1024
# LD64-NEXT:        bl 40

## LA32: &DTPMOD(a) - . = 0x20280 - 0x101cc = 16429<<2
# LD32-RELAX:      101cc: pcaddi  $a0, 16429
# LD32-RELAX-NEXT:        bl 48

## LA64: &DTPMOD(a) - . = 0x20400 - 0x102e0 = 16456<<2
# LD64-RELAX:      102e0: pcaddi  $a0, 16456
# LD64-RELAX-NEXT:        bl 44

# NOREL: no relocations

## a is local - its DTPMOD/DTPREL slots are link-time constants.
## a@dtpmod = 1 (main module)
# LE32-GOT: section '.got':
# LE32-GOT-NEXT: 0x00030120 01000000 00000000

# LE64-GOT: section '.got':
# LE64-GOT-NEXT: 0x000301d8 01000000 00000000 00000000 00000000

# LE32-GOT-RELAX: section '.got':
# LE32-GOT-RELAX-NEXT: 0x0003011c 01000000 00000000

# LE64-GOT-RELAX: section '.got':
# LE64-GOT-RELAX-NEXT: 0x000301d0 01000000 00000000 00000000 00000000

## LA32: DTPMOD(.LANCHOR0) - . = 0x30120 - 0x20114: 0x10 pages, page offset 0x120
# LE32:      20114: pcalau12i $a0, 16
# LE32-NEXT:        addi.w $a0, $a0, 288
# LE32-NEXT:        bl 4

## LA64: DTPMOD(.LANCHOR0) - . = 0x301d8 - 0x201c8: 0x10 pages, page offset 0x1d8
# LE64:      201c8: pcalau12i $a0, 16
# LE64-NEXT:        addi.d $a0, $a0, 472
# LE64-NEXT:        bl 4

## LA32: DTPMOD(.LANCHOR0) - . = 0x3011c - 0x20114 = 16386<<2
# LE32-RELAX:      20114: pcaddi $a0, 16386
# LE32-RELAX-NEXT:        bl 4

## LA64: DTPMOD(.LANCHOR0) - . = 0x301d0 - 0x201c8 = 16386<<2
# LE64-RELAX:      201c8: pcaddi $a0, 16386
# LE64-RELAX-NEXT:        bl 4


#--- a.s
la.tls.ld $a0, .LANCHOR0
bl %plt(__tls_get_addr)

.section .tbss,"awT",@nobits
.set .LANCHOR0, . + 0
.zero 8

#--- tga.s
.globl __tls_get_addr
__tls_get_addr:
