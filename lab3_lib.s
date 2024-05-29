.data
in_buffer:
    .space 64, 0x0 # Reservera buffern

in_buffer_pos:
    .quad 0

out_buffer:
    .space 64, 0x0 # Reservera buffern

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

    movq $in_buffer, %rdi    # Load address of the buffer into %rdi
    movq $64, %rsi           # Set length to read
    movq stdin, %rdx         # Load stdin
    call fgets               # Call fgets to read input

    leaq in_buffer_pos, %rdi # Calculate effective address for in_buffer_pos
    movq $0, (%rdi)          # Store 0 at the calculated address

    popq %rdx
    popq %rsi
    popq %rdi

    addq $16, %rsp
    popq %rbp
    ret

getInt:
    pushq %rbp                  # Save the base pointer
    movq %rsp, %rbp             # Set the base pointer
    pushq %rbx                  # Save %rbx
    pushq %r12                  # Save %r12
    pushq %r13                  # Save %r13
    pushq %r14                  # Save %r14
    pushq %r15                  # Save %r15

    xorq %rax, %rax                # Rensa %rax för resultatet
    xorq %rdx, %rdx
    xorq %rcx, %rcx

    movq in_buffer_pos, %rsi # Ladda aktuell position för indata
    leaq in_buffer, %rdi     # Ladda effektiv adress för in_buffer
    xorq %rdx, %rdx                # Rensa %rdx för teckenflaggan (0 = positiv, 1 = negativ)
    cmpq $63, %rsi
    je _refill_buffer # pekare på slutet av bufferten

_check_whitespace:
    cmpb $' ', (%rdi, %rsi)        # Kontrollera om det finns mellanslag
    jne _check_sign

    cmpq $63, %rsi
    je _end_int              # Om buffertpositionen är i slutet, fyll på

    incq %rsi                      # Gå till nästa tecken
    jmp _check_whitespace

_check_sign:
    cmpb $'-', (%rdi, %rsi)        # Kontrollera om det finns negativt tecken
    je _set_negative

    cmpb $'+', (%rdi, %rsi)        # Kontrollera om det finns positivt tecken
    jne _check_digit               # Hoppa över om det inte finns något tecken

    cmpq $63, %rsi
    incq %rsi
    jmp _check_digit

_set_negative:
    movq $1, %rdx                  # Sätt teckenflaggan till negativ
    incq %rsi                      # Gå till nästa tecken
    jmp _check_digit

_check_digit:
    cmpq $63, %rsi
    je _refill_buffer              # Om buffertpositionen är i slutet, fyll på

    movb (%rdi, %rsi), %cl         # Ladda aktuellt tecken
    cmpb $'0', %cl                 # Kontrollera om det är en siffra
    jb _end_int                    # Om mindre än '0', sluta

    cmpb $'9', %cl
    ja _end_int                    # Om större än '9', sluta

    subb $'0', %cl                 # Konvertera ASCII till numeriskt värde
    imulq $10, %rax                # Multiplicera resultatet med 10
    addq %rcx, %rax                # Lägg till siffran till resultatet
    incq %rsi                      # Gå till nästa tecken
    jmp _check_digit

_refill_buffer:
    call inImage                   # Fyll på indata-bufferten
    movq in_buffer_pos , %rsi # Ladda om aktuell position för indata-bufferten
    jmp _check_whitespace          # Fortsätt kontrollera siffror

_end_int:
    cmpq $1, %rdx                  # Kontrollera om talet är negativt
    jne _return_int
    negq %rax                      # Applicera negativt tecken

_return_int:
    movq %rsi, in_buffer_pos  # Uppdatera aktuell position för indata-bufferten

    popq %r15                   # Restore %r15
    popq %r14                   # Restore %r14
    popq %r13                   # Restore %r13
    popq %r12                   # Restore %r12
    popq %rbx                   # Restore %rbx
    movq %rbp, %rsp             # Restore the stack pointer
    popq %rbp                   # Restore the base pointer
    ret                         # Return from subroutine

getText:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq in_buffer_pos , %rdx    # Ladda aktuell position för indata-bufferten till %rdx
    leaq in_buffer , %rcx        # Ladda effektiv adress för in_buffer till %rcx
    xorq %rax, %rax                   # Rensa %rax (används som teckenräknare)

    cmpq $63, %rdx                    # Jämför buffertens position med buffertens gräns
    je _get_next_text                 # Om bufferten är på gränsen, hämta nya data
    jmp _getText_loop

