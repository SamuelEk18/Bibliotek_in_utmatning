.data
in_buffer:
    .space 64 # Reservera buffern

in_buffer_pos:
    .quad 0

out_buffer:
    .space 64 # Reservera buffern

out_buffer_pos:
    .quad 0

utstring:
    .asciz "%s\n"


.global inImage,getInt,getText,getChar,getInPos,setInPos,outImage,putInt,putText,putChar,getOutPos,setOutPos
.text
inImage:
    movq $in_buffer, %rdi # Ladda adressen för buffern
    movl $64, %esi # läs
    movq stdin, %rdx # Ladda in stdin
    call fgets
    leaq in_buffer_pos(%rip), %rdi
    movq $0, (%rdi)
    ret

getInt:
    pushq %rbp                  # Spara baspekaren
    movq %rsp, %rbp             # Sätt baspekaren

    call checkBuffer            # Kolla och fyll bufferten om nödvändigt

    leaq in_buffer(%rip), %rax  # Ladda in buffern
    movq in_buffer_pos(%rip), %r12 # Ladda aktuell position
    addq %r12, %rax             # Justera buffertadressen med aktuell position

    movq $0, %rdi               # Initialisera resultatet
    movq $0, %r13               # Teckenflagga (0 för positivt, 1 för negativt)

_white_space:
    movzbq (%rax), %r14         # Ladda aktuell karaktär
    cmpb $0, %r14b              # Kolla om slutet på bufferten
    je _to_inImage
    cmpb $'\n', %r14b           # Kolla om ny rad
    je _to_inImage
    cmpb $' ', %r14b            # Kolla om mellanslag
    je _next_int
    cmpb $'\t', %r14b           # Kolla om tab
    je _next_int
    jmp _check_sign

_next_int:
    incq %rax                   # Flytta till nästa karaktär
    incq %r12                   # Uppdatera buffertpositionen
    jmp _white_space

_check_sign:
    cmpb $'-', %r14b            # Kolla om negativt tecken
    je _set_negative
    cmpb $'+', %r14b            # Kolla om positivt tecken
    je _next_sign
    jmp _check_num

_set_negative:
    movq $1, %r13               # Sätt teckenflaggan till negativt

_next_sign:
    incq %rax                   # Flytta till nästa karaktär
    incq %r12                   # Uppdatera buffertpositionen
    jmp _check_num

_check_num:
    movzbq (%rax), %r15         # Ladda aktuell karaktär
    cmpb $'0', %r15b            # Kolla om det är en siffra
    jb _end_int
    cmpb $'9', %r15b
    ja _end_int

    subb $'0', %r15b            # Konvertera ASCII till numeriskt värde
    imulq $10, %rdi             # Multiplicera aktuellt resultat med 10
    addq %r15, %rdi             # Lägg till ny siffra till resultatet

    incq %rax                   # Flytta till nästa karaktär
    incq %r12                   # Uppdatera buffertpositionen
    jmp _check_num

_end_int:
    cmpq $1, %r13               # Kolla om talet är negativt
    jne _store_int
    negq %rdi                   # Applicera negativt tecken om det behövs

_store_int:
    movq %r12, in_buffer_pos(%rip) # Uppdatera buffertpositionen
    movq %rbp, %rsp
    popq %rbp
    ret

_to_inImage:
    call inImage                # Anropa inImage för att fylla på buffern
    jmp getInt                  # Försök läsa om talet

getText:
    pushq %rbp                 # Spara baspekaren
    movq %rsp, %rbp            # Sätt baspekaren
    pushq %rbx                 # Spara %rbx
    pushq %rsi                 # Spara %rsi
    pushq %rdi                 # Spara %rdi

    movq %rdi, %rbx            # Spara buf (första parameter) i %rbx
    movq %rsi, %rdi            # Spara n (andra parameter) i %rdi
    movq $0, %rax              # Initialisera räknare för antal tecken
    call checkBuffer           # Kontrollera och fyll på bufferten om nödvändigt

    movq in_buffer_pos(%rip), %rcx  # Ladda aktuell buffertposition
    leaq in_buffer(%rip), %rdx      # Ladda buffertadress

