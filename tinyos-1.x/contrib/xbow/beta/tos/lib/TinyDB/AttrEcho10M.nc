// $Id: AttrEcho10M.nc,v 1.2 2004/06/16 22:01:19 mturon Exp $

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

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     3/25/2003
 *
 */
// component to expose Echo10 (soil humidity) sensor readings in an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrEcho10M
{
  provides interface StdControl;
  uses 
    {
      interface AttrRegister as Echo10Attr;
      interface ADConvert as Echo10;
      interface SplitControl as SensorControl;
    }
}
implementation
{
  char *echo10;
  bool started;

  command result_t StdControl.init() {
    started = FALSE;
    if (call Echo10Attr.registerAttr("echo10", UINT16, 2) != SUCCESS)
      return FAIL;
    return call SensorControl.init();
  }

  event result_t SensorControl.initDone() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SensorControl.stop();
    return SUCCESS;
  }

  event result_t SensorControl.stopDone() {
    started = FALSE;
    return SUCCESS;
  }

  event result_t SensorControl.startDone() {
    started = TRUE;
    call Echo10Attr.startAttrDone();
    return SUCCESS;
  }

  event result_t Echo10Attr.startAttr() {
    if (started)
      return call Echo10Attr.startAttrDone();
    return call SensorControl.start();
  }

  event result_t Echo10Attr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo) {
    echo10 = resultBuf;
    *(uint16_t*)echo10 = 0xffff;
    *errorNo = SCHEMA_ERROR;
    if (call Echo10.getData() != SUCCESS)
      return FAIL;
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t Echo10.dataReady(uint16_t data) {
    // This is mv = data * 2.5 / 4096; 
    //         echo10 (in % water) = 6.95e-4 * mv - 0.29
    // with a scaling factor of 100 and round to nearest
    //*(uint16_t*)echo10 = data * (100 * 2500.0 / 4096 * 6.95e-4) - 28.5;
    // experimental formula (in air, around 400, in water around 1350)
    //*(uint16_t*)echo10 = data * (1 / 11.5) - 34; // echo10
    //*(uint16_t*)echo10 = data * (1 / 14.0) - 28; // echo20
    *(uint16_t*)echo10 = data;
    call Echo10Attr.getAttrDone("echo10", echo10, SCHEMA_RESULT_READY);
    return SUCCESS;
  }

  event result_t Echo10Attr.setAttr(char *name, char *attrVal) {
    return FAIL;
  }
}
 