_get_next_text:
    call inImage                      # Anropa funktion för att hämta nästa indata-buffert
    movq in_buffer_pos , %rdx    # Ladda om aktuell position för indata-bufferten

_getText_loop:
    cmpq %rsi, %rax                   # Jämför teckenräknaren med önskad längd
    je _return_GetText                # Om önskad längd har uppnåtts, returnera

    movb (%rcx, %rdx), %r8b           # Ladda ett byte från indata-bufferten
    cmpb $0, %r8b                     # Kontrollera om det är slutet av strängen
    je _return_GetText                # Om det är slutet av strängen, returnera

    movb %r8b, (%rdi, %rax)           # Kopiera byte till destinations-bufferten
    incq %rax                         # Öka teckenräknaren

    cmpq $63, %rdx                    # Kontrollera om aktuell position är på buffertens gr

    je _get_next_text                 # Om det är på gränsen, hämta nya data

    incq %rdx                         # Öka indata-buffertens position
    jmp _getText_loop

_return_GetText:
    movb $0, (%rdi, %rax)             # Avsluta destinationsträngen med

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

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    addq $16, %rsp
    popq %rbp
    ret


getInPos:
    movq in_buffer_pos , %rax
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

    cmpq $0, %rdi                 # Jämför indata värdet med 0
    jle _inpos_set_to_zero        # Om mindre än 0, hoppa

    cmpq in_buffer_pos, %rdi      # Jämför indata värdet med aktuell buffertposition
    jge _inpos_set_to_max         # Om större än eller lika med aktuell buffertposition, hoppa

    movq %rdi, in_buffer_pos      # Sätt in_buffer_pos till indata värdet
    jmp _set_in_pos_end

_inpos_set_to_zero:
    movq $0, in_buffer_pos        # Sätt indata värdet till 0
    jmp _set_in_pos_end

_inpos_set_to_max:
    movq in_buffer_pos, %rax      # Ladda aktuell buffertposition i %rax
    movq %rax, in_buffer_pos      # Sätt in_buffer_pos till aktuell buffertposition
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

    leaq out_buffer, %rdi     # Load the address of out_buffer into %rdi
    movq out_buffer_pos, %rsi # Load the current position of the output buffer into %rsi
    xorq %rcx, %rcx           # Clear %rcx (used for loop counter)

_clear_buffer:
    movb $0, (%rdi, %rsi, 1) # Write null terminator to each byte of the buffer
    incq %rsi                # Move to the next byte
    cmpq $63, %rsi           # Compare the current position to the buffer size
    jge _output_buffer       # If the end of the buffer is reached, go to output

    jmp _clear_buffer        # Otherwise, continue clearing the buffer

_output_buffer:
    leaq out_buffer, %rdi     # Load the address of out_buffer into %rdi
    call puts                 # Call puts to print the buffer
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
    pushq %rbp                     # Save base pointer
    movq %rsp, %rbp                # Set base pointer
    subq $16, %rsp                 # Allocate space on stack for local variables

    pushq %rbx                     # Save %rbx
    pushq %r12                     # Save %r12
    pushq %r13                     # Save %r13
    pushq %r14                     # Save %r14
    pushq %r15                     # Save %r15

    movq out_buffer_pos , %r9 # Load current output buffer position
    leaq out_buffer , %r8     # Load effective address of out_buffer
    movq $10, %rsi                 # Set divisor to 10
    xorq %rdx, %rdx                # Clear %rdx for division
    xorq %rcx, %rcx                # Clear %rcx for digit count
    xorq %rbp, %rbp                # Clear %rbp, used for negative flag

    cmpq $0, %rdi               # Check if the input is zero
    jl _put_int_negative

    movq %rdi, %rax
    jmp _put_int_divide

_put_int_negative:
    negq %rdi                      # Negate %rdi
    movq %rdi, %rax                # Move negated value to %rax
    movq $1, %rbp                  # Set negative flag

_put_int_divide:
    idivq %rsi                     # Divide %rax by %rsi, quotient in %rax, remainder in %rdx
    pushq %rdx                     # Push remainder (digit) onto stack
    incq %rcx
    cmpq $0, %rax               # Check if quotient is zero
    je _put_int_output_sign

    xorq %rdx, %rdx
    jmp _put_int_divide            # If not, continue dividing

