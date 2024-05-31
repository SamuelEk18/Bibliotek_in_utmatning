.data
in_buffer:
    .space 64, 0x0 # Reservera buffern, och ge värde 0

in_buffer_pos:
    .quad 0

out_buffer:
    .space 64, 0x0 # Reservera buffern, och ge värde 0

out_buffer_pos:
    .quad 0

.global inImage, getInt, getText, getChar, getInPos, setInPos, outImage, putInt, putText, putChar, getOutPos, setOutPos

.text

inImage:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rdi
    pushq %rsi
    pushq %rdx

    movq $in_buffer, %rdi    # ladda in addressen till buffern
    movq $64, %rsi # max inläsning
    movq stdin, %rdx # ladda in stdin
    call fgets # läs input med fgets

    leaq in_buffer_pos, %rdi # ladda in positionen
    movq $0, (%rdi) # lägg 0 på den addressen

    popq %rdx
    popq %rsi
    popq %rdi
    addq $16, %rsp
    popq %rbp
    ret

getInt:
    pushq $0

    movq $in_buffer, %rdi # ladda in addressen
    movq $in_buffer_pos, %rsi # ladda in positonen
    movq (%rsi), %rbx # ta in värdet som pekas på
    movq $0, %rax
    movq $0, %r8

    cmpq $62,%rbx # kolla om går ladda in mer
    jge  _buffer_refill

    movzbq (%rdi,%rbx,1), %rdx # läs byte från positionen och gör till 64
    cmpq $10, %rdx # kolla om mellan 0-9
    jle _buffer_refill

_loop_get_int:
    movzbq (%rdi,%rbx,1), %rdx # läs byte från positionen och gör till 64
    cmpq $45, %rdx # kolla om negativt
    je _negative

    cmpq $43, %rdx # kolla om positivt
    je _positive

    cmpq $32, %rdx # kolla om " "
    je _skip

    cmpq $48, %rdx # kolla < 0
    jl _return_get_int

    cmpq $57, %rdx # kolla > 9
    jg _return_get_int

    sub $'0', %rdx # ascii
    cmpq $0, %rax # kolla om 0
    jne _relevant_numbers

    movq %rdx, %rax # ge till ut
    incq %rbx
    jmp _loop_get_int

_negative:
    movq $1, %r8 # flagga negativ
    incq %rbx
    jmp _loop_get_int

_set_to_negative:
    negq %rax # sätt ut som negativ
    movq $0, %r8
    jmp _return_get_int

_positive:
    incq %rbx
    jmp _loop_get_int

_skip:
    cmpq $0, %rax # koll om slut
    jne _return_get_int

    incq %rbx
    jmp _loop_get_int

_relevant_numbers:
    imulq $10, %rax
    addq %rdx, %rax # lägg ihop
    incq %rbx # gå till vänster
    jmp _loop_get_int

_buffer_refill:
    pushq %rax
    pushq %rsi
    pushq %rdi
    pushq %rbx

    call inImage

    popq %rbx
    popq %rdi
    popq %rsi
    popq %rax

    movq $0, %rbx # sätt positionen till 0
    jmp _loop_get_int

_return_get_int:
    cmpq $1, %r8 # är den flaggad negativ?
    je _set_to_negative

    popq %rsi # ge tillbaka senaste
    movq $in_buffer_pos, %rsi # sätt på buffernpositionen
    movq %rbx, (%rsi) # ge värde till rbx
    movq $in_buffer, %rdi # ge värde till buffern
    ret

getText:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq in_buffer_pos , %rdx # lägg position i register
    leaq in_buffer , %rcx # lägg buffern i register
    xorq %rax, %rax

    cmpq $63, %rdx # kolla va vi är
    je _get_next_text # om så hämta nytt
    jmp _getText_loop

_get_next_text:
    call inImage # hämta nytt
    movq in_buffer_pos , %rdx # ge positionen

_getText_loop:
    cmpq %rsi, %rax # kolla längden är nådd av andra argumentet
    je _return_GetText

    movb (%rcx, %rdx), %r8b # ta en byte från buffern på positionen
    cmpb $0, %r8b # är slut?
    je _return_GetText

    movb %r8b, (%rdi, %rax) # lägg byte på out
    incq %rax

    cmpq $63, %rdx # kolla om behöver ny data
    je _get_next_text

    incq %rdx # gå upp en pos
    jmp _getText_loop

_return_GetText:
    movb $0, (%rdi, %rax) # makera slut

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

getChar:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    xorq %rax, %rax
    movq in_buffer_pos, %rsi # sätt positonen på register
    leaq in_buffer, %rdi # ladda buffern på register
    cmpq $63, %rsi # kolla om behöver nu data
    je _get_new_char
    jmp _getChar_loop

_get_new_char:
    call inImage
    movq in_buffer_pos, %rsi # ge ny position

_getChar_loop:
    movb (%rdi, %rsi), %al # läs byte från buffer på positionen
    incq %rsi # gå till nästa

_result_get_char:
    movq %rsi, in_buffer_pos # ge positionen

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

getInPos:
    movq in_buffer_pos , %rax # ge positionen
    ret

setInPos:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    cmpq $0, %rdi
    jle _inpos_set_to_zero # <0 hoppa

    cmpq in_buffer_pos, %rdi # kolla strl argument
    jge _inpos_set_to_max # om större hoppa

    movq %rdi, in_buffer_pos # flytta positionen till argumentet
    jmp _set_in_pos_end

_inpos_set_to_zero:
    movq $0, in_buffer_pos # sätt positonen först
    jmp _set_in_pos_end

