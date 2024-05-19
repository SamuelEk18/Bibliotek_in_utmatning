.section .data
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

.section .text
.global inImage,getInt,getText,getChar,getInPos,setInPos,outImage,putInt,putText,putChar,getOutPos,setOutPos

inImage:
    leaq in_buffer(%rip), %rdi # Ladda adressen för buffern

    movl $64, %esi # Sätt buffert strl
    movq stdin(%rip), %rdx # Ladda in stdin

    call fgets

    movq $0, in_buffer_pos(%rip) # Återställ buffert positionen
    jmp _inImageProcess # Fortsätt processen

_inImageProcess:
    leaq in_buffer(%rip), %rax # Ladda in i rax som håller värdet vid ret

    movq in_buffer_pos(%rip), %r12 # Ladda in värde i register
    movq (%rax, %r12), %rdi # Ladda in nuvarande karaktär
    testq %rdi, %rdi # Kolla om o
    je _inImageEnd # Om 0 avsluta

    incq %r12 # Öka buffert positionen
    movq %r12, in_buffer_pos(%rip) # Uppdatera i buffern
    ret

_inImageEnd:
    call inImage # Fyll på buffern
    jmp _inImageProcess # Fortsätt hantera

getInt:
    pushq %rbp # Spara basen
    movq %rsp, %rbp # Sätter staket och basen på samma

    leaq in_buffer(%rip), %rax # Ladda in buffern
    movq in_buffer_pos(%rip), %r12 # Lägg i register
    addq %r12, %rax # Justera buffert adressen med nuvarande position

    movq $0, %rdi # Initialisera resultatet
    movq $0, %r13 # Tecken flagga (0 för positivt, 1 för negativt)

_white_space:
    movzbq (%rax), %r14 # Ladda aktuell karaktär
    movb %r14b, %al # Flytta från %r14 till %al

    cmpb $0, %al # Kolla om slutet på bufferten
    je _to_inImage

    cmpb $'\n', %al # Kolla om ny rad
    je _to_inImage

    cmpb $' ', %al # Kolla om mellanslag
    je _next_int

    cmpb $'\t', %al # Kolla om tab
    je _next_int

    jmp _check_neg

_next_int:
    incq %rax # Flytta till nästa karaktär
    incq %r12 # Uppdatera buffert positionen
    jmp _white_space

_check_neg:
    cmpb $'-', %al # Kolla om negativt tecken
    jne _check_num

    movq $1, %r13 # Sätt tecken flaggan till negativt
    incq %rax # Flytta till nästa karaktär
    incq %r12 # Uppdatera buffert positionen

    jmp _check_num

_check_num:
    movzbq (%rax), %r15 # Ladda aktuell karaktär till %r15
    movb %r15b, %al # Flytta byte-storleken värdet från %r15 till %al

    cmpb $'0', %al # Kolla om det är en siffra
    jb _end_int

    cmpb $'9', %al
    ja _end_int

    subb $'0', %al # Konvertera ASCII till numeriskt värde
    imulq $10, %rdi # Multiplicera aktuellt resultat med 10
    addq %rdi, %rax # Lägg till ny siffra till resultatet

    incq %rax # Flytta till nästa karaktär
    incq %r12 # Uppdatera buffert positionen
    jmp _check_num

_end_int:
    cmpq $1, %r13 # Kolla om talet är negativt
    jne _store_int
    negq %rdi # Applicera negativt tecken om det behövs

_store_int:
    movq %r12, in_buffer_pos(%rip) # Uppdatera buffert positionen
    movq %rbp, %rsp
    popq %rbp
    ret

_to_inImage:
    call inImage # Anropa inImage för att fylla på buffern
    jmp getInt # Försök läsa om talet

getText:
    pushq %rbx # Spara %rbx
    movq in_buffer_pos(%rip), %rcx  # Ladda aktuell buffert position
    leaq in_buffer(%rip), %rax  # Ladda buffert adressen
    movq $0, %rbx # Initialisera räknare för karaktärer

_getText_loop:
    cmpq $0, %rsi # Kolla om läst tillräckligt med karaktärer
    je _return_GetText # Om ja, avsluta

    movzbq (%rax, %rcx), %rdx   # Ladda en byte från indatabuffern
    movb %dl, (%rdi) # Kopiera till målbuffern
    incq %rcx # Nästa byte i indatabuffern
    movq %rdx, %rbx # Spara karaktär för att kolla nollavslutare

    cmpb $0, %dl # Kolla om slutet på strängen
    je _return_GetText # Om ja, avsluta

    decq %rsi # Minska räknaren
    incq %rdi # Nästa byte i målbuffern
    jmp _getText_loop # Fortsätt loopen

_return_GetText:
    movq %rcx, in_buffer_pos(%rip) # Uppdatera buffert positionen
    movq %rbx, %rax # Returnera antalet lästa karaktärer
    popq %rbx # Återställ %rbx
    ret

getChar:
    pushq %rbp # Bevara basen
    movq %rsp, %rbp # Ställ in basen för sp

