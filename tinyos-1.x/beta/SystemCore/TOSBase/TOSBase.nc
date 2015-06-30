// $Id: TOSBase.nc,v 1.3 2004/09/20 21:59:29 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Author:	Phil Buonadonna
 * Revision:	$Id: TOSBase.nc,v 1.3 2004/09/20 21:59:29 gtolle Exp $
 */

/**
 * @author Phil Buonadonna
 */

includes TOSBase;

configuration TOSBase {
}
implementation {
  components Main, TOSBaseM, RadioCRCPacket as Comm, FramerM, UART, LedsC;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  components CC1000RadioC as Radio, CC1000RadioIntM;
#elif defined(PLATFORM_TELOS)
  components CC2420RadioC as Radio;
#endif

  Main.StdControl -> TOSBaseM;

  TOSBaseM.UARTControl -> FramerM;
  TOSBaseM.UARTSend -> FramerM;
  TOSBaseM.UARTReceive -> FramerM;
  TOSBaseM.UARTTokenReceive -> FramerM;
  TOSBaseM.RadioControl -> Comm;
  TOSBaseM.RadioSend -> Comm;
  TOSBaseM.RadioReceive -> Comm;

  TOSBaseM.Leds -> LedsC;

  FramerM.ByteControl -> UART;
  FramerM.ByteComm -> UART;

  TOSBaseM.MacControl -> Radio.MacControl;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)
  TOSBaseM.CC1000Control -> Radio.CC1000Control;
  TOSBaseM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  TOSBaseM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
#endif
}

