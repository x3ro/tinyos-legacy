/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

includes mc13192Const;

configuration mc13192TOSRadioC
{
	provides {
		interface StdControl as Control;
		interface BareSendMsg as Send;
		interface ReceiveMsg as Receive;
	}
	uses {
		interface FastSPI as SPI;
		interface Debug;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	components mc13192TOSRadioM as Radio,
	           mc13192DataM as Data,
	           mc13192ControlM as RadioControl,
	           mc13192InterruptM as Interrupt,
	           mc13192HardwareM as Hardware,
	           mc13192TimerM as Timer,
	           mc13192TimerCounterM as TimerCounter,
	           mc13192StateM as State,
	           LedsC;

	Control = RadioControl.StdControl;
	Control = Timer.StdControl;
	Control = Data.StdControl;
	Control = Radio.StdControl;
	Send = Radio.Send;
	Receive = Radio.Recv;
	SPI = Hardware.SPI;
	SPI = Data.SPI;
	SPI = Interrupt.SPI;
	

	
	RadioControl.Interrupt -> Interrupt.Control;
	RadioControl.Regs -> Hardware.Regs;
	RadioControl.Timer2 -> Timer.Timer[1];
	RadioControl.Time -> TimerCounter.Time;
	RadioControl.State -> State.State;
	RadioControl.Debug = Debug;

	Data.Time -> TimerCounter.Time;
	Data.Regs -> Hardware.Regs;
	Data.Interrupt -> Interrupt.Data;
	Data.State -> State.State;
	Data.EventTimer -> Timer.EventTimer;
	Data.Timer1 -> Timer.Timer[0];
	Data.Debug = Debug;

	Radio.RadioSend -> Data.Send;
	Radio.RadioRecv -> Data.Recv;
	Radio.StreamOp -> Data.StreamOp;
	Radio.Time -> TimerCounter.Time;
	Radio.Debug = Debug;
	
	Timer.Regs -> Hardware.Regs;
	Timer.Interrupt -> Interrupt.Timer;
	Timer.Debug = Debug;
	
	Interrupt.State -> State.State;
	Interrupt.Debug = Debug;
	
	State.Regs -> Hardware.Regs;
	State.EventTimer -> Timer.EventTimer;
	State.Debug = Debug;
	
	Hardware.Leds -> LedsC;
	Hardware.ConsoleOut = ConsoleOut;
	
	TimerCounter.Regs -> Hardware.Regs;
	TimerCounter.Leds -> LedsC;
	TimerCounter.ConsoleOut = ConsoleOut;
	
	// Timing tests.
	//Control = HPLTimer2M.StdControl;
	//Data.HPLTimer -> HPLTimer2M.HPLTimer;
}
