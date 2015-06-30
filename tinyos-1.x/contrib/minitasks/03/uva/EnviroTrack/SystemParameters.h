/* "Copyright (c) 2000-2002 University of Virginia.  
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
 * 
 * Authors: Tian He 
 */

#ifndef __SYSTEMPARAMETERS_H__
#define __SYSTEMPARAMETERS_H__

#include "SysSync.h"

enum {
  MAX_GROUPS = 3,
  PHOTO_EVENT = 99,
  BASE_GROUP = 0,
  BASE_LEADER = 0,
  RANDOM_JITTER = 15,
  SENSING = 1,
  NOTSENSING = 2,
  HOPS = 1,
  GREEN_LED_TICKS = 25,
  RED_LED_TICKS = 25,      
  RANDOM_GROUP_MAX = 50,

  /* Tracking */  
  MAX_EVENTS = 1,
  TRACKING_PORT = 5,
  TRK_SENSOR_BASE = 0,
  SENSE_PER_PURGE = 5,
  MULT_FACTOR = 256,
  ENVIRO_WORKING_CLOCK_RATE=32,	//timer expires ENVIRO_WORKING_CLOCK_RATE times per second

  /* only need to reinstall mote base_leader to reset the parameters in all the motes */
  DEFAULT_GridX = 5,
  DEFAULT_GridY = 2,
  DEFAULT_SENSE_CNT_THRESHOLD  = 3, ///ENVIRO_WORKING_CLOCK_RATE/(DEFAULT_SENSE_CNT_THRESHOLD+1)=32/(3+1)=8 sampling per second
  DEFAULT_SEND_CNT_THRESHOLD = 15, //ENVIRO_WORKING_CLOCK_RATE/(DEFAULT_SENSE_CNT_THRESHOLD+1) report to base per second	      
  DEFAULT_MagThreshold = 18,
  DEFAULT_RECRUIT_THRESHOLD = 8, //EMM_WORKING_CLOCK_RATE/50 reduce it can make group managment faster      
  DEFAULT_EVENTS_BEFORE_SENDING = 4, // 2 report per second to the leader 
  //for GF
  DEFAULT_BEACON_INCLUDED = 0,//if it is 1, beacon function is used. If it is 0, beacon is closed.
  DEFAULT_SENSOR_DISTANCE = 25, //25/10=sensor_distance this needs to be more than double the sensing radius
};




#endif


      
      
