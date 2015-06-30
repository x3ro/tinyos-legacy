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
 */

/**
 * Implementation of the XnpCount application
 *
 * Author:             Jaein Jeong
 * Date last modified: 06/27/03
 */

//force radio to special 76.8kbaud mode (2)
//#define CC1K_DEFAULT_FREQ	(CC1K_433_002_MHZ76p8)

includes AM;


module XnpCountM {
  provides {
    interface StdControl;
  }
  uses {
    interface Xnp;  
    interface StdControl as CntControl;
    interface TS;
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
    call Xnp.NPX_SET_IDS();               //set mote_id and group_id 

    return SUCCESS;
  }


  /**
   * Start things up.  
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
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
    call CntControl.stop();
    return SUCCESS;
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet,uint16_t wEENofP){
    uint32_t ts;
    call TS.get_timestamp(&ts);

    if (bRet == TRUE)
       call CntControl.start();

    return SUCCESS;
  }
 
 }
