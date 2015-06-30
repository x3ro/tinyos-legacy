/* Flash erase funclet to be used with MSP430mspgcc.dll/so.

Three arguments must be supplied in RAM:
srinit: initial value for SR, used to switch of DCO+
type:   value for FCTL1, which selects MASS, MAIN or single segment erase
addr:   an address within the segment to be erased
*/

#include <io.h>

#define ERASECYCLES   (5296 * 5)

.text
start:  .word   start
        .word   main
        .word   stop

srinit: .word   0
type:   .word   0
addr:   .word   0

main:   mov     #WDTPW|WDTHOLD, &WDTCTL ;Disable Watchdog.
        dint                            ;Disable interrupts.
        mov     srinit, r2              ;Initialize status register (Possibly disable FLL+).
;        mov     #0xa544, &FCTL2         ;Source = MCLK, DIV = 5.
        mov     #0xa541, &FCTL2         ;Source = MCLK, DIV = 2.
        mov     #0xa500, &FCTL3         ;Clear bits.
        mov     #10, r9                 ;Bug requires 10 erase cycles.
.LAgain:mov     type, &FCTL1            ;Load FCTL1 value. MUST CONTAIN PASSWORD.
        mov     addr, r10               ;Load (page) address to erase.
        mov     #0xffff, 0(r10)         ;Write data into the address (to erase the FLASH).
        mov     #(ERASECYCLES/3), r10   ;Delay for FLASH to erase (BUSY does not work on older devices).
.LWait: dec     r10                     ;Loop requires 3 clock cycles.
        jnz     .LWait                  ;
        mov     #0xA500, &FCTL1         ;Clear ERASE + MERAS bits.
        mov     #0xA500, &FCTL3         ;Clear BUSY + LOCK bits.
        dec     r9                      ;Loop on erase cycles.
        jnz     .LAgain                 ;

stop:   jmp     stop                    ;Wait here until detected by driver.