_getChar_loop:
    movq in_buffer_pos, %rax  # Ladda buffert pekaren
    leaq in_buffer, %rdx # Ladda buffertens basadress
    movzbl (%rdx, %rax), %ecx    # Ladda aktuell karaktär till %ecx
    testb %cl, %cl # Kolla om karaktären är noll
    jz _to_getChar # Om det är noll, fyll på buffern

    incq %rax # Flytta till nästa karaktär
    movq %rax, in_buffer_pos # Uppdatera buffert pekaren
    popq %rbp # Återställ basen
    ret

_to_getChar:
    call inImage # Fyll på buffern
    jmp _getChar_loop # Hoppa tillbaka till loopen

getInPos:
    movq in_buffer_pos, %rax
    ret

setInPos:
    cmpq $0, %rdi # Jämför indata värdet med 0
    jle _inpos_lower# Om mindre än eller lika med 0, hoppa

    cmpq $63, %rdi # Jämför indata värdet med 63
    jge _inpos_higher # Om större än eller lika med 63, hoppa

    movq %rdi, in_buffer_pos   # Sätt in_buffer_pos till indata värdet
    ret

_inpos_lower:
    movq $0, in_buffer_pos     # Sätt in_buffer_pos till 0
    ret

_inpos_higher:
    movq $63, in_buffer_pos    # Sätt in_buffer_pos till 63
    ret

outImage:
    movq $out_buffer, %rsi    # Ladda buffert adressen
    movq $utstring, %rdi  # Ladda format sträng adressen
    xor %rax, %rax # Rensa eventuella tidigare värden i %rax
    call printf # Anropa printf för att skriva ut strängen

    movq $0, out_buffer_pos    # Återställ buffert positionen
    ret

putInt:
    pushq $0 # 0 för att justera stacken och använda som avgränsare
    movq $10, %rcx # Sätt divisor till 10
    cmpq $0, %rdi # Jämför indatat heltal med 0
    jl _handle_neg_putint # Om negativt, hoppa för att hantera negativa nummer

_putint_negativ_ret:
    movq %rdi, %rax # Flytta heltal till %rax

_putint_loop:
    cqto # Teckens-förläng %rax till %rdx
    divq %rcx # Dividera %rax med 10, kvot i %rax, rest i %rdx
    addq $'0', %rdx # Konvertera resten till ASCII

    pushq %rdx

    cmpq $0, %rax # Kontrollera om kvoten är noll
    je _putint_buffer # Om noll, hoppa
    jmp _putint_loop # Annars, fortsätt loopen

_handle_neg_putint:
    pushq %rdi # push ursprungligt heltal på stacken

    movq $'-', %rdi  # Ladda '-' till %rdi
    call putChar# Anropa putChar för att skriva ut '-'

    popq %rdi # Återställ ursprungligt heltal
    negq %rdi # Negativt heltal
    jmp _putint_negativ_ret # Hoppa tillbaka för att fortsätta konverteringen

_putint_buffer:
    popq %rdi # Poppa en siffra från stacken
    cmpq $0, %rdi # Kontrollera om det är initiala 0
    je _end_putint # Om ja, avsluta

    call putChar # Annars, anropa putChar för att skriva ut siffran

    jmp _putint_buffer # Upprepa tills alla siffror är skrivna

_end_putint:
    ret

putText:
    pushq %rbx # Spara %rbx
    movq out_buffer_pos(%rip), %rax # Ladda aktuell buffert pekare
    leaq out_buffer(%rip), %rdx  # Ladda basadressen för out_buffer
    movq $0, %rbx # Initialisera indexregistret

_loop_in_putText:
    movzbq (%rdi, %rbx), %rcx   # Ladda byte från indatat strängen till %rcx
    movb %cl, (%rdx, %rax)      # Kopiera byte till utdatat buffern
    cmpb $0, %cl # Kontrollera om slutet på strängen
    je _end_puttext # Om slutet på strängen, hoppa till done

    incq %rax # Öka buffert pekaren
    incq %rbx # Öka indatat sträng pekaren
    cmpq $64, %rax # Kontrollera om buffert pekaren överskrider buffert storleken
    je _överflöd_puttext # Om överflöd, hoppa till overflow
    jmp _loop_in_putText        # Upprepa loopen

_överflöd_puttext:
    call outImage  # Anropa outImage för att hantera buffert överskridning
    movq $0, %rax # Återställ buffert pekaren till 0
    jmp _loop_in_putText # Fortsätt bearbetningen av indata

_end_puttext:
    movq %rax, out_buffer_pos(%rip) # Uppdatera buffert pekaren
    popq %rbx # Återställ %rbx
    ret

putChar:
    movq out_buffer_pos(%rip), %rax  # Ladda aktuell buffert pekare
    cmpq $64, %rax                 # Jämför med buffert storleken (64)
    jge _överflöd_putchar              # Om överflöd, hoppa till hantering av överflöde

    leaq out_buffer(%rip), %rdx     # Ladda basadressen för out_buffer
    movb %sil, (%rdx, %rax)        # Kopiera karaktär till buffert
    incq %rax                      # Öka buffert pekaren
    movq %rax, out_buffer_pos(%rip)  # Uppdatera buffert pekaren
    jmp _end_putchar

_överflöd_putchar:
    call outImage # Hantera överflödet
    jmp putChar # Försök skriva karaktär efter hantering av överflöde

_end_putchar:
    ret

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