_getText_loop:
    cmpq %rdi, %rax            # Har vi läst tillräckligt med tecken?
    je _return_GetText         # Om ja, avsluta

    movzbq (%rdx, %rcx), %r8   # Ladda en byte från inmatningsbufferten
    cmpb $0, %r8b              # Kolla om slutet på strängen
    je _return_GetText         # Om ja, avsluta

    movb %r8b, (%rbx, %rax)    # Kopiera byte till målbuffern
    incq %rax                  # Öka räknaren för antal tecken
    incq %rcx                  # Nästa byte i inmatningsbufferten

    call checkBuffer           # Kontrollera och fyll på bufferten om nödvändigt

    jmp _getText_loop          # Fortsätt loopen

_return_GetText:
    movb $0, (%rbx, %rax)      # NULL-terminera strängen
    movq %rax, %rdi            # Spara antalet överförda tecken i %rdi
    movq %rcx, in_buffer_pos(%rip) # Uppdatera buffertpositionen

    popq %rdi                  # Återställ %rdi
    popq %rsi                  # Återställ %rsi
    popq %rbx                  # Återställ %rbx
    movq %rdi, %rax            # Returnera antalet överförda tecken
    popq %rbp                  # Återställ baspekaren
    ret

checkBuffer:
    leaq in_buffer(%rip), %r9  # Ladda buffertadressen
    movq in_buffer_pos(%rip), %r10 # Ladda aktuell position
    addq %r10, %r9             # Justera adressen med positionen
    movzbq (%r9), %r11         # Ladda aktuell karaktär
    cmpb $0, %r11b             # Kolla om bufferten är slut
    je _call_inImage
    ret

_call_inImage:
    call inImage               # Anropa inImage
    ret


getChar:
    pushq %rbp                    # Spara baspekaren
    movq %rsp, %rbp               # Sätt baspekaren

_getChar_loop:
    movq in_buffer_pos(%rip), %rax # Ladda buffertpositionen
    leaq in_buffer(%rip), %rdx    # Ladda buffertens basadress
    movzbl (%rdx, %rax), %ecx     # Ladda aktuell karaktär till %ecx

    cmpb $0, %cl                  # Kontrollera om karaktären är noll
    je _to_getChar                # Om det är noll, fyll på bufferten

    incq %rax                     # Flytta till nästa karaktär
    movq %rax, in_buffer_pos(%rip) # Uppdatera buffertpositionen

    movzbl %cl, %eax              # Flytta tecknet till %eax (returvärde)
    popq %rbp                     # Återställ baspekaren
    ret

_to_getChar:
    call inImage                  # Fyll på bufferten
    jmp _getChar_loop             # Hoppa tillbaka till loopen

getInPos:
    movq in_buffer_pos(%rip), %rax
    ret

setInPos:
    cmpq $0, %rdi                 # Jämför indata värdet med 0
    jl _inpos_set_to_zero         # Om mindre än 0, hoppa

    cmpq $63, %rdi                # Jämför indata värdet med 63 (MAXPOS)
    jg _inpos_set_to_max          # Om större än 63, hoppa

    movq %rdi, in_buffer_pos(%rip) # Sätt in_buffer_pos till indata värdet
    ret

_inpos_set_to_zero:
    movq $0, %rdi                 # Sätt indata värdet till 0
    jmp _set_in_buffer_pos        # Gå till inställningen av buffertpositionen

_inpos_set_to_max:
    movq $63, %rdi                # Sätt indata värdet till 63 (MAXPOS)
    jmp _set_in_buffer_pos        # Gå till inställningen av buffertpositionen

_set_in_buffer_pos:
    movq %rdi, in_buffer_pos(%rip) # Sätt in_buffer_pos till värdet i %rdi
    ret

outImage:
    leaq out_buffer, %rdi     # Ladda adressen till formatsträngen i %rdi
    call puts                   # Anropa printf för att skriva ut strängen
    movq $0, %rdi # Återställ buffertpositionen
    movq $rdi, out_buffer_pos # Återställ buffertpositionen
    ret

putInt:
    pushq %rbp                 # Spara baspekaren
    movq %rsp, %rbp            # Ställ in baspekaren
    subq $32, %rsp             # Allokera stackutrymme för temporära data

    movq %rdi, -8(%rbp)        # Spara talet n i stacken

    movq $10, %rcx             # Sätt divisor till 10
    cmpq $0, %rdi              # Jämför indatat heltal med 0
    jge _putint_convert        # Om n >= 0, hoppa till konvertering
    negq %rdi                  # Gör n positivt
    movq $'-', %rsi            # Ladda '-' tecken
    call putChar               # Skriv ut '-' tecken

