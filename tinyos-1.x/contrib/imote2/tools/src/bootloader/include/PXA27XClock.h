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
 * @file PXA27XClock.h
 * @author 
 *
 * Ported from TinyOS repository and modified as per
 * the requirements - Junaith Ahemed
 *
 * This file provides the clock routines ported from the tinyos repository from 
 * PXA27XClockM.nc.
 */
#ifndef PXA27X_CLOCK_H
#define PXA27X_CLOCK_H

#include <types.h>
#include <pxa27xhardware.h>
#include <stdlib.h>

/**
 * There are situations where we have to set the 
 * clock for a non MsgId type which is not an Error
 * or a command.
 */
typedef enum ExtendedClockDef
{
  SYNC_TIMEOUT = 10000,
}ExtendedClockDef;

typedef struct TimeoutDetail
{
  uint32_t TimeoutMS; /*Timeout in MS*/
  uint16_t  MsgId; /* To distinguish higher level message (command, error etc)*/
  uint8_t  Type;  /* The type of message (one of Commands, Errors etc)*/
  uint8_t  ExpectedType; /* What response type is need to stop this timeout cycle*/
  uint8_t  NumRetries; /* Number of retires*/
  void (*NotifyFunc) (uint8_t id, uint8_t typ, uint8_t ret);
} TimeoutDetail;

/**
 * OSTIrq_Fired
 * 
 * This method is called from the IRQ handler when ever there is a
 * clock interrupt. The higher level Clock_Fire function maintains
 * the higher resolution.
 *
 */
void OSTIrq_Fired();

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
result_t Enable_Timeout (TimeoutDetail* tout);

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
result_t Check_Timeout_Disable (uint8_t msgId, uint8_t type);

/***************************************************************
 ***********   INTERNAL FUNCTIONS FOR NOW  *********************
 ***************************************************************/
/**
 * PXA27XClock_Start
 *
 * Initializes the required regiesters and enables the clock interrupt.
 * Currently an interrupt will occur every 1ms.
 *
 * @return SUCESS | FAIL
 */
result_t PXA27XClock_Start(uint32_t interval);

/**
 * PXA27XClock_Stop
 *
 * Disable the OMCR5 match interrupt and disable the counter.
 *
 * @return SUCESS | FAIL
 */
result_t PXA27XClock_Stop();

void PXA27XClock_SetInterval (uint32_t interval);

#endif
