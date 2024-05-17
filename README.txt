Datorteknik Lab 3 - "Bibliotek för in- och utmatning (Intel x64 assembler)"
I denna katalog finns de filer ni kan utgå från för att jobba med laborationen.

Följande filer finns (modifiera inte dessa!):
Mprov64.s - testprogram i assembler
test_prog.c - testprogram i C
my_iolib.h - headerfil för test_prog.c
Makefile - används för kompilering etc med verktyget "make" (beskrivs längre ner)
Implementering
Ni ska själva implementera ett antal funktioner som beskrivs i laborations-instruktionen (t.ex. inImage(), getInt(), getText(), etc.). Detta gör ni i en separat fil, t.ex. "lab3_lib.s".

Testprogram
Till er hjälp finns testprogram som använder era funktioner och som förväntas göra vissa utskrifter. Det är dessa testprogram som kommer att köras vid redovisning av laborationen.

Det finns två testprogram: ett assemblerprogram och ett C-program. Ni väljer själva vilket av dessa ni vill använda. Det kan dock vara enklare att följa och modifiera C-programmet.

OBS: Testprogrammen får inte modifieras inför redovisningen! Ni kan dock kopiera och modifiera testprogrammen under utvecklingen för att köra en del i taget.

Kompilering
Vi använder kompilatorn "gcc". Det finns två sätt att kompilera ert program:

1. Kompilering direkt med gcc
Antag att din fil heter "lab3_lib.s" och ditt körbara program ska heta "prog".

Kompilera ditt "lib" med assembler-testprogrammet Mprov64.s:

sh
Kopiera kod
gcc -g -no-pie lab3_lib.s Mprov64.s -o prog
Kompilera alla assemblerfiler (*.s), inkl. testprogrammet Mprov64.s:

sh
Kopiera kod
gcc -g -no-pie *.s -o prog
Kompilera med C-testprogrammet test_prog.c:

sh
Kopiera kod
gcc -g -no-pie lab3_lib.s test_prog.c -o prog
2. Användning av verktyget "make" med Makefile
Verktyget "make" används för att automatisera och förenkla kompilering, speciellt vid stora program med många filer. I en "Makefile" definierar man vad som kan göras med "make". En fördel med "make" är att kompilering bara sker om någon ingående fil har ändrats. Makefilen byggs upp av olika "targets", vilket kan ses som de olika kommandon man vill kunna köra med "make".

Det finns en färdig enkel "Makefile" i katalogen. Du kan modifiera denna med namn på ditt lib (default "lab3_lib.s") och utfiler (asmTest, cTest).

Kompilering för båda testprogrammen (asmTest, cTest):

sh
Kopiera kod
make
alternativt:

sh
Kopiera kod
make all
Kompilera med testprogrammet Mprov64.s (assembler-programmet):

sh
Kopiera kod
make asmTest
Kompilera med testprogrammet test_prog.c (C-programmet):

sh
Kopiera kod
make cTest
Rensa projektkatalogen från temporära filer:

sh
Kopiera kod
make clean
Packa ihop alla filer inför inlämning (submission.tgz):

sh
Kopiera kod
make submission
