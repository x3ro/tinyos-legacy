/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Alec Woo, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

enum {
  TOSH_ACTUAL_PHOTO_PORT = 1,
  TOSH_ACTUAL_TEMP_PORT = 1, 
  TOSH_ACTUAL_MIC_PORT = 2, 
  TOSH_ACTUAL_ACCEL_X_PORT = 3, 
  TOSH_ACTUAL_ACCEL_Y_PORT = 4, 
  TOSH_ACTUAL_MAG_X_PORT = 6, 
  TOSH_ACTUAL_MAG_Y_PORT  = 5
};

enum {
  TOS_ADC_PHOTO_PORT = 1,
  TOS_ADC_TEMP_PORT = 2,
  TOS_ADC_MIC_PORT = 3,
  TOS_ADC_ACCEL_X_PORT = 4,
  TOS_ADC_ACCEL_Y_PORT = 5,
  TOS_ADC_MAG_X_PORT = 6,
  // TOS_ADC_VOLTAGE_PORT = 7,  defined this in hardware.h
  TOS_ADC_MAG_Y_PORT = 8,
};

enum {
  TOS_MAG_POT_ADDR = 0,
  TOS_MIC_POT_ADDR = 1
};

TOSH_ALIAS_PIN(PHOTO_CTL, INT1);
TOSH_ALIAS_PIN(TEMP_CTL, INT2);
TOSH_ALIAS_PIN(TONE_DECODE_SIGNAL, INT3);
TOSH_ALIAS_OUTPUT_ONLY_PIN(MIC_CTL, PW3);
TOSH_ALIAS_OUTPUT_ONLY_PIN(SOUNDER_CTL, PW2);
TOSH_ALIAS_OUTPUT_ONLY_PIN(ACCEL_CTL, PW4);
TOSH_ALIAS_OUTPUT_ONLY_PIN(MAG_CTL, PW5);
TOSH_ALIAS_OUTPUT_ONLY_PIN(MIC_MUX_SEL, PW6);
