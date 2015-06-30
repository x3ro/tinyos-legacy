/*                  tab:4
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
 *  Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *  Redistributions in binary form must reproduce the above copyright
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
/**
 * Module provides detects presence of someone in the area controlled by
 * IR sensor.
 **/

// debug mode to be used for this module 
#define DBG_IRDETECT DBG_SENSOR

module IrDetectM
{
  provides
  {
    interface StdControl;
    interface ADC;
    interface IrsAlarm;
  }
  uses
  {
    interface Timer as Timeout;
    interface StdControl as SensControl;
    interface MicInterrupt;
    interface Leds;
  }
}

implementation
{
  /*
   * Internal variables
   */
  // Flag masks
  enum FLAG_MASK
  {
    IRD_SOMEONE = 0x01,
    IRD_ISCONT = 0x02,
    IRD_OLDSTATE = 0x04,
    IRD_BUSY = 0x08
  };
  //Flags
  uint8_t flags;
  
  // Timer constants
  enum
  {
    TM_TOUT = 3200
  };

  /*
   * StdControl interface functions
   */
  command result_t StdControl.init()
  {
    return call SensControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    result_t sensOk; //operation results
    atomic
    {
      //Do flags initialization
      flags = 0;
    }
    sensOk = call SensControl.start();
    if (sensOk == SUCCESS)
      dbg(DBG_IRDETECT, "IRDETECT: START\n");
    return sensOk;
  }

  command result_t StdControl.stop()
  {
    dbg(DBG_IRDETECT, "IRDETECT: STOP\n");
    call Timeout.stop();
    call SensControl.stop();
    return SUCCESS;
  }
  
  /*
   * ADC interface functions
   */
  async command result_t ADC.getData()
  {
    bool someone; //local variable for is there someone
    atomic
    {
      someone = (flags & IRD_SOMEONE)? TRUE: FALSE;
    }
    return signal ADC.dataReady((someone)? 1: 0);
  }

  async command result_t ADC.getContinuousData()
  {
    atomic
    {
      flags |= IRD_ISCONT;
    }
    return SUCCESS;
  }

  // signal the alarm on to upper level
  task void alarmOn()
  {
    bool isCont; //if we have to provide data continuously
    atomic
    {
      isCont = (flags & IRD_ISCONT)? TRUE: FALSE;
    }
    dbg(DBG_IRDETECT, "IRDETECT: alarm ON\n");
    signal IrsAlarm.irsAlarmOn();
    if (isCont)
      signal ADC.dataReady(1);
    atomic
    {
      flags &= ~IRD_BUSY;
    }
  }

  // signal the alarm off
  task void alarmOff()
  {
    bool isCont; //if we have to provide data continuously
    atomic
    {
      isCont = (flags & IRD_ISCONT)? TRUE: FALSE;
    }
    dbg(DBG_IRDETECT, "IRDETECT: alarm OFF\n");
    signal IrsAlarm.irsAlarmOff();
    call Leds.redOff();
    if (isCont)
      signal ADC.dataReady(0);
  }
  
  //If there was a rising edge - stop timer so the 
  task void markEdge()
  {
    dbg(DBG_IRDETECT, "IRDETECT: RAISE alldead timer STOP\n");
    call Timeout.stop();
    call Timeout.start(TIMER_ONE_SHOT, TM_TOUT);
    post alarmOn();
  }

  /*
   * Timeout interface functions
   */
  event result_t Timeout.fired()
  {
    atomic
    {
      flags &= ~IRD_SOMEONE;
    }
    dbg(DBG_IRDETECT, "IRDETECT: all dead!!\n");
    post alarmOff();
    return SUCCESS;
  }

  /*
   * Default functions of the IrsAlarm interface
   */
  default async event result_t IrsAlarm.irsAlarmOn()
  {
    return SUCCESS;
  }

  default async event result_t IrsAlarm.irsAlarmOff()
  {
    return SUCCESS;
  }
  
  /*
   * Default method for ADC interface
   */
  default async event result_t ADC.dataReady(uint16_t data)
  {
    return SUCCESS;
  }

  //Methods for MicInterrupt interface
  event result_t MicInterrupt.toneDetected() 
  {
    bool isBusy; //if we ar busy right now
    atomic
    {
      isBusy = (flags & IRD_BUSY)? TRUE: FALSE;
    }
    if (!isBusy)
    {
      atomic
      {
        flags |= IRD_BUSY;
      }
      call Leds.redOn();
      post markEdge();
    }
    return SUCCESS;
  }

}

//eof
