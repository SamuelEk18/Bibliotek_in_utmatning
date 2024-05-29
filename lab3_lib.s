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
    xorq %rax, %rax                # Clear %rax for the result
    movq in_buffer_pos, %rsi # Load current input buffer position
    leaq in_buffer, %rdi     # Load effective address of in_buffer
    xorq %rdx, %rdx                # Clear %rdx for the sign flag (0 = positive, 1 = negative)
    cmpq $63, %rsi
    je _refill_buffer # pointer at end of buffer

_check_whitespace:
    cmpb $' ', (%rdi, %rsi)        # Check for whitespace
    jne _check_sign

    cmpq $63, %rsi
    je _end_int              # If buffer position is at end, refill

    incq %rsi                      # Move to next character
    jmp _check_whitespace

_check_sign:
    cmpb $'-', (%rdi, %rsi)        # Check for negative sign
    je _set_negative
    cmpb $'+', (%rdi, %rsi)        # Check for positive sign
    cmpq $63, %rsi
    incq %rsi
    jmp _check_digit

_set_negative:
    movq $1, %rdx                  # Set sign flag to negative
    incq %rsi                      # Move to next character
    jmp _check_digit

_check_digit:
    cmpq $63, %rsi
    je _refill_buffer              # If buffer position is at end, refill
    movb (%rdi, %rsi), %cl         # Load current character
    cmpb $'0', %cl                 # Check if it is a digit
    jb _end_int                    # If less than '0', end
    cmpb $'9', %cl
    ja _end_int                    # If greater than '9', end

    subb $'0', %cl                 # Convert ASCII to numeric value
    imulq $10, %rax                # Multiply result by 10
    addq %rcx, %rax                # Add the digit to the result
    incq %rsi                      # Move to next character
    jmp _check_digit

_refill_buffer:
    call inImage                   # Refill input buffer
    movq in_buffer_pos , %rsi # Reload input buffer position
    jmp _check_whitespace          # Continue checking for digits

_end_int:
    cmpq $1, %rdx                  # Check if number is negative
    jne _return_int
    negq %rax                      # Apply negative sign

_return_int:
    movq %rsi, in_buffer_pos  # Update input buffer position
    ret

getText:
    movq in_buffer_pos , %rdx    # Load current input buffer position into %rdx
    leaq in_buffer , %rcx        # Load effective address of in_buffer into %rcx
    xorq %rax, %rax                   # Clear %rax (used as character count)

    cmpq $63, %rdx                    # Compare buffer position with buffer limit
    je _get_next_text                 # If buffer is at limit, fetch new data
    jmp _getText_loop

_get_next_text:
    call inImage                      # Call function to get next input buffer
    movq in_buffer_pos , %rdx    # Reload input buffer position

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
    movq %rdx, in_buffer_pos     # Save updated input buffer position
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
    movq in_buffer_pos , %rax
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
    pushq %rbp                     # Save base pointer
    movq %rsp, %rbp                # Set base pointer
    subq $16, %rsp                 # Allocate space on stack for local variables

    movq out_buffer_pos , %r9 # Load current output buffer position
    leaq out_buffer , %r8     # Load effective address of out_buffer
    movq $10, %rsi                 # Set divisor to 10
    xorq %rdx, %rdx                # Clear %rdx for division
    xorq %rcx, %rcx                # Clear %rcx for digit count
    xorq %rbp, %rbp                # Clear %rbp, used for negative flag

    cmpq $0, %rdi               # Check if the input is zero
    je _put_zero                   # If zero, handle separately
    jl _put_int_negative

    movq %rdi, %rax
    jmp _put_int_divide

_put_zero:
    cmpq $63, %r9                  # Check buffer position for overflow
    jge _put_int_handle_overflow
    movb $'0', (%r8, %r9)          # Place '0' in buffer
    incq %r9                       # Increment buffer position
    jmp _put_int_done

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
    jne _put_int_output_digits

    cmpq $62, %r9                  # Check buffer position for overflow
    jge _put_int_handle_overflow
    movb $'-', (%r8, %r9)          # Insert negative sign
    incq %r9                       # Increment buffer position

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
    movq %r9, out_buffer_pos  # Update output buffer position
    addq $16, %rsp                 # Restore stack
    popq %rbp                      # Restore base pointer
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
    pushq %rsi                   # Save %rsi
    movq out_buffer_pos, %rsi    # Load current output buffer position
    leaq out_buffer, %rdx        # Load effective address of out_buffer

    cmpq $63, %rsi               # Compare buffer position with buffer size
    je _fetch_putChar            # If buffer is full, handle overflow

    movb %dil, (%rdx, %rsi)      # Move the character to the buffer
    incq %rsi                    # Increment buffer position
    movq %rsi, out_buffer_pos    # Update output buffer position
    popq %rsi                    # Restore %rsi
    ret                          # Return from subroutine

_fetch_putChar:
    call outImage                # Handle full buffer (print and reset)
    movq $0, %rsi                # Reset buffer position
    movb %dil, (%rdx, %rsi)      # Move the character to the buffer
    incq %rsi                    # Increment buffer position
    movq %rsi, out_buffer_pos    # Update output buffer position
    popq %rsi                    # Restore %rsi
    ret                          # Return from subroutine


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






