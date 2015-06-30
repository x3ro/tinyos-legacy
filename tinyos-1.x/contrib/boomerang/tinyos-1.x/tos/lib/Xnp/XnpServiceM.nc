// $Id: XnpServiceM.nc,v 1.1.1.1 2007/11/05 19:10:06 jpolastre Exp $

/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

/* $Id: XnpServiceM.nc,v 1.1.1.1 2007/11/05 19:10:06 jpolastre Exp $
 *
 * Simple service controller for XNP.
 * When enabled, the red LED blinks once a second with a 20% duty cycle.
 *
 * Author: Cory Sharp
 * Date created: 06/29/03
 */

//!! Config 47 { uint8_t XnpFlags = 0; }


/**
 * @author Cory Sharp
 */

module XnpServiceM
{
  provides interface StdControl as XnpRequiredControl;
  provides interface StdControl as XnpServiceControl;
  uses interface Xnp;  
  uses interface StdControl as XnpControl;  
  uses interface TimedLeds;
  uses interface Timer;
}
implementation
{
  enum
  {
    FLAG_XNP_ENABLED = 0x01,
  };

  bool is_flagged( uint8_t flag ) { return ((G_Config.XnpFlags & flag) != 0) ? TRUE : FALSE; }
  void set_flag( uint8_t flag ) { G_Config.XnpFlags |= flag; } 
  void clear_flag( uint8_t flag ) { G_Config.XnpFlags &= ~flag; }

  command result_t XnpRequiredControl.init()
  {
    call XnpControl.init();
    call Xnp.NPX_SET_IDS(); //set mote_id and group_id 
    return SUCCESS;
  }

  command result_t XnpRequiredControl.start()
  {
    call XnpControl.start();
    return SUCCESS;
  }

  command result_t XnpRequiredControl.stop()
  {
    call XnpControl.stop();
    return SUCCESS;
  }

  command result_t XnpServiceControl.init()
  {
    clear_flag( FLAG_XNP_ENABLED );
    return SUCCESS;
  }

  void blinkStart()
  {
    call Timer.start( TIMER_REPEAT, 1000 );
  }

  void blinkStop()
  {
    call Timer.stop();
  }

  command result_t XnpServiceControl.start()
  {
    set_flag( FLAG_XNP_ENABLED );
    blinkStart();
    return SUCCESS;
  }

  command result_t XnpServiceControl.stop()
  {
    blinkStop();
    clear_flag( FLAG_XNP_ENABLED );
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    call TimedLeds.redOn( 200 );
    return SUCCESS;
  }

  /*
    NPX_DOWNLOAD_REQ

    NetProgramming service module has received a request from the network to
    download a program srec image. Our choices are:

     - Release EEPROM resource and acknowledge OK
     - Acknowledge with NO
  */

  event result_t Xnp.NPX_DOWNLOAD_REQ ( uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP )
  {
    if( is_flagged(FLAG_XNP_ENABLED) )
    {
      blinkStop();
      call Xnp.NPX_DOWNLOAD_ACK( TRUE );
    }
    else
    {
      call Xnp.NPX_DOWNLOAD_ACK( FALSE );
    }

    return SUCCESS; // return value is meaningless
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE( uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP )
  {
    if( bRet == TRUE )
      blinkStart();
    return SUCCESS;
  }
}

