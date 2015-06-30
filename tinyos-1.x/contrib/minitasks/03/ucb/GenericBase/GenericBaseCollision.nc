/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

includes DefineCC1000;

configuration GenericBase
{
}
implementation
{
  components Main 
           , GenericBaseM as GenericBaseM
	   , RadioCRCPacket as Comm
//	  , GenericComm as GComm
	  , UARTNoCRCPacket
//#if defined(RADIO_CC1000)
	   , CC1000RadioIntM
	   , CC1000ControlM
//#endif
	   , LedsC
	  , TimerC
	   ;

  Main.StdControl -> GenericBaseM;
  Main.StdControl -> TimerC;
  GenericBaseM.UARTControl -> UARTNoCRCPacket;
  GenericBaseM.UARTSend -> UARTNoCRCPacket;
  GenericBaseM.UARTReceive -> UARTNoCRCPacket;

  GenericBaseM.RadioControl -> Comm;
  GenericBaseM.RadioSend -> Comm;
  GenericBaseM.RadioReceive -> Comm;

//  GenericBaseM.CollisionMsg -> Comm.RadioReceive;
  GenericBaseM.Timer -> TimerC.Timer[unique("Timer")];

//#if defined(RADIO_CC1000)
  GenericBaseM.SetTransmitMode -> CC1000RadioIntM.SetTransmitMode;
  GenericBaseM.CC1000Control -> CC1000ControlM;
//#endif

  GenericBaseM.Leds -> LedsC;
}

