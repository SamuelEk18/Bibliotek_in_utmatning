# Nytt test under:
# Fgets har parametrar (buffert, antal, fil)
# stdin -> Tangentbordet

.section .data
in_buffer:
    .space 1024 # Reservera inmatningsbufferten
in_buffer_pos:
    .quad 0

out_buffer:
    .space 1024 # Reservera utmatningsbuffert
out_buffer_pos:
    .quad 0

.section .text
.global inImage
inImage:
    pushq %rbp # pushar register ägda av den caller
    movq %rsp, %rbp # lägg registerna på stacken

    movq $in_buffer, %rdi # buffer address
    movl $1024, %esi # buffer strl
    movq $stdin, %rdx # stdin

    call fgets

    # Nollställa buffer position
    movb $0, in_buffer_pos

    /*återställ*/
    movq %rbp, %rsp
    popq %rbp
    ret

.global outImage
outImage:
    pushq %rbp # pushar register ägda av den caller
    movq %rsp, %rbp # lägg registerna på stacken

    movq $out_buffer, %rdi # buffer address

    call puts

    # Nollställa buffer position
    movq $0, out_buffer_pos

    /*återställ*/
    movq %rbp, %rsp
    popq %rbp
    ret

.global putText
putText:
    pushq %rbp # pushar register ägda av den caller
    movq %rsp, %rbp # lägg registerna på stacken

    movq $out_buffer, %rdi # buffer address
    movq %rsi, %rsi # ladda in värde

loop_in_putText:
    movb (%rsi), %al # läser en byte från text
    movb %al, (%rdi) # kopiera byten till buffern
    incq %rdi # öka addressen
    incq %rsi # ökar till nästa byte i texten
    cmpb $0, %al # kolla om vi nått slutet av filen/texten
    jne loop_in_putText # om inte loopa

    movq %rdi, out_buffer_pos  # om vi nått uppdatera addressen

    /*återställ*/
    movq %rbp, %rsp
    popq %rbp
    ret

