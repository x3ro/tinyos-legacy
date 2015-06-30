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
// $Id: TestPIRDetectSimple.nc,v 1.6 2005/07/07 21:08:26 phoebusc Exp $
/**
 * For demonstrating Trios interoperability with Nucleus/Registry.
 * 
 * @author Phoebus Chen
 * @modified 6/9/2005 Most Basic Detection Code
 */

configuration TestPIRDetectSimple
{
}
implementation
{
  components Main,
             RegistryC,
             KrakenC,
             TestPIRDetectSimpleM,
             OscopeC,
             PIRDetectSimpleC,
             TimerC,
             LedsC;

  Main.StdControl -> KrakenC;
  Main.StdControl -> TestPIRDetectSimpleM;
  Main.StdControl -> OscopeC;

  TestPIRDetectSimpleM.Leds -> LedsC;
  TestPIRDetectSimpleM.OscopeRaw -> OscopeC.Oscope[0];
  TestPIRDetectSimpleM.OscopeDetect -> OscopeC.Oscope[1];
  TestPIRDetectSimpleM.StaggerTimer -> TimerC.Timer[unique("Timer")];

  TestPIRDetectSimpleM.PIRDetectCtrl -> PIRDetectSimpleC;
  TestPIRDetectSimpleM.PIRDetection -> RegistryC.PIRDetection;
  TestPIRDetectSimpleM.PIRRawData -> RegistryC.PIRRawData;

  //////////Registry Code Start//////////
  TestPIRDetectSimpleM.TestValue -> RegistryC.TestValue;
  //////////Registry Code Stop//////////
}
