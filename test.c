#include <stdio.h>

// Declarations of your assembly functions
extern void inImage();
extern void outImage();
extern void putText(const char* text);

int main() {
    // Calling inImage to read input from stdin
    printf("Enter some text: ");
    inImage();

    // Example of calling putText to put some text in out_buffer
    putText("Hello, World!");

    // Calling outImage to print the content of out_buffer
    outImage();

    return 0;
}