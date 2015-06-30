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
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     9/25/2002
 *
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
