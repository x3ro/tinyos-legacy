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
 * Basic Application testing functionality of RFPower setting for radio
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/07/20 15:58:04 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
includes AM;
includes testRadio;
configuration RadioSenderC {
}
implementation {
  components Main, RadioSenderM
           , TimerC
           , LedsC
           , RandomLFSR           
           , TDA5250C
           , MarshallerM
           ;           

  Main.StdControl -> RadioSenderM;
  Main.StdControl -> TimerC;
  Main.StdControl -> TDA5250C;
  Main.StdControl -> MarshallerM;

  RadioSenderM.Timer -> TimerC.Timer[unique("Timer")];
  RadioSenderM.Leds -> LedsC;
  RadioSenderM.Random -> RandomLFSR;

  RadioSenderM.TDA5250Modes -> TDA5250C;
  RadioSenderM.TDA5250Config -> TDA5250C;
  RadioSenderM.MarshallerControl -> MarshallerM;
  RadioSenderM.GenericMsgComm -> MarshallerM;

  MarshallerM.ByteComm->TDA5250C;
  MarshallerM.PacketTx->TDA5250C;
}



