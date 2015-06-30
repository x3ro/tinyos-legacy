// $Id: TelosPWMM.nc,v 1.6 2005/06/07 23:38:19 shawns Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// revised by John Breneman - 5/9/05 <johnyb_4@berkeley.edu>

module TelosPWMM
{
  provides interface StdControl;
  provides interface TelosPWM;

  uses interface MSP430Compare as High0Alarm;
  uses interface MSP430Compare as High1Alarm;
  uses interface MSP430Compare as High2Alarm;
  uses interface MSP430Compare as High3Alarm;
  uses interface MSP430TimerControl as High0AlarmControl;
  uses interface MSP430TimerControl as High1AlarmControl;
  uses interface MSP430TimerControl as High2AlarmControl;
  uses interface MSP430TimerControl as High3AlarmControl;
  uses interface MSP430GeneralIO as PWMPort0;
  uses interface MSP430GeneralIO as PWMPort1;
  uses interface MSP430GeneralIO as PWMPort2;
  uses interface MSP430GeneralIO as PWMPort3;
}
implementation
{
  uint16_t m_freq;
  uint16_t m_high0;
  uint16_t m_high1;
  uint16_t m_high2;
  uint16_t m_high3;

  char isHigh0;
  char isHigh1;
  char isHigh2;
  char isHigh3;

  command result_t StdControl.init()
  {
    atomic
    {
      call PWMPort0.setLow();
      call PWMPort0.makeOutput();
      call PWMPort0.selectIOFunc();

      call PWMPort1.setLow();
      call PWMPort1.makeOutput();
      call PWMPort1.selectIOFunc();

      call PWMPort2.setLow();
      call PWMPort2.makeOutput();
      call PWMPort2.selectIOFunc();

      call PWMPort3.setLow();
      call PWMPort3.makeOutput();
      call PWMPort3.selectIOFunc();

      m_freq = 546;            // default frequency is 60Hz on a 32kHz clock
      m_high0 = 0;
      m_high1 = 0;
      m_high2 = 0;
      m_high3 = 0;

      isHigh0 = 0;
      isHigh1 = 0;
      isHigh2 = 0;
      isHigh3 = 0;

    }
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic
    {
      call TelosPWM.setHigh0( m_high0 );
      call TelosPWM.setHigh1( m_high1 );
      call TelosPWM.setHigh2( m_high2 );
      call TelosPWM.setHigh3( m_high3 );
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic
    {
      call High0AlarmControl.disableEvents();
      call High1AlarmControl.disableEvents();
      call High2AlarmControl.disableEvents();
      call High3AlarmControl.disableEvents();
   }
    return SUCCESS;
  }

  async command void TelosPWM.setFreq( uint16_t micro )
  {
    atomic
      {
	m_freq = micro >> 5;
      }
  }

  async command void TelosPWM.setHigh0( uint16_t micro )
  {
    atomic
    {
      m_high0 = micro >> 5;
      if( m_high0 == 0 )
      {
	call High0AlarmControl.disableEvents();
      }
      else
      {
	if( call High0AlarmControl.areEventsEnabled() == FALSE )
	{
	  call High0Alarm.setEventFromNow(2);
	  call High0AlarmControl.clearPendingInterrupt();
	  call High0AlarmControl.enableEvents();
	}
      }
    }
  }

  async command void TelosPWM.setHigh1( uint16_t micro )
  {
    atomic
    {
      m_high1 = micro >> 5;
      if( m_high1 == 0 )
      {
	call High1AlarmControl.disableEvents();
      }
      else
      {
	if( call High1AlarmControl.areEventsEnabled() == FALSE )
	{
	  call High1Alarm.setEventFromNow(2);
	  call High1AlarmControl.clearPendingInterrupt();
	  call High1AlarmControl.enableEvents();
	}
      }
    }
  }

  async command void TelosPWM.setHigh2( uint16_t micro )
  {
    atomic
    {
      m_high2 = micro >> 5;
      if( m_high2 == 0 )
      {
	call High2AlarmControl.disableEvents();
      }
      else
      {
	if( call High2AlarmControl.areEventsEnabled() == FALSE )
	{
	  call High2Alarm.setEventFromNow(2);
	  call High2AlarmControl.clearPendingInterrupt();
	  call High2AlarmControl.enableEvents();
	}
      }
    }
  }

  async command void TelosPWM.setHigh3( uint16_t micro )
  {
    atomic
    {
      m_high3 = micro >> 5;
      if( m_high3 == 0 )
      {
	call High3AlarmControl.disableEvents();
      }
      else
      {
	if( call High3AlarmControl.areEventsEnabled() == FALSE )
	{
	  call High3Alarm.setEventFromNow(2);
	  call High3AlarmControl.clearPendingInterrupt();
	  call High3AlarmControl.enableEvents();
	}
      }
    }
  }

  async event void High0Alarm.fired()
  {
    atomic
    {
      if( isHigh0==1 )
	{
	  call High0Alarm.setEventFromNow( m_freq - m_high0 );
	  call PWMPort0.setLow();
	  call High0AlarmControl.clearPendingInterrupt();
	  call High0AlarmControl.enableEvents();
	  isHigh0 = 0;
	}
      else 
	{
	  call High0Alarm.setEventFromNow( m_high0 );
	  call PWMPort0.setHigh();
	  call High0AlarmControl.clearPendingInterrupt();
	  call High0AlarmControl.enableEvents();
	  isHigh0 = 1;
	}
    }
  }

  async event void High1Alarm.fired()
  {
    atomic
    {
      if( isHigh1==1 )
	{
	  call High1Alarm.setEventFromNow( m_freq - m_high1 );
	  call PWMPort1.setLow();
	  call High1AlarmControl.clearPendingInterrupt();
	  call High1AlarmControl.enableEvents();
	  isHigh1 = 0;
	}
      else 
	{
	  call High1Alarm.setEventFromNow( m_high1 );
	  call PWMPort1.setHigh();
	  call High1AlarmControl.clearPendingInterrupt();
	  call High1AlarmControl.enableEvents();
	  isHigh1 = 1;
	}
    }
  }

  async event void High2Alarm.fired()
  {
    atomic
    {
      if( isHigh2==1 )
	{
	  call High2Alarm.setEventFromNow( m_freq - m_high2 );
	  call PWMPort2.setLow();
	  call High2AlarmControl.clearPendingInterrupt();
	  call High2AlarmControl.enableEvents();
	  isHigh2 = 0;
	}
      else 
	{
	  call High2Alarm.setEventFromNow( m_high2 );
	  call PWMPort2.setHigh();
	  call High2AlarmControl.clearPendingInterrupt();
	  call High2AlarmControl.enableEvents();
	  isHigh2 = 1;
	}
    }
  }

  async event void High3Alarm.fired()
  {
    atomic
    {
      if( isHigh3==1 )
	{
	  call High3Alarm.setEventFromNow( m_freq - m_high3 );
	  call PWMPort3.setLow();
	  call High3AlarmControl.clearPendingInterrupt();
	  call High3AlarmControl.enableEvents();
	  isHigh3 = 0;
	}
      else 
	{
	  call High3Alarm.setEventFromNow( m_high3 );
	  call PWMPort3.setHigh();
	  call High3AlarmControl.clearPendingInterrupt();
	  call High3AlarmControl.enableEvents();
	  isHigh3 = 1;
	}
    }
  }

}

