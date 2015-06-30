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
// $Id: PNIMagM.nc,v 1.2 2003/10/07 21:45:39 idgay Exp $

module PNIMagM
{
  provides
  {
    interface PNIMag;
    interface StdControl;
  }
  uses
  {
    interface StdControl as FlashControl;
  }
}
implementation
{
  enum
  {
    STATE_INIT = 0,
    STATE_OFF,
    STATE_BEGIN,
    STATE_CONTINUE,
    STATE_MAGX,
    STATE_MAGY,
    STATE_MAGZ,
    AXIS_X = 1,
    AXIS_Y = 2,
    AXIS_Z = 4,
  };

  int16_t m_data[3];
  uint8_t m_current_axis;
  uint8_t m_command;
  uint8_t m_state;
  uint8_t m_axes;
  uint8_t m_count;


  void spi_write_u8( uint8_t byte )
  {
    uint8_t mask = 0x80;
    while( mask )
    {
      // flash clock low
      TOSH_CLR_FLASH_CLK_PIN();

      // place bit
      if( byte & mask )
	TOSH_SET_FLASH_OUT_PIN();
      else
	TOSH_CLR_FLASH_OUT_PIN();

      // flash clock high
      TOSH_SET_FLASH_CLK_PIN();

      // next bit
      mask >>= 1;
    }

    // flash clock low
    TOSH_CLR_FLASH_CLK_PIN();
  }


  uint16_t spi_read_u16()
  {
    uint16_t value = 0;
    uint8_t n = 16;

    while( n > 0 )
    {
      // shift value left a bit
      value <<= 1;

      // flash clock high
      TOSH_SET_FLASH_CLK_PIN();

      // read bit
      if( TOSH_READ_FLASH_IN_PIN() )
	value |= 1;
      // decrement bit count
      n--;

      // flash clock low
      TOSH_CLR_FLASH_CLK_PIN();
    }

    return value;
  }

  void pni_enable()
  {
    // disable int0
    cbi( EIMSK, INT0 );
    // trigger on rising edge on int0
    sbi( EICRA, ISC00 );
    sbi( EICRA, ISC01 );
    // set up PW0 and PW1 for output
    sbi( DDRC, DDC0 ); // PW0
    sbi( DDRC, DDC1 ); // PW1
    // set SSNOT low to enable the PNI
    TOSH_CLR_PW1_PIN();
    // enable int0
    sbi( EIMSK, INT0 );
  }


  void pni_disable()
  {
    // disable int0
    cbi( EIMSK, INT0 );
    // set SSNOT high to disable the PNI
    TOSH_SET_PW1_PIN();
  }


  void pni_reset()
  {
    // pulse RESET to prepare for a command
    TOSH_SET_PW0_PIN();
    TOSH_CLR_PW0_PIN();
  }


  void pni_write_command( uint8_t cmd )
  {
    pni_reset();
    spi_write_u8( cmd );
  }


  void pni_read_mag( uint8_t axis )
  {
    m_current_axis = axis;
    pni_write_command( (m_command & 0xfc) | (axis+1) );
  }

  task void readDone()
  {
    m_state = STATE_OFF;
    signal PNIMag.readDone( m_data );
  }


  void next_state();
  task void task_next_state() { next_state(); }
  void next_state()
  {
    switch( m_state )
    {
      case STATE_INIT:
	m_state = STATE_OFF;
	pni_disable();
	break;

      case STATE_OFF:
	break;

      case STATE_BEGIN:
	pni_enable();

      case STATE_CONTINUE:
	if( m_axes & AXIS_X )
	{
	  m_state = STATE_MAGX;
	  pni_read_mag(0);
	  break;
	}

      case STATE_MAGX:
	if( m_axes & AXIS_Y )
	{
	  m_state = STATE_MAGY;
	  pni_read_mag(1);
	  break;
	}

      case STATE_MAGY:
	if( m_axes & AXIS_Z )
	{
	  m_state = STATE_MAGZ;
	  pni_read_mag(2);
	  break;
	}

      case STATE_MAGZ:
      default:
	if( --m_count == 0 )
	{
	  pni_disable();
	  post readDone();
	}
	else
	{
	  m_state = STATE_CONTINUE;
	  post task_next_state();
	}
    }
  }


  task void data_ready()
  {
    m_data[m_current_axis] += (int16_t)spi_read_u16();
    next_state();
  }


  TOSH_SIGNAL(SIG_INTERRUPT0)
  {
    post data_ready();
  }


  command result_t PNIMag.read( uint8_t axes, uint8_t period, uint8_t count )
  {
    if( m_state != STATE_OFF || axes == 0 || count == 0 )
      return FAIL;
    m_state = STATE_BEGIN;
    m_axes = axes;
    m_command = (period & 7) << 4;
    m_count = count;
    m_data[0] = 0;
    m_data[1] = 0;
    m_data[2] = 0;
    post task_next_state();
    return SUCCESS;
  }


  void pni_init()
  {
    // initialize the pni into a low power state
    m_state = STATE_INIT;
    m_command = 0x10;
    m_count = 1;
    pni_enable();
    pni_read_mag(0);
  }


  command result_t StdControl.init()
  {
    return call FlashControl.init();
  }


  command result_t StdControl.start()
  {
    call FlashControl.stop();
    pni_init();
    return SUCCESS;
  }


  command result_t StdControl.stop()
  {
    call FlashControl.start();
    return SUCCESS;
  }
}

