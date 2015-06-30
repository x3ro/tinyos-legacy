/* Flash programming funclet to be used with MSP430mspgcc.dll/so.

The data to be programmed is appended to this code by the download
library. Three arguments must be supplied in RAM:
srinit: initial value for SR, used to switch of DCO+
addr:   starting address in flash, where the programmin begins
length: length of the data block that is written to the flash
*/

#include <io.h>

.text
start:  .word   start
        .word   main
        .word   stop

srinit: .word   0                       ;arg 1
addr:   .word   0                       ;arg 2
length: .word   0                       ;arg 3

main:   mov     #WDTPW|WDTHOLD, &WDTCTL ;Disable Watchdog.
        dint                            ;Disable interrupts.
        mov     srinit, r2              ;Initialize status register (Possibly disable FLL+).
        mov     #0xffff, &CCR0          ;CCR is used as return value -> error
;        mov     #0xa544, &FCTL2         ;Source = MCLK, DIV = 5.
        mov     #0xa541, &FCTL2         ;Source = MCLK, DIV = 2
        mov     #0xa500, &FCTL3         ;Clear bits.
        mov     addr, r9                ;Address to program.
        mov     length, r8              ;Length to program.
        mov     #buffer, r10            ;Buffer to program.
.LProg: cmp     @R10, 0(r9)             ;Value already present?
        jeq     .LNext                  ;Yes, so skip and advance to next.
        mov     #(0xa500|WRT), &FCTL1   ;No, so enable writing to flash.
        mov     @R10, 0(r9)             ;Write data to flash.
.LWait: bit     #BUSY, &FCTL3           ;Wait for completion of write.    
        jnz     .LWait                  ;Busy bit is cleared upon completion.
        mov     #0xa500, &FCTL1         ;Reset writing to flash.
        mov     #0xa500, &FCTL3         ;Clear BUSY + LOCK bits.
        cmp     @R10, 0(r9)             ;Verify written data.
        jne     stop                    ;Verification failure
.LNext: incd    r10                     ;Advance source pointer.
        incd    r9                      ;Advance destination pointer.
        dec     r8                      ;Decrement word counter.
        jnz     .LProg                  ;Program Length words.
        clr     &CCR0                   ;set return value -> OK

stop:   jmp     stop                    ;Wait here until detected by driver.

buffer:                                 ;data follows, appended by driver
