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
// $Id: HDMagM.nc,v 1.4 2004/03/16 05:32:41 cssharp Exp $

includes HDMag;
includes sensorboard;

module HDMagM
{
  provides
  {
    interface HDMag;
    interface StdControl;
    command void pulseSetReset();
  }
  uses
  {
    interface X9259;
    interface StdControl as X9259Control;

    interface ADC as MagX;
    interface ADC as MagY;
    interface ADCControl;
  }
}
implementation
{
  enum
  {
    STATE_IDLE = 0,
    STATE_BEGIN_READ,
    STATE_READING_X,
    STATE_READING_Y,
    STATE_BEGIN_SET_BIAS,
    STATE_SETTING_BIAS_X,
    STATE_SETTING_BIAS_Y,
    STATE_BEGIN_SET_FILTER,
    STATE_SETTING_FILTER_X,
    STATE_SETTING_FILTER_Y,

    WIPER_BIAS_X   = 1,
    WIPER_BIAS_Y   = 2,
    WIPER_FILTER_X = 0,
    WIPER_FILTER_Y = 3,
  };

  uint8_t m_state;
  uint8_t m_axes;
  uint16_t m_data_x;
  uint16_t m_data_y;
  result_t m_success;


#ifndef PLATFORM_PC

  void power_on()
  {
    TOSH_MAKE_MAG_CTL_OUTPUT();
    TOSH_SET_MAG_CTL_PIN();
    //TOSH_MAKE_BOOST_5V_CTL_OUTPUT();
    //TOSH_SET_BOOST_5V_CTL_PIN();
  }

  void power_off()
  {
    TOSH_MAKE_MAG_CTL_OUTPUT();
    TOSH_CLR_MAG_CTL_PIN();
    //TOSH_MAKE_BOOST_5V_CTL_OUTPUT();
    //TOSH_CLR_BOOST_5V_CTL_PIN();
  }

  void init_setreset()
  {
    HDMAG_MAKE_SETRESET_CLOCK_OUTPUT();
    HDMAG_SET_SETRESET_CLOCK();
  }

  void pulse_setreset()
  {
    HDMAG_MAKE_SETRESET_CLOCK_OUTPUT();
    HDMAG_CLEAR_SETRESET_CLOCK();
    TOSH_uwait(30);
    HDMAG_SET_SETRESET_CLOCK();
    TOSH_uwait(30);
  }

#else // PLATFORM_PC

  enum
  {
    PORT_MAGX = 120,
    PORT_MAGY = 121,
    PORT_MAGZ = 122,
  };

  void power_on() { }
  void power_off() { }
  void init_setreset() { }
  void pulse_setreset() { }

  default command result_t X9259.writeWiper( uint8_t wiper, uint8_t value )
  {
    switch( wiper )
    {
      case WIPER_BIAS_X:
	dbg( DBG_USR1, "(MAG SET BIAS) [honeydot] [x=%d]\n", value );
	break;

      case WIPER_BIAS_Y:
	dbg( DBG_USR1, "(MAG SET BIAS) [honeydot] [y=%d]\n", value );
	break;

      case WIPER_FILTER_X:
	dbg( DBG_USR1, "(MAG SET FILTER) [honeydot] [x=%d]\n", value );
	break;

      case WIPER_FILTER_Y:
	dbg( DBG_USR1, "(MAG SET FILTER) [honeydot] [y=%d]\n", value );
	break;
    }
    signal X9259.commandDone( SUCCESS );
    return SUCCESS;
  }

  default command result_t X9259.globalSaveWipers( uint8_t register_set )
  {
    return SUCCESS;
  }

  default command result_t X9259.globalRestoreWipers( uint8_t register_set )
  {
    return SUCCESS;
  }

  default command result_t X9259Control.init()
  {
    return SUCCESS;
  }

  default command result_t X9259Control.start()
  {
    return SUCCESS;
  }

  default command result_t X9259Control.stop()
  {
    return SUCCESS;
  }

  task void MagX_dataReady()
  {
    signal MagX.dataReady( generic_adc_read(TOS_LOCAL_ADDRESS, PORT_MAGX, 0) );
  }

  default command result_t MagX.getData()
  {
    dbg( DBG_USR1, "(MAG READ ADC) [honeydot] [x]\n" );
    return post MagX_dataReady();
  }

  default command result_t MagX.getContinuousData()
  {
    return FAIL;
  }

  task void MagY_dataReady()
  {
    signal MagY.dataReady( generic_adc_read(TOS_LOCAL_ADDRESS, PORT_MAGY, 0) );
  }

  default command result_t MagY.getData()
  {
    dbg( DBG_USR1, "(MAG READ ADC) [honeydot] [y]\n" );
    return post MagY_dataReady();
  }

  default command result_t MagY.getContinuousData()
  {
    return FAIL;
  }

  default command result_t ADCControl.init()
  {
    return SUCCESS;
  }

  default command result_t ADCControl.setSamplingRate( uint8_t rate )
  {
    return SUCCESS;
  }

  default command result_t ADCControl.bindPort( uint8_t port, uint8_t adcPort )
  {
    return SUCCESS;
  }

#endif //PLATFORM_PC


  result_t set_wiper( uint8_t wiper, uint8_t value )
  {
    return call X9259.writeWiper( wiper, value );
  }

  task void next_state()
  {
    switch( m_state )
    {
      // ---
      // --- Read
      // ---

      case STATE_BEGIN_READ:

	//pulse_setreset();

	if( m_axes & HDMAG_AXIS_X )
	{
	  m_state = STATE_READING_X;
	  if( call MagX.getData() == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_READING_X:

	if( m_axes & HDMAG_AXIS_Y )
	{
	  m_state = STATE_READING_Y;
	  if( call MagY.getData() == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_READING_Y:

	m_state = STATE_IDLE;
	signal HDMag.readDone( m_axes, m_data_x, m_data_y, m_success );
	break;


      // ---
      // --- Set bias
      // ---

      case STATE_BEGIN_SET_BIAS:

	if( m_axes & HDMAG_AXIS_X )
	{
	  m_state = STATE_SETTING_BIAS_X;
	  if( set_wiper( WIPER_BIAS_X, m_data_x ) == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_SETTING_BIAS_X:

	if( m_axes & HDMAG_AXIS_Y )
	{
	  m_state = STATE_SETTING_BIAS_Y;
	  if( set_wiper( WIPER_BIAS_Y, m_data_y ) == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_SETTING_BIAS_Y:

	m_state = STATE_IDLE;
	signal HDMag.setBiasDone( m_success );
	break;


      // ---
      // --- Set filter
      // ---

      case STATE_BEGIN_SET_FILTER:

	if( m_axes & HDMAG_AXIS_X )
	{
	  m_state = STATE_SETTING_FILTER_X;
	  if( set_wiper( WIPER_FILTER_X, m_data_x ) == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_SETTING_FILTER_X:

	if( m_axes & HDMAG_AXIS_Y )
	{
	  m_state = STATE_SETTING_FILTER_Y;
	  if( set_wiper( WIPER_FILTER_Y, m_data_y ) == SUCCESS )
	    break;
	  m_success = FAIL;
	}

      case STATE_SETTING_FILTER_Y:

	m_state = STATE_IDLE;
	signal HDMag.setFilterDone( m_success );
	break;
    }
  }


  async event result_t MagX.dataReady( uint16_t data )
  {
    m_data_x = data;
    post next_state();
    return SUCCESS;
  }

  async event result_t MagY.dataReady( uint16_t data )
  {
    m_data_y = data;
    post next_state();
    return SUCCESS;
  }

  event void X9259.commandDone( result_t success )
  {
    if( m_success == SUCCESS )
      m_success = success;
    post next_state();
  }


  result_t init_state( uint8_t state, uint8_t axes, uint16_t init_x, uint16_t init_y )
  {
    if( (m_state == STATE_IDLE) && ((axes & 0x03) != 0) )
    {
      m_state = state;
      m_axes = axes;
      m_data_x = init_x;
      m_data_y = init_y;
      m_success = SUCCESS;
      return post next_state();
    }
    return FAIL;
  }

  command result_t HDMag.read( uint8_t axes )
  {
    return init_state( STATE_BEGIN_READ, axes, 0, 0 );
  }

  command result_t HDMag.setBias( uint8_t axes, uint8_t biasx, uint8_t biasy )
  {
    return init_state( STATE_BEGIN_SET_BIAS, axes, biasx, biasy );
  }

  command result_t HDMag.setFilter( uint8_t axes, uint8_t filterx, uint8_t filtery )
  {
    return init_state( STATE_BEGIN_SET_FILTER, axes, filterx, filtery );
  }

  command void pulseSetReset()
  {
    pulse_setreset();
  }
  

  command result_t StdControl.init()
  {
    call ADCControl.init();
    power_off();
    call X9259Control.init();
    m_state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    power_on();
    call X9259Control.start();
    init_setreset();
    m_state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    m_state = STATE_IDLE;
    init_setreset();
    call X9259Control.stop();
    power_off();
    return SUCCESS;
  }
}

