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
// $Id: TestPIRDetect.nc,v 1.3 2005/07/15 21:28:04 phoebusc Exp $
/**
 * Tests detection algorithm in lib/PIRDetectC.
 * See TestPIRDetectM.nc for usage documentation.
 * 
 * @author Phoebus Chen
 * @modified 6/27/2005 Initial Version modified from TestPIRDetectSimple
 */

configuration TestPIRDetect
{
}
implementation
{
  components Main,
             RegistryC,
             KrakenC,
             TestPIRDetectM,
             OscopeC,
             PIRDetectC,
             TimerC,
             LedsC;

  Main.StdControl -> KrakenC;
  Main.StdControl -> TestPIRDetectM;
  Main.StdControl -> OscopeC;

  TestPIRDetectM.Leds -> LedsC;
  TestPIRDetectM.OscopeRaw -> OscopeC.Oscope[0];
  TestPIRDetectM.OscopeDetect -> OscopeC.Oscope[1];
  TestPIRDetectM.StaggerTimer -> TimerC.Timer[unique("Timer")];

  TestPIRDetectM.PIRDetectCtrl -> PIRDetectC;
  TestPIRDetectM.PIRDetection -> RegistryC.PIRDetection;
  TestPIRDetectM.PIRRawData -> RegistryC.PIRRawData;

  //////////Registry Code Start//////////
  TestPIRDetectM.TestValue -> RegistryC.TestValue;
  //////////Registry Code Stop//////////
}
