/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
 */
// $Id: TestPIRDetectM.nc,v 1.3 2005/07/15 21:28:04 phoebusc Exp $
/**
 * Tests functionality of lib/PIRDetectC module.  Uses Registry pass data
 * between application and PIRDetectC module.
 * 
 * PIR Detection Reports as well as Raw ADC data readings are sent out
 * as Oscope Packets.
 *
 * @author Phoebus Chen
 * @modified 6/27/2005 Initial version modified from TestPIRDetectSimple
 */

includes Registry;

module TestPIRDetectM
{
  provides interface StdControl;
  uses interface Oscope as OscopeRaw;
  uses interface Oscope as OscopeDetect;
  uses interface Attribute<uint16_t> as TestValue @registry("TestValue");
  uses interface Attribute<uint16_t> as PIRDetection @registry("PIRDetection");
  uses interface Attribute<uint16_t> as PIRRawData @registry("PIRRawData");
  uses interface StdControl as PIRDetectCtrl;
  uses interface Leds;
  uses interface Timer as StaggerTimer;
}

implementation
{
  uint16_t lastDetect;

  command result_t StdControl.init() {    
    call Leds.init();
    call PIRDetectCtrl.init();
    return SUCCESS;
    //    return rcombine(call Leds.init(),call PIRDetectCtrl.init());
  }


  command result_t StdControl.start() {
    //////////Registry Code Start//////////
    call TestValue.set(100);
    //////////Registry Code Stop//////////
    return call PIRDetectCtrl.start();
  }


  command result_t StdControl.stop() {
    return call PIRDetectCtrl.stop();
  }


  event result_t StaggerTimer.fired() {
    if (!call OscopeDetect.put(lastDetect)) {
      call Leds.redOn(); //Signifies that detections are too quick for radio
    }
    return SUCCESS;
  }


  event void PIRDetection.updated(uint16_t val) {
    lastDetect = val;
  }


  event void PIRRawData.updated(uint16_t val) {
    dbg(DBG_USR1, "%d - TestPIRDetectM.PIRRawData.updated: val = %u\n",
	TOS_LOCAL_ADDRESS, val);
    if (!call OscopeRaw.put(val)) {
      call Leds.redOn(); //Signifies that detections are too quick for radio
    }
    call StaggerTimer.start(TIMER_ONE_SHOT, 5); 
  }

  //////////Registry Code Start//////////
  event void TestValue.updated(uint16_t val) {
  }
  //////////Registry Code Stop//////////
}

