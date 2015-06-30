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
 * @date   March, 2010
 *
 * @author Steve Ayer
 * @date   February, 2011
 *
 * broken out from original gyromagboard* interface/implementation
 *
 * wiring to msp430 i2c implmentation to flesh out gyro/mag board on shimmer2
 * using direct module because we don't need arbitration for this platform.
 */

configuration MagnetometerC {
  provides {
    interface StdControl;
    interface Magnetometer;
  }
}

implementation {
  components HMC5843M, MSP430I2CC, TimerC;
  
  StdControl = HMC5843M;
  Magnetometer = HMC5843M;

  HMC5843M.testTimer     -> TimerC.Timer[unique("Timer")];

  HMC5843M.I2CPacket     -> MSP430I2CC;
  HMC5843M.I2CStdControl -> MSP430I2CC;

  HMC5843M.I2CControl    -> MSP430I2CC.MSP430I2C;
  HMC5843M.I2CPacket     -> MSP430I2CC.MSP430I2CPacket;
  HMC5843M.I2CEvents     -> MSP430I2CC.MSP430I2CEvents;
  HMC5843M.I2CStdControl -> MSP430I2CC.StdControl;
}

