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
// $Id: PIRDetectC.nc,v 1.3 2005/07/15 21:28:04 phoebusc Exp $
/**
 *
 * 
 * @author Phoebus Chen, Mike Manzo
 * @modified 6/2/2005 Initial Port of UVA Detection Code
 */

includes PIRDetectConst;

configuration PIRDetectC {
  provides interface StdControl;
}

implementation {
  components 
    RegistryC, //Assume Main.StdControl is wired to RegistryC already
    PIRDetectM, 
    LedsC,
    TimerC,
#ifdef PLATFORM_PC
    FakePIRC as PIRC;
#else
    PIRC;
#endif
  
  StdControl = PIRDetectM;
  
  PIRDetectM.PIRControl -> PIRC;
  PIRDetectM.PIRADC -> PIRC;
  PIRDetectM.PIR -> PIRC;
  PIRDetectM.InitTimer -> TimerC.Timer[unique("Timer")];
  PIRDetectM.SampleTimer -> TimerC.Timer[unique("Timer")];

  PIRDetectM.Leds -> LedsC;

  PIRDetectM.PIRRawData -> RegistryC.PIRRawData;
  PIRDetectM.PIRDetection -> RegistryC.PIRDetection;
  //////////Registry Code Start//////////
  PIRDetectM.PIRConfidenceThresh -> RegistryC.PIRConfidenceThresh;
  PIRDetectM.PIRAdaptMinThresh -> RegistryC.PIRAdaptMinThresh;
  //////////Registry Code Stop//////////
}