_inpos_set_to_max:
    movq in_buffer_pos, %rax # ta nuvarande positonen
    movq %rax, in_buffer_pos # ge nuvarande positonen
    jmp _set_in_pos_end

_set_in_pos_end:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

outImage:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rdi
    pushq %rsi

    leaq out_buffer, %rdi # ladda buffern
    movq out_buffer_pos, %rsi # ladda pos
    xorq %rcx, %rcx

_clear_buffer:
    movb $0, (%rdi, %rsi, 1) # nolla positionen
    incq %rsi # gå vidare
    cmpq $63, %rsi # kolla om vi nåt slutet
    jge _output_buffer # om ja hoppa
    jmp _clear_buffer

_output_buffer:
    leaq out_buffer, %rdi # ladda buffer
    call puts
    movq $0, out_buffer_pos   # Reset the buffer position to 0

    popq %rsi
    popq %rdi
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

putInt:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq out_buffer_pos , %r9 # lägg buffern i register
    leaq out_buffer , %r8 # ladda positionen i register
    movq $10, %rsi # delare
    xorq %rdx, %rdx
    xorq %rcx, %rcx
    xorq %rbp, %rbp

    cmpq $0, %rdi # kolla om argument är negativt
    jl _put_int_negative

    movq %rdi, %rax # sätt argument på ut
    jmp _put_int_divide

_put_int_negative:
    negq %rdi # sätt negativ
    movq %rdi, %rax # sätt arguement på ut
    movq $1, %rbp # flagga negativ

_put_int_divide:
    idivq %rsi # dela
    pushq %rdx # lägg upp kvarstående på stacken
    incq %rcx # öka mängd
    cmpq $0, %rax # är kvot 0?
    je _put_int_output_sign # om ja hoppa

    xorq %rdx, %rdx
    jmp _put_int_divide # fortsätt dividera

_put_int_output_sign:
    cmpq $1, %rbp # kolla om negativit
    jne _put_int_output_digits

    cmpq $62, %r9 # kolla om de får plats mer
    jge _put_int_handle_overflow  # om inte hoppa

    movb $'-', (%r8, %r9) # ge negativ
    incq %r9 # gå till nästa i buffern
    jmp _put_int_output_digits

_put_int_output_digits:
    cmpq $0, %rcx # finns det tal kvar
    je _put_int_done

    popq %rdx # ta fram tal från stacken
    addb $'0', %dl # ascii konvertering
    cmpq $63, %r9 # kolla om de får plats mer
    jge _put_int_handle_overflow # om inte hoppa

    movb %dl, (%r8, %r9) # lägg ascii i buffern
    incq %r9 # gå visare
    decq %rcx # ta bort en från mängd
    jmp _put_int_output_digits

_put_int_handle_overflow:
    call outImage
    xorq %r9, %r9 # postionen är 0
    jmp _put_int_output_sign

_put_int_done:
    movq %r9, out_buffer_pos # sätt ny position

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

putText:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq out_buffer_pos, %rsi # ladda in position
    leaq out_buffer, %rdx # ladda in buffer
    movq $0, %rcx # sätt register till noll, bas
    xorq %r8, %r8
    movq $0, %r9 # sätt register till noll, pekare

_put_text_lenght:
    movb (%rdi, %r9), %r8b # läs byten
    incq %r9 # gå till nästa byte
    cmpb $0, %r8b # kolla om den är noll
    je _check_lenght_put_text # om noll ge strl
    jmp _put_text_lenght

_check_lenght_put_text:
    addq %rsi, %r9 # kolla längden
    cmpq $63, %r9
    jg _put_text_fetch_more # om större hämta ny data
    jmp _put_text_loop

_put_text_fetch_more:
    call outImage
    movq out_buffer_pos, %rsi # ge ny position

_put_text_loop:
    movb (%rdi, %rcx), %r8b # läs in värdet i register
    movb %r8b, (%rdx, %rsi) # flytta värdet till positionen
    cmpb $0, %r8b # kolla om värdet är 0
    je _return_put_text

    incq %rsi # flytta positionen
    incq %rcx # flytta bas
    jmp _put_text_loop

_return_put_text:
    movq %rsi, out_buffer_pos # ge ny position

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

putChar:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq out_buffer_pos, %rsi # läs in positionen
    leaq out_buffer, %rdx # läs in buffer
    cmpq $63, %rsi # kan de få in mer
    je _fetch_putChar # nej hoppa
    jmp _move_char

_fetch_putChar:
    call outImage
    movq out_buffer_pos, %rsi # ge ny position

_move_char:
    movb %dil, (%rdx, %rsi) # läs in en byte från buffern
    incq %rsi # gå till nästa

_return_char:
    movq %rsi, out_buffer_pos # ge ny position

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret

getOutPos:
    movq out_buffer_pos, %rax # ge positionen
    ret

setOutPos:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    cmpq $0, %rdi # kolla om argument är 0
    jle _outpos_lower # <0 hoppa

    cmpq out_buffer_pos, %rdi # kolla om större än position
    jge _outpos_higher # om större hoppa

    movq %rdi, out_buffer_pos  # ge positionen
    jmp _set_out_pos_end

_outpos_lower:
    movq $0, out_buffer_pos # sätt positionen till första
    jmp _set_out_pos_end

_outpos_higher:
    movq out_buffer_pos, %rax # ta fram position
    movq %rax, out_buffer_pos # sett till denne
    jmp _set_out_pos_end

_set_out_pos_end:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    addq $16, %rsp
    popq %rbp
    ret