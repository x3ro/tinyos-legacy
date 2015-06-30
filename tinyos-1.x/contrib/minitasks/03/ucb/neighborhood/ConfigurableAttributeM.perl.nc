/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: ConfigurableAttributeM.perl.nc,v 1.8 2003/07/10 17:59:57 cssharp Exp $


/*
  This type of attribute can be get and set with messages, where the msg payload of each message is a memory copy of the attribute.

   You need to give it the parameters:
   ${Get_AM} = AM type for sending/receive "Get" commands and responses
   ${Set_AM} = AM type for sending "Set" commands
*/

includes ConfigurableAttribute;
includes Routing;

module ${Attribute}M
{
  provides interface ${Attribute};
  provides interface StdControl;
  uses interface SendMsg as GetSend;
  uses interface ReceiveMsg as GetReceive;
  uses interface ReceiveMsg as SetReceive;
  uses interface MsgBuffers;
}
implementation
{
  ${Type} m_value;
  
  command result_t StdControl.init()
  {
    const ${Type} init = ${Init};
    m_value = init;
    call MsgBuffers.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  command ${Type} ${Attribute}.get()
  {
    return m_value;
  }

  command void ${Attribute}.set( ${Type} value )
  {
    m_value = value;
    signal ${Attribute}.updated();
  }

  default event void ${Attribute}.updated()
  {
  }

  task void send()
  {
    TOS_MsgPtr msg = call MsgBuffers_alloc();
    if( msg != 0 )
    {
      ${Type}* data = (${Type}*)initRoutingMsg( msg, sizeof(${Type}) );
      if( data != 0 )
      {
	*data = m_value;
	if( call GetSend.send( TOS_BCAST_ADDR, msg ) == SUCCESS )
	  return;
      }
      call MsgBuffers.free( msg );
    }
  }

  event result_t GetSend.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr GetReceive.receive(TOS_MsgPtr m)
  {
    if( m->length == 0 )
      post send();
    return m;
  }

  event TOS_MsgPtr SetReceive.receive(TOS_MsgPtr m)
  {
    ${Type}* data = (${Type}*)popFromRoutingMsg( m, sizeof(${Type}) );
    if( data != 0 )
      call ${Attribute}.set( *data );
    return m;
  }

}

