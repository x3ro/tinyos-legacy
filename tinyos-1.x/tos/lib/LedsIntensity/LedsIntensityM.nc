//$Id: LedsIntensityM.nc,v 1.5 2004/11/08 18:25:31 klueska Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

module LedsIntensityM
{
  provides interface StdControl;
  provides interface LedsIntensity;
  uses interface Leds;
}
implementation
{
  enum
  {
    NUM_LEDS = 3,
    NUM_INTENSITY = 32,
    RESOLUTION = 128,
  };

  bool m_run;
  int8_t m_intensity[NUM_LEDS];
  int8_t m_accum[NUM_LEDS];
  static const int8_t m_exp[NUM_INTENSITY] = {
    0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 4, 5, 6, 7, 8, 9,
    11, 13, 16, 19, 22, 26, 30, 36, 42, 49, 58, 67, 79, 93, 108, 127,
  };

  task void dimleds()
  {
    if( m_run )
    {
      int i;
      int ledval = 0;
      for( i=NUM_LEDS-1; i>=0; i-- )
      {
	ledval <<= 1;
	if( (m_accum[i] += m_intensity[i]) >= 0 )
	{
	  m_accum[i] -= (RESOLUTION-1);
	  ledval |= 1;
	}
      }
      call Leds.set( ledval );
      post dimleds();
    }
    else
    {
      call Leds.set( 0 );
    }
  }

  command void LedsIntensity.set( uint8_t ledNum, uint8_t intensity )
  {
    if( ledNum < NUM_LEDS )
    {
      intensity >>= 3;
      if( intensity >= (NUM_INTENSITY-1) )
      {
	m_intensity[ledNum] = m_exp[NUM_INTENSITY-1];
	m_accum[ledNum] = 0;
      }
      else
      {
	m_intensity[ledNum] = m_exp[intensity];
	if( m_intensity[ledNum] == 0 )
	  m_accum[ledNum] = -1;
      }
    }
  }

  command result_t StdControl.init()
  {
    int i;
    for( i=0; i<NUM_LEDS; i++ )
    {
      m_intensity[i] = 0;
      m_accum[i] = -1;
    }
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_run = TRUE;
    post dimleds();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    m_run = FALSE;
    return SUCCESS;
  }
}

