org 0x7c00
bits 16

%define ENDL 0x0d, 0x0a

;
;   FAT12 Headers
;

jmp short start
nop

bdm_oem:                        db "MSWIN4.1" ;8 bytes
bdm_bytes_per_sector:           dw 512
bdm_sectors_per_cluster:        db 1
bdm_reserved_sectors:           dw 1
bdm_file_allocation_tables:     db 2
bdm_root_dir_entries:           dw 0E0h
bdm_total_sectors:              dw 2880
bdm_media_descriptor:           db 0F0h
bdm_sectors_per_fat:            dw 9
bdm_sectors_per_track:          dw 18
bdm_heads:                      dw 2
bdm_hidden_sectors:             dd 0
bdm_total_sectors_big:          dd 0

;extended boot record
ebr_drive_number:               db 0
                                db 0    ;reserved
ebr_signature:                  db 29h
ebr_volume_id:                  db 12h, 24h, 36h, 48h
ebr_volume_label:               db "ATANAS   OS" ;11 bytes
ebr_system_id:                  db "FAT12   " ;8 bytes

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

    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                   ; LBA=1, second sector from disk
    mov cl, 1                   ; 1 sector to read
    mov bx, 0x7E00              ; data should be after the bootloader
    call disk_read

    mov si, msg_hello
    call puts

    cli
    hlt

;
;   Error handlers
;
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                 ; wait for key press
    jmp 0FFFFh:0            ; Jump to beginning of bios, effectively reboot system

;creating the halt label to prevent the assembler from complaining
.halt:
    cli
    hlt

;
;   Disk routines
;

;   Converts LBA to CHS
;   Params:
;   - ax - LBA
;   Returns:
;   - cx [bits 0 : 5]: sector number
;   - cx [bits 6 : 15]: cylinder number
;   - dh: head number
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdm_sectors_per_track]    ; ax = LBA / SPT
                                        ; dx = LBA % SPT
    inc dx                              ; dx = (LBA % SPT) + 1 (1-based indexing)
    mov cx, dx                          ; Set the ouput

    xor dx, dx                          ; Clear dx for second division
    div word [bdm_heads]                ; ax = (LBA / SPT) / HPC
                                        ; dx = (LBA / SPT) % HPC

    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder low 8 bits
    ;cx = ch (lower 8 bits) | cl (higher 8 bits)
    shl ah, 6                           ; ch = cylinder high 2 bits
    or cl, ah                           ; ch = cylinder

    pop ax
    mov dl, al
    pop ax
    ret

;   Reads sectors from disk
;   Params:
;   - ax: LBA address
;   - cl: numbers of sectors to read
;   - dl: drive number
;   - es:bx: memory address to store the data
;
disk_read:

    push ax             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx
    call lba_to_chs
    pop ax              ; AL = number of sectors to read

    mov ah, 02h
    mov di, 3           ; retry number
    
.retry:
    pusha               ; Save all registers
    stc                 ; Set the carry flag
    int 13h             ; Carry flag cleared on success
    jnc .done

    popa                ; Restore all values
    call disk_reset     ; Reset disk state if failed

    dec di
    test di, di
    jnz .retry

.fail:
    ;all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di             ; restore registers we modified
    pop dx
    pop cx
    pop bx
    pop ax

    ret

;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello:              db 'Hello from AtanasOS!', ENDL, 0
msg_read_failed:        db 'Reading from floppy failed!', ENDL, 0

times 510-($-$$)        db 0

dw 0AA55H
