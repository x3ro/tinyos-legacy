/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 02/02/04
 */

includes CC1000Const;
includes RSSIDriver;

module RSSIDriverM
{
	provides interface RSSIDriver;

	uses
	{
		interface HPLCC1000;
		interface ADCControl;
		interface StdControl as CommControl;
		interface StdControl as CC1000StdControl;
		interface CC1000Control;
		interface Leds;
	}
}

implementation
{
/*
	We use REFDIV = 14 to get the maximum frequency resolution.
	Note that REFDIV = 15 cannot be used with the 14.7456 MHz crystal.
	IF is 150 KHz. FSEP is always 0 to get an unmodulated signal.
*/
	enum
	{
		RX_FREQ = 0x660000L,	// 430.105543 MHz + 150 KHz, high side LO
		TX_FREQ = 0x65F6E2L,	// 430.105543 MHz
		CHANNEL_SEP = 8192,	// 526.6285 KHz for optimal RX
	};

	norace uint8_t freqReg;	// 0x00 for register A, (1<<CC1K_F_REG) for register B
	norace uint32_t channelFreq; // the calibrated channel frequency

	void setNextFreq(uint32_t freq)
	{
		freqReg = freqReg ? 0x00 : (1<<CC1K_F_REG);
		call HPLCC1000.write(freqReg ? CC1K_FREQ_2B : CC1K_FREQ_2A, (uint8_t)(freq >> 16));
		call HPLCC1000.write(freqReg ? CC1K_FREQ_1B : CC1K_FREQ_1A, (uint8_t)(freq >> 8));
		call HPLCC1000.write(freqReg ? CC1K_FREQ_0B : CC1K_FREQ_0A, (uint8_t)freq);
	}

	enum
	{
		PROG_WAIT = 0xF0,	// shifted by 4
		PROG_WAIT_CAL = 0xF1,
		PROG_END = 0xFF,
	};

	void execute(const prog_uchar *program)
	{
		uint8_t reg, val;
		for(;;)
		{
			reg = PRG_RDB(program++);

			switch( reg )
			{
			case PROG_END:
				return;

			case PROG_WAIT_CAL:
				while( (call HPLCC1000.read(CC1K_CAL) & (1<<CC1K_CAL_COMPLETE)) == 0 )
					;
				break;

			default:
				val = PRG_RDB(program++);

				switch( reg )
				{
					case PROG_WAIT:
						TOSH_uwait(((uint16_t)val) << 4);
						break;

					case CC1K_MAIN:
						val |= freqReg;

					default:
						call HPLCC1000.write(reg, val);
				}
			}
		}
	}

	static const prog_uchar prog_acquire[] = 
	{
		// reset
		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_FS_PD)|(1<<CC1K_BIAS_PD),
		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_FS_PD)|(1<<CC1K_BIAS_PD)|(1<<CC1K_RESET_N),
		PROG_WAIT, 2000 >> 4,

		// setup the basic registers
		CC1K_FSEP1, 0x00,
		CC1K_FSEP0, 0x00,

		CC1K_FRONT_END, 1<<CC1K_IF_RSSI,
		CC1K_PLL, 14<<CC1K_REFDIV,
		CC1K_LOCK, 0x00,
		CC1K_MODEM2, (1<<CC1K_PEAKDETECT)|(55<<CC1K_PEAK_LEVEL_OFFSET),
		CC1K_MODEM1, (3<<CC1K_MLIMIT)|(1<<CC1K_LOCK_AVG_MODE)|(3<<CC1K_SETTLING)|(1<<CC1K_MODEM_RESET_N),
		CC1K_MODEM0, (0<<CC1K_BAUDRATE)|(2<<CC1K_DATA_FORMAT)|(1<<CC1K_XOSC_FREQ),
		CC1K_MATCH, (0x7<<CC1K_RX_MATCH)|(0x0<<CC1K_TX_MATCH),
		CC1K_FSCTRL, (0<<CC1K_SHAPE)|(1<<CC1K_FS_RESET_N),

		// go to idle
		CC1K_PA_POW, 0x00,
		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_RESET_N),
		PROG_WAIT, 200 >> 4,

		PROG_END,
	};

    uint8_t saved_rx_power = 128;
