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

includes UVARouting;

module BCM{
    provides{
        interface StdControl;
        interface RoutingSendByBroadcast[uint8_t app_ID];
        interface RoutingReceive        [uint8_t app_ID];
    }
    uses{
        interface ReceiveMsg as ReceiveDataMsg;
        interface SendMsg    as SendDataMsg;
        interface StdControl as RoutingControl;
        interface Timer as BackOffTimer;
	 interface Random;
    }
}

implementation{
    
    TOS_Msg 	global_data_buf;
	uint16_t 		global_currentSeqNO;
    uint16_t       receiveBctFirstTime;

    BC_BUFFER   global_bc_buffer;
    
 	void print_BC_PACKET(BC_PACKET * data);

    void print_BC_BUFFER(BC_BUFFER * bc_buffer);
    void init_BC_BUFFER(BC_BUFFER * bc_buffer);
    void insert_BC_BUFFER(BC_BUFFER * bc_buffer, uint16_t ID, uint16_t seqNO);
    uint16_t check_BC_BUFFER(BC_BUFFER * bc_buffer, uint16_t ID, uint16_t seqNO);
    uint32_t delay;

   ////////////////////StdControl//////////
   //////////////////////////////////////

    command result_t StdControl.init(){
        dbg(DBG_USR1, "BCM.init()\n");
        
        global_currentSeqNO = 0;
        receiveBctFirstTime = 1;
        init_BC_BUFFER(&global_bc_buffer);
        return (call RoutingControl.init());
    }

    command result_t StdControl.start(){
        dbg(DBG_USR1, "BCM.start()\n");
        
        return (call RoutingControl.start());
    }

    command result_t StdControl.stop(){
        dbg(DBG_USR1, "BCM.stop()\n");
    
        return (call RoutingControl.stop());
    }
    
    //////////Broad cast////////////
    ///////////////////////////////

    command result_t RoutingSendByBroadcast.send[uint8_t app_ID](RoutingHopCount_t hops, TOS_MsgPtr msg){
        int i;
        BC_PACKET * packet;
        
        dbg(DBG_USR1, "@@@Routing: RoutingSendByBroadcast.send\n");
        
        packet = (BC_PACKET *)(global_data_buf.data);
        
		for(i=0;i<PAYLOAD_SIZE;i++)
			packet->data[i] = msg->data[i];
		packet->header.globalReceiverID = (uint16_t)0xffff;
		packet->header.globalSenderID  = TOS_LOCAL_ADDRESS;
		packet->header.seqNO = global_currentSeqNO ++;
        packet->header.hopCount = 0;
        packet->header.hopCountLimit = (uint8_t)hops;
        packet->header.appID = app_ID;
        
        //tian
        global_data_buf.length = msg->length+sizeof(BC_HEADER);
        
        dbg(DBG_USR1,"The message to be broadcast is:\n");
        print_BC_PACKET((BC_PACKET *)global_data_buf.data);
		
		//tian support variable size
        if(call SendDataMsg.send(TOS_BCAST_ADDR,global_data_buf.length,&global_data_buf)){
            dbg(DBG_USR1,"SendDataMsg.send is called to broadcast a data packet\n");
            dbg(DBG_USR1,"Broadcast packet with SeqNo %d and app_ID %d from %d to every one in the radio scope\n",
                packet->header.seqNO,packet->header.appID,TOS_LOCAL_ADDRESS);
        }else{
            dbg(DBG_USR1,"SendMsg.send fail\n");
            call BackOffTimer.start(TIMER_ONE_SHOT, 30);
            return FAIL;
        }
        return SUCCESS;
    }

    default event result_t RoutingSendByBroadcast.sendDone[uint8_t app_ID](TOS_MsgPtr msg, result_t success){
        dbg(DBG_USR1,"@@@Routing: RoutingSendByBroadcast.sendDone[ %d ] happen\n",app_ID);
        return success;
    }
  
    default event TOS_MsgPtr RoutingReceive.receive[uint8_t app_ID](TOS_MsgPtr msg){
        dbg(DBG_USR1,"@@@Routing: RoutingReceive.receive[ %d ] happens\n",app_ID);
        return msg;
    }

    ////////////Bottom Routing///////
    /////////////////////////////////

    event result_t SendDataMsg.sendDone(TOS_MsgPtr msg, result_t success){
        BC_PACKET * packet;
        uint8_t app_ID;
        packet = (BC_PACKET *)msg->data;
        app_ID = packet->header.appID;
        
        dbg(DBG_USR1,"SendDataMsg.sendDone: A packet with SeqNO %d app_ID %d is confirmed to sent out from %d \n",
            packet->header.seqNO,packet->header.appID,TOS_LOCAL_ADDRESS);
        dbg(DBG_USR1,"Send available\n");
        if(packet->header.globalSenderID == TOS_LOCAL_ADDRESS){
            signal RoutingSendByBroadcast.sendDone[app_ID](msg,success);
        }
        return success;
    }
   
    event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr m){
        int i;
        BC_PACKET * packet;
        BC_PACKET * fw_packet;		
        packet      =   (BC_PACKET *)(m->data);
        fw_packet   =   (BC_PACKET *)(global_data_buf.data);
        
        if((uint16_t)0xffff == packet->header.globalReceiverID){
            
            //print_BC_BUFFER(&global_bc_buffer);
           
            if(packet->header.globalSenderID == TOS_LOCAL_ADDRESS)
                return m;
           
            if (check_BC_BUFFER(&global_bc_buffer,packet->header.globalSenderID,packet->header.seqNO) == 1){
                return m;
            }else{
                insert_BC_BUFFER(&global_bc_buffer,packet->header.globalSenderID,packet->header.seqNO);
            }
        
            if(packet->header.hopCount <= packet->header.hopCountLimit){

                	//dbg(DBG_USR1,"BC: Get from: %d with seqNO: %d appID: %d ,Limit %d,hopCount %d\n",
                    //packet->header.globalSenderID, packet->header.seqNO,
                    //packet->header.appID  , packet->header.hopCountLimit,  packet->header.hopCount);
            	            	
                	signal RoutingReceive.receive[packet->header.appID](m);                
                	receiveBctFirstTime = 0;
            }
            
            if(packet->header.hopCount < packet->header.hopCountLimit){

                //print_BC_PACKET(packet);
                
                fw_packet->header.globalSenderID   =   packet->header.globalSenderID;
                fw_packet->header.globalReceiverID =   packet->header.globalReceiverID;
                fw_packet->header.seqNO            =   packet->header.seqNO;
                fw_packet->header.hopCount         =   packet->header.hopCount + 1;
                fw_packet->header.hopCountLimit    =   packet->header.hopCountLimit;
                fw_packet->header.appID            =   packet->header.appID;
        		        
                for(i=0;i<PAYLOAD_SIZE;i++)
                    fw_packet->data[i]             =   packet->data[i];

        	  //tian
        	  global_data_buf.length = m->length;      
 		  while(delay == 0) delay = call Random.rand() & 0xf;		
 	  	  delay = delay * 25+50;
		  call BackOffTimer.start(TIMER_ONE_SHOT, delay);       		  		                 
            }
        }
        return m;
    }
    /////////////Help Functions//////
    /////////////////////////////////
	void print_BC_PACKET(BC_PACKET * data){
		int i;
		dbg_clear(DBG_USR1, "Packet Header :seqNO: %d , Sender: %d , Receiver: %d , hopCount: %d , hopCountLimit %d , appID: %d \n",
			data->header.seqNO,data->header.globalSenderID,data->header.globalReceiverID,
            data->header.hopCount, data->header.hopCountLimit, data->header.appID);
		for(i=0;i<PAYLOAD_SIZE;i++)
			dbg_clear(DBG_USR1,"%hhx",data->data[i]);
		dbg_clear(DBG_USR1,"\n");
	}

    void init_BC_BUFFER(BC_BUFFER * bc_buffer){
        int i;

        for(i=0;i< MAX_BC_BUFFER;i++){
            bc_buffer->globalSenderID[i]    =   (uint16_t)0xffff;
            bc_buffer->seqNO[i]             =   (uint16_t)0xffff;
        }
        bc_buffer->head =   0;
    }
    
    
    void insert_BC_BUFFER(BC_BUFFER * bc_buffer, uint16_t ID, uint16_t seqNO){
       
        if (bc_buffer->head == MAX_BC_BUFFER)
            bc_buffer->head =0;
    
        bc_buffer->globalSenderID[bc_buffer->head]    =   ID;
        bc_buffer->seqNO[bc_buffer->head]             =   seqNO;
        bc_buffer->head ++;
    }
    
    
    uint16_t check_BC_BUFFER(BC_BUFFER * bc_buffer, uint16_t ID, uint16_t seqNO){
        int i;
        
        for(i=0;i<MAX_BC_BUFFER;i++){
            if(bc_buffer->globalSenderID[i] == ID && bc_buffer->seqNO[i] == seqNO){
                return 1;
            }       
        }
        return 0;
    }

    void print_BC_BUFFER(BC_BUFFER * bc_buffer){
        int i;

        dbg(DBG_USR1, "BC_BUFFER:\n");
        for(i=0;i<MAX_BC_BUFFER;i++){
            dbg_clear(DBG_USR1, "globalSenderID[%d] == %d , seqNO[%d] == %d \n",i, bc_buffer->globalSenderID[i],
                                                                                i, bc_buffer->seqNO[i]);
        }
        dbg_clear(DBG_USR1,"head == %d \n",bc_buffer->head);
    }
    
    event result_t BackOffTimer.fired() {

        if(call SendDataMsg.send(TOS_BCAST_ADDR,global_data_buf.length,&global_data_buf)){
            dbg(DBG_USR1,"SendDataMsg.send is retried to broadcast a data packet\n");                
            return SUCCESS;
        }else{
            dbg(DBG_USR1,"SendMsg.send fail\n");
            call BackOffTimer.start(TIMER_ONE_SHOT, 30);
			return SUCCESS;
        }                 
    
    }
    
        
}
