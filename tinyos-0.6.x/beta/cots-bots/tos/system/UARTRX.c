/*									tab:4
 * Sarah Bergbreiter
 * 11/8/2001
 * COTS-BOTS
 *
 * This is a component implementation of a receive-only uart.  The purpose is 
 * to limit the program memory space required to receive data from the whisker
 * board which communicates by sending data over the UART.
 *
 * History:
 * 11/8/2001 - created.
 *
 */

#include "tos.h"
#include "UARTRX.h"
#include "dbg.h"

//#define TOS_FRAME_TYPE UART_frame
//TOS_FRAME_BEGIN(UART_frame) {
//}
//TOS_FRAME_END(UART_frame);


char TOS_COMMAND(UARTRX_INIT)(){
  outp(25, UBRR);  // set baud rate to 9600
  outp(0x90,UCR);
  sei();

  dbg(DBG_BOOT, ("UART initialized\n"));
  return 1;
}

TOS_SIGNAL_HANDLER(_uart_recv_, (char bitIn)){
  TOS_CALL_COMMAND(UARTRX_TOGGLE_LED)();
  if(inp(USR) & 0x80){ // Will always be 0 in fullpc: inp() resolves to 1
    TOS_SIGNAL_EVENT(UARTRX_RX_BYTE_READY)(inp(UDR));
  }
  dbg(DBG_UART, ("signal: bitIn %d\n", bitIn));
}



