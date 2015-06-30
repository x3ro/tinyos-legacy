// $Id: PIC18F4620_Test_I2C.nc,v 1.1 2005/05/02 07:37:48 hjkoerber Exp $

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
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
 */

/* @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/05/02 07:37:48 $
 * $Revision: 1.1 $
 */

/*
 * This configuration describes the PIC18F4620_Test_I2 application,
 * a simple TinyOS app that periodically takes sensor readings
 * from the Microchip TC74 I2C temperature sensor which is onboard of the 
 * Microchip PICDEM PLUS 2 DEMO BOARD 
 */

configuration PIC18F4620_Test_I2C{ }
implementation
{
  components Main, PIC18F4620_Test_I2CM, PIC18F4620TimerC,I2CPacketC as I2C;

  Main.StdControl -> PIC18F4620_Test_I2CM;
  Main.StdControl -> PIC18F4620TimerC;

  
  PIC18F4620_Test_I2CM.Timer -> PIC18F4620TimerC.Timer[unique("Timer")];
  
  PIC18F4620_Test_I2CM.I2CControl -> I2C;
  PIC18F4620_Test_I2CM.I2CPacket -> I2C;
 
}
