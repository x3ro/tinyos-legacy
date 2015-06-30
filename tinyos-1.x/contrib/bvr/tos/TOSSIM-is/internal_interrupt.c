/* $Id: internal_interrupt.c,v 1.1 2005/11/08 06:59:27 rfonseca76 Exp $ */
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
 *
 * Author:		Rodrigo Fonseca
 * Modified: Rodrigo Fonseca 02/05
 * cf internal_interrupt.txt
 *
 */


/* Allows events with global knowledge independent of the actual code
   on the motes. This is a mechanism that allows powerful scripting,
   by inserting identified events in the event queue.
   
   This file is a dummy implementation of the internal_interrupt interface,
   and does nothing.
  
   Start by adding events to schedule_first_events, and create event
   types and handlers to do your thing. To get state from the motes,
   you may want to check the __nesc_nido_resolve function that NESC > 1.1.1
   creates */


/* Warning: it is dangerous to use this module with jython, there is currently
   no guarantee that the events ids will be different, and we are using the
   exact same InterruptCommands that jython uses */

enum {
  INT_EVENT_FIRST,
};

void schedule_first_events() {
  dbg_clear(DBG_SIM,"II:schedule_first_events, at %llu\n",tos_state.tos_time);
  //Dummy implementation: won't schedule more events
}

/* --------------------------------------------------------------------*/
/* Exported Functions */

void internalInterruptInit() {
  dbg_clear(DBG_SIM,"II:InternalInterruptInit! %llu\n",tos_state.tos_time);
  scheduleInterrupt(INT_EVENT_FIRST, tos_state.tos_time);
}


/*This function is called whenever an interrupt event is
 *triggered. This allows us to dispatch different handlers
 *based on id. Rescheduling can be done by calling
 *scheduleInterrupt(id,time)
 */
void internalInterruptHandler(uint32_t id) {
  dbg_clear(DBG_SIM,"II:InternalInterruptHandler %llu!\n",tos_state.tos_time);
  switch(id) {
    case INT_EVENT_FIRST:
      schedule_first_events();
      break;
    default:
      break;
  }
}


