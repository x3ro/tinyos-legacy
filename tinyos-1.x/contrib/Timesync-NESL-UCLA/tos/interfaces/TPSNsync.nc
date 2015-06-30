/* -*-C-*- */
/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/**********************************************************************
 Description: The API for the TPSN time synchronization service 
 middleware
***********************************************************************/
includes TPSNMsg;
interface TPSNsync{

  /**
   * Returns the Mticks corresponding to the current Global time 
   **/
  async command uint16_t getTime();

  
  /**
   * Command to freeze the Time Synchronization Protocol
   **/
  async command void freeze();

  
  /**
   * Command to initiate the periodic synchronization mode.
   * @period: Specifies the number of MTicks after which the nodes
   *          exchange synchronization packets.
   **/
  async command void periodicSync(uint16_t period);


  /**
   * Command to synchronize a node instantaneously. The node 
   * immediately exchanges a synchronization packet with the
   * node above its particular level.
   **/
  async command result_t instantSync();


  /**
   * Command to set a Timer based upon on the Global clock
   * @interval: Specifies the interval in MTicks
   * @attribute: ONE_SHOT or PERIODIC
   **/
  async command void setTimer(uint16_t interval, uint8_t attribute);


  /**
   * Command to set an alarm based on a particular Global Time
   * It differs from the setTimer command as follows. 
   * setTime specifies after "HOW MANY" MTicks, we want an event. e.g. Fire after 4 hrs
   * setAlarm specifies "AT WHAT" MTick, we want an event. e.g. Fire at 4 PM
   **/
  async command result_t setAlarm(uint16_t alarm);

  
  /**
   * Event generated when the timer fires
   **/
  async event void timerFire();

  
  /**
   * Event generated when synchronization is done
   **/
  async event result_t syncDone();

  
  /**
   * Event generated when the alarm rings.
   **/
  async event void alarmRing();
}
