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

configuration mc13192PhyDriverC
{
	provides
	{
		interface StdControl;
		interface PhyReceive;
		interface PhyTransmit;
		interface PhyEnergyDetect;
		interface PhyAttributes;
		interface PhyControl;
		interface PhyReset;
	}
	uses
	{
		interface LocalTime as MCUTime;
		interface FastSPI as SPI;
		interface Debug;
	}
}
implementation
{
	components mc13192PhyDriverM,
	           mc13192PhyInitM,
	           mc13192PhyInterruptM,
	           mc13192PhyTimerM;

	StdControl = mc13192PhyInitM.StdControl;
	StdControl = mc13192PhyTimerM.StdControl;

	PhyReceive = mc13192PhyDriverM.PhyReceive;
	PhyTransmit = mc13192PhyDriverM.PhyTransmit;
	PhyAttributes = mc13192PhyDriverM.PhyAttributes;
	PhyEnergyDetect = mc13192PhyDriverM.PhyEnergyDetect;
	PhyControl = mc13192PhyDriverM.PhyControl;

	PhyReset = mc13192PhyDriverM.PhyReset;
	PhyReset = mc13192PhyInitM.PhyReset;

	mc13192PhyDriverM.Interrupt -> mc13192PhyInterruptM.Interrupt;
	mc13192PhyDriverM.Timer -> mc13192PhyTimerM.Timer;
	mc13192PhyInitM.RadioTime -> mc13192PhyTimerM.Timer;
	mc13192PhyInitM.MCUTime = MCUTime;
	mc13192PhyDriverM.MCUTime = MCUTime;
	
	// Wire up the SPI.
	mc13192PhyInitM.SPI = SPI;
	mc13192PhyDriverM.SPI = SPI;
	mc13192PhyInterruptM.SPI = SPI;
	mc13192PhyTimerM.SPI = SPI;

	// Wire debug module.
	mc13192PhyDriverM.Debug = Debug;
	mc13192PhyInterruptM.Debug = Debug;
	mc13192PhyTimerM.Debug = Debug;
}