_put_int_output_sign:
    cmpq $1, %rbp                  # Check if number was negative
    jne _put_int_output_digits     # If not negative, jump to output digits

    cmpq $62, %r9                  # Check buffer position for overflow
    jge _put_int_handle_overflow   # If buffer overflow, handle overflow

    movb $'-', (%r8, %r9)          # Insert negative sign
    incq %r9                       # Increment buffer position
    jmp _put_int_output_digits     # Continue to output digits


_put_int_output_digits:
    cmpq $0, %rcx                  # Check if there are digits to output
    je _put_int_done

    popq %rdx                      # Pop digit from stack
    addb $'0', %dl                 # Convert to ASCII
    cmpq $63, %r9                  # Check buffer position for overflow
    jge _put_int_handle_overflow

    movb %dl, (%r8, %r9)           # Store ASCII digit in buffer
    incq %r9                       # Increment buffer position
    decq %rcx                      # Decrement digit count
    jmp _put_int_output_digits

_put_int_handle_overflow:
    call outImage                  # Handle buffer overflow (print and reset)
    xorq %r9, %r9                  # Reset buffer position to zero
    jmp _put_int_output_sign       # Retry outputting sign/digits

_put_int_done:
    movq %r9, out_buffer_pos       # Update output buffer position

    popq %r15                      # Restore %r15
    popq %r14                      # Restore %r14
    popq %r13                      # Restore %r13
    popq %r12                      # Restore %r12
    popq %rbx                      # Restore %rbx
    addq $16, %rsp                 # Restore stack
    popq %rbp                      # Restore base pointer
    ret

putText:
    pushq %rbp                   # Save base pointer
    movq %rsp, %rbp              # Set base pointer
    subq $16, %rsp               # Allocate space on stack for local variables

    pushq %rbx                   # Save %rbx
    pushq %r12                   # Save %r12
    pushq %r13                   # Save %r13
    pushq %r14                   # Save %r14
    pushq %r15                   # Save %r15

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
    movq %rsi, out_buffer_pos    # Update output buffer position

    popq %r15                    # Restore %r15
    popq %r14                    # Restore %r14
    popq %r13                    # Restore %r13
    popq %r12                    # Restore %r12
    popq %rbx                    # Restore %rbx
    addq $16, %rsp               # Restore stack
    popq %rbp                    # Restore base pointer
    ret                          # Return from subroutine

putChar:
    pushq %rbp                   # Save base pointer
    movq %rsp, %rbp              # Set base pointer
    subq $16, %rsp               # Allocate space on stack for local variables

    pushq %rbx                   # Save %rbx
    pushq %r12                   # Save %r12
    pushq %r13                   # Save %r13
    pushq %r14                   # Save %r14
    pushq %r15                   # Save %r15

    movq out_buffer_pos, %rsi
    leaq out_buffer, %rdx
    cmpq $63, %rsi
    je _fetch_putChar
    jmp _move_char

_fetch_putChar:
    call outImage
    movq out_buffer_pos, %rsi

_move_char:
    movb %dil, (%rdx, %rsi)
    incq %rsi

_return_char:
    movq %rsi, out_buffer_pos

    popq %r15                    # Restore %r15
    popq %r14                    # Restore %r14
    popq %r13                    # Restore %r13
    popq %r12                    # Restore %r12
    popq %rbx                    # Restore %rbx
    addq $16, %rsp               # Restore stack
    popq %rbp                    # Restore base pointer
    ret                          # Return from subroutine

getOutPos:
    movq out_buffer_pos, %rax   # Returnera aktuell position
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

    cmpq $0, %rdi                 # Jämför utdatavärdet med 0
    jle _outpos_lower             # Om mindre än 0, hoppa

    cmpq out_buffer_pos, %rdi     # Jämför utdatavärdet med aktuell buffertposition
    jge _outpos_higher            # Om större än eller lika med aktuell buffertposition, hoppa

    movq %rdi, out_buffer_pos     # Sätt out_buffer_pos till utdatavärdet
    jmp _set_out_pos_end

_outpos_lower:
    movq $0, out_buffer_pos       # Sätt out_buffer_pos till 0
    jmp _set_out_pos_end

_outpos_higher:
    movq out_buffer_pos, %rax     # Ladda aktuell buffertposition i %rax
    movq %rax, out_buffer_pos     # Sätt out_buffer_pos till aktuell buffertposition
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




