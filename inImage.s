# Nytt test under:
# Fgets har parametrar (buffert, antal, fil)
# stdin -> Tangentbordet

.data 
buffer:
    .space 1024 # Reservera plats för inmatningsbufferten (1024 bytes, kan väl ändra om man vill??)
buffer_pointer:
    .byte 0

.text
.global inImage 
inImage:
    movq $buffer, %rdi
    movq $5, %rsi
    movq stdin, %rdx
    call fgets

    # Nollställa buffer_pointer
    movb $0, buffer_pointer

    ret


