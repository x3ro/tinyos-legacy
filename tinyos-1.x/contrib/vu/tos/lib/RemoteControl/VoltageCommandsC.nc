/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Gabor Pap
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */

/**
 * The VoltageCommandsC component allows you to query the current voltage of the
 * motes. For some reason this number is not really reliable probably due to 
 * broken ADCs. The voltage as returned by the ADC is reported back.
 * VoltageCommandsC implements the IntCommand interface with appid 37 (0x25).
 *
 * @author Miklos Maroti
 * @modified 02/02/05
 */ 


configuration VoltageCommandsC
{
}

implementation
{
	components Main, VoltageCommandsM, RemoteControlC, VoltageC;

	Main.StdControl -> VoltageC.StdControl;

    // VoltageCommands's appid is 37 (0x25)   
	RemoteControlC.IntCommand[0x25] -> VoltageCommandsM;
	VoltageCommandsM.ADC -> VoltageC.Voltage;
}
