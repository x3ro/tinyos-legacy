#include "motelib.h"

/*  
 * Empty functions to link in case module does not use these interrupts
 */

void MainUartTransmitInterrupt() { return; }

void MainUartReceiveInterrupt(uint8 *data, int bytes) { return; }

void RTOSClockInterrupt() { return; }

void GPIOInterrupt() { return; }


