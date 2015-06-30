/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test TDA5250 component
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

configuration TestTDA5250 {
}
implementation
{
  components
      Main,
      TestTDA5250M,
      TimerC,
      TDA5250C as Radio,
      LedsNumberedC as LedsC,
      SerialDumpC,
      RandomLFSR; 
  
  Main.StdControl -> Radio;
  Main.StdControl -> SerialDumpC;
  Main.StdControl -> TestTDA5250M;

  TestTDA5250M.PacketRx -> Radio;
  TestTDA5250M.PacketTx -> Radio;
  TestTDA5250M.TDA5250Modes -> Radio;
  TestTDA5250M.TDA5250Config -> Radio;
  TestTDA5250M.ByteComm -> Radio;

  TestTDA5250M.Random -> RandomLFSR.Random;
  TestTDA5250M.Leds  -> LedsC;
  TestTDA5250M.TxModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.RxModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.CCAModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.SleepModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.TimerModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.SelfPollingModeTimer -> TimerC.TimerMilli[unique("TimerMilli")];

  TestTDA5250M.CommandTimer -> TimerC.TimerMilli[unique("TimerMilli")];
  TestTDA5250M.RawDump -> SerialDumpC;
}
