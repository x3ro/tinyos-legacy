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
// $Id: TuplePublisherM.neighbor.nc,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

includes cqueue;
includes SchemaType;
includes Command;
includes NestArch;

module TuplePublisherM
{
  provides
  {
    interface TuplePublisher;
    interface StdControl;
${provides}
  }
  uses
  {
    interface Leds;
    interface TupleStore;
    interface TupleManager;
    interface RoutingSendByBroadcast;
    interface RoutingSendByBroadcast as CommandBroadcast;
    interface RoutingReceive;
    interface StdControl as CommandControl;
    interface CommandRegister as Publish;
    interface Random;
    interface Timer;
  }
}
implementation
{
  TOS_Msg m_msg;
  bool m_is_sending;
  uint8_t m_tupleTypeToBePublished;
  uint16_t m_nodeIDToBePublished;

/*typedef struct {
  uint16_t address;
  uint8_t tupletype;
} TupleMsgHeader_t;

typedef struct{
  const Neighbor_t* tuple;
} TupleIterator_t;*/

  enum {
    MAX_QUEUE_SIZE = 12,
  };

  TupleMsgHeader_t m_queue[ MAX_QUEUE_SIZE ];
  cqueue_t m_cq;

  command result_t StdControl.init()
  {
    ParamList paramList;
    m_is_sending = FALSE;
    init_cqueue( &m_cq, MAX_QUEUE_SIZE );
    call CommandControl.init();
    paramList.numParams=1;
    paramList.params[0]=INT8;
    paramList.params[1]=INT16;
    if (call Publish.registerCommand("Publish", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call CommandControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  { 
   call CommandControl.stop();
   return SUCCESS;
  }

  event result_t Publish.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
	    //This adds a random delay before executing the "publish" command
	    //in order to avoid network collisions.  Notice that it doesn't
            //work if you get more than one publish command at a time
	    uint32_t randomDelay;
	    m_tupleTypeToBePublished = *(uint8_t*)params->paramDataPtr[0];
	    m_nodeIDToBePublished = *(uint16_t*)params->paramDataPtr[1];
	    if(m_nodeIDToBePublished == 0)
		m_nodeIDToBePublished = TOS_LOCAL_ADDRESS;
	    randomDelay = call Random.rand() & 0x0fff; //use the last bytes
            call Timer.start(TIMER_ONE_SHOT, randomDelay);
	    return SUCCESS;
	}

  event result_t Timer.fired() 
  {
	call TuplePublisher.publish(m_tupleTypeToBePublished, m_nodeIDToBePublished);
	return SUCCESS;
  }

  task void do_publish();

  result_t requestRemoteTuples(uint8_t tupleType)
  {
    if( push_back_cqueue(&m_cq) == SUCCESS )
    {
      m_queue[ m_cq.back ].address   = 0;
      m_queue[ m_cq.back ].tupletype = tupleType;
      post do_publish();
      return SUCCESS;
    }
    return FAIL;
  }
      
  result_t createRemoteTupleRequest(uint8_t tupleType)
  {
    struct CommandMsg* cmdHeaders;
    char* cmdName;
    uint8_t* tupleTypeParam;
    uint16_t* nodeIDParam;

    // get pointers to the appropriate command headers in the message body
   if( (cmdHeaders = (struct CommandMsg*)initRoutingMsg( &m_msg, sizeof(struct CommandMsg) )) == 0 )
         return FAIL;
   if( (cmdName = (char*)pushToRoutingMsg( &m_msg, sizeof("Publish") )) == 0 )
      return FAIL;
   if( (tupleTypeParam = (uint8_t*)pushToRoutingMsg( &m_msg, sizeof(uint8_t) )) == 0 )
      return FAIL;
   if( (nodeIDParam = (uint16_t*)pushToRoutingMsg( &m_msg, sizeof(uint16_t) )) == 0 )
      return FAIL;

   //add the appropriate data to the message
   cmdHeaders->nodeid = TOS_BCAST_ADDR;
   cmdHeaders->fromBase = 0;
   strcpy(cmdName, "Publish");
   *tupleTypeParam = tupleType;
   *nodeIDParam = 0; //this is always set to zero because we are currently not giving nodes themselves the ability to request tuples of their neighbors' neighbors.  We could expand this function to have a nodeID parameter, thus allowing multi-hop neighborhoods. (I am only adding this nodeID param for debugging purposes at the moment.) 
   return SUCCESS;
  }
      


${neighbor_funcs}

  command void TuplePublisher.publish( uint8_t tupletype, uint16_t address )
  {
    if( address != TOS_LOCAL_ADDRESS )
      return;

    if( push_back_cqueue(&m_cq) == SUCCESS )
    {
      m_queue[ m_cq.back ].address   = address;
      m_queue[ m_cq.back ].tupletype = tupletype;
      post do_publish();
    }
  }

  task void post_do_publish()
  {
    post do_publish();
  }

  task void do_publish()
  {
    TupleMsgHeader_t* head;
    void* msgdata;
    TupleMsgHeader_t headdata;
    const Neighbor_t* nn;

    // if already sending or the queue is empty, leave
    if( (m_is_sending == TRUE) || (is_empty_cqueue( &m_cq ) == TRUE) )
      return;

    // save the front of the queue and pop it off
    headdata = m_queue[ m_cq.front ];
    pop_front_cqueue( &m_cq );

    // if the address is zero, this is a request for this tupleType (by convention)  this is a messy hack that should be changed
    if( headdata.address == 0 )
    {
       if( createRemoteTupleRequest(headdata.tupletype) == FAIL)
          return;
       // if the message sent successfully, then lock out reentry to this task.
       // otherwise, re-enqueue the message and try to publish it again later.
      if( call CommandBroadcast.send( 0, &m_msg ) == SUCCESS )
      {
         m_is_sending = TRUE;
       }
       else
       {
         if( push_front_cqueue( &m_cq ) == TRUE ) 
         m_queue[ m_cq.front ] = headdata;
         post post_do_publish();
       }
    }
    else
    {

       // if the address isn't in the tuple store, leave
       if( (nn = call TupleStore.getByAddress(headdata.address)) == 0 )
        return;
 
       // put the appropriate tuple data into the message body
       switch( headdata.tupletype )
       {
${send_cases}
         default:
     	   return;
       }

       // if there's no room for the publish header, leave, because there's
       // nothing more we can do now or in the future
       if( (head = (TupleMsgHeader_t*)pushToRoutingMsg( &m_msg, sizeof(TupleMsgHeader_t) )) == 0 )
         return;

       // put the publish header into the message
       *head = headdata;


       // if the message sent successfully, then lock out reentry to this task.
       // otherwise, re-enqueue the message and try to publish it again later.
       if( call RoutingSendByBroadcast.send( 0, &m_msg ) == SUCCESS )
       {
         m_is_sending = TRUE;
       }
       else
       {
         if( push_front_cqueue( &m_cq ) == TRUE )
	   m_queue[ m_cq.front ] = headdata;
         post post_do_publish();
       }
    }
  }

  event result_t RoutingSendByBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( msg == &m_msg )
      m_is_sending = FALSE;
    post do_publish();
    return SUCCESS;
  }

  event result_t CommandBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( msg == &m_msg )
      m_is_sending = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr RoutingReceive.receive( TOS_MsgPtr msg )
  {
    TupleMsgHeader_t* head;
    void* msgdata;

    //call Leds.yellowToggle();

    if( (head = (TupleMsgHeader_t*)popFromRoutingMsg( msg, sizeof(TupleMsgHeader_t) )) == 0 )
      return msg;

    switch( head->tupletype )
    {
${receive_cases}
      default:
	return msg;
    }

    //call Leds.greenToggle();

    return msg;
  }
}


