.section .text
.global _start
_start:
    li   sp, 0x400   /* stack top = end of 1 KB BRAM */
    call main
.hang:
    j    .hang
