#include <stdio.h>

extern void inImage(char *buffer);

int main() {
    char buffer[1024];

    // Anropa inImage för att läsa in en rad från tangentbordet
    inImage(buffer);

    // Skriv ut den inlästa raden
    printf("Inmatad rad: %s\n", buffer);

    return 0;
}
