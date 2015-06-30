/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
// $Id: ConfigM.config.nc,v 1.2 2003/06/09 00:47:27 cssharp Exp $

includes Routing;

module ConfigM
{
  provides
  {
    interface StdControl;
${provides}
  }
  uses
  {
    interface RoutingReceive as ReceiveConfigUpdate;
    interface RoutingReceive as ReceiveConfigQuery;
    interface RoutingSendByBroadcast as SendConfigValue;
  }
}
implementation
{
  typedef struct
  {
    uint8_t type;
  } header_t;

  enum
  {
    IDLE,
    ENCODE_VALUE,
    SENDING_MSG,
  };

  TOS_Msg m_datamsg;
  uint8_t m_state;
  uint8_t m_type;


  command result_t StdControl.init()
  {
    G_Config = G_DefaultConfig;
    m_state = IDLE;
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


  event TOS_MsgPtr ReceiveConfigUpdate.receive( TOS_MsgPtr msg )
  {
    void* msgdata;
    header_t* head = (header_t*)popFromRoutingMsg( msg, sizeof(header_t) );
    if( head == 0 ) return msg;

    switch( head->type )
    {
${receive_cases}
    }

    return msg;
  }

  task void encode_value()
  {
    bool bSend = FALSE;
    TOS_MsgPtr msg = &m_datamsg;
    void* msgdata;
    if( initRoutingMsg( msg, 0 ) == 0 )
      return;

    switch( m_type )
    {
${query_cases}
    }

    if( bSend == TRUE )
    {
      header_t* head = (header_t*)pushToRoutingMsg( msg, sizeof(header_t) );
      if( head != 0 )
      {
	head->type = m_type;
	if( call SendConfigValue.send( 0, msg ) == SUCCESS )
	{
	  m_state = SENDING_MSG;
	  return;
	}
      }
    }

    m_state = IDLE;
  }

  event TOS_MsgPtr ReceiveConfigQuery.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)popFromRoutingMsg( msg, sizeof(header_t) );
    if( (head != 0) && (m_state == IDLE) )
    {
      m_state = ENCODE_VALUE;
      m_type = head->type;
      post encode_value();
    }
    return msg;
  }

  event result_t SendConfigValue.sendDone( TOS_MsgPtr msg, result_t success )
  {
    m_state = IDLE;
    return SUCCESS;
  }

${config_funcs}
}

