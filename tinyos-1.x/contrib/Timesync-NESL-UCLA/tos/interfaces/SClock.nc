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
/*********************************************************************
 Description: Interface SClock provides commands and events to 
 manipulate the Global Time maintained using the AVR Timer3.
 Timer3 is a 16 bit timer.
**********************************************************************/

includes SClock;
interface SClock {

  /** 
   * Set the rate of the Global Clock i.e. Timer3. Some of the valid
   * time values are set in SClock.h
   **/
  async command result_t SetRate(uint16_t interval, char scale);


  /**
   * Reads the current value of the Timer3 register (TCNT3).
   **/
  async command uint16_t readCounter();


  /**
   * Sets the value of the Timer3 register (TCNT3).
   **/
  async command result_t setCounter(uint16_t n);


  /**
   * Gets the pointer to the Global time data structure
   **/
  async command void getTime(GTime* t);


  /**
   * Command to change the Global time data structure
   **/
  async command void setTime(uint8_t PosOrNeg, GTime* t);


  /**
   * Command to disable all the Timer3 generated interrupts
   **/
  async command void intDisable();


  /**
   * Command to enable all the Timer3 generated interrupts
   **/
  async command void intEnable();

  /**
   * Event triggered upon Timer3 output compare match
   * The output compare match value is incidentally also
   * equal to the Timer3 overflow value.
   **/
  async event result_t fire(uint16_t mTicks);

  /**
   * Event triggered upon the updation of the Global Time
   * data structure during the course of Time Synchronization
   **/
  async event result_t syncDone();
}
