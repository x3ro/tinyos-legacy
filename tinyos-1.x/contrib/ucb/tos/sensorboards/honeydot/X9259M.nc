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

// Authors: Cory Sharp
// $Id: X9259M.nc,v 1.2 2003/10/07 21:45:39 idgay Exp $

module X9259M
{
  provides
  {
    interface X9259;
    interface StdControl;
  }
  uses
  {
    interface I2CPacket;
    interface StdControl as I2CPacketControl;
  }
}
implementation
{
  enum
  {
    STATE_IDLE = 0,
    STATE_WRITE_WIPER,
    STATE_GLOBAL_SAVE,
    STATE_GLOBAL_RESTORE,

    STOP_FLAG = 0x01,
    ADDR_8BITS_FLAG = 0x80,
  };

  uint8_t m_data[2];
  uint8_t m_state;


  event result_t I2CPacket.writePacketDone( bool result )
  {
    m_state = STATE_IDLE;
    signal X9259.commandDone( result ? SUCCESS : FAIL );
    return FAIL;
  }

  event result_t I2CPacket.readPacketDone( char length, char* data )
  {
    return FAIL;
  }

  command result_t X9259.writeWiper( uint8_t wiper, uint8_t value )
  {
    if( m_state == STATE_IDLE )
    {
      m_state = STATE_WRITE_WIPER;
      m_data[0] = 0xa0 | (wiper & 0x03);
      m_data[1] = value;
      return call I2CPacket.writePacket( 2, m_data, ADDR_8BITS_FLAG|STOP_FLAG );
    }
    return FAIL;
  }

  result_t send_command( uint8_t state, uint8_t cmdbyte )
  {
    if( m_state == STATE_IDLE )
    {
      m_state = state;
      m_data[0] = cmdbyte;
      return call I2CPacket.writePacket( 1, m_data, ADDR_8BITS_FLAG|STOP_FLAG );
    }
    return FAIL;
  }

  command result_t X9259.globalSaveWipers( uint8_t register_set )
  {
    uint8_t cmdbyte = 0x80 | ((register_set & 0x03) << 2);
    return send_command( STATE_GLOBAL_SAVE, cmdbyte );
  }

  command result_t X9259.globalRestoreWipers( uint8_t register_set )
  {
    uint8_t cmdbyte = 0x10 | ((register_set & 0x03) << 2);
    return send_command( STATE_GLOBAL_RESTORE, cmdbyte );
  }


  command result_t StdControl.init()
  {
    m_state = STATE_IDLE;
    call I2CPacketControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call I2CPacketControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call I2CPacketControl.stop();
    m_state = STATE_IDLE;
    return SUCCESS;
  }
}

