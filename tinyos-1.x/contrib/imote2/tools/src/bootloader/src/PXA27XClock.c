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
/* @file PXA27XClock.c
 * @author Phil Buonadonna
 * @author Robbie Adler   
 */
/**
 * Ported to the boot loader from tinyos tree. - Junaith
 */
#include <PXA27XClock.h>
#include <PXA27XInterrupt.h>
#include <string.h>

bool Clock_Timeout_Started = FALSE;
TimeoutDetail todetail;

/**
 * Disable_Timeout
 *
 * 
 */
void Disable_Timeout ()
{
  Clock_Timeout_Started = FALSE;
  todetail.TimeoutMS = 0;
  todetail.MsgId = 0;
  todetail.Type = 0;
  todetail.ExpectedType = 0;
  todetail.NumRetries = 0;
  todetail.NotifyFunc = NULL;
}

/**
 * Clock_Fire
 *
 * Indicates that it is time to signal the requestor
 * about the time out. The functions calls the respective
 * call back function from the struct.
 */
void Clock_Fire ()
{
  /* We dont want the interrupt till we finish
   * all the required actions at the higher level.
   * Lets disable the timer and reenable if required.
   */
  PXA27XClock_Stop ();
  
  /* Invoke the call back function to signal the
   * componenet that requested a timeout.
   */
  if (todetail.NotifyFunc != NULL)
  {
    todetail.NotifyFunc (todetail.MsgId, todetail.Type, todetail.NumRetries);
    if (todetail.NumRetries > 0)
    {
      PXA27XClock_Start(todetail.TimeoutMS);
      -- todetail.NumRetries;
    }
    else
      Disable_Timeout ();
  }
  else
    Disable_Timeout ();
}

/**
 * OSTIrq_Fired
 * 
 * This method is called from the IRQ handler when ever there is a
 * clock interrupt. The higher level Clock_Fire function maintains
 * the higher resolution.
 *
 */
void OSTIrq_Fired() 
{
  if (OSSR & OIER_E5) 
  {
    OSSR = (OIER_E5);  // Reset the Status register bit.
    
    if (Clock_Timeout_Started)
      Clock_Fire();
    else
      /* We should not have received this interrupt, Just Ignore.*/
      PXA27XClock_Stop ();
  }
}

/**
 * PXA27XClock_Start
 *
 * Initializes the required regiesters and enables the clock interrupt.
 * Currently an interrupt will occur every 1ms.
 *
 * @return SUCESS | FAIL
 */
result_t PXA27XClock_Start(uint32_t interval)
{
  result_t res = FAIL;
  res = PXA27XIrq_Allocate (PPID_OST_4_11);
  Clock_Timeout_Started = TRUE; 
  //we want a simple match based timer...i.e. Not periodic, interrupt at match
  // Resolution = 1 ms...should change in the future to be 1/32768
  OMCR5 = (OMCR_C | OMCR_CRES(0x2)); 

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();
    OIER |= (OIER_E5); // Enable the channel 5 interrupt
    OSMR5 = interval;
    OSCR5 = 0x0;  // start the  counter 
  __nesc_atomic_end (atomic);
  }
  PXA27XIrq_Enable (PPID_OST_4_11); //enable the main interrupt  
  return res;
}

/**
 * PXA27XClock_Stop
 *
 * Disable the OMCR5 match interrupt and disable the counter.
 *
 * @return SUCESS | FAIL
 */
result_t PXA27XClock_Stop() 
{
  {
  __nesc_atomic_t atomic = __nesc_atomic_start();
    OIER &= ~(OIER_E5); // Disable interrupts on channel 5
  __nesc_atomic_end (atomic);
  }
  PXA27XIrq_Disable(PPID_OST_4_11);
  OMCR5 = 0x0UL;  // Disable the counter..
  Clock_Timeout_Started = FALSE;
  return SUCCESS;
}

void PXA27XClock_SetInterval (uint32_t interval)
{
  //In the future, we probably set to some number of microseconds 
  //based on val and how long it typically take to config...multiply 
  //by 32 for now
  OSMR5 = interval;
  OSCR5 = 0x0;  // start the  counter 
}

/**
 * Enable_Timeout
 *
 * Function will enable the timeout mechanism for a particular
 * command or other message types. The struct passed as parameter
 * will contain the details of timeout value and call back
 * functions etc.
 *
 * @param tout Structure which contains the time out details. The
 * 		function requesting the timeout must provide all the
 * 		required details.
 *
 * @return SUCCESS | FAIL
 */
result_t Enable_Timeout (TimeoutDetail* tout)
{
  result_t res = FAIL;
  if (Clock_Timeout_Started)
  {
    /* Currently we are allowing only one time out request.*/
    /* FIXME, if we port the timer then its easier to add more
     * but im not sure if we really have to.
     */
    return FAIL;
  }
  memcpy (&todetail, tout, sizeof (TimeoutDetail));
  if (todetail.TimeoutMS > 0)
    res = PXA27XClock_Start(todetail.TimeoutMS);
  else
    res = FAIL;
  return res;
}

/**
 * Check_Timeout_Disable
 *
 * This function is called whenever a message
 * is received, If the received message type matches
 * with the 'ExpectedType' then the time out
 * mechanism is not required anymore. So the timer
 * will be disabled.
 *
 * @param msgId Message Id
 * @param type Type of the message received (eg a particular command)
 *
 * @return SUCCESS | FAIL
 */
result_t Check_Timeout_Disable (uint8_t msgId, uint8_t type)
{
  if (todetail.MsgId == SYNC_TIMEOUT)
  {
    Disable_Timeout ();
  }
  else if ((msgId == todetail.MsgId) && (type == todetail.ExpectedType))
  {
    Disable_Timeout ();
  }
  return SUCCESS;
}
