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
 * Authors:		Jaein Jeong
 * Date last modified:  6/25/02
 *
 */

module ChipconM {
  provides interface Chipcon;
  uses interface HPLChipcon;
}
implementation
{
  uint8_t tunefreq;
  uint8_t rfpower;

  uint8_t CC1K_freqs[4][23];

  result_t chipcon_init();
  result_t chipcon_cal();
  char serial_delay(int u_sec);
  char serial_delay_null_func();

  command result_t Chipcon.init(uint8_t freq) {
    tunefreq = freq;
    chipcon_init();  // start up the radio clock and vco
    call Chipcon.tune(freq);	     // go to default tune frequency
    rfpower = CC1K_freqs[freq][0xc];

    return SUCCESS;
  }

  command result_t Chipcon.tune(uint8_t freq) {
    int i;
    tunefreq = freq;
    rfpower = CC1K_freqs[freq][0xc];

    for (i=1;i<10;i++)
      call HPLChipcon.write(i,CC1K_freqs[freq][i]);

    call HPLChipcon.write(10,CC1K_freqs[freq][11]);
    call HPLChipcon.write(11,CC1K_freqs[freq][12]);
    call HPLChipcon.write(12,CC1K_freqs[freq][13]);

    for (i=13;i<20;i++)
      call HPLChipcon.write(i,CC1K_freqs[freq][i+2]);

    call HPLChipcon.write(0x1c,CC1K_freqs[freq][0x16]);
    chipcon_cal();

    call Chipcon.rxmode();

    return SUCCESS;
  }

  command result_t Chipcon.txmode() {
    call HPLChipcon.write(0,0xe1);  // main register to tx mode
    call HPLChipcon.write(0x09,CC1K_freqs[tunefreq][0x0a]);
    call HPLChipcon.write(0x0b,0xff);
    call HPLChipcon.write(0x0c,CC1K_freqs[tunefreq][0x0e]);

    return SUCCESS;
  }

  command result_t Chipcon.rxmode() {
    call HPLChipcon.write(0,0x11);  // main register to rx mode
    call HPLChipcon.write(0x09,CC1K_freqs[tunefreq][0x09]);
    call HPLChipcon.write(0x0b,0x00); // turn off power amp
    call HPLChipcon.write(0x0c,CC1K_freqs[tunefreq][0x0d]);

    return SUCCESS;
  }

  command result_t Chipcon.sleep() {
    call HPLChipcon.write(0,0x3b);  // main register to SLEEP mode
    return SUCCESS;
  }

  command result_t Chipcon.awake() {
    call Chipcon.rxmode();
    serial_delay(500);
    return SUCCESS;
  }

  command result_t Chipcon.off() {
    call HPLChipcon.write(0,0x3f);  // main register to power down mode
    return SUCCESS;
  }

  command result_t Chipcon.on() {
    call HPLChipcon.write(0,0x3b);  // wake up xtal osc
    serial_delay(2000);
    call HPLChipcon.write(0,0x11);  // main register to rx mode
    call HPLChipcon.write(0x09,CC1K_freqs[tunefreq][0x09]);
    call HPLChipcon.write(0x0b,0x00); // turn off power amp
    call HPLChipcon.write(0x0c,CC1K_freqs[tunefreq][0x0d]);

    return SUCCESS;
  }

  command result_t Chipcon.rf_power(uint8_t power) {
    rfpower = power;
    call HPLChipcon.write(0x0b,rfpower); // turn off power amp
    return 1;
  }

  command result_t Chipcon.rf_pwup() {
    if (rfpower < 0xff)
      rfpower++;
    call HPLChipcon.write(0x0b,rfpower); // turn off power amp
    return SUCCESS;
  }

  command result_t Chipcon.rf_pwdn() {
    if (rfpower > 0) 
      rfpower--;
    call HPLChipcon.write(0x0b,rfpower); // turn off power amp
    return SUCCESS;
  }

  char serial_delay(int u_sec) {
        int cnt;
        for(cnt=0;cnt<u_sec/8;cnt++)
                serial_delay_null_func();
        return 1;
  }

  char serial_delay_null_func() {
        return 1;
  }

  ///************************************************************/
  ///* Function: chipcon_init                                   */
  ///* Description: places the chipcon radio in calibrate mode  */
  ///*                                                          */
  ///************************************************************/

  result_t chipcon_init() {
    call HPLChipcon.init();

    // 433 mhz 19.2kb manchester
    CC1K_freqs[0][0x0] = 0x31; //main
    CC1K_freqs[0][0x1] = 0x58; //rx freq
    CC1K_freqs[0][0x2] = 0x00; //rx freq
    CC1K_freqs[0][0x3] = 0x00; //rx freq
    CC1K_freqs[0][0x4] = 0x57; //tx freq
    CC1K_freqs[0][0x5] = 0xf7; //tx freq
    CC1K_freqs[0][0x6] = 0x85; //tx freq
    CC1K_freqs[0][0x7] = 0x03; //fsep1
    CC1K_freqs[0][0x8] = 0x55; //fsep0
    CC1K_freqs[0][0x9] = 0x84; //9 RX current mode
    CC1K_freqs[0][0xa] = 0x81; //9 TX current mode MAX SETTING
    CC1K_freqs[0][0xb] = 0x02;//a
    CC1K_freqs[0][0xc] = 0xff;// b rf power out
    CC1K_freqs[0][0xd] = 0x60; //c rx refdiv
    CC1K_freqs[0][0xe] = 0x60; //c tx refdiv
    CC1K_freqs[0][0xf] = 0xe0;
    CC1K_freqs[0][0x10] = 0x26;
    CC1K_freqs[0][0x11] = 0xa1;
    CC1K_freqs[0][0x12] = 0x6f;
    CC1K_freqs[0][0x13] = 0x57;
    CC1K_freqs[0][0x14] = 0x70;
    CC1K_freqs[0][0x15] = 0x01;
    CC1K_freqs[0][0x16] = 0x00;

    CC1K_freqs[1][0x0] = 0x31; //main
    CC1K_freqs[1][0x1] = 0x58; //rx freq
    CC1K_freqs[1][0x2] = 0x20; //rx freq
    CC1K_freqs[1][0x3] = 0x00; //rx freq
    CC1K_freqs[1][0x4] = 0x58; //tx freq
    CC1K_freqs[1][0x5] = 0x17; //tx freq
    CC1K_freqs[1][0x6] = 0x85; //tx freq
    CC1K_freqs[1][0x7] = 0x03; //fsep1
    CC1K_freqs[1][0x8] = 0x55; //fsep0
    CC1K_freqs[1][0x9] = 0x84; //9 RX current mode
    CC1K_freqs[1][0xa] = 0x81; //9 TX current mode MAX SETTING
    CC1K_freqs[1][0xb] = 0x02;//a
    CC1K_freqs[1][0xc] = 0xff;// b rf power out
    CC1K_freqs[1][0xd] = 0x60; //c rx refdiv
    CC1K_freqs[1][0xe] = 0x60; //c tx refdiv
    CC1K_freqs[1][0xf] = 0xe0;
    CC1K_freqs[1][0x10] = 0x26;
    CC1K_freqs[1][0x11] = 0xa1;
    CC1K_freqs[1][0x12] = 0x6f;
    CC1K_freqs[1][0x13] = 0x57;
    CC1K_freqs[1][0x14] = 0x70;
    CC1K_freqs[1][0x15] = 0x01;
    CC1K_freqs[1][0x16] = 0x00;

    CC1K_freqs[2][0x0] = 0x31; //main
    CC1K_freqs[2][0x1] = 0x58; //rx freq
    CC1K_freqs[2][0x2] = 0x40; //rx freq
    CC1K_freqs[2][0x3] = 0x00; //rx freq
    CC1K_freqs[2][0x4] = 0x58; //tx freq
    CC1K_freqs[2][0x5] = 0x37; //tx freq
    CC1K_freqs[2][0x6] = 0x85; //tx freq
    CC1K_freqs[2][0x7] = 0x03; //fsep1
    CC1K_freqs[2][0x8] = 0x55; //fsep0
    CC1K_freqs[2][0x9] = 0x84; //9 RX current mode
    CC1K_freqs[2][0xa] = 0x81; //9 TX current mode MAX SETTING
    CC1K_freqs[2][0xb] = 0x02;//a
    CC1K_freqs[2][0xc] = 0xff;// b rf power out
    CC1K_freqs[2][0xd] = 0x60; //c rx refdiv
    CC1K_freqs[2][0xe] = 0x60; //c tx refdiv
    CC1K_freqs[2][0xf] = 0xe0;
    CC1K_freqs[2][0x10] = 0x26;
    CC1K_freqs[2][0x11] = 0xa1;
    CC1K_freqs[2][0x12] = 0x6f;
    CC1K_freqs[2][0x13] = 0x57;
    CC1K_freqs[2][0x14] = 0x70;
    CC1K_freqs[2][0x15] = 0x01;
    CC1K_freqs[2][0x16] = 0x00;

    CC1K_freqs[3][0x0] = 0x31; //main
    CC1K_freqs[3][0x1] = 0x58; //rx freq
    CC1K_freqs[3][0x2] = 0x60; //rx freq
    CC1K_freqs[3][0x3] = 0x00; //rx freq
    CC1K_freqs[3][0x4] = 0x58; //tx freq
    CC1K_freqs[3][0x5] = 0x57; //tx freq
    CC1K_freqs[3][0x6] = 0x85; //tx freq
    CC1K_freqs[3][0x7] = 0x03; //fsep1
    CC1K_freqs[3][0x8] = 0x55; //fsep0
    CC1K_freqs[3][0x9] = 0x84; //9 RX current mode
    CC1K_freqs[3][0xa] = 0x81; //9 TX current mode MAX SETTING
    CC1K_freqs[3][0xb] = 0x02;//a
    CC1K_freqs[3][0xc] = 0xff;// b rf power out
    CC1K_freqs[3][0xd] = 0x60; //c rx refdiv
    CC1K_freqs[3][0xe] = 0x60; //c tx refdiv
    CC1K_freqs[3][0xf] = 0xe0;
    CC1K_freqs[3][0x10] = 0x26;
    CC1K_freqs[3][0x11] = 0xa1;
    CC1K_freqs[3][0x12] = 0x6f;
    CC1K_freqs[3][0x13] = 0x57;
    CC1K_freqs[3][0x14] = 0x70;
    CC1K_freqs[3][0x15] = 0x01;
    CC1K_freqs[3][0x16] = 0x00;

/*
// 915 mhz 19.2kb

    CC1K_freqs[1][0x0] = 0x31; //main
    CC1K_freqs[1][0x1] = 0x7c; //rx freq
    CC1K_freqs[1][0x2] = 0x00; //rx freq
    CC1K_freqs[1][0x3] = 0x00; //rx freq
    CC1K_freqs[1][0x4] = 0x7b; //tx freq
    CC1K_freqs[1][0x5] = 0xf9; //tx freq
    CC1K_freqs[1][0x6] = 0xae; //tx freq
    CC1K_freqs[1][0x7] = 0x02; //fsep1
    CC1K_freqs[1][0x8] = 0x39; //fsep0
    CC1K_freqs[1][0x9] = 0x88; //9 RX current mode
    CC1K_freqs[1][0xa] = 0xf3; //9 TX current mode MAX SETTING
    CC1K_freqs[1][0xb] = 0x02;//a
    CC1K_freqs[1][0xc] = 0xff;// b rf power out
    CC1K_freqs[1][0xd] = 0x40; //c rx refdiv
    CC1K_freqs[1][0xe] = 0x40; //c tx refdiv
    CC1K_freqs[1][0xf] = 0x10;
    CC1K_freqs[1][0x10] = 0x26;
    CC1K_freqs[1][0x11] = 0xa1;
    CC1K_freqs[1][0x12] = 0x6f;
    CC1K_freqs[1][0x13] = 0x57;
    CC1K_freqs[1][0x14] = 0x20;
    CC1K_freqs[1][0x15] = 0x01;
    CC1K_freqs[1][0x16] = 0x00;

    CC1K_freqs[2][0x0] = 0x31; //main
    CC1K_freqs[2][0x1] = 0x7c; //rx freq
    CC1K_freqs[2][0x2] = 0x00; //rx freq
    CC1K_freqs[2][0x3] = 0x00; //rx freq
    CC1K_freqs[2][0x4] = 0x7b; //tx freq
    CC1K_freqs[2][0x5] = 0xf9; //tx freq
    CC1K_freqs[2][0x6] = 0xae; //tx freq
    CC1K_freqs[2][0x7] = 0x02; //fsep1
    CC1K_freqs[2][0x8] = 0x39; //fsep0
    CC1K_freqs[2][0x9] = 0x88; //9 RX current mode
    CC1K_freqs[2][0xa] = 0xf3; //9 TX current mode MAX SETTING
    CC1K_freqs[2][0xb] = 0x02;//a
    CC1K_freqs[2][0xc] = 0xff;// b rf power out
    CC1K_freqs[2][0xd] = 0x40; //c rx refdiv
    CC1K_freqs[2][0xe] = 0x40; //c tx refdiv
    CC1K_freqs[2][0xf] = 0x10;
    CC1K_freqs[2][0x10] = 0x26;
    CC1K_freqs[2][0x11] = 0xa1;
    CC1K_freqs[2][0x12] = 0x6f;
    CC1K_freqs[2][0x13] = 0x57;
    CC1K_freqs[2][0x14] = 0x20;
    CC1K_freqs[2][0x15] = 0x01;
    CC1K_freqs[2][0x16] = 0x00;
*/
    call HPLChipcon.write(0,0x3a); // wake up xtal reset unit
    call HPLChipcon.write(0,0x3b); // clear reset
    serial_delay(2000);        // reset timeout
    call HPLChipcon.write(0,0x39);  // wake up bias and synth
    serial_delay(200);

    return SUCCESS;
  }

  ///************************************************************/
  ///* Function: chipcon_cal                                    */
  ///* Description: places the chipcon radio in calibrate mode  */
  ///*                                                          */
  ///************************************************************/

  result_t chipcon_cal()
  {
    int i;
    int freq = tunefreq;

    call HPLChipcon.write(0x0b,0x00);  // turn off rf amp
    call HPLChipcon.write(0x0d,0xe0);  // set lock reg to monitor vco
    call HPLChipcon.write(66,0x3f); // data rate >= 38.4kb
    call HPLChipcon.write(0,0x11); // configure main freq a
    serial_delay(2000);
    call HPLChipcon.write(14,0xa6); // start cal

    for (i=0;i<34;i++)  // need 30 ms delay
      serial_delay(1000);

    call HPLChipcon.write(14,0x26);  //exit cal mode

    call HPLChipcon.write(0,0xe1); // configure main freq b
    call HPLChipcon.write(0x09,CC1K_freqs[freq][0x0a]);
    call HPLChipcon.write(0x0b,0x00);
    serial_delay(2000);
    call HPLChipcon.write(14,0xa6); // start cal

    for (i=0;i<34;i++)  // need 30 ms delay
      serial_delay(1000);

    call HPLChipcon.write(14,0x26);  //exit cal mode
    serial_delay(200);

    return SUCCESS;
  }

}
