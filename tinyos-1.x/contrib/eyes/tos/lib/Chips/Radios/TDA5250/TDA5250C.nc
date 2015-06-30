/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250, switching modes and initializing.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.6 $
 * $Date: 2005/11/29 12:16:07 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

configuration TDA5250C {
  provides {
    interface StdControl;
    interface TDA5250Config;
    interface TDA5250Modes;
    interface ByteComm;
    interface PacketTx;
    interface PacketRx;
    interface FrameSync;	
  }
}
implementation
{
   components TDA5250M, HPLTDA5250C, PotC, BusArbitrationC, DTClockC;

   StdControl = TDA5250M;
   StdControl = HPLTDA5250C;
   StdControl = DTClockC;	
   
   TDA5250Config = TDA5250M;
   TDA5250Modes = TDA5250M;
   ByteComm = TDA5250M;
   PacketTx = TDA5250M;
   PacketRx = TDA5250M;
   FrameSync = TDA5250M;
   
   TDA5250M.Pot -> PotC;
   TDA5250M.PotControl -> PotC.StdControl;
	
   TDA5250M.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
   TDA5250M.HPLTDA5250Data -> HPLTDA5250C;
   TDA5250M.HPLTDA5250Config -> HPLTDA5250C;

   TDA5250M.TicClock -> DTClockC;
   TDA5250M.TicDelta -> DTClockC;	
}
