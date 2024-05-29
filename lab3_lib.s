.data
in_buffer:
    .space 64, 0x0 # Reservera buffern

in_buffer_pos:
    .quad 0

out_buffer:
    .space 64, 0x0 # Reservera buffern

out_buffer_pos:
    .quad 0

.global inImage,getInt,getText,getChar,getInPos,setInPos,outImage,putInt,putText,putChar,getOutPos,setOutPos
.text

inImage:
    pushq %rdi
    pushq %rsi
    pushq %rdx

    movq $in_buffer, %rdi   # Loading the address of the buffer into %rdi
    movq $64, %rsi          # Setting the length to read
    movq stdin, %rdx        # Loading stdin
    call fgets              # Calling fgets to read input

    leaq in_buffer_pos, %rdi  # Computing the effective address of in_buffer_pos
    movq $0, (%rdi)                 # Storing 0 at the computed address

    popq %rdx
    popq %rsi
    popq %rdi
    ret          # Return from the subroutine

getInt:
    movq in_buffer_pos(%rip), %rsi
    leaq in_buffer(%rip), %rdi
    cmpq $63, %rsi
    je _next_int
    jmp _white_space

_next_int:
    call inImage
    movq in_buffer_pos, %rsi

_white_space:
    cmpb $' ',(%rdi, %rsi)            # Kolla om mellanslag
    jne _check_sign
    cmpq $63, %rsi
    je _end_int
    incq %rsi
    jmp _white_space

_check_sign:
    cmpb $'-', (%rdi, %rsi) # Kolla om negativt tecken
    je _set_negative
    cmpb $'+', (%rdi, %rsi)           # Kolla om positivt tecken
    je _end_int
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
    movq in_buffer_pos(%rip), %rdx    # Load current input buffer position into %rdx
    leaq in_buffer(%rip), %rcx        # Load effective address of in_buffer into %rcx
    xorq %rax, %rax                   # Clear %rax (used as character count)

    cmpq $63, %rdx                    # Compare buffer position with buffer limit
    je _get_next_text                 # If buffer is at limit, fetch new data
    jmp _getText_loop

_get_next_text:
    call inImage                      # Call function to get next input buffer
    movq in_buffer_pos(%rip), %rdx    # Reload input buffer position

_getText_loop:
    cmpq %rsi, %rax                   # Compare character count with desired length
    je _return_GetText                # If reached the desired length, return

    movb (%rcx, %rdx), %r8b           # Load a byte from the input buffer
    cmpb $0, %r8b                     # Check if it's the end of the string
    je _return_GetText                # If end of string, return

    movb %r8b, (%rdi, %rax)           # Copy byte to destination buffer
    incq %rax                         # Increment character count

    cmpq $63, %rdx                    # Check if the input buffer position is at its limit
    je _get_next_text                 # If at limit, fetch new data

    incq %rdx                         # Increment input buffer position
    jmp _getText_loop

_return_GetText:
    movb $0, (%rdi, %rax)             # NULL-terminate the destination string
    movq %rdx, in_buffer_pos(%rip)    # Save updated input buffer position
    ret

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
    pushq %rbp                 # Save base pointer
    movq %rsp, %rbp            # Set base pointer
    subq $16, %rsp             # Allocate space on stack for local variables

    movq out_buffer_pos, %r9
    leaq out_buffer(%rip), %r8 # Load effective address of out_buffer
    movq $10, %rsi             # Set divisor to 10
    xorq %rdx, %rdx            # Clear %rdx for division
    xorq %rcx, %rcx            # Clear %rcx for digit count
    xorq %rbp, %rbp            # Clear %rbp, used for negative flag

    cmpq $0, %rdi
    jl _put_int_negativ

    movq %rdi, %rax
    jmp _put_int_division

_put_int_negativ:
    negq %rdi                  # Negate %rdi
    movq %rdi, %rax            # Move negated value to %rax
    movq $1, %rbp              # Set negative flag

_put_int_division:
    idivq %rsi                 # Divide %rax by %rsi, quotient in %rax, remainder in %rdx
    pushq %rdx                 # Push remainder (digit) onto stack
    incq %rcx                  # Increment digit count
    cmpq $0, %rax
    je _check_sign_put_int

    xorq %rdx, %rdx            # Clear %rdx for next division
    jmp _put_int_division

_check_sign_put_int:
    cmpq $1, %rbp
    jne _put_int_lenght

    addq $1, %r9               # Adjust for negative sign
    cmpq $62, %r9
    jg _put_int_loop
    movq $'-', (%r8, %r9)      # Insert negative sign
    incq %r9                   # Increment position

_put_int_lenght:
    addq %rcx, %r9             # Adjust for digit count
    cmpq $62, %r9
    jg _put_int_loop

_put_int_handle_str:
    cmpq $0, %rcx
    je _return_put_int

    popq %rdx                  # Pop digit from stack
    addq $'0', %rdx            # Convert to ASCII
    movb %dl, (%r8, %r9)       # Store ASCII digit in buffer
    decq %rcx                  # Decrement digit count
    incq %r9                   # Increment buffer position
    jmp _put_int_handle_str

_put_int_loop:
    call outImage              # Handle full buffer (assuming this function resets out_buffer and out_buffer_pos)
    movq out_buffer_pos, %r9   # Reload updated out_buffer_pos

    jmp _put_int_handle_str

_return_put_int:
    movb $0, (%r8, %r9)        # Null-terminate the string
    movq %r9, out_buffer_pos   # Update out_buffer_pos
    addq $16, %rsp             # Restore stack
    popq %rbp                  # Restore base pointer
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






