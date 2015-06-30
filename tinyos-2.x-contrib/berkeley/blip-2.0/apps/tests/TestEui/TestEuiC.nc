// $Id: TestEuiC.nc,v 1.1 2010/05/05 21:46:49 sdhsdh Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */

/**
 * This application reads the 64-bit EUI of the device at initialization time
 * and then periodically, and prints it out using printf.
 *
 */

#include <PrintfUART.h>
#define printf(fmt, args ...) printfUART(fmt, ## args)
#define printfflush() ;

module TestEuiC
{
  uses interface Boot;
  uses interface Timer<TMilli>;
  uses interface Leds;
  uses interface LocalIeeeEui64;
}
implementation
{
  void print() {
  }

  event void Boot.booted()  {
    printfUART_init();
    call Timer.startPeriodic(1000);
  }

  event void Timer.fired() {
    int i;
    ieee_eui64_t id;

    call Leds.led0Toggle();

    id = call LocalIeeeEui64.getId();

    printf("IEEE 64-bit UID: ");
    for(i=0;i<8;i++) {
      printf("%x ", id.data[i]);
    }
    printf("\n");
  	printfflush();

  }
}

