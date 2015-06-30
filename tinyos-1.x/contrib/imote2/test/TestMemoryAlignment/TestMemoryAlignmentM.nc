
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Test PowerModes
 **/
module TestMemoryAlignmentM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface Sleep;
  }
}
implementation {

  uint32_t counter;

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call Leds.init(); 
    return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1000);
    counter = 1;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired()
  {

    uint8_t temp[20], i;
    uint8_t out[20];
    uint16_t *temps, temps_val;
    uint32_t *templ, temp_val;
    uint8_t *buf;

    struct test {
    uint8_t type;
    uint8_t len; 
    uint8_t val[1];
    } __attribute__((packed));
    struct test *tempStruct;

    call Leds.redToggle();
    
    if (counter == 1) {
       for(i=0; i<20; i++) {
          temp[i] = i;
       }
#if 0
       trace(DBG_USR1, "addr is %x\r\n", temp);
       tempStruct = (struct test *) temp;
       temp_val = *(uint32_t *) &(tempStruct->val[0]);
       trace(DBG_USR1, "value is %x \r\n", temp_val);
#endif


       trace(DBG_USR1, "16 bit reads \r\n");
       temps = (uint16_t *) &(temp[0]);
       trace(DBG_USR1, "short temp 0 %x at %x\r\n", *temps, temps);
       temps = (uint16_t *) &(temp[1]);
       trace(DBG_USR1, "short temp 1 %x at %x\r\n", *temps, temps);
       temps = (uint16_t *) &(temp[2]);
       trace(DBG_USR1, "short temp 2 %x at %x\r\n", *temps, temps);
       temps = (uint16_t *) &(temp[3]);
       trace(DBG_USR1, "short temp 3 %x at %x\r\n", *temps, temps);

       trace(DBG_USR1, "32 bit reads \r\n");
       buf = temp;
       temp_val = *(uint32_t *) buf;
       trace(DBG_USR1, "temp 0 %x at %x\r\n", temp_val, buf);
       buf++;
       temp_val = *(uint32_t *) buf;
       trace(DBG_USR1, "temp 1 %x at %x\r\n", temp_val, buf);
       buf++;
       temp_val = *(uint32_t *) buf;
       trace(DBG_USR1, "temp 2 %x at %x\r\n", temp_val, buf);
       buf++;
       temp_val = *(uint32_t *) buf;
       trace(DBG_USR1, "temp 3 %x at %x\r\n", temp_val, buf);

       trace(DBG_USR1, "32 bit writes \r\n");
       // output
       temp_val = 0x03020100;
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       templ = (uint32_t *) &(out[0]);
       *templ = temp_val;
       trace(DBG_USR1, "out %d %d %d %d %d %d %d %d \r\n", out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       templ = (uint32_t *) &(out[1]);
       *templ = temp_val;
       trace(DBG_USR1, "out %d %d %d %d %d %d %d %d \r\n", out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       templ = (uint32_t *) &(out[2]);
       *templ = temp_val;
       trace(DBG_USR1, "out %d %d %d %d %d %d %d %d \r\n", out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       templ = (uint32_t *) &(out[3]);
       *templ = temp_val;
       trace(DBG_USR1, "out %d %d %d %d %d %d %d %d \r\n", out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       
#if 0
       // output for short
       trace(DBG_USR1, "Print out short\n");
       temps_val = 0x0302;
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       temps = (uint16_t *) &(out[0]);
       *temps = temps_val;
       trace(DBG_USR1, "out %x , %d %d %d %d %d %d %d %d \r\n", temps, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       temps = (uint16_t *) &(out[1]);
       *temps = temps_val;
       trace(DBG_USR1, "out %x , %d %d %d %d %d %d %d %d \r\n", temps, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       temps = (uint16_t *) &(out[2]);
       *temps = temps_val;
       trace(DBG_USR1, "out %x, %d %d %d %d %d %d %d %d \r\n", temps, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);
       out[0] = out[1] = out[2] = out[3] = 0xEE;
       out[4] = out[5] = out[6] = out[7] = 0xEE;
       temps = (uint16_t *) &(out[3]);
       *temps = temps_val;
       trace(DBG_USR1, "out %x, %d %d %d %d %d %d %d %d \r\n", temps, out[0], out[1], out[2], out[3], out[4], out[5], out[6], out[7]);

#endif
    }

    counter++;

    return SUCCESS;
  }
  
}

