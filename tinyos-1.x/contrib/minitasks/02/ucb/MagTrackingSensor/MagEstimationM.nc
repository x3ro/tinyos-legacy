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
// $Id: MagEstimationM.nc,v 1.2 2003/02/03 23:42:28 cssharp Exp $

includes common_structs;
includes MagHood;
includes TickSensor;

//!! Neighbor 20 { MagHood_t mag; }

//!! Config 20 { uint16_t mag_threshold = 32; }
//!! Config 21 { uint16_t mag_movavg_timer_period = 64; }
//!! Config 22 { Ticks_t leader_quiet_ticks = 16; }
//!! Config 23 { Ticks_t reading_timeout_ticks = 16; }


module MagEstimationM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface U16Sensor;
    interface TickSensor;
    interface Timer;

    interface Config_mag_movavg_timer_period;
    interface Neighbor_mag;
    interface TupleStore;

    interface TimedLeds;

    interface EstimationComm;
  }
}
implementation
{
  bool m_is_processing;
  uint16_t m_sensor_val;

  typedef Pair_int16_t estimate_t;

  Ticks_t m_last_leader_time;
  TOS_Msg m_msg;
  bool m_is_sending;


  Ticks_t backdate( Ticks_t now, Ticks_t delta )
  {
    return (now <= delta) ? 0 : (now - delta);
  }

  
  void check_estimate( Ticks_t now )
  {
    const Neighbor_t* me = call TupleStore.getByAddress( TOS_LOCAL_ADDRESS );
    TupleIterator_t ii = call TupleStore.initIterator();
    int32_t x = 0;
    int32_t y = 0;
    int32_t mag_sum = 0;
    Ticks_t oldest = backdate( now, G_Config.reading_timeout_ticks );

    // quit if already sending
    // quit if the bad bad bad happens
    // quit if uninitialized location
    // quit if our own reading has timed out
    // quit if we've been the leader too recently
    if( (m_is_sending == TRUE)
        || (me == 0)
        || (me->location.coordinate_system == 0)
        || (me->mag.time < oldest)
	|| (backdate( now, G_Config.leader_quiet_ticks ) < m_last_leader_time)
      )
    {
      return;
    }

    while( call TupleStore.getNext(&ii) == TRUE )
    {
      // skip our own reading
      if( ii.tuple->address == me->address )
	continue;

      // do something if this neighbor has a valid location and mag val
      if( (ii.tuple->location.coordinate_system != 0)
	  && (oldest <= ii.tuple->mag.time)
	)
      {
	// quit if this neighbor has a greater or eqivalent mag val as our own
	if( me->mag.val <= ii.tuple->mag.val )
	  return;
	
	// val in the weighted location
	x += ii.tuple->mag.val * ii.tuple->location.pos.x;
	y += ii.tuple->mag.val * ii.tuple->location.pos.y;
	mag_sum += ii.tuple->mag.val;
      }
    }

    // if we got this far, incorporate our own mag val
    x += me->mag.val * me->location.pos.x;
    y += me->mag.val * me->location.pos.y;
    mag_sum += me->mag.val;

    // if we actually have a valid mag val, send out an estimate
    if( mag_sum > 0 )
    {
      Estimation_t estimate = {
	  x : (x*256) / mag_sum,
	  y : (y*256) / mag_sum,
	  z : 0,
	};
      call EstimationComm.sendEstimation( &estimate );
      m_last_leader_time = now;
    }
  }


  task void process_senses()
  {
    Ticks_t now = call TickSensor.get();
    MagHood_t mag = { val : m_sensor_val, time : now };

    if( mag.val >= G_Config.mag_threshold )
    {
      call TimedLeds.redOn( 333 );
      call Neighbor_mag.set( TOS_LOCAL_ADDRESS, &mag );
      check_estimate( now );
    }

    m_is_processing = FALSE;
  }


  command result_t StdControl.init()
  {
    m_is_processing = FALSE;
    m_last_leader_time = 0;
    m_is_sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, G_Config.mag_movavg_timer_period );
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }


  event result_t Timer.fired()
  {
    return call U16Sensor.read();
  }


  event result_t U16Sensor.readDone( uint16_t val )
  {
    if( m_is_processing == FALSE )
    {
      m_is_processing = TRUE;
      m_sensor_val = val;
      post process_senses();
    }
    return SUCCESS;
  }


  event void Neighbor_mag.updatedFromRemote( uint16_t address )
  {
    Ticks_t now = call TickSensor.get();
    const Neighbor_t* nn = call TupleStore.getByAddress( address );
    if( nn != 0 )
    {
      MagHood_t mag = { val : nn->mag.val, time : now };
      call Neighbor_mag.set( address, &mag );
    }
  }


  event void Config_mag_movavg_timer_period.updated()
  {
    call Timer.stop();
    m_is_processing = FALSE;
    call Timer.start( TIMER_REPEAT, G_Config.mag_movavg_timer_period );
  }
}

