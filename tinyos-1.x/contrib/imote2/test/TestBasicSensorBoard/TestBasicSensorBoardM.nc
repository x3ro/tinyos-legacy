// $Id: TestBasicSensorBoardM.nc,v 1.2 2007/03/05 06:20:52 lnachman Exp $

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

includes trace;
#include "pmic.h"

module TestBasicSensorBoardM {
  provides {
    interface StdControl;
    interface BluSH_AppI as ReadTempReg;
    interface BluSH_AppI as ReadADCChannel;
    interface BluSH_AppI as ReadLightSensor;
  }
  uses {
    interface StdControl as I2CControl;
    interface I2C;
    interface Leds;
    interface PMIC;
  }
}
implementation {

#define TEMP_SLAVE_ADDR 0x4A
#define ADC_SLAVE_ADDR 0x34
#define LIGHT_SLAVE_ADDR 0x49

#define READ_OP 1
#define WRITE_OP 0

#define MAX_OPS 20
#define I2C_START 0
#define I2C_END   1
#define I2C_READ  2
#define I2C_WRITE 3

typedef struct i2c_op_t {
   uint8_t op;
   uint8_t param;
   uint8_t res;
} i2c_op_t;

   i2c_op_t sequence[MAX_OPS];
   uint8_t num_ops;
   uint8_t current_op;

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call Leds.init(); 
    call I2CControl.init();
    num_ops = 0;
    current_op = 0;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
     call PMIC.enableSBVoltage_High(TRUE, LDO_TRIM_3P0);
     return call I2CControl.start();
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
     call PMIC.enableSBVoltage_High(FALSE, LDO_TRIM_3P0);
     return call I2CControl.stop();
  }

  // For now, just printout the results
  void processResults() {
     uint8_t i;
     for(i=0; i<num_ops; i++) {
        if (sequence[i].op == I2C_READ) {
           trace(DBG_USR1, "Op %d, param %d, Read %d\r\n", i, sequence[i].param,
                 sequence[i].res);
        } else if (sequence[i].op == I2C_WRITE) {
           trace(DBG_USR1, "Op %d, param %d, Write result %d\r\n", i, 
                 sequence[i].param, sequence[i].res);
        }
     }
  } 

  task void processNextCmd() {
     if (num_ops == 0) {
        // empty queue
        return;
     }
     if (current_op > (num_ops - 1)) { // changed gte to strictly greater so that the last op is performed
        // finished last op
        processResults();
        num_ops = 0;
        return;
     }
     // process next command
     switch (sequence[current_op].op) {
        case I2C_START:
           call I2C.sendStart();
           break;
        case I2C_END:
           call I2C.sendEnd();
           break;
        case I2C_READ:
           call I2C.read(sequence[current_op].param);
           break;
        case I2C_WRITE:
           call I2C.write(sequence[current_op].param);
           break;
     }
     
  }

  /*
   * Read the temp from the temp sensor
   */
  command BluSH_result_t ReadTempReg.getName(char *buff, uint8_t len) {
     const char name[] = "ReadTempReg";
     strcpy(buff, name);
     return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadTempReg.callApp(char *cmdBuff, uint8_t cmdLen,
                                           char *resBuff, uint8_t resLen) {
     uint8_t reg_val;
     uint32_t temp_val;

     reg_val = 0;

     if (strlen(cmdBuff) >= strlen("ReadTempReg 0")) {
        sscanf(cmdBuff, "ReadTempReg %d", &temp_val);
        if (temp_val < 4) {
           reg_val = (uint8_t) temp_val;
        }
     }

     if (num_ops > 0) {
        trace(DBG_USR1, "I2C busy \r\n");
        return BLUSH_SUCCESS_DONE;
     }

     /*
      * Set the pointer reg
      */
     num_ops = 8;
     current_op = 0;
     sequence[0].op = I2C_START;
     sequence[1].op = I2C_WRITE;
     sequence[1].param = (TEMP_SLAVE_ADDR << 1) | WRITE_OP;
     sequence[2].op = I2C_WRITE;
     sequence[2].param = reg_val;

     /*
      * Read the High temp
      */

     sequence[3].op = I2C_START;
     sequence[4].op = I2C_WRITE;
     sequence[4].param = (TEMP_SLAVE_ADDR << 1) | READ_OP;
     sequence[5].op = I2C_READ;
     sequence[5].param = TRUE;
     sequence[6].op = I2C_END;
     sequence[7].op = I2C_READ;
     sequence[7].param = FALSE; // changed to FALSE

     post processNextCmd();
    
     return BLUSH_SUCCESS_DONE;
  }

  /*
   * Read the ADC channel
   */
  command BluSH_result_t ReadADCChannel.getName(char *buff, uint8_t len) {
     const char name[] = "ReadADCChannel";
     strcpy(buff, name);
     return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadADCChannel.callApp(char *cmdBuff, uint8_t cmdLen,
                                           char *resBuff, uint8_t resLen) {
     uint8_t channel_val;
     uint32_t temp_val;

     channel_val = 0;

     if (strlen(cmdBuff) >= strlen("ReadADCChannel 0")) {
        sscanf(cmdBuff, "ReadADCChannel %d", &temp_val);
        if (temp_val < 4) {
           channel_val = (uint8_t) temp_val;
        }
     }

     if (num_ops > 0) {
        trace(DBG_USR1, "I2C busy \r\n");
        return BLUSH_SUCCESS_DONE;
     }

     /*
      * Set the configuration reg
      */
     num_ops = 10;
     current_op = 0;
     sequence[0].op = I2C_START;
     sequence[1].op = I2C_WRITE;
     sequence[1].param = (ADC_SLAVE_ADDR << 1) | WRITE_OP;
     sequence[2].op = I2C_WRITE;
     // config byte, single channel conversion, single ended input
     sequence[2].param = 0x79 | (channel_val << 1);

     /*
      * Read the High temp
      */

     sequence[3].op = I2C_START;
     sequence[4].op = I2C_WRITE;
     sequence[4].param = (ADC_SLAVE_ADDR << 1) | READ_OP;
     sequence[5].op = I2C_READ;
     sequence[5].param = TRUE;
     sequence[6].op = I2C_READ;
     sequence[6].param = TRUE;
     sequence[7].op = I2C_READ;
     sequence[7].param = TRUE;
     sequence[8].op = I2C_END;
     sequence[9].op = I2C_READ;
     sequence[9].param = FALSE; // changed to FALSE

     post processNextCmd();
    
     return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadLightSensor.getName(char *buff, uint8_t len) {
     const char name[] = "ReadLightSensor";
     strcpy(buff, name);
     return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadLightSensor.callApp(char *cmdBuff, uint8_t cmdLen,
                                           char *resBuff, uint8_t resLen) {

     if (num_ops > 0) {
        trace(DBG_USR1, "I2C busy \r\n");
        return BLUSH_SUCCESS_DONE;
     }

     /*
      * Set the configuration reg
      */
     num_ops = 10;
     current_op = 0;
     sequence[0].op = I2C_START;
     sequence[1].op = I2C_WRITE;
     sequence[1].param = (LIGHT_SLAVE_ADDR << 1) | WRITE_OP;
     sequence[2].op = I2C_WRITE;
     // write 3 to the control register (power up)
     sequence[2].param = 0x80;

     sequence[3].op = I2C_WRITE;
     // write 3 to the control register (power up)
     sequence[3].param = 0x03;

     // choose ID register
     sequence[4].op = I2C_WRITE;
     // address ID register
     sequence[4].param = 0x8A;

     // read ID register
     sequence[5].op = I2C_START;
     sequence[6].op = I2C_WRITE;
     sequence[6].param = (LIGHT_SLAVE_ADDR << 1) | READ_OP;
     sequence[7].op = I2C_READ;
     sequence[7].param = TRUE;

     sequence[8].op = I2C_END;
     sequence[8].op = I2C_READ;
     sequence[9].param = FALSE; // changed to FALSE

     post processNextCmd();
    
     return BLUSH_SUCCESS_DONE;
  }

  /*
   * I2C interface events
   */

  event result_t I2C.sendStartDone() {
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.sendEndDone() {
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.readDone(char data) {
     // Done reading, update the table
     sequence[current_op].res = data;
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }

  event result_t I2C.writeDone(bool success) {
     // Done writing, update the table with result
     sequence[current_op].res = success;
     current_op++;
     post processNextCmd();
     return SUCCESS;
  }
}

