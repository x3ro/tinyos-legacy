/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Tian He,Su Ping,Miklos Maroti
// $Id: GlobalAbsoluteTimer.nc,v 1.1.1.1 2005/05/10 23:37:07 rsto99 Exp $


includes TosTime;
interface GlobalAbsoluteTimer {
  /**
   *  start a AbsoluteTimer and set its expire time to t 
   *  If the AbsoluteTimer is started of, return SUCCESS
   *  Else, return FAIL. This unit of time is 1/1000 second.
   **/
  command result_t set(tos_time_t t );
  
  /**
   *  start a AbsoluteTimer and set its expire time to t 
   *  If the AbsoluteTimer is started of, return SUCCESS
   *  Else, return FAIL. This unit of time is 1/32768 second.
   **/
  command result_t set2(tos_time_t t );  
    
  /**
   *  Cancel an absolute timer. 
   *  If the timer does not exist, 
   *  return FALSE.
   **/
  command result_t cancel();

  /**
   *  The AbsoluteTimer exipired event that a timer user needs to handle 
   **/
  event   result_t fired();
  
  /**
   *  Get 64 bit GlobalTime in unit of millisecond
   *  @return false if it hasn't been synchronized by 
   *  @return true if global time has been return successfuuly
   **/  
   
  command result_t getGlobalTime(tos_time_t *t);
  
    /**
   *  Get 64 bit GlobalTime in unit of jiffies
   *  @return false if it hasn't been synchronized by 
   *  @return true if global time has been return successfuuly
   **/     
  command result_t getGlobalTime2(tos_time_t *t);
  
    /**
   *  convert jiffies into millisecond
   *  @return ms 
   **/    
  command uint32_t jiffy2ms(uint32_t jiffy);
   
   /**
   *  convert millisecond into jiffies
   *  @return jiffies 
   **/      
  command uint32_t ms2jiffy(uint32_t ms);
}

