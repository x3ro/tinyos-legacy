// $Id: XnpRfmToLedsM.nc,v 1.7 2003/10/07 21:45:27 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * Implementation of the XnpRfmToLeds application
 *
 * Author:             Jaein Jeong
 * Date last modified: 06/27/03
 * @author Jaein Jeong
 */

//force radio to special 76.8kbaud mode (2)
//#define CC1K_DEF_PRESET	(CC1K_433_002_MHZ76p8)

includes AM;


module XnpRfmToLedsM {
  provides {
    interface StdControl;
  }
  uses {
    interface Xnp;  
    interface StdControl as CommControl;
  }
}
implementation {
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
    return SUCCESS;
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet,uint16_t wEENofP){

    return SUCCESS;
  }
 
 }
