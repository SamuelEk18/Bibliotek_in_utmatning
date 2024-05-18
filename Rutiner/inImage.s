.section .bss
.lcomm input_buffer, 256  # Inmatningsbuffert, 256 bytes
.lcomm buffer_position, 4  # Aktuell position i bufferten, 4 bytes

.section .text
.global inImage

inImage:
    pushl %ebp                # Spara gammalt basregister
    movl %esp, %ebp           # Sätt nytt basregister
    subl $8, %esp             # Allokera utrymme på stacken

    # Läs in från tangentbordet till input_buffer
    movl $3, %eax             # Systemanropnummer (sys_read)
    movl $0, %ebx             # File descriptor (stdin)
    leal input_buffer, %ecx   # Adressen till input_buffer
    movl $256, %edx           # Maximalt antal bytes att läsa
    int $0x80                 # Anropa kernel

    # Nollställ den aktuella positionen i bufferten
    movl $0, buffer_position  # Sätt buffer_position till 0

    addl $8, %esp             # Frigör utrymme på stacken
    movl %ebp, %esp           # Återställ stackpekare
    popl %ebp                 # Återställ basregister
    ret                       # Returnera