_putint_convert:
    movq -8(%rbp), %rax        # Flytta talet n till %rax
    leaq -8(%rbp), %rbx        # Pekare till stack för att lagra siffrorna
    addq $24, %rbx             # Flytta pekaren till slutet av det allokerade utrymmet

_putint_loop:
    cqto                       # Teckens-förläng %rax till %rdx
    idivq %rcx                 # Dividera %rax med 10, kvot i %rax, rest i %rdx
    addq $'0', %rdx            # Konvertera resten till ASCII
    decq %rbx                  # Flytta stackpekaren bakåt
    movb %dl, (%rbx)           # Spara resten på stacken
    testq %rax, %rax           # Kontrollera om kvoten är noll
    jnz _putint_loop           # Om inte noll, fortsätt loopen

_putint_output:
    cmpq %rbx, %rbp            # Jämför stackpekaren med baspekaren
    je _putint_end             # Om de är lika, avsluta

    movzbl (%rbx), %edi        # Ladda en siffra från stacken
    call putChar               # Skriv ut siffran
    incq %rbx                  # Flytta stackpekaren framåt
    jmp _putint_output         # Upprepa tills alla siffror är skrivna

_putint_end:
    leave                      # Återställ stacken och baspekaren
    ret                        # Återvänd från rutinen


putText:
    pushq %rbx                      # Spara %rbx
    movq out_buffer_pos(%rip), %rax # Ladda aktuell buffertpekare
    leaq out_buffer(%rip), %rdx     # Ladda basadressen för out_buffer
    movq $0, %rbx                   # Initialisera indexregistret

_loop_in_putText:
    movzbq (%rdi, %rbx), %rcx       # Ladda byte från indatasträngen till %rcx
    cmpb $0, %cl                    # Kontrollera om slutet på strängen
    je _end_puttext                 # Om slutet på strängen, hoppa till end

    movb %cl, (%rdx, %rax)          # Kopiera byte till utdata buffern
    incq %rax                       # Öka buffertpekaren
    incq %rbx                       # Öka indatasträngpekaren
    cmpq $64, %rax                  # Kontrollera om buffertpekaren överskrider buffertstorleken
    je _overflow_puttext            # Om överflöd, hoppa till overflow
    jmp _loop_in_putText            # Upprepa loopen

_overflow_puttext:
    call outImage                   # Anropa outImage för att hantera buffertöverskridning
    movq $0, %rax                   # Återställ buffertpekaren till 0
    jmp _loop_in_putText            # Fortsätt bearbetningen av indata

_end_puttext:
    movq %rax, out_buffer_pos(%rip) # Uppdatera buffertpekaren
    popq %rbx                       # Återställ %rbx
    ret                             # Återvänd från rutinen


putChar:
    movq out_buffer_pos(%rip), %rax  # Ladda aktuell buffertpekare i %rax
    cmpq $64, %rax                   # Jämför med buffertstorleken (64)
    jge _overflow_putChar            # Om överflöd, hoppa till hantering av överflöde

    leaq out_buffer(%rip), %rdx      # Ladda basadressen för out_buffer i %rdx
    movb %sil, (%rdx, %rax)          # Kopiera tecknet (i %sil) till bufferten
    incq %rax                        # Öka buffertpekaren med 1
    movq %rax, out_buffer_pos(%rip)  # Uppdatera buffertpekaren med den nya positionen
    jmp _end_putChar                 # Hoppa till slutet av rutinen

_overflow_putChar:
    call outImage                    # Anropa outImage för att tömma bufferten
    jmp putChar                      # Försök skriva tecknet igen efter hantering av överflöde

_end_putChar:
    ret                              # Återvänd från rutinen

getOutPos:
    movq out_buffer_pos, %rax   # Returnera aktuell position
    ret

setOutPos:
    cmpq $0, %rdi # Jämför indata värdet med 0
    jle _outpos_lower # Om mindre än eller lika med 0, hoppa
    cmpq $63, %rdi # Jämför indata värdet med 63
    jge _outpos_higher  # Om större än eller lika med 63, hoppa
    movq %rdi, out_buffer_pos(%rip) # Sätt out_buffer_pos till indata värdet
    ret

_outpos_lower:
    movq $0, out_buffer_pos(%rip) # Sätt out_buffer_pos till 0
    ret

_outpos_higher:
    movq $63, out_buffer_pos(%rip) # Sätt out_buffer_pos till 63
    ret







