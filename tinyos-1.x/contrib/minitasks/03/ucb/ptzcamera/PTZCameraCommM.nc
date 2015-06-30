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

// Authors: Cory Sharp
// $Id: PTZCameraCommM.nc,v 1.2 2003/10/03 21:35:30 cssharp Exp $

includes UARTBaudRate;

module PTZCameraCommM
{
  provides
  {
    interface PTZCmdPantilt;
    interface PTZCmdZoom;
    interface StdControl;
  }
  uses
  {
    interface StdControl as ByteCommStdControl;
    interface ByteComm;
    interface UARTBaudRate;
    interface StdControl as UARTBaudRateControl;
    interface Leds;
    interface Timer;
  }
}
implementation
{
  enum {
    MAX_PACKET_LENGTH = 16,

    EVI_D30 = 0,
    EVI_D100 = 1,
    CAMERA_MODE = EVI_D30,

    ID_Unknown = 0,
    ID_AddressSet,
    ID_IFClear,
    ID_Pantilt,
    ID_Zoom,
  };

  typedef struct {
    uint8_t bytes[ MAX_PACKET_LENGTH ];
    uint8_t length;
    uint8_t n;
    uint8_t id;
    uint8_t pending;
  } buffer_t;

  buffer_t m_out;
  buffer_t m_active[2];
  buffer_t m_in;
  
  bool m_is_sending;
  uint8_t m_init_state;

  void init_camera();

  int16_t minmax( int16_t n, int16_t min, int16_t max )
  {
    return ( (n<min) ? min : ((max<n) ? max : n) );
  }

  int16_t round( float x )
  {
    return (int16_t)(x+0.5);
  }

  void cmdAck( uint8_t id, result_t success )
  {
    if( m_init_state )
      init_camera();

    switch( id )
    {
      case ID_Pantilt: signal PTZCmdPantilt.cmd_ack(success); break;
      case ID_Zoom: signal PTZCmdZoom.cmd_ack(success); break;
      default:
    }
  }

  void cmdDone( uint8_t id, result_t success )
  {
    switch( id )
    {
      case ID_Pantilt: signal PTZCmdPantilt.cmd_done(success); break;
      case ID_Zoom: signal PTZCmdZoom.cmd_done(success); break;
      default:
    }
  }


  bool stalled_buffer( buffer_t* buffer )
  {
    if( buffer->pending )
    {
      // a stalled buffer will reboot in no less than 5 watchdog ticks
      if( ++buffer->pending >= (5+2) )
	return TRUE;
    }
    return FALSE;
  }


  void reboot_buffer( buffer_t* buffer )
  {
    if( buffer->pending )
    {
      if( buffer == &m_out )
	m_is_sending = FALSE;
      buffer->pending = 0;
      cmdAck( buffer->id, FAIL );
      cmdDone( buffer->id, FAIL );
    }
  }


  task void watchdog()
  {
    if( stalled_buffer(&m_out) ) reboot_buffer(&m_out);
    if( stalled_buffer(m_active+0) ) reboot_buffer(m_active+0);
    if( stalled_buffer(m_active+1) ) reboot_buffer(m_active+1);
  }

  
  event result_t Timer.fired()
  {
    post watchdog();
    return SUCCESS;
  }


  result_t send_one_byte()
  {
    if( m_out.n < m_out.length )
      return call ByteComm.txByte( m_out.bytes[ m_out.n ] );
    return FAIL;
  }
  

  async event result_t ByteComm.txByteReady( bool success )
  {
    if( success )
    {
      if( ++m_out.n == m_out.length )
	return SUCCESS;
    }

    if( send_one_byte() == SUCCESS )
      return SUCCESS;

    reboot_buffer( &m_out );
    return FAIL;
  }


  async event result_t ByteComm.txDone()
  {
    return SUCCESS;
  }


  void process_input()
  {
    if( m_in.length >= 2 )
    {
      const uint8_t ni = m_in.bytes[1];
      if(    (ni==0x41) // ack command socket 1
	  || (ni==0x42) // ack command socket 2
	)
      {
	// ack, it's now okay to send another command
	m_active[ni&1] = m_out;
	m_is_sending = FALSE;
	cmdAck( m_out.id, SUCCESS );
      }
      else if(    (ni==0x51) // command complete socket 1
	       || (ni==0x52) // command complete socket 2
	     )
      {
	// command complete, but this does not mean it's okay to send.
	m_active[ni&1].pending = 0;
	cmdDone( m_active[ni&1].id, SUCCESS );
      }
      else // if(    (ni==0x50) // information return
	   //     || (ni==0x30) // address set response
	   //     || (ni==0x01) // ifclear response
	   //     || (ni==0x38) // address set
	   //     || (ni==0x60) // error
	   //  )
      {
	// well, whatever else, it's okay to send now
	m_out.pending = 0;
	m_is_sending = FALSE;
	cmdAck( m_out.id, SUCCESS );
      }
    }
  }



  async event result_t ByteComm.rxByteReady( uint8_t data, bool error, uint16_t strength )
  {
    call Leds.yellowToggle();
      
    if( m_in.n < MAX_PACKET_LENGTH-1 )
    {
      m_in.bytes[ m_in.n++ ] = data;
      if( data == 0xff )
      {
	m_in.length = m_in.n;
	m_in.n = 0;
	process_input();
      }
    }

    return SUCCESS;
  }


  result_t send_bytes( const uint8_t* bytes, uint8_t length, uint8_t id )
  {
    if( m_is_sending == FALSE )
    {
      int ii;

      for( ii=0; ii<length; ii++ )
	m_out.bytes[ii] = bytes[ii];

      m_out.length = length;
      m_out.n = 0;
      m_out.id = id;
      m_out.pending = 0;

      if( send_one_byte() == SUCCESS )
      {
	m_is_sending = TRUE;
	m_out.pending = 1;
	return SUCCESS;
      }

    }
    return FAIL;
  }


  result_t CmdAddressSet_set()
  {
    const uint8_t data[] = { 0x88, 0x30, 0x01, 0xff };
    return send_bytes( data, sizeof(data), ID_AddressSet );
  }

  result_t CmdIFClear_set()
  {
    const char data[] = { 0x88, 0x01, 0x00, 0x01, 0xff };
    return send_bytes( data, sizeof(data), ID_IFClear );
  }


  void init_camera()
  {
    switch( m_init_state )
    {
      case 0: // state 0, fall through
	break;

      case 1: // state 1, send AddressSet
	if( CmdAddressSet_set() == SUCCESS )
	  m_init_state = 2;
	break;

      case 2: // state 2, send IFClear
	if( CmdIFClear_set() == SUCCESS )
	  m_init_state = 0;
	break;
    }
  }


  result_t CmdPantilt_set( int16_t pan, int16_t tilt, bool absolute )
  {
    if( m_init_state ) { init_camera(); return FAIL; }

    switch( CAMERA_MODE )
    {
      case EVI_D30:
	pan  = minmax( pan,  -880, 880 );
	tilt = minmax( tilt, -300, 300 );
	break;
      case EVI_D100:
	pan  = minmax( pan,  -1440, 1440 );
	tilt = minmax( tilt, -360, 360 );
	break;
    }

    {
      const char data[] = { 0x81, 0x01, 0x06, (absolute?0x02:0x03), 0x18, 0x14,
			    SONY_EVI_NIBBLES(pan), SONY_EVI_NIBBLES(tilt), 0xff };
      return send_bytes( data, sizeof(data), ID_Pantilt );
    }
  }

  result_t CmdPantilt_set_rad( float pan, float tilt, bool absolute )
  {
    switch( CAMERA_MODE )
    {
      case EVI_D30:
	pan  *= ((180.0/M_PI) * (880.0/100.0));
	tilt *= ((180.0/M_PI) * (300.0/25.0));
	break;
      case EVI_D100:
	pan  *= ((180.0/M_PI) * (1440.0/100.0));
	tilt *= ((180.0/M_PI) * (360.0/25.0));
	break;
    }

    return CmdPantilt_set( round(pan), round(tilt), absolute );
  }

  command result_t PTZCmdPantilt.set_abs( int16_t pan, int16_t tilt )
  {
    return CmdPantilt_set( pan, tilt, TRUE );
  }


  command result_t PTZCmdPantilt.set_abs_rad( float pan, float tilt )
  {
    return CmdPantilt_set_rad( pan, tilt, TRUE );
  }


  result_t CmdZoom_set_abs( int16_t zoom )
  {
    if( m_init_state ) { init_camera(); return FAIL; }

    switch( CAMERA_MODE )
    {
      case EVI_D30:
	zoom = minmax( zoom, 0, 0x3ff );
	break;
      case EVI_D100:
	zoom = minmax( zoom, 0, 0x7000 );
	break;
    }

    {
      const char data[] = { 0x81, 0x01, 0x04, 0x47, SONY_EVI_NIBBLES(zoom), 0xff };
      return send_bytes( data, sizeof(data), ID_Zoom );
    }
  }


  command result_t PTZCmdZoom.set_abs( int16_t zoom )
  {
    return CmdZoom_set_abs( zoom );
  }

  command result_t PTZCmdZoom.set_abs_factor( float zoom )
  {
    switch( CAMERA_MODE )
    {
      case EVI_D30:
	//zoom = log(log(zoom)+1.0) * 1023.0 / log(log(12.0)+1.0);
	// resolve that constant double log
	zoom = log(log(zoom)+1.0) * (1023.0 / 1.24844125756621);
	break;
      case EVI_D100: // FIXME: this transformation has not been verified
	zoom = (zoom <= 10.0)
	     ? (zoom * 4095.0) / 10.0
	     : ((zoom - 10.0) * (7167-4096)) / 30.0;
	break;
    }

    return CmdZoom_set_abs( round(zoom) );
  }


  event UARTBaudRate_t UARTBaudRate.getInitial()
  {
    return UART_9600_BAUD;
  }

  command result_t StdControl.init()
  {
    call ByteCommStdControl.init();
    call UARTBaudRateControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_is_sending = FALSE;
    m_init_state = 1;
    call ByteCommStdControl.start();
    call UARTBaudRateControl.start();
    call Timer.start( TIMER_REPEAT, 1000 );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    call UARTBaudRateControl.stop();
    call ByteCommStdControl.stop();
    return SUCCESS;
  }


  default event result_t PTZCmdPantilt.cmd_ack( result_t success ) { return SUCCESS; }
  default event result_t PTZCmdPantilt.cmd_done( result_t success ) { return SUCCESS; }
  default event result_t PTZCmdZoom.cmd_ack( result_t success ) { return SUCCESS; }
  default event result_t PTZCmdZoom.cmd_done( result_t success ) { return SUCCESS; }
}

