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
 * Authors: Gary Zhou,Tian He 
 */

includes  UVARouting;

module GFM{
	provides{
		interface StdControl;
        interface RoutingSendByLocation [uint8_t app_ID];
        interface RoutingSendByAddress  [uint8_t app_ID];
        interface RoutingReceive        [uint8_t app_ID];
        interface Beacon;
	}
	uses{
		interface ReceiveMsg as ReceiveDataMsg;
        interface ReceiveMsg as ReceiveBeaconMsg;
		interface SendMsg    as SendDataMsg;
        interface SendMsg    as SendBeaconMsg;
		interface StdControl as CommControl;
		interface Random;
	 	interface Local;
        interface Timer as T1_SendBeacon;
		interface Timer as T2_RefreshNT;
        interface Timer as BackOffTimer;
	}
}

implementation{
	uint8_t BEACON_INCLUDED = 1;
	
	TOS_MsgPtr 	GF_ROUTE_PACKET  (TOS_MsgPtr msg);
    void  	    print_GF_PACKET  (GF_PACKET * data);
   
    void        GetLocalPosition();
    POSITION    GetRemotePosition(uint16_t id);
    uint16_t   GetForwardingIDByLocLoc(NEIGHBOR_TABLE * nt,POSITION source_position,POSITION dest_position );
    uint16_t   GetForwardingIDByIDLoc(NEIGHBOR_TABLE * nt,uint16_t SourceID, POSITION dest_position);
    uint16_t   GetDistanceByPosition(POSITION sourse, POSITION dest);
	
    uint16_t 	insertNT  (NEIGHBOR_TABLE *nt,uint16_t NewID,POSITION pos);
	void    initNT    (NEIGHBOR_TABLE * nt);  	
	void	printNT   (NEIGHBOR_TABLE * nt);
	uint16_t   deleteNT  (NEIGHBOR_TABLE * nt, uint16_t NewID);
    void    setNT     (NEIGHBOR_TABLE * nt, short r);
    
    int     refresh_count;
    
	////////variables///////
	NEIGHBOR_TABLE  global_nt;
	TOS_Msg 	global_data_buf;
			
	uint8_t 	global_currentSeqNO;
    uint16_t    global_beacon_wait_status;
	POSITION    global_local_position;
    uint32_t    delay;
    
    //////////  StdControl  /////
    //////////////////////////////
	command result_t StdControl.init(){
		dbg(DBG_USR1,"GFM.init()\n");
        
        call CommControl.init();

        global_beacon_wait_status= 0;
		global_currentSeqNO      = 0;
		
        refresh_count = 0;
        
        call Random.init();
		initNT(&global_nt);
		
		return SUCCESS;
	}

	command result_t StdControl.start(){

        
        call CommControl.start();
        GetLocalPosition();
        
        if(BEACON_INCLUDED == 1){
            
            delay = (call Random.rand() % 1000) * FIRST_BEACON_TIME;
            
            dbg(DBG_USR1,"GFM.start()with first beacon at %ld\n",delay);            
            
            call T1_SendBeacon.start(TIMER_ONE_SHOT,delay);
            
            delay = (call Random.rand() % 1000) * REFRESH_NT_PERIOD;
                                    
		    call T2_RefreshNT.start(TIMER_REPEAT,delay);	
		}else{
            setNT(&global_nt,RADIO_RANGE);
            printNT(&global_nt);
        }
        return SUCCESS;
	}
	
	command result_t StdControl.stop(){
        dbg(DBG_USR1,"GFM.stop()\n");
    
		call CommControl.stop();
		call T1_SendBeacon.stop();
        call T2_RefreshNT.stop();
		return SUCCESS;
	}
    
    /////////////// Beacon Control /////////
    /////////////////////////////////////////////////////////////////////
    command result_t Beacon.setParameters(uint8_t BeaconIncluded){
      dbg(DBG_USR1,"GFM.setbeacon as %d\n", BeaconIncluded);            
      BEACON_INCLUDED = BeaconIncluded;
      return SUCCESS;  
    }

    ////////////////  Bottom  Routing   and  Beacon ///////////////
    //////////////////////////////////////////////////////////////
	event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr m){
	
		POSITION pos;
        GF_PACKET* packet = (GF_PACKET*)(m->data);
		
        dbg(DBG_USR1,"Data destination is %d %d \n",packet->header.position.x, packet->header.position.y);
		pos = global_local_position;
        if(pos.x == packet->header.position.x && pos.y == packet->header.position.y ){
			signal RoutingReceive.receive[packet->header.appID](m);
            dbg(DBG_USR1,"Get message from: %d with segNO: %d appID: %d \n",packet->header.globalSenderID, 	packet->header.seqNO,packet->header.appID);
			return m;
		}else{
			GF_ROUTE_PACKET(m);
            return m;
		}
	}

    event TOS_MsgPtr ReceiveBeaconMsg.receive(TOS_MsgPtr m){
        int i;
        BEACON * beacon;
        int findID;
        uint16_t r=1;

        dbg(DBG_USR3,"@@@Beacon---ReceiveBeaconMsg.receive\n");
        
        r = RADIO_RANGE;
        
        beacon = (BEACON *)m->data;
        //this following secgment is only useful in simulator
        if((beacon->position.x - global_local_position.x) >= r+1 || 
           (beacon->position.y - global_local_position.y) >= r+1 ||
           (global_local_position.x - beacon->position.x) >= r+1 ||
           (global_local_position.y - beacon->position.y) >= r+1)
        {    return m; }
        //the above segment is only useful in simulator
        
        findID = 0;
        for(i=0;i<MAX_NEIGHBOR;i++){
            if(beacon->globalSenderID == global_nt.NeighborID[i]){
                findID = 1;
                break;
            }
        }

        if (findID == 1){
            global_nt.RefreshStatus[i] = 1;
            global_nt.NeighborStatus[i]= 1;
        }else{
           insertNT(&global_nt,beacon->globalSenderID,beacon->position);
           for(i=0;i<MAX_NEIGHBOR;i++){
                if(beacon->globalSenderID == global_nt.NeighborID[i]){
                    global_nt.RefreshStatus[i] = 1;
                    global_nt.NeighborStatus[i]= 1;
                    break;
                }
           }
        }
        
        dbg(DBG_USR3,"@@@Beacon---ReceiveBeaconMsg.receive from %d happened!\n",beacon->globalSenderID);
        printNT(&global_nt); 
        return m;
    }

	event result_t SendDataMsg.sendDone(TOS_MsgPtr msg, result_t success){
		GF_PACKET * packet;
        uint8_t app_ID;
        
        packet = (GF_PACKET *)msg->data;
        app_ID = packet->header.appID;
        
        dbg(DBG_USR1,"SendDataMsg.sendDone: A packet with SeqNO %d app_ID %d is confirmed to sent out from %d \n",
            packet->header.seqNO,packet->header.appID,TOS_LOCAL_ADDRESS);
        dbg(DBG_USR1,"Send available\n");
	
        if(packet->header.globalSenderID == TOS_LOCAL_ADDRESS){
            signal RoutingSendByLocation.sendDone[app_ID](msg,success);
        }
        return success;
	}

    event result_t SendBeaconMsg.sendDone(TOS_MsgPtr msg, result_t success){
		dbg(DBG_USR3,"@@@Beacon---Beacon sendDone\n");
		return success;
	
    }
    
    /////////////// RoutingSendByLocation & RoutingSendByAddress/////////
    /////////////////////////////////////////////////////////////////////
    
    default event TOS_MsgPtr RoutingReceive.receive[uint8_t app_ID](TOS_MsgPtr msg){
        dbg(DBG_USR1,"@@@Routing: RoutingReceive.receive[ %d ] happens\n",app_ID);
        return msg;
    }
 
    command result_t RoutingSendByAddress.send[uint8_t app_ID](RoutingAddress_t  address, TOS_MsgPtr msg){
        RoutingLocation_t  location;
        POSITION pos;

	if(address == TOS_UART_ADDR)
	{
	return(call SendDataMsg.send(TOS_UART_ADDR,sizeof(GF_PACKET),msg));
	}
	else{
        pos =   GetRemotePosition((uint16_t)address);
        location.pos.x  =   pos.x;
        location.pos.y  =   pos.y;
        return (call RoutingSendByLocation.send[app_ID](&location, msg));
        }
    }
  
    command result_t RoutingSendByLocation.send[uint8_t app_ID](RoutingLocation_t * location, TOS_MsgPtr msg){
        uint16_t i;
        uint16_t nexthop;
		GF_PACKET * packet = (GF_PACKET *)(global_data_buf.data);
        POSITION dest_position;
        
        dest_position.x = (*location).pos.x;
        dest_position.y = (*location).pos.y;
        
        dbg(DBG_USR1, "Enter into RoutingSendByLocation.send\n");
        
		for(i=0;i<PAYLOAD_SIZE;i++)packet->data[i] = msg->data[i];		
		packet->header.position = dest_position;
		packet->header.globalSenderID  = TOS_LOCAL_ADDRESS;
        packet->header.globalReceiverID= 0xffff;
		packet->header.seqNO = global_currentSeqNO;
        global_currentSeqNO ++;
        if(global_currentSeqNO == 255)global_currentSeqNO = 0;
        packet->header.appID = app_ID;

        nexthop = GetForwardingIDByIDLoc(&global_nt,TOS_LOCAL_ADDRESS,dest_position);
        dbg(DBG_USR1,"The forwardingID is %d \n",nexthop);
        
        if(nexthop != (uint16_t)0xffff){
            dbg(DBG_USR1,"The message to be send is:\n");
            print_GF_PACKET((GF_PACKET *)global_data_buf.data);
            if(call SendDataMsg.send(nexthop,sizeof(GF_PACKET),&global_data_buf)){
                dbg(DBG_USR1,"SendDataMsg.send is called to send a data packet with packet length %d \n", sizeof(GF_PACKET));
                dbg(DBG_USR1,"Sent packet with SeqNo %d and app_ID %d from %d to %d \n",
                    packet->header.seqNO,packet->header.appID,TOS_LOCAL_ADDRESS,nexthop);
            }else{
                dbg(DBG_USR1,"SendMsg.send fail with packet length %d\n",sizeof(GF_PACKET));
                call BackOffTimer.start(TIMER_ONE_SHOT, 30);
                return FAIL;
            }
        }else{
            dbg(DBG_USR1,"Failed to find out a mote from the neighbor table, so this packet %d is dropped\n",packet->header.seqNO);
            return FAIL;
        }

        return SUCCESS;
    }
    
    default event result_t RoutingSendByLocation.sendDone[uint8_t app_ID](TOS_MsgPtr msg, result_t success){
        dbg(DBG_USR1,"@@@Routing: RoutingSendByLocation.sendDone[ %d ] happen\n",app_ID);
        return success;
    }
    
    default event result_t RoutingSendByAddress.sendDone[uint8_t app_ID](TOS_MsgPtr msg, result_t success){
        dbg(DBG_USR1,"@@@Routing: RoutingSendByAddress.sendDone[ %d ] happen\n",app_ID);
        return success;
    }
    
    /////////////////////   Neighbor Table ////////////
    ///////////////////////////////////////////////////
   
    event result_t T1_SendBeacon.fired(){
    
		POSITION position;
		BEACON * beacon_packet;
		TOS_Msg beacon_msg;
        uint32_t beacon_delay = 0; 
                 
        beacon_packet = (BEACON*)beacon_msg.data;
        beacon_packet ->globalSenderID = TOS_LOCAL_ADDRESS;
        position.x = (uint16_t)global_local_position.x;
        position.y = (uint16_t)global_local_position.y;
        beacon_packet ->position = position;
        if(call SendBeaconMsg.send(TOS_BCAST_ADDR,sizeof(BEACON),&beacon_msg)){
            dbg(DBG_USR3, "@@@Beacon---A beacon packet is sent from %d \n",TOS_LOCAL_ADDRESS);
        }else{
            dbg(DBG_USR3,"@@@Beacon---A beacon send fail SendBeaconMsg.Send fail!\n");
        }
        
        beacon_delay = (call Random.rand()% 1000 +1000)* SEND_BEACON_PERIOD;
        dbg(DBG_USR3,"the random time delay of next beacon message is %d \n",beacon_delay);
        call T1_SendBeacon.start(TIMER_ONE_SHOT,beacon_delay);
        return SUCCESS;
	}
       
    event result_t T2_RefreshNT.fired(){
        int i;
        
        if (refresh_count < 7){
            refresh_count ++;
            return SUCCESS;
        }else{
            refresh_count = 0;
        }
        
        for(i=0;i<MAX_NEIGHBOR;i++){
            if(global_nt.RefreshStatus[i] == 1)
                global_nt.NeighborStatus[i] = 1;
            else
                global_nt.NeighborStatus[i] = 0;
            global_nt.RefreshStatus[i]  = 0;
        }
        dbg(DBG_USR1,"Refresh NT!\n");
        
        return SUCCESS;
	}

  ///////////   help functions  /////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////
 
    void print_GF_PACKET(GF_PACKET * data){
		int i;

		dbg_clear(DBG_USR1, "Packet Header (header size %d ) seqNO: %d, ",data->header.seqNO); 
        dbg_clear(DBG_USR1, "Sender: %d,",data->header.globalSenderID);
        dbg_clear(DBG_USR1, "Receiver: %d",data->header.globalReceiverID);
        dbg_clear(DBG_USR1, "appID: %d",data->header.appID);
        dbg_clear(DBG_USR1, "pos.x: %d pos.y: %d \n",data->header.position.x,data->header.position.y);
		
        for(i=0;i<PAYLOAD_SIZE;i++)
			dbg_clear(DBG_USR1,"%hhx",data->data[i]);
		dbg_clear(DBG_USR1,"\n");

	}

	uint16_t insertNT(NEIGHBOR_TABLE *nt,uint16_t NewID,POSITION pos){
		// if 0 is returned, it inserts succesfully. if 1 is returned, it fails.
		uint16_t i;

		for(i=0;i<MAX_NEIGHBOR;i++){
			if(nt->NeighborID[i] == (uint16_t)0xffff){
				nt->NeighborID[i] = NewID;
                nt->NeighborPOSITION[i].x = pos.x;
                nt->NeighborPOSITION[i].y = pos.y;
                nt->NeighborStatus[i] = 1;
                nt->RefreshStatus[i] = 1;
				nt->size++;
				return 1;
			}
		}
		return 0;
	}

    void initNT(NEIGHBOR_TABLE * nt){
		uint16_t i;
		
		for(i=0;i<MAX_NEIGHBOR;i++){
			nt->NeighborID[i]         =   (uint16_t)0xffff;
            nt->NeighborPOSITION[i].x =   (uint16_t)0xffff;
            nt->NeighborPOSITION[i].y =   (uint16_t)0xffff;
            nt->NeighborStatus[i]     =   0;
            nt->RefreshStatus[i]      =   0;
        }
		nt->size = 0;
	}
    

    //for debug use
    void setNT(NEIGHBOR_TABLE * nt, short r){
    
        short i,j;
        uint16_t temp_ID = 0xffff;
        short temp_x,temp_y;
        POSITION neighborPos;
                
        for(i=-r; i<=r; i++){
            for(j=-r; j<=r; j++){
              
                if ( !(i ==0 & j==0) ){
                    temp_x = global_local_position.x + i;
                    temp_y= global_local_position.y + j;
                    if(temp_x >= 0 && temp_y >= 0 ){
                    	temp_ID = call Local.GetIDByLocation(temp_x,temp_y); 
                   		if(temp_ID != 0xffff){
                   		 neighborPos.x = temp_x;
                   		 neighborPos.y = temp_y;                   		 
                       	 insertNT(&global_nt,temp_ID,neighborPos);    
                    	}
                    }
                }
            }
        }
    
    }

	void printNT(NEIGHBOR_TABLE * nt){
		uint16_t i;

		dbg(DBG_USR1,"%d Neighbors are:\n ",nt->size);
		for(i=0;i<MAX_NEIGHBOR;i++){
			if(nt->NeighborID[i] != (uint16_t)0xffff){
				dbg_clear(DBG_USR1, "ID: %d ",nt->NeighborID[i]);
                dbg_clear(DBG_USR1, "POSITION: (%d, %d) ",nt->NeighborPOSITION[i].x, nt->NeighborPOSITION[i].y);
			    dbg_clear(DBG_USR1, "Alive: %d ",nt->NeighborStatus[i]);
                dbg_clear(DBG_USR1, "Refresh: %d ",nt->RefreshStatus[i]);
                dbg_clear(DBG_USR1,"\n");
            }
		}
	}

	uint16_t deleteNT(NEIGHBOR_TABLE * nt, uint16_t NewID ){
		uint16_t i;

		for(i=0;i<MAX_NEIGHBOR;i++){
			if(nt->NeighborID[i] == NewID){
				nt->NeighborID[i] = (uint16_t)0xffff;
                nt->NeighborPOSITION[i].x = (uint16_t)0xffff;
                nt->NeighborPOSITION[i].y = (uint16_t)0xffff;
                nt->NeighborStatus[i] = 0;
                nt->RefreshStatus[i] = 0;
				nt->size --;
				return 1;
			}
		}
		return 0;
	}

	TOS_MsgPtr GF_ROUTE_PACKET (TOS_MsgPtr m){
		GF_PACKET* packet = (GF_PACKET *)(m->data);
		uint16_t nexthop;
        
        POSITION pos;
        pos = global_local_position;
		if(pos.x == packet->header.position.x && pos.y == packet->header.position.y){
			dbg(DBG_USR1,"A packet sent from %d to %d %d is received\n",
                            packet->header.globalSenderID,packet->header.position.x, packet->header.position.y);
            return m;
		}
        
		nexthop = GetForwardingIDByIDLoc(&global_nt,TOS_LOCAL_ADDRESS,packet->header.position);
		if(nexthop != (uint16_t)0xffff){
			//packet->header.hopCount++;
			dbg(DBG_USR1,"routing packet woth seqNO %d and appID %d from %d to nexthop %d \n",
                    packet->header.seqNO,packet->header.appID,TOS_LOCAL_ADDRESS,nexthop);

            if(call SendDataMsg.send(nexthop,sizeof(GF_PACKET),m)){
                dbg(DBG_USR1,"@@SendDataMsg.send is called to send a data packet\n");
                return m;
            }else{
                dbg(DBG_USR1,"SendDadaMsg.send() fail\n");
            }
        }else{
            dbg(DBG_USR1,"Failed to find a mote in the Neighbor table. So dropped this packet %d \n",packet->header.seqNO);
        }
		return m;	
	}

	uint16_t GetForwardingIDByLocLoc(NEIGHBOR_TABLE * nt,POSITION source_position,POSITION dest_position ){
        //when 0xffff is returned, there is error
        int i;
        uint16_t MinDistance  = GetDistanceByPosition(source_position, dest_position);
        uint16_t forwardingID = (uint16_t)0xffff;
        POSITION pos;
        
        printNT(&global_nt); 
        
        for(i=0;i<MAX_NEIGHBOR;i++){
			if(nt->NeighborID[i] != (uint16_t)0xffff  &&   nt->NeighborStatus[i] == 1){
                pos = nt->NeighborPOSITION[i];
				if(MinDistance > GetDistanceByPosition(pos,dest_position)){
                    MinDistance  = GetDistanceByPosition(pos,dest_position);
					forwardingID = nt->NeighborID[i];
                    dbg(DBG_USR1,"GetForwarding: %d MinDistance %d \n",forwardingID,MinDistance);
				}
			}
		}

		if(forwardingID == (uint16_t)0xffff)
			dbg(DBG_USR1,"Error in Get next mote from the neighbor table\n");
		return forwardingID;
    }

    uint16_t GetForwardingIDByIDLoc(NEIGHBOR_TABLE * nt,uint16_t SourceID, POSITION dest_position){
        POSITION source_position = global_local_position;
        return GetForwardingIDByLocLoc(nt, source_position, dest_position);
    }

    uint16_t GetDistanceByPosition(POSITION source, POSITION dest){
        short dist_x;
        short dist_y;
        dist_x = source.x - dest.x;
        if (dist_x < 0) dist_x = -dist_x;
        dist_y = source.y - dest.y;
        if (dist_y < 0) dist_y = -dist_y;
        return dist_x + dist_y;
    } 
    
    void GetLocalPosition(){
        global_local_position.x = call Local.LocalizationByID_X(TOS_LOCAL_ADDRESS);
        global_local_position.y = call Local.LocalizationByID_Y(TOS_LOCAL_ADDRESS);
    }

    POSITION GetRemotePosition(uint16_t id){
        POSITION pos;
        pos.x = call Local.LocalizationByID_X(id);
        pos.y = call Local.LocalizationByID_Y(id);
        return pos;
    }
    
    event result_t BackOffTimer.fired() {
		
		uint16_t nexthop = 0xffff;
		
		GF_PACKET * packet = (GF_PACKET *)(global_data_buf.data);
		
		nexthop = GetForwardingIDByIDLoc(&global_nt,TOS_LOCAL_ADDRESS,packet->header.position);
		
		if(nexthop == 0xffff) return FAIL;
		
        if(call SendDataMsg.send(nexthop,sizeof(GF_PACKET),&global_data_buf)){
            dbg(DBG_USR1,"SendDataMsg.send is retried to broadcast a data packet\n");                
            return SUCCESS;
        }else{
            dbg(DBG_USR1,"SendMsg.send fail\n");
            call BackOffTimer.start(TIMER_ONE_SHOT, 30);
			return SUCCESS;
        }                 
    
    }
}
