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
// $Id: PIRDetectFilterC.nc,v 1.3 2005/08/24 01:53:19 phoebusc Exp $
/**
 * See PIRDetectEventM for comments on important parameters
 * not exported by the Registry or interfaces.
 * 
 * @author Phoebus Chen, Mike Manzo
 & @modified 7/21/2005 Migration to work with detectionevent
 * @modified 6/2/2005 Initial Port of UVA Detection Code
 */

includes PIRDetectConst;

configuration PIRDetectFilterC {
  provides interface StdControl;
}

implementation {
  components PIRDetectFilterM;
  components PIRRawDriverC; //Communicates through RegistryC.PIRRawValue
#ifndef NO_LEDS
  components LedsC;
#else
  components NoLeds as LedsC;
#endif
  components TimerC;
  components RegistryC; //Assume Main.StdControl is wired to RegistryC already
  
  StdControl = PIRDetectFilterM;
  StdControl = PIRRawDriverC;

  PIRDetectFilterM.Leds -> LedsC;
  PIRDetectFilterM.DampTimer -> TimerC.Timer[unique("Timer")];

  PIRDetectFilterM.PIRDampTimer -> RegistryC.PIRDampTimer;
  PIRDetectFilterM.PIRRawValue -> RegistryC.PIRRawValue;
  PIRDetectFilterM.PIRDetectValue -> RegistryC.PIRDetectValue;
  //////////Registry Code Start//////////
  PIRDetectFilterM.PIRConfidenceThresh -> RegistryC.PIRConfidenceThresh;
  PIRDetectFilterM.PIRAdaptMinThresh -> RegistryC.PIRAdaptMinThresh;
  //////////Registry Code Stop//////////
}

