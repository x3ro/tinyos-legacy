//$Id: LocalTimeMicroM.nc,v 1.1.1.1 2007/11/05 19:10:14 jpolastre Exp $

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

module LocalTimeMicroM 
{
  provides interface LocalTime;
  uses interface MSP430Timer as CounterFrom;
}
implementation
{
  typedef uint32_t to_size_type;
  typedef uint16_t from_size_type;
  typedef uint16_t upper_count_type;

  enum
  {
    bit_shift_right = 0,
    LOW_SHIFT_RIGHT = bit_shift_right,
    HIGH_SHIFT_LEFT = 8*sizeof(from_size_type) - LOW_SHIFT_RIGHT,
    //NUM_UPPER_BITS = 8*sizeof(to_size_type) - 8*sizeof(from_size_type) + bit_shift_right,
    //OVERFLOW_MASK = (1 << NUM_UPPER_BITS) - 1,
  };

  upper_count_type m_upper = 0;

  async command to_size_type LocalTime.read()
  {
    to_size_type rv = 0;
    atomic
    {
      upper_count_type high = m_upper;
      from_size_type low = call CounterFrom.read();
      if( call CounterFrom.isOverflowPending() )
      {
	// If we signalled CounterFrom.overflow, that might trigger a
	// Counter.overflow, which breaks atomicity.  The right thing to do
	// increment a cached version of high without overflow signals.
	// m_upper will be handled normally as soon as the out-most atomic
	// block is left unless Clear.clearOverflow is called in the interim.
	// This is all together the expected behavior.
	high++;
	low = call CounterFrom.read();
      }
      {
	to_size_type high_to = high;
	to_size_type low_to = low >> LOW_SHIFT_RIGHT;
	rv = (high_to << HIGH_SHIFT_LEFT) | low_to;
      }
    }
    return rv;
  }

  async event void CounterFrom.overflow()
  {
    atomic
    {
      m_upper++;
      /*
      if( (m_upper & OVERFLOW_MASK) == 0 )
        signal LocalTime.overflow();
      */
    }
  }
}

