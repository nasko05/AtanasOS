org 0x7c00
bits 16

%define ENDL 0x0d, 0x0a

start:
    jmp main

;
;   Function prints character to screen until it encounters a NULL character
;   Params:
;       ds:si - points to string
;
puts:
;Save registers we will modify
    push si
    push ax
.loop:
    lodsb               ;Loads the byte at ds:si into al and increments si
    or al, al           ;Check is al is null
    jz .done            ;If al is null, we are done

    mov ah, 0x0e        ;BIOS teletype function (Serial communication)
    ;ah is used to store the interrupt number
    mov bh, 0x00        ;Page number
    int 0x10            ;Call the BIOS
    jmp .loop           ;repeat until null character
.done:
    pop ax
    pop si
    ret

;For now just block the operating system
main:
    ;code segment is already set up
    mov ax, 0   ; can't write to ds/es directly
    ;setup the data segment
    mov ds, ax
    ;setup extra space segment
    mov es, ax

    ;setup the stack
    mov ss, ax
    mov sp, 0x7c00  ;stack grows downwards from where we are loaded in memory
    ;meaning that the memory value is going to decrease as we push things onto the stack

    mov si, msg_hello
    call puts

    hlt
;creating the halt label to prevent the assembler from complaining

.halt:
    jmp .halt

msg_hello: db 'Hello from AtanasOS!', ENDL, 0

times 510-($-$$) db 0

dw 0AA55H
