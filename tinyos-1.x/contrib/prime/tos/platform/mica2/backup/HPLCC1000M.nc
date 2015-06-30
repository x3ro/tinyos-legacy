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
 * Authors:		Jaein Jeong, Philip Buonadonna
 * Date last modified:  $Revision: 1.1.1.1 $
 *
 */

/**
 * Low level hardware access to the CC1000
 */

module HPLCC1000M {
  provides {
    interface HPLCC1000;
  }
}
implementation
{
  command result_t HPLCC1000.init() {
    TOSH_MAKE_CC_CHP_OUT_INPUT();
    TOSH_MAKE_CC_PALE_OUTPUT();  // PALE
    TOSH_MAKE_CC_PCLK_OUTPUT();    // PCLK
    TOSH_MAKE_CC_PDATA_OUTPUT();    // PDATA
    TOSH_SET_CC_PALE_PIN();      // set PALE high
    TOSH_SET_CC_PDATA_PIN();        // set PCLK high
    TOSH_SET_CC_PCLK_PIN();        // set PDATA high
    return SUCCESS;
  }

  //********************************************************/
  // function: write                                       */
  // description: accepts a 7 bit address and 8 bit data,  */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb high for write      */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked out on the falling edge of PCLK.        */
  // Input:  7 bit address, 8 bit data                     */
  //********************************************************/

  command result_t HPLCC1000.write(uint8_t addr, uint8_t data) {
    char cnt = 0;

    // address cycle starts here
    addr <<= 1;
    TOSH_CLR_CC_PALE_PIN();  // enable PALE
    for (cnt=0;cnt<7;cnt++)  // send addr PDATA msb first
    {
      if (addr&0x80)
        TOSH_SET_CC_PDATA_PIN();
      else
        TOSH_CLR_CC_PDATA_PIN();
      TOSH_CLR_CC_PCLK_PIN();   // toggle the PCLK
      TOSH_SET_CC_PCLK_PIN();
      addr <<= 1;
    }
    TOSH_SET_CC_PDATA_PIN();
    TOSH_CLR_CC_PCLK_PIN();   // toggle the PCLK
    TOSH_SET_CC_PCLK_PIN();

    TOSH_SET_CC_PALE_PIN();  // disable PALE

    // data cycle starts here
    for (cnt=0;cnt<8;cnt++)  // send data PDATA msb first
    {
      if (data&0x80)
        TOSH_SET_CC_PDATA_PIN();
      else
        TOSH_CLR_CC_PDATA_PIN();
      TOSH_CLR_CC_PCLK_PIN();   // toggle the PCLK
      TOSH_SET_CC_PCLK_PIN();
      data <<= 1;
    }
    TOSH_SET_CC_PALE_PIN();
    TOSH_SET_CC_PDATA_PIN();
    TOSH_SET_CC_PCLK_PIN();
    return SUCCESS;
  }

  //********************************************************/
  // function: read                                        */
  // description: accepts a 7 bit address,                 */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb low for read        */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked in on the falling edge of PCLK.         */
  // Input:  7 bit address                                 */
  // Output:  8 bit data                                   */
  //********************************************************/

  command uint8_t HPLCC1000.read(uint8_t addr) {
    int cnt;
    uint8_t din;
    uint8_t data = 0;

    // address cycle starts here
    addr <<= 1;
    TOSH_CLR_CC_PALE_PIN();  // enable PALE
    for (cnt=0;cnt<7;cnt++)  // send addr PDATA msb first
    {
      if (addr&0x80)
        TOSH_SET_CC_PDATA_PIN();
      else
        TOSH_CLR_CC_PDATA_PIN();
      TOSH_CLR_CC_PCLK_PIN();   // toggle the PCLK
      TOSH_SET_CC_PCLK_PIN();
      addr <<= 1;
    }
    TOSH_CLR_CC_PDATA_PIN();
    TOSH_CLR_CC_PCLK_PIN();   // toggle the PCLK
    TOSH_SET_CC_PCLK_PIN();

    TOSH_MAKE_CC_PDATA_INPUT();  // read data from chipcon
    TOSH_SET_CC_PALE_PIN();  // disable PALE

    // data cycle starts here
    for (cnt=7;cnt>=0;cnt--)  // send data PDATA msb first
    {
      TOSH_CLR_CC_PCLK_PIN();  // toggle the PCLK
      din = TOSH_READ_CC_PDATA_PIN();
      if(din)
        data = (data<<1)|0x01;
      else
        data = (data<<1)&0xfe;
      TOSH_SET_CC_PCLK_PIN();
    }

    TOSH_SET_CC_PALE_PIN();
    TOSH_MAKE_CC_PDATA_OUTPUT();
    TOSH_SET_CC_PDATA_PIN();

    return data;
  }


  command bool HPLCC1000.GetLOCK() {
    char cVal;

    cVal = TOSH_READ_CC_CHP_OUT_PIN();

    return cVal;
  }
}
  
