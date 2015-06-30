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

main:   mov.b   #0x00, &P1OUT           ;init IOs
        mov.b   #0x00, &P1SEL           ;
        mov.b   #0xff, &P1DIR           ;
        mov.b   #0x00, &P2OUT           ;
        mov.b   #0x00, &P2SEL           ;
        mov.b   #0xff, &P2DIR           ;
        mov     #20, r14                ;loop N times
.L1:    xor.b   #0xff, &P1OUT           ;P1 is toggled
        mov.b   r14, &P2OUT             ;P2 shows the counter
        mov     #0x3000, r15            ;constant for a delay
.L2:    dec     r15                     ;busy wait delay
        jnz     .L2                     ;
        dec     r14                     ;count loops
        jnz     .L1                     ;

stop:   jmp     stop                    ;end of program, detected by library
