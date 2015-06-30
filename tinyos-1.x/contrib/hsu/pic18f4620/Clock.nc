// $Id: Clock.nc,v 1.1 2005/04/15 10:00:07 hjkoerber Exp $

/*									
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

/*
 * The hardware clock interface. 
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Nelson Lee
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 
 * $Date: 2005/04/15 10:00:07 $
 * $Revision: 1.1 $
 *
 */


includes Clock;
includes timers;

interface Clock {


  async command result_t setRate(uint16_t interval, uint8_t scale);

  /**
   *  Set clock interval 
   * 
   *  @param value New clock interval
   *
   *  @return none
   **/
  async command void setInterval(uint16_t value);

  /**
   *  Set clock interval at next clock interrupt time
   * 
   *  @param value New clock interval
   *
   *  @return none
   **/
  async command void setNextInterval(uint16_t value);

  /**
   *  Get clock interval 
   * 
   *  @return current clock interval
   **/
  async command uint16_t getInterval();

  /**
   *  Get clock scale 
   * 
   *  @return current clock scale level
   **/  
  async command uint8_t getScale();

  /**
   *  Set clock scale at next clock interrupt time 
   * 
   *  @param scale New clock scale
   *
   *  @return none
   **/
  async command void setNextScale(uint8_t scale);

  /**
   *  Set both clock interval and scale
   * 
   *  @param interval New clock interval
   *
   *  @param scale New clock scale
   *
   *  @return SUCCESS or FAILED 
   **/
  async command result_t setIntervalAndScale(uint16_t interval, uint8_t scale);

  /**
   *  Read HW clock counter
   */
  async command uint16_t readCounter() ;

  /**
   *  Set HW clock counter to a specified value
   *
   *  @param n Value to write to TMR1
   *
   *  @return None
   */
  async command void setCounter(uint16_t n);


  /**
   *  Disable Clock interrupt
   */
  async command void intDisable();


  /**
   *  Enable Clock interrupt
   */
  async command void intEnable() ;


  /**
   *  An event sent when the clock goes off.
   **/
  async event result_t fire();
}










