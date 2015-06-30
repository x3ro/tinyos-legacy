/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Brain Blum,Tian He 
 */
 
/*
 * $Header: /cvsroot/tinyos/tinyos-1.x/contrib/minitasks/03/uva/EnviroTrack/ECMM.nc,v 1.5 2003/06/12 03:19:48 cssharp Exp $
 */

//!! Config 40 { uint8_t UVA_MaxGroups = MAX_GROUPS; }

includes ECM;

module ECMM {
  provides interface ECM;
  uses {
//0406B
    interface GetLeader;
    interface RoutingSendByMobileID as SendMsgByID;
    interface RoutingDDReceiveDataMsg as ReceiveRoutingMsg;

    interface RoutingSendByAddress as SendToUart;
    interface RoutingReceive as ReceiveGFRoutingMsg;
  
    interface TimedLeds;	 
//0406E
    interface Config_UVA_MaxGroups;
  }
}

implementation {
  ECMTable ecmTable;
  ECMPacket ecmData;
  TOS_Msg m_msg;  

  /***********************************************************************/
  void initECMTable(ECMTable *tt) {
    uint16_t i;
    for (i = 0; i < G_Config.UVA_MaxGroups; i++){
      tt->group[i] = (uint16_t)0xffff;
      tt->port[i] = (uint16_t)0xffff;
      tt->leader[i] = (uint16_t)0xffff;
    }
    tt->size=0;
  }

  /************************************************************************/
  uint16_t insertECMTable(ECMTable *tt, uint16_t group,
		       uint16_t port,	uint16_t leader) {
    uint16_t i;
    uint16_t lastEntry = 0;
    char entryFound = 'F';
	  
    for (i = 0; i < G_Config.UVA_MaxGroups; i++) {
      if(tt->group[i] != (uint16_t)0xffff)
	lastEntry++;
      if(tt->group[i] == group)
	entryFound = 'T';
    }

    if(entryFound == 'F' && lastEntry < G_Config.UVA_MaxGroups) {
      dbg(DBG_USR1, "ECM: Tracking Table Insert %d\n", group); 
      tt->group[lastEntry] = group;
      tt->port[lastEntry] = port;
      tt->leader[lastEntry] = leader;
      tt->size++;
    }
    else if(lastEntry == G_Config.UVA_MaxGroups)
    {
      dbg(DBG_USR1, "ECM: Table full\n");
    }
    else if(entryFound == 'T')
      dbg(DBG_USR1, "ECM: Table Entry %d Exists\n", group);
    return 1;
  }

  /***********************************************************************/
  uint16_t lookupLeaderInECMTable(ECMTable *tt, 
			       uint16_t group) {
    uint16_t i;
    for (i = 0; i < G_Config.UVA_MaxGroups; i++){
      if(tt->group[i] == group)
	return tt->leader[i];
    }
    return (uint16_t)0xffff;
  }
	
  /*********************************************************************/
  command result_t ECM.init() {
    dbg(DBG_USR1, "ECM: ecm init\n"); 
    
    initECMTable(&ecmTable); /* initialize ECM table */
	 
    /* ecm table faked initialization */
    insertECMTable(&ecmTable,
		   (uint16_t) BASE_GROUP,
		   PHOTO_EVENT,
		   (uint16_t) BASE_LEADER);
	 
    return SUCCESS;
  }

  /*********************************************************************/
  command result_t ECM.sendToGroup(char *data, uint16_t group,uint16_t app_ID) {
    int i;
  	ECMPacket* ecmData2;
    uint16_t dest = lookupLeaderInECMTable(&ecmTable, group);
  
    dbg(DBG_USR1, "ECM: send event to group %d, node %d\n", group, dest); 
 
    if ((ecmData2 = (ECMPacket*)initRoutingMsg(&m_msg, sizeof(ECMPacket))) == 0)
	{	
	   			dbg(DBG_USR1, "SEND: routing msg init fail\n");
	   			return FAIL;
    }
	   	
	   	dbg(DBG_USR1, "SEND: data length %d address %d\n", m_msg.length, m_msg.data);
	  		
    /* copy application information into ECM packet */
		ecmData2->group = group;
		ecmData2->port = app_ID;
		
    	dbg_clear(DBG_USR1, "ECM Payload\n");

	    for(i = 0; i < ECM_PAYLOAD_SIZE; i++) {
	      ecmData2->payload[i] = data[i];      
	      dbg_clear(DBG_USR1, "%x ", (uint8_t) data[i]);
	    }
	    dbg_clear(DBG_USR1, "\n");
    
	    if (call SendMsgByID.send(dest,	&m_msg))
	    {
	    	call TimedLeds.redOn(32);			
		dbg(DBG_USR1, "ECM: sendEvent to %d\n", dest);
	}
	
	   return SUCCESS;
  }
  /*************************************************************************/
/*05/06B delete
  event result_t SendMsgByID.sendDone( TOS_MsgPtr msg, result_t success )
  {
    dbg(DBG_USR1, "ECM: packet sent successfully\n");
    return SUCCESS;
  }
05/06E*/

//0406B add
  /*************************************************************************/
  event result_t SendToUart.sendDone( TOS_MsgPtr msg, result_t success )
  {
    dbg(DBG_USR1, "ECM: packet sent successfully\n");
    return SUCCESS;
  }
//0406E

  /********************************************************************/
  event TOS_MsgPtr ReceiveRoutingMsg.receive( TOS_MsgPtr msg )
  {
    uint16_t group;
    uint16_t port;
    uint8_t i=0;
    uint8_t * tempCharPtr;
    uint16_t groupLeader;
	
	ECMPacket* ecmPacket;	      
      	
	if ((ecmPacket = (ECMPacket*)popFromRoutingMsg(msg, sizeof(ECMPacket))) == 0)
		{
			dbg(DBG_USR1, "RECEIVE:	fain\n");	
			return msg;
    }
	
    if(ecmPacket == 0) return FAIL;

  	dbg(DBG_USR1, "RECEIVE: data length %d\n", msg->length);
  
    group = ecmPacket->group;
    port = ecmPacket->port;
	 
    dbg(DBG_USR1, "ECM: process msg for group=%d, port=%d\n", group, port); 

    /* update ECMTable with leader=sender from sending group */
    groupLeader = (uint16_t) BASE_LEADER; 
    // groupLeader = call GetLeader.getLeaderForGroup(group);

    /* either process or forward message to appropriate leader*/
//0406B
    if(groupLeader == TOS_LOCAL_ADDRESS) {
//0406E
        
      dbg(DBG_USR1, "ECM: Leader = ME\n"); 
      /* signal application to handle incoming packet */
      signal ECM.fromEndPacketDone(ecmPacket->payload,ecmPacket->port);
                    
    }

   if(TOS_LOCAL_ADDRESS == (uint16_t )BASE_LEADER){
   
	    dbg(DBG_USR1,"BaseReceive:\t");	      
	    tempCharPtr = (uint8_t *)msg;
	    for(i = 0 ;  i < sizeof(TOS_Msg); i++){
	     if(i == 5)dbg_clear(DBG_USR1,"ECM:: "); 
	     if(i == 9)dbg_clear(DBG_USR1,"GF: "); 	
	     if(i == 19)dbg_clear(DBG_USR1,"PayLoad: "); 		          
	     dbg_clear(DBG_USR1,"%hhx ",tempCharPtr[i]);
    	}
    	dbg_clear(DBG_USR1,"\n");	
	    
	    /*send to UART for GUI display */
	    msg->length = TOSH_DATA_LENGTH;
	    
	    call TimedLeds.redOn(32);   
//0406B
	    if (call SendToUart.send(TOS_UART_ADDR,msg) == FAIL){	
//0406E
	   			dbg(DBG_USR1, "SEND: send fail\n");
	  	}
  	}
  	  	
    return msg;
  }

//0406B add
  /********************************************************************/
  event TOS_MsgPtr ReceiveGFRoutingMsg.receive( TOS_MsgPtr msg )
  {
    return msg;
  }
//0406E

  event void Config_UVA_MaxGroups.updated()
  {
    if( G_Config.UVA_MaxGroups > MAX_GROUPS )
      G_Config.UVA_MaxGroups = MAX_GROUPS;
  }
}
