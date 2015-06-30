/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ----------------------------------------------------------
 * Basic Application testing functionality of receiving over the radio
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/07/20 15:58:04 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
includes AM;
includes testRadio; 
configuration RadioReceiverC {
}
implementation {
  components Main, RadioReceiverM
           , LedsC      
           , TimerC   
           , TDA5250C
           , MarshallerM
           ;           

  Main.StdControl -> RadioReceiverM;
  Main.StdControl -> TimerC;
  Main.StdControl -> TDA5250C; 
  Main.StdControl -> MarshallerM;

  RadioReceiverM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
	RadioReceiverM.ModeTimer -> TimerC.Timer[unique("Timer")];
  RadioReceiverM.Leds  -> LedsC;
  RadioReceiverM.TDA5250Modes -> TDA5250C;
  RadioReceiverM.TDA5250Config -> TDA5250C;
  RadioReceiverM.MarshallerControl -> MarshallerM;
  RadioReceiverM.GenericMsgComm -> MarshallerM;
  RadioReceiverM.PacketRx -> TDA5250C;
  
  MarshallerM.ByteComm->TDA5250C;
  MarshallerM.PacketTx->TDA5250C;
}



