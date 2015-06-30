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
// $Id: PIRDetectSimpleC.nc,v 1.5 2005/07/08 04:11:09 phoebusc Exp $
/**
 *
 * 
 * @author Phoebus Chen, Mike Manzo
 * @modified 6/2/2005 Initial Port of UVA Detection Code
 */

configuration PIRDetectSimpleC {
  provides interface StdControl;
}

implementation {
  components 
    RegistryC,
    PIRDetectSimpleM, 
    LedsC,
    TimerC,
#ifdef PLATFORM_PC
    FakePIRC as PIRC;
#else
    PIRC;
#endif
  
  StdControl = PIRDetectSimpleM;
  
  PIRDetectSimpleM.PIRControl -> PIRC;
  PIRDetectSimpleM.PIRADC -> PIRC;
  PIRDetectSimpleM.PIR -> PIRC;
  PIRDetectSimpleM.InitTimer -> TimerC.Timer[unique("Timer")];
  PIRDetectSimpleM.SampleTimer -> TimerC.Timer[unique("Timer")];

  PIRDetectSimpleM.Leds -> LedsC;

  PIRDetectSimpleM.PIRRawData -> RegistryC.PIRRawData;
  PIRDetectSimpleM.PIRDetection -> RegistryC.PIRDetection;
  //////////Registry Code Start//////////
  PIRDetectSimpleM.MotionThreshold -> RegistryC.MotionThreshold;
  //////////Registry Code Stop//////////
}

