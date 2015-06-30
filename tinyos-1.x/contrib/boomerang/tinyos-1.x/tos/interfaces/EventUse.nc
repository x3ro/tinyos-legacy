// $Id: EventUse.nc,v 1.1.1.1 2007/11/05 19:09:02 jpolastre Exp $

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
 * Date:     9/25/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


includes Event;

/** The interface for using events
    <p>
    See lib/Events/... for examples of components that register commands.
    <p>
    See interfaces/Event.h for the data structures used in this interface 
    <p>
    Implemented by lib/Event.nc
    <p>
    @author Wei Hong (wei.hong@intel-research.net)
*/
interface EventUse
{
  /** Register an event interest by associating a command to an event
      @param eventName The name of the event
      @param cmdName The name of the command.  the command must have identical
	  parameter signature as the event, otherwise FAIL will be returned.
  */
  command result_t registerEventCallback(char *eventName, char *cmdName);

  /** delete an event interest
      @param eventName The name of the event
      @param cmdName The name of the command
  */
  command result_t deleteEventCallback(char *eventName, char *cmdName);

  /** Get a descriptor for the specified event
      @param name The (8 byte or shorter, null-terminated) name for the event of interest.
      @return A pointer to the event descriptior, or NULL if no such event exists.
  */
  command EventDescPtr getEvent(char *name);

  /** Get a descriptor for a specified event id
      @param idx The (0-based) index of the event of interest
      @return A pointer to the event descriptor, or NULL if no such event exists.
  */
  command EventDescPtr getEventById(uint8_t idx);
  
  /** @return The number of events currently registered with the system */
  command uint8_t numEvents();

  /** @return A list of all the events in the system */
  command EventDescsPtr getEvents();

  /** signal an event, all commands associated with the event will be called
  	  in a task.  the eventDone event will be signaled when all commands
	  are completed.
     @param eventName The event to signal.
     @param params The parameters to this event.
  */
  command result_t signalEvent(char *eventName, ParamVals *params);

  /** Given a msg represent an event signaling, signal the appropriate event,
      See signalEvent(...) above
      @param msg The event message.  The format of this message is a packed array representing the name of
                 the event, followed by a packed list of parameters.  See java/net/tinyos/tinydb/EventMsgs.java
		 for an example of a Java program that invokes a command.
      @param errorNo (on return)The result code
  */
  command result_t signalEventMsg(TOS_MsgPtr msg);

  /** the event to be signaled upon completion of all the commands associated
  	  to the event
	  @param name The event name
      @param errorNo The result code
  */
  event result_t eventDone(char *name, SchemaErrorNo errorNo);
}
