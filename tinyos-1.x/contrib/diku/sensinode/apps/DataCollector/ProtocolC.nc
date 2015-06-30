/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
        Author:         Marcus Chang <marcus@diku.dk>
                        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/

includes protocol;

configuration ProtocolC {
	provides {
		interface StdControl;
		interface ProtocolStarter;
	}
	
	uses {
		interface FlashManagerReader;
		interface Timer;
		interface StdOut;
	}
}

implementation {
	components ProtocolM, BufferManagerM, DatasetManagerM, ConnectionC, StatisticsC;

	StdControl = ProtocolM;
	ProtocolStarter = ProtocolM;

	FlashManagerReader = ProtocolM;
	Timer = ProtocolM;
	StdOut = ProtocolM;

	StdControl = ConnectionC;
	StdOut = ConnectionC;
	
	ProtocolM.Connection				->		ConnectionC.Connection;
	ProtocolM.DatasetManager			->		DatasetManagerM.DatasetManager;
	ProtocolM.StatNoConnection 			-> 		StatisticsC.Statistics[unique("Statistic")];
	ProtocolM.StatLostConnection 		-> 		StatisticsC.Statistics[unique("Statistic")];
	ProtocolM.StatGotConnection 		-> 		StatisticsC.Statistics[unique("Statistic")];

	ProtocolM.StatisticsReader			->		StatisticsC.StatisticsReader;
	ProtocolM.StatControl				->		StatisticsC.StdControl;

	StdOut = DatasetManagerM;
	DatasetManagerM.BufferManager		->		BufferManagerM.BufferManager;
}