//#ifdef CC1K_DEF_FREQ 
//    uint8_t saved_rx_freq = CC1K_DEF_FREQ;
//#else
//    uint8_t saved_rx_freq = CC1K_DEF_PRESET;
//#endif
// can make this work if we figure out how to get the current freq (other than storing the values of gCurrentParameters array)

	command result_t RSSIDriver.acquire()
	{
		result_t ret;
		
	    saved_rx_power = call CC1000Control.GetRFPower();
	    
		ret = call CommControl.stop()
			&& call HPLCC1000.init()
			&& call ADCControl.bindPort(RSSIDRIVER_ADC_PORT,
				TOSH_ACTUAL_CC_RSSI_PORT)
			&& call ADCControl.setSamplingRate(RSSIDRIVER_SAMPLING_RATE);

		if( ret )
		{
			freqReg = 0x00;		// use regA
			execute(prog_acquire);
			freqReg = (1<<CC1K_F_REG);
		}

		call Leds.yellowOn();
		//call Leds.set(4);

		return ret;
	}


	command result_t RSSIDriver.restore()
	{
		result_t ret;

		ret = call CommControl.stop();
		ret &= call CC1000StdControl.init();
		ret &= call CommControl.start();

        ret &= call CC1000Control.SetRFPower(saved_rx_power);
        
        
		if (ret)
		    call Leds.yellowOff();

		return ret;
	}

	static const prog_uchar prog_calibrate_transmit[] = 
	{
		CC1K_PA_POW, 0x00,
		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),
		CC1K_MAIN, (1<<CC1K_RXTX)|(1<<CC1K_RX_PD)|(1<<CC1K_RESET_N),
		CC1K_CURRENT, (8<<CC1K_VCO_CURRENT)|(1<<CC1K_PA_DRIVE),

		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_START)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),
		PROG_WAIT_CAL,
		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),

		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_FS_PD)|(1<<CC1K_RESET_N),
		PROG_END,
	};

	command result_t RSSIDriver.calibrateTransmit(int8_t channel)
	{
		channelFreq = TX_FREQ + (uint32_t)CHANNEL_SEP * channel;
		setNextFreq(channelFreq);
		execute(prog_calibrate_transmit);
		return SUCCESS;
	}

	static const prog_uchar prog_transmit[] = 
	{
		CC1K_MAIN, (1<<CC1K_RXTX)|(1<<CC1K_RX_PD)|(1<<CC1K_RESET_N),
		CC1K_CURRENT, (8<<CC1K_VCO_CURRENT)|(1<<CC1K_PA_DRIVE),
		PROG_END,
	};
	
	async command result_t RSSIDriver.transmit(uint8_t strength, int16_t tuning)
	{
		setNextFreq(channelFreq + tuning);
		execute(prog_transmit);
		call HPLCC1000.write(CC1K_PA_POW, strength);
		return SUCCESS;
	}

	static const prog_uchar prog_calibrate_receive[] = 
	{
		CC1K_PA_POW, 0x00,
		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),
		CC1K_MAIN, (1<<CC1K_TX_PD)|(1<<CC1K_RESET_N),
		CC1K_CURRENT, (4<<CC1K_VCO_CURRENT)|(1<<CC1K_LO_DRIVE),

		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_START)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),
		PROG_WAIT_CAL,
		CC1K_CAL, (1<<CC1K_CAL_DUAL)|(1<<CC1K_CAL_WAIT)|(6<<CC1K_CAL_ITERATE),

		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_FS_PD)|(1<<CC1K_RESET_N),
		PROG_END,
	};
	
	command result_t RSSIDriver.calibrateReceive(int8_t channel)
	{
		channelFreq = RX_FREQ + (uint32_t)CHANNEL_SEP * channel;
		setNextFreq(channelFreq);
		execute(prog_calibrate_receive);
		return SUCCESS;
	}

	static const prog_uchar prog_receive[] = 
	{
		CC1K_MAIN, (1<<CC1K_TX_PD)|(1<<CC1K_RESET_N),
		CC1K_CURRENT, (4<<CC1K_VCO_CURRENT)|(1<<CC1K_LO_DRIVE),
		CC1K_PA_POW, 0x00,
		PROG_END,
	};
	
	async command result_t RSSIDriver.receive()
	{
		execute(prog_receive);
		return SUCCESS;
	}

	static const prog_uchar prog_suspend[] = 
	{
		CC1K_PA_POW, 0x00,
		CC1K_MAIN, (1<<CC1K_RX_PD)|(1<<CC1K_TX_PD)|(1<<CC1K_FS_PD)|(1<<CC1K_RESET_N),
		PROG_END,
	};
	
	async command result_t RSSIDriver.suspend()
	{
		execute(prog_suspend);
		return SUCCESS;
	}
}
