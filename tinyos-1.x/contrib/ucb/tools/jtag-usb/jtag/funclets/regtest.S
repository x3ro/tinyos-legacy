/* Demo funclet
can be used to play with the -f option of the python jtag tool.

This programm must be linked specialy so that it's placed in the RAM.
(see makfile).
The first six bytes and its contents is mandatory. Also must the funclet
end with a "jmp $" instruction.

chris <cliechti@gmx.net>
*/

#include <io.h>

.text
start:  .word   start                   ;target address to download in MSP430
        .word   main                    ;staring address of code
        .word   stop                    ;end address, where the "jmp $" is located

main:   mov     #0x04aa, R4
        mov     #0x05aa, R5
        mov     #0x06aa, R6
        mov     #0x07aa, R7
        mov     #0x08aa, R8
        mov     #0x09aa, R9
        mov     #0x10aa, R10
        mov     #0x11aa, R11
        mov     #0x12aa, R12
        mov     #0x13aa, R13
        mov     #0x14aa, R14
        mov     #0x15aa, R15

stop:   jmp     stop                    ;end of program, detected by library
