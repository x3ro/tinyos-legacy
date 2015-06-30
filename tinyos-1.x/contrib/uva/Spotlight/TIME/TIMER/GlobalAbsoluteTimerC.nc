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
// $Id: GlobalAbsoluteTimerC.nc,v 1.1.1.1 2005/05/10 23:37:07 rsto99 Exp $

includes GlobalAbsoluteTimer;

#define TIME_SYNC 

configuration GlobalAbsoluteTimerC {

     provides interface GlobalAbsoluteTimer[uint8_t id];
     provides interface StdControl;

 }
 implementation {
     components TimerC, GlobalAbsoluteTimerM, TimeUtilC,LedsC;

#ifdef SOWN_DBG  
  components DebugC,RegisterC;
#else
  components NoDebug as DebugC,NoRegisterC as RegisterC;  
#endif
  
#ifdef TIME_SYNC    
     components TimeSyncC;
#else 
     components ClockC;    
#endif
      
     GlobalAbsoluteTimer = GlobalAbsoluteTimerM;
     StdControl = GlobalAbsoluteTimerM;
     GlobalAbsoluteTimerM.TimerControl -> TimerC;
     GlobalAbsoluteTimerM.Timer -> TimerC.Timer[unique("Timer")];
     GlobalAbsoluteTimerM.TimeUtil -> TimeUtilC;
     GlobalAbsoluteTimerM.Leds ->LedsC;
     
#ifdef TIME_SYNC
	  GlobalAbsoluteTimerM.GlobalTime ->TimeSyncC.GlobalTime;
#else
	  GlobalAbsoluteTimerM.LocalTime ->ClockC; 	
#endif
     GlobalAbsoluteTimerM.Debug ->DebugC; 	          
}
