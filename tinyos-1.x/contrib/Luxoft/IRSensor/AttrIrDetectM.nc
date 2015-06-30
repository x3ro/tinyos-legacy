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
 * Authors:  Dmitriy Korovkin
 * Date:     9/24/2003
 *
 */
// component to expose IR detector sensor reading as an attribute

// name of the ACK enable attribute
#define IRDETECT "irdetec"

module AttrIrDetectM
{
  provides interface StdControl;
  uses 
  {
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
    interface IrsAlarm;
    interface StdControl as DetectControl;
#endif
    interface AttrRegister;
    interface Leds;
  }
}
implementation
{
  bool detect; //if someone detected in the area

  /*
   * StdControl Interface functions
   */
  command result_t StdControl.init()
  {
    result_t sensOk, attrOk; //operation results
    atomic
    {
      detect = FALSE;
    }
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
    sensOk = call DetectControl.init();
#else
    sensOk = SUCCESS;
#endif
    attrOk = call AttrRegister.registerAttr(IRDETECT, UINT16, 1);
    return rcombine(sensOk, attrOk);
  }

  command result_t StdControl.start()
  {
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
    return call DetectControl.start();
#else
    return SUCCESS;
#endif
  }

  command result_t StdControl.stop()
  {
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
    return call DetectControl.stop();
#else
    return SUCCESS;
#endif
  }

  /*
   * AttrRegister interface functions
   */
  event result_t AttrRegister.startAttr()
  {
    return call AttrRegister.startAttrDone();
  }

  event result_t AttrRegister.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
  {
    atomic
    {
      *errorNo = SCHEMA_RESULT_READY;
      if (detect == TRUE)
        *(uint16_t*)resultBuf = 1;
      else
        *(uint16_t*)resultBuf = 0;
    }
    return SUCCESS;
  }

  event result_t AttrRegister.setAttr(char *name, char *attrVal)
  {
    return FAIL;
  }
  
#if defined(PLATFORM_MICA2DOT) || defined(PLATFORM_PC)
  /*
   * IrsDetect interface functions
   */
  async event result_t IrsAlarm.irsAlarmOn()
  {
    atomic 
    {
      detect = TRUE;
    }
    return SUCCESS;
  }

  async event result_t IrsAlarm.irsAlarmOff()
  {
    atomic 
    {
      detect = FALSE;
    }
    return SUCCESS;
  }
#endif
}

//eof
