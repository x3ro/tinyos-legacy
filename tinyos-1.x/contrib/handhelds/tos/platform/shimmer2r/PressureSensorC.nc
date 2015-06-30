/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
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
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
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
 * @author Steve Ayer
 * @date   October, 2010
 */

configuration PressureSensorC {
  provides {
    interface StdControl;
    interface PressureSensor;
  }
}

implementation {
  components BMP085M, MSP430InterruptC, MSP430GeneralIOC, MSP430I2CC, LedsC;

  StdControl     = BMP085M;
  PressureSensor = BMP085M;
  
  BMP085M.Leds -> LedsC;

  BMP085M.MSP430Interrupt -> MSP430InterruptC.Port13;
  BMP085M.MSP430GeneralIO -> MSP430GeneralIOC.Port13;

  BMP085M.I2CPacket     -> MSP430I2CC;
  BMP085M.I2CStdControl -> MSP430I2CC;

  BMP085M.I2CControl    -> MSP430I2CC.MSP430I2C;
  BMP085M.I2CPacket     -> MSP430I2CC.MSP430I2CPacket;
  BMP085M.I2CEvents     -> MSP430I2CC.MSP430I2CEvents;
  BMP085M.I2CStdControl -> MSP430I2CC.StdControl;
}

