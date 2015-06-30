/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:  Andrew Christian <andrew.christian@hp.com>
 *           Brian Avery      <b.avery@hp.com>
 *           May 2005
 **/

includes InfoMem;

module TestPowerM {
  provides interface StdControl;

  uses {
#ifdef RADIO
    interface StdControl as RadioStdControl;
    interface Message2   as Radio;
    interface CC2420Control;
    interface MessagePool;
#endif
    interface Leds;
  }
}
implementation {

  task void activeTask()
  {
    volatile int v;
    while (1) {
      v = TBR;
    }
  }

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call Leds.init();
#ifdef RADIO
    call RadioStdControl.init();
#endif
    return SUCCESS;
  }

  command result_t StdControl.start() {
#ifdef RADIO
    call CC2420Control.set_pan_coord( TRUE );
    call CC2420Control.set_short_address( 1 );
    call CC2420Control.set_pan_id( infomem->pan_id );

    call RadioStdControl.start();
#endif

#ifdef BACKLIGHT
    TOSH_SET_LCD_BACKLIGHT_PIN();
#endif

#ifdef IR
    TOSH_CLR_IR_LOWPRW_H_PIN();
#endif

#ifdef IRDA
    TOSH_SET_MCP2150_EN_H_PIN();
#endif

#ifdef MSP
    post activeTask();
#endif
    return SUCCESS;
  }

  command result_t StdControl.stop() {
#ifdef RADIO
    call RadioStdControl.stop();
#endif
    return SUCCESS;
  }

  /*******************************************************************************/

#ifdef RADIO
  event void Radio.receive( struct Message *msg ) 
  {
    call MessagePool.free(msg);
  }

  event void Radio.sendDone( struct Message *msg, result_t result )
  {
    call MessagePool.free(msg);
  }
#endif
}


