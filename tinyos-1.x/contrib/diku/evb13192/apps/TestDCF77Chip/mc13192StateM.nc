/* Copyright (c) 2006, Marcus Chang, Jan Flora
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
	Author:		Marcus Chang <marcus@diku.dk>
				Jan Flora <j@nflora.dk>
	Last modified:	June, 2006
*/

#include "mc13192Const.h"

module mc13192StateM {
	provides {
		interface mc13192State as State;
	}
	uses {
		interface mc13192Regs as Regs;
		interface Leds;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	// Global transceiver mode mirror
	uint16_t rxtxMode;
	uint16_t irqMask = 0;
	bool eventTrigOp = FALSE;
	
	// Forward declarations
	void setRXTXMode(uint16_t mode);
	void enableLowerIRQs();
	void disableLowerIRQs();
		
	command result_t State.setEventTrigger()
	{
		atomic eventTrigOp = TRUE;
		return SUCCESS;
	}
	
	command result_t State.clearEventTrigger()
	{
		atomic eventTrigOp = FALSE;
		return SUCCESS;
	}
	
	async command uint16_t State.getRXTXStateMirror()
	{
		uint16_t mirror;
		atomic mirror = rxtxMode;
		return mirror;
	}
	
	async command uint16_t State.getRXTXState()
	{
		uint16_t reg;
		reg = call Regs.read(CONTROL_A); 
		reg &= 0x1F33; // Mask out mode.
		return reg;
	}

	async command result_t State.setRXTXStateMirror(uint16_t reqMode)
	{
		// This is only used to set the state mirror back in
		// to idle mode, when the transceiver has automatically changed
		// state after fx. a successful rx/tx operation.
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		atomic rxtxMode = reqMode;
		return SUCCESS;
	}
	
	async command result_t State.setIdleMode()
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_LNA_CTRL;
		TOSH_SET_RADIO_LNA_CTRL_PIN();
		//DISABLE_PA_CTRL;
		// Clear timer trigger.
		eventTrigOp = FALSE;
		setRXTXMode(IDLE_MODE);
		return SUCCESS;
	}
	
	async command result_t State.setCCAMode(uint8_t mode)
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_LNA_CTRL;
		TOSH_SET_RADIO_LNA_CTRL_PIN();
		//DISABLE_PA_CTRL;
		//ENABLE_RX_ANTENNA;
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		setRXTXMode(CCA_MODE);
		if (mode == STREAM_MODE) {
			// Do ED with stream_mode bit set.
			call Regs.write(0x38, 0x03FF); // WAS: 0x01FF
		}
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	async command result_t State.setEDMode(uint8_t mode)
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_LNA_CTRL;
		TOSH_SET_RADIO_LNA_CTRL_PIN();
		//DISABLE_PA_CTRL;
		//ENABLE_RX_ANTENNA;
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		setRXTXMode(ED_MODE);
		if (mode == STREAM_MODE) {
			// Do ED with stream_mode bit set.
			call Regs.write(0x38, 0x03FF); // WAS: 0x01FF
		}
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	async command result_t State.setRXMode()
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_LNA_CTRL;
		TOSH_SET_RADIO_LNA_CTRL_PIN();
		//DISABLE_PA_CTRL;
		//ENABLE_RX_ANTENNA;
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		setRXTXMode(RX_MODE);
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	async command result_t State.setTXMode()
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_PA_CTRL;
		//DISABLE_LNA_CTRL;
		TOSH_CLR_RADIO_LNA_CTRL_PIN();
		TOSH_SET_RADIO_ANT_CTRL_PIN();
		//ENABLE_TX_ANTENNA;
		setRXTXMode(TX_STRM_MODE);
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	inline async command result_t State.setRXStreamMode()
	{		
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_LNA_CTRL;
		TOSH_SET_RADIO_LNA_CTRL_PIN();
		//DISABLE_PA_CTRL;
		//ENABLE_RX_ANTENNA;
		TOSH_CLR_RADIO_ANT_CTRL_PIN();
		setRXTXMode(RX_STRM_MODE);
		
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	inline async command result_t State.setTXStreamMode()
	{
		//DEASSERT_RXTXEN;
		TOSH_CLR_RADIO_RXTXEN_PIN();
		//ENABLE_PA_CTRL;
		//DISABLE_LNA_CTRL;
		TOSH_CLR_RADIO_LNA_CTRL_PIN();
		//ENABLE_TX_ANTENNA;
		TOSH_SET_RADIO_ANT_CTRL_PIN();
		setRXTXMode(TX_STRM_MODE);
		//atomic irqMask = call Regs.read(IRQ_MASK);
		// Disable all interrupts not rxtx related. 
		//call Regs.write(IRQ_MASK, 0x0040);
		//ASSERT_RXTXEN;
		TOSH_SET_RADIO_RXTXEN_PIN();
		return SUCCESS;
	}
	
	// Helper functions	
	inline void setRXTXMode(uint16_t mode)
	{
		// This entire section is atomic, to ensure that state changes
		// are completed one at a time!
		atomic {
			rxtxMode = mode;
			if (eventTrigOp) mode |= 0x0080;			
			call Regs.write(CONTROL_A, mode);
		}
	}
}
