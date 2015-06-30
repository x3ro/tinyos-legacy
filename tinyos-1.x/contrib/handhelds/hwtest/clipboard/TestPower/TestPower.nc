/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 * Authors: Andrew Christian <andrew.christian@hp.com>
 *          May 2005
 */

configuration TestPower {
}
implementation {
  components Main, 
    TestPowerM, 
    LedsC,
#ifdef RADIO
    CC2420HighLevelC,
    MessagePoolM,
#endif
#ifdef LCD_LINES
    LCD_B,  
#endif
    TimerC;

  Main.StdControl->TestPowerM;
  Main.StdControl->TimerC;

  TestPowerM.Leds -> LedsC;

#ifdef RADIO
  TestPowerM.RadioStdControl -> CC2420HighLevelC;
  TestPowerM.Radio           -> CC2420HighLevelC;
  TestPowerM.CC2420Control   -> CC2420HighLevelC;
  TestPowerM.MessagePool     -> MessagePoolM;
#endif
#ifdef LCD_LINES  
  TestPowerM.LCD -> LCD_B;
#endif
}

