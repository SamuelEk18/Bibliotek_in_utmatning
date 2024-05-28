.data
in_buffer:
    .space 64 # Reservera buffern

in_buffer_pos:
    .quad 0

out_buffer:
    .space 64 # Reservera buffern

out_buffer_pos:
    .quad 0

.global inImage,getInt,getText,getChar,getInPos,setInPos,outImage,putInt,putText,putChar,getOutPos,setOutPos
.text

inImage:
    pushq %rdi    # Pushing %rdi (64-bit) onto the stack
    pushq %rsi   # Pushing %esi (32-bit) onto the stack
    pushq %rdx    # Pushing %rdx (64-bit) onto the stack

    movq $in_buffer, %rdi   # Loading the address of the buffer into %rdi
    movq $64, %rsi          # Setting the length to read
    movq stdin, %rdx        # Loading stdin
    call fgets              # Calling fgets to read input
    
    leaq in_buffer_pos, %rdi  # Computing the effective address of in_buffer_pos
    movq $0, (%rdi)                 # Storing 0 at the computed address

    popq %rdx     # Popping %rdx (64-bit) from the stack
    popq %rsi    # Popping %esi (32-bit) from the stack
    popq %rdi     # Popping %rdi (64-bit) from the stack
    ret          # Return from the subroutine

getInt:
    movq in_buffer_pos(%rip), %rsi
    leaq in_buffer(%rip), %rdi
    cmpq $63, %rsi
    je _new_int
    jmp _white_space

_white_space:
    cmpb $' ',(%rdi, %rsi)            # Kolla om mellanslag
    jne _check_sign
    cmpq $63, %rsi
    je _end_int
    incq %rsi
    jmp _white_space

_next_int:
    call inImage
    movq in_buffer_pos, %rsi

_check_sign:
    cmpb $'-', (%rdi, %rsi) # Kolla om negativt tecken
    je _set_negative
    cmpb $'+', (%rdi, %rsi)           # Kolla om positivt tecken
    je _next_sign
    jmp _check_num

_set_negative:
    movq $1, %rdx            # Sätt teckenflaggan till negativt
    cmpq $63, %rsi
    je _end_int
    incq %rsi
    jmp _check_num

_check_num:
    movb (%rdi,%rsi), %cl         # Ladda aktuell karaktär
    cmpb $'0', %cl            # Kolla om det är en siffra
    jl _end_int
    cmpb $'9', %cl
    jg _end_int

    subq $'0', %rcx            # Konvertera ASCII till numeriskt värde
    imulq $10, %rax            # Multiplicera aktuellt resultat med 10
    addq %rcx, %rax             # Lägg till ny siffra till resultatet
    cmpq $63, %rsi
    je _end_int
    incq %rsi                   # Flytta till nästa 
    jmp _check_num

_end_int:
    cmpq $1, %rdx              # Kolla om talet är negativt
    jne _get_int_return
    negq %rax # Applicera negativt tecken om det behövs

_get_int_return:
    movq %rsi, in_buffer_pos
    ret

getText:
    movq in_buffer_pos(%rip), %rdx            # Spara buf (första parameter) i %rbx
    leaq in_buffer(%rip), %rcx            # Spara n (andra parameter) i %rdi
    cmpq $63, %rdx              # Initialisera räknare för antal tecken
    je _get_next_text
    jmp _getText_loop

_get_next_text:
    call inImage
    movq in_buffer_pos, %rdx
    
_getText_loop:
    cmpq %rsi, %rax            # Har vi läst tillräckligt med tecken?
    je _return_GetText         # Om ja, avsluta

    movb (%rcx, %rdx), %r8b   # Ladda en byte från inmatningsbufferten
    cmpb $0, %r8b              # Kolla om slutet på strängen
    je _return_GetText         # Om ja, avsluta

    movb %r8b, (%rdi, %rax)    # Kopiera byte till målbuffern
    incq %rax                  # Öka räknaren för antal tecken
    cmpq $63, rdx
    je _return_GetText
    incq %rdx
    jmp _getText_loop

_return_GetText:
    movb $0, 1(%rdi, %rax)      # NULL-terminera strängen
    movq %rdx, in_buffer_pos            # Spara antalet överförda tecken i %rdi

getChar:
    xorq %rax, %rax 
    movq in_buffer_pos, %rsi
    leaq in_buffer, %rdi
    cmpq $63, %rsi
    je _get_new_char 
    jmp _getChar_loop

_get_new_char:
    call inImage
    movq in_buffer_pos, %rsi

_getChar_loop:
    movb (%rdi, %rsi), %al
    incq %rsi

_result_get_char:
    movq %rsi, in_buffer_pos
    ret

getInPos:
    movq in_buffer_pos(%rip), %rax
    ret

