#include "types.h"

void printf(char* str){
    static uint16_t* VideoMemory = (uint16_t*) 0xb8000;
    for(int i = 0; str[i]!='\0'; ++i)
        //VideoMemory[i] = (0x0F << 8) | str[i];
        VideoMemory[i] = (VideoMemory[i] & 0xff00) | str[i];
}

typedef void (*constructor)();
extern "C" constructor start_ctors;
extern "C" constructor end_ctors;
/*extern "C" void callConstructors()
{
    for(constructor* i = *start_ctors; i!=*end_ctors; i++)
        (*i)(); //in the loader .extern callConstructors in loader call callConstructors after stack pointer
}*/


extern "C" void kernelMain(void* multiboot_structure, uint32_t /*magicnumber*/)
{
    printf("Hello World(ADO<3)! --- https://github.com/amssGuard");

    while(1);
}
