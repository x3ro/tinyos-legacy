/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:      
 * 
 * $Id: XTestXnpM.nc,v 1.1 2003/06/30 07:05:57 cssharp Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 */

/**
 * Implementation of the TestSnooze application
 */

//force radio to special 76.8kbaud mode (2)
//#define CC1K_DEFAULT_FREQ	(CC1K_433_002_MHZ76p8)

includes AM;


module XTestXnpM {
  provides {
    interface StdControl;
  }
  uses {
    interface Xnp;  
    interface StdControl as GenericCommCtl;
    interface Clock;
    interface Leds;
  }
}
implementation {
#include "Xnp.h"
//#include "AM.h"
  
  
   uint16_t dest;  
   uint8_t  cAck;


  /**
   * Initialize the component.
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    result_t r2;
    call Xnp.NPX_SET_IDS();               //set mote_id and group_id 
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();

    call GenericCommCtl.init();
    return r2;
  }


  /**
   * Start things up.  
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

   event result_t Clock.fire()
  {
    call Leds.yellowToggle();
    return SUCCESS;
  }
/*****************************************************************************
 NPX_DOWNLOAD_REQ
NetProgramming service module has received a request from the network to
download a program srec image. Our choices are:
-Release EEPROM resource and acknowledge OK
-Acknowledge with NO

*****************************************************************************/
  event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP){


//Acknowledge NPX
    call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
    return SUCCESS;
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet,uint16_t wEENofP){
    return SUCCESS;
  }
 
 }
