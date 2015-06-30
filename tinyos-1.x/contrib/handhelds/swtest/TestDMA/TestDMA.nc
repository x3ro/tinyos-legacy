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
 * Authors: Steve Ayer
 *          April 2005
 */

configuration TestDMA {
}
implementation {
    components 
	Main, 
	TestDMA_M, 
	DMA_M, 
	TimerC, 
	LedsC, 	
	IPCLIENT as IPClientC,
	TelnetM,
	ParamViewM;

    Main.StdControl->TestDMA_M;
    Main.StdControl->TimerC;

    /* have to fix compile time channel limitation */
    TestDMA_M.DMA0         -> DMA_M.DMA[0];
    TestDMA_M.DMA1         -> DMA_M.DMA[1];
    TestDMA_M.DMA2         -> DMA_M.DMA[2];
    TestDMA_M.Leds        -> LedsC;
    TestDMA_M.yTimer       -> TimerC.Timer[unique("Timer")];
    TestDMA_M.gTimer       -> TimerC.Timer[unique("Timer")];
    TestDMA_M.rTimer       -> TimerC.Timer[unique("Timer")];

    /* telnet stuff */
    TestDMA_M.IPStdControl  -> IPClientC;
    TestDMA_M.UIP           -> IPClientC;
    TestDMA_M.Client        -> IPClientC;
    TestDMA_M.TCPClient      -> IPClientC.TCPClient[unique("TCPClient")];

    TestDMA_M.PVStdControl      -> ParamViewM;
    TestDMA_M.TelnetStdControl  -> TelnetM;

    TelnetM.TCPServer            -> IPClientC.TCPServer[unique("TCPServer")];

    ParamViewM.TelnetShow         -> TelnetM.Telnet[unique("Telnet")];
    ParamViewM.ParamView          -> IPClientC.ParamView;
    ParamViewM.ParamView          -> TestDMA_M.ParamView;
    /* end telnet stuff */
}
