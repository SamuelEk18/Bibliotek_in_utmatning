#include <stdio.h>

extern void inImage();
extern char input_buffer[256];
extern int buffer_position;

int main() {
    inImage();  // Anropa inImage för att läsa in data
    printf("Input buffer: %s\n", input_buffer);  // Skriv ut innehållet i input_buffer
    printf("Buffer position: %d\n", buffer_position);  // Kontrollera att positionen är nollställd
    return 0;
}

//jag gillar inte gifs det är en fasad