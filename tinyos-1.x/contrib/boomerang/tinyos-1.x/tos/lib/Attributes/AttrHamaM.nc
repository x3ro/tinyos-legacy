// $Id: AttrHamaM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $
/*                  tab:4
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
 * Date:     8/6/2002
 *
 */
// component to expose Accelerometer readings as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */

#if defined(BOARD_MEP401)
#define PRESENT
#endif

module AttrHamaM
{
  provides interface StdControl;
  uses 
  {
#ifdef PRESENT
    interface ADC as TopPAR;
    interface ADC as TopBS;
    interface ADC as BotPAR;
    interface ADC as BotBS;
    interface SplitControl as HamaControl;
#endif
    interface AttrRegister as AttrHamaTopPAR;
    interface AttrRegister as AttrHamaTopBS;
    interface AttrRegister as AttrHamaBotPAR;
    interface AttrRegister as AttrHamaBotBS;
  }
}

implementation
{
  bool started;
  bool start_toppar;
  bool start_topbs;
  bool start_botpar;
  bool start_botbs;

  char *resultTopPAR;
  char *resultTopBS;
  char *resultBotPAR;
  char *resultBotBS;
  
  command result_t StdControl.init()
  {
    started = FALSE;
    start_toppar = FALSE;
    start_topbs = FALSE;
    start_botpar = FALSE;
    start_botbs = FALSE;
    if (call AttrHamaTopPAR.registerAttr("hmtoppr", UINT16, 2) != SUCCESS)
      return FAIL;
    if (call AttrHamaTopBS.registerAttr("hmtopbs", UINT16, 2) != SUCCESS)
      return FAIL;
    if (call AttrHamaBotPAR.registerAttr("hmbotpr", UINT16, 2) != SUCCESS)
      return FAIL;
    if (call AttrHamaBotBS.registerAttr("hmbotbs", UINT16, 2) != SUCCESS)
      return FAIL;
#ifdef PRESENT
    return call HamaControl.init();
#else
    return SUCCESS;
#endif
  }

#ifdef PRESENT
  event result_t HamaControl.initDone()
  {
    return SUCCESS;
  }
#endif

  command result_t StdControl.stop()
  {
#ifdef PRESENT
    if(started)
      return call HamaControl.stop();
#endif
    return SUCCESS;
  }

#ifdef PRESENT
  event result_t HamaControl.stopDone()
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
  event result_t HamaControl.startDone()
  {
    started = TRUE;

    if(start_toppar) {
      call AttrHamaTopPAR.startAttrDone();
      start_toppar = FALSE;
    }
    if(start_topbs) {
       call AttrHamaTopBS.startAttrDone();
       start_topbs = FALSE;
    }
    if(start_botpar) {
      call AttrHamaBotPAR.startAttrDone();
      start_botpar = FALSE;
    }
    if(start_botbs) {
      call AttrHamaBotBS.startAttrDone();
      start_botbs = FALSE;
    }

    return SUCCESS;
  }
#endif

// Top PAR

  event result_t AttrHamaTopPAR.startAttr()
  {
#ifdef PRESENT
    if(started)
        return call AttrHamaTopPAR.startAttrDone();

    start_toppar = TRUE;
    if(start_topbs || start_botpar || start_botbs)
        return SUCCESS;

    return call HamaControl.start();
#else
    return SUCCESS;
#endif
  }

  event result_t AttrHamaTopPAR.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    resultTopPAR = resultBuf;
    *(uint16_t*)resultTopPAR = 0xffff;
    *errorNo = SCHEMA_ERROR;
#ifndef PRESENT
    return FAIL;
#else
    if (call TopPAR.getData() != SUCCESS)
      return FAIL;
#endif
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t AttrHamaTopPAR.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t TopPAR.dataReady(uint16_t data)
  {
    *(uint16_t*)resultTopPAR=data;
    call AttrHamaTopPAR.getAttrDone("hmtoppr", resultTopPAR, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif

// Top BS

  event result_t AttrHamaTopBS.startAttr()
  {
#ifdef PRESENT
    if(started)
      return call AttrHamaTopBS.startAttrDone();

    start_topbs = TRUE;
    if(start_toppar || start_botpar || start_botbs)
        return SUCCESS;

    return call HamaControl.start();
#else
    return SUCCESS;
#endif	 
  }

  event result_t AttrHamaTopBS.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    resultTopBS = resultBuf;
    *(uint16_t*)resultTopBS = 0xffff;
    *errorNo = SCHEMA_ERROR;
#ifndef PRESENT
    return FAIL;
#else
    if (call TopBS.getData() != SUCCESS)
      return FAIL;
#endif
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t AttrHamaTopBS.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t TopBS.dataReady(uint16_t data)
  {
    *(uint16_t*)resultTopBS=data;
    call AttrHamaTopBS.getAttrDone("hmtopbs", resultTopBS, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif

// Bot PAR

  event result_t AttrHamaBotPAR.startAttr()
  {
#ifdef PRESENT
    if(started)
      return call AttrHamaBotPAR.startAttrDone();

    start_botpar = TRUE;
    if(start_toppar || start_topbs || start_botbs)
        return SUCCESS;

    return call HamaControl.start();
#else
    return SUCCESS;
#endif
  }

  event result_t AttrHamaBotPAR.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
#ifdef PRESENT
    resultBotPAR = resultBuf;
    *(uint16_t*)resultBotPAR = 0xffff;
    *errorNo = SCHEMA_ERROR;

    if (call BotPAR.getData() != SUCCESS)
      return FAIL;

    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
#else
    return FAIL;
#endif
  }

  event result_t AttrHamaBotPAR.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t BotPAR.dataReady(uint16_t data)
  {
    *(uint16_t*)resultBotPAR=data;
    call AttrHamaBotPAR.getAttrDone("hmbotpr", resultBotPAR, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif

// Bot BS

  event result_t AttrHamaBotBS.startAttr()
  {
#ifdef PRESENT
    if(started)
      return call AttrHamaBotBS.startAttrDone();

    start_botbs = TRUE;
    if(start_toppar || start_topbs || start_botpar)
        return SUCCESS;

    return call HamaControl.start();
#else
    return SUCCESS;
#endif
  }

  event result_t AttrHamaBotBS.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    resultBotBS = resultBuf;
    *(uint16_t*)resultBotBS = 0xffff;
    *errorNo = SCHEMA_ERROR;
#ifndef PRESENT
    return FAIL;
#else
    if (call BotBS.getData() != SUCCESS)
      return FAIL;
#endif
    *errorNo = SCHEMA_RESULT_PENDING;
    return SUCCESS;
  }

  event result_t AttrHamaBotBS.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }

#ifdef PRESENT
  async event result_t BotBS.dataReady(uint16_t data)
  {
    *(uint16_t*)resultBotBS=data;
    call AttrHamaBotBS.getAttrDone("hmbotbs", resultBotBS, SCHEMA_RESULT_READY);
    return SUCCESS;
  }
#endif
}
