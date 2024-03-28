section .multiboot_header
header_start:
    ; magic number
    dd 0xe85250d6 ; multiboot2 magic number
    ; architecture
    dd 0x00000000 ; architecture i386(protectedc mode)
    dd header_end - header_start ; header length
    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0x00000000 + (header_end - header_start))

    dw 0
    dw 0
    dd 8
header_end: