// $Id: AttrNewAccelM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $
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
 * Authors:  Alan Mainwaring
 *           Intel Research Berkeley Lab
 * Date:     8/6/2002
 *
 */
// component to expose Accelerometer readings as an attribute

/**
 * @author ALan Mainwaring
 * @author Intel Research Berkeley Lab
 */

#if defined(BOARD_MEP401)
#define PRESENT
#endif

module AttrNewAccelM
{
  provides interface StdControl;
  uses 
  {
#ifdef PRESENT
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface SplitControl as AccelControl;
#endif
    interface AttrRegister as AttrNewAccelX;
    interface AttrRegister as AttrNewAccelY;
  }
}
implementation
{
  bool started;
  bool start_accelx;
  bool start_accely;

  char *resultAccelX;
  char *resultAccelY;
  
  command result_t StdControl.init()
  {
    started = FALSE;
    start_accelx = FALSE;
    start_accely = FALSE;
    if (call AttrNewAccelX.registerAttr("accel_x", UINT16, 2) != SUCCESS)
      return FAIL;
    if (call AttrNewAccelY.registerAttr("accel_y", UINT16, 2) != SUCCESS)
      return FAIL;
#ifdef PRESENT
    return call AccelControl.init();
#else
    return SUCCESS;
#endif
  }

#ifdef PRESENT
  event result_t AccelControl.initDone()
  {
    return SUCCESS;
  }
#endif

  command result_t StdControl.stop()
  {
#ifdef PRESENT
    if(started)
      return call AccelControl.stop();
#endif
    return SUCCESS;
  }

#ifdef PRESENT
  event result_t AccelControl.stopDone()
  {
    started = FALSE;
    return SUCCESS;
  }
#endif

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

#ifdef PRESENT
  event result_t AccelControl.startDone()
  {
    started = TRUE;

    if(start_accelx) {
      call AttrNewAccelX.startAttrDone();
      start_accelx = FALSE;
    }
    if(start_accely) {
       call AttrNewAccelY.startAttrDone();
       start_accely = FALSE;
    }

    return SUCCESS;
  }
#endif

// Accel X

  event result_t AttrNewAccelX.startAttr()
  {
#ifdef PRESENT
    if(started)
        return call AttrNewAccelX.startAttrDone();

    start_accelx = TRUE;
    if(start_accely)
        return SUCCESS;

    return call AccelControl.start();
#else
    return SUCCESS;
#endif
  }

  event result_t AttrNewAccelX.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    resultAccelX = resultBuf;
    *(uint16_t*)resultAccelX = 0xffff;
    *errorNo = SCHEMA_ERROR;
#ifndef PRESENT
    return FAIL;
#else
    if (call AccelX.getData() != SUCCESS)
      return FAIL;
#endif
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t AttrNewAccelX.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t AccelX.dataReady(uint16_t data)
  {
    *(uint16_t*)resultAccelX=data;
    call AttrNewAccelX.getAttrDone("accel_x", resultAccelX, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif

// Accel Y

  event result_t AttrNewAccelY.startAttr()
  {
#ifdef PRESENT
    if(started)
      return call AttrNewAccelY.startAttrDone();

    start_accely = TRUE;
    if(start_accelx)
        return SUCCESS;

    return call AccelControl.start();
#else
    return SUCCESS;
#endif
  }

  event result_t AttrNewAccelY.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    resultAccelY = resultBuf;
    *(uint16_t*)resultAccelY = 0xffff;
    *errorNo = SCHEMA_ERROR;
#ifndef PRESENT
    return FAIL;
#else
    if (call AccelY.getData() != SUCCESS)
      return FAIL;
#endif
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t AttrNewAccelY.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t AccelY.dataReady(uint16_t data)
  {
    *(uint16_t*)resultAccelY=data;
    call AttrNewAccelY.getAttrDone("accel_y", resultAccelY, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif
}