setInPos:
    cmpq $0, %rdi                 # Jämför indata värdet med 0
    jle _inpos_set_to_zero         # Om mindre än 0, hoppa

    cmpq $63, %rdi                # Jämför indata värdet med 63 (MAXPOS)
    jge _inpos_set_to_max          # Om större än 63, hoppa

    movq %rdi, %rax # Sätt in_buffer_pos till indata värdet
    jmp _set_in_pos_end

_inpos_set_to_zero:
    movq $0, %rax                # Sätt indata värdet till 0
    jmp _set_in_pos_end        # Gå till inställningen av buffertpositionen

_inpos_set_to_max:
    movq $63, %rax                # Sätt indata värdet till 63 (MAXPOS)
    jmp _set_in_pos_end        # Gå till inställningen av buffertpositionen

_set_in_pos_end:
    movq %rax, in_buffer_pos # Sätt in_buffer_pos till värdet i %rdi
    ret

outImage:
    pushq %rdi
    pushq %rsi

    leaq out_buffer, %rdi     # Ladda adressen till formatsträngen i %rdi
    call puts                  # Anropa printf för att skriva ut strängen
    movq $0, %rdi # Återställ buffertpositionen
    movq %rdi, out_buffer_pos # Återställ buffertpositionen
    
    popq %rsi
    popq %rdi
    ret

putInt:
    pushq %rbp                 # Spara baspekaren
    
    leaq out_buffer, %r8
    movq out_buffer_pos, %r9
    movq $10, %rsi 
    xorq %rdx, %rdx
    cmpq $0, %rdi
    jl _put_int_negativ

    movq %rdi, %rax
    jmp _put_int_division

_put_int_negativ:
    negq %rdi
    movq %rdi, %rax
    movq $1, %rbp

_put_int_division:
    idivq %rsi
    pushq %rdx
    incq %rcx
    cmpq $0, %rax
    je _check_sign_put_int

    xorq %rdx, %rdx
    jmp _put_int_division

_check_sign_put_int:
    movq %rcx, %rdi
    cmpq $1, %rbp
    jne _put_int_lenght

    addq %r9, %rdi
    addq $1, %rdi
    cmpq $62, %rdi
    jg _put_int_loop
    jmp _put_int_set_neg

_put_int_loop:
    call outImage
    movq out_buffer, %r9
    cmpq $1, %rbp
    je _put_int_set_neg
    jmp _put_int_handle_str

_put_int_lenght:
    movq %rcx, %rdi
    addq %r9, %rdi
    cmpq $62, %rdi
    jg _put_int_loop
    jmp _put_int_handle_str

_put_int_set_neg:
    movq $'-', (%r8, %r9)
    incq %r9

_put_int_handle_str:
    cmpq $0, %rcx
    je _return_put_int

    popq %rdx
    addq $'0', %rdx
    movb %dl, (%r8, %r9)
    decq %rcx
    incq %r9
    jmp _put_int_handle_str

_return_put_int:
    movb $0, (%r8, %r9)
    movq %r9, out_buffer_pos
    popq %rbp
    ret

putText:
    movq out_buffer_pos, %rsi
    leaq out_buffer, %rdx
    movq $0, %rcx
    xorq %r8, %r8
    movq $0, %r9
_put_text_lenght:
    movb (%rdi, %r9), %r8b
    incq %r9
    cmpb $0, %r8b
    je _check_lenght_put_text
    jmp _put_text_lenght

_check_lenght_put_text:
    addq %rsi, %r9
    cmpq $63, %r9
    jg _put_text_fetch_more
    jmp _put_text_loop

_put_text_fetch_more:
    call outImage
    movq out_buffer_pos, %rsi

_put_text_loop:
    movb (%rdi, %rcx), %r8b
    movb %r8b, (%rdx, %rsi)
    cmpb $0, %r8b
    je _return_put_text

    incq %rsi
    incq %rcx
    jmp _put_text_loop

_return_put_text:
    movq %rsi, out_buffer_pos
    ret


putChar:
    movq out_buffer_pos, %rsi
    leaq out_buffer, %rdx
    cmpq $63, %rsi
    je _fetch_putChar
    jmp _loop_put_char

_loop_put_char:
    movb %dil, (%rdx, %rsi)
    incq %rsi

_fetch_putChar:
    call outImage                    # Anropa outImage för att tömma bufferten
    movq out_buffer_pos, %rsi                   # Försök skriva tecknet igen efter hantering av överflöde

_return_putChar:
    movq %rsi, out_buffer_pos
    ret                              # Återvänd från rutinen

getOutPos:
    movq out_buffer_pos, %rax   # Returnera aktuell position
    ret

setOutPos:
    cmpq $0, %rdi
    jle _outpos_lower

    cmpq $63, %rdi
    jge _outpos_lower

    movq %rdi, %rax
    jmp _return_outpos


_outpos_lower:
    movq $0, %rax # Sätt out_buffer_pos till 0
    jmp _return_outpos

_outpos_higher:
    movq $63, %rax 
    jmp _return_outpos

_return_outpos:
    movq %rax, out_buffer
    ret






