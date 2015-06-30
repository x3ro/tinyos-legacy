/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 *
 * WSN Link Layer Adapter - a proxy interface on the existing driver that
 * implements an interface known by the ULLA (methods and queries), enabling
 * the ULLA to forward queries and method calls to the driver through the LLA.
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UQLCmdMsg;
includes UllaQuery;
includes MultiHop;
includes AMTypes;

configuration UllaLinkProviderC {
  provides {
    interface LinkProviderIf[uint8_t id]; // replacement of RequestUpdate
    //interface StdControl;
    
  }
	
}
implementation {

  components 
      Main
    , UllaLinkProviderM
		, LedsC
#ifndef MAKE_PC_PLATFORM
    , CC2420ControlM
		, CC2420RadioC
#endif
    ;

  //Main.StdControl -> UllaLinkProviderM;
  //StdControl = UllaLinkProviderM;

  UllaLinkProviderM.Leds -> LedsC;
  LinkProviderIf = UllaLinkProviderM;

#if defined(TELOS_PLATFORM) || defined(SIM_TELOS_PLATFORM) || defined(MICAZ_PLATFORM)
  UllaLinkProviderM.CC2420Control -> CC2420ControlM;
#endif

}
