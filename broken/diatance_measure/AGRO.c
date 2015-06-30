#include "tos.h"
#include "AGRO.h"

#define MAG_THRESHOLD 0xf

typedef struct {
   char nodeID;
   unsigned int value;
} dataReading;

typedef struct {
   char type;
   char pack_ID;
   char from;
   dataReading readings[4];
} agroDataPacket;

typedef struct {
   short mag;
   short x;
   short x_avg;
   short y;
   short y_avg;
   char potx;
   char poty;
} agroDebugPacket;

void bar_foo();

#define TOS_FRAME_TYPE AGRO_obj_frame
TOS_FRAME_BEGIN(AGRO_obj_frame) {
	dataReading dataBlock[4];
	uint16_t max_strength;
	uint16_t my_strength;
        char route;
	char set;
	TOS_Msg rel_buf;
	TOS_Msg data_buf;
	TOS_MsgPtr msg;
	TOS_MsgPtr rel_ptr;
	char rel_cnt;
	char data_send_pending;
	char msg_send_pending;
	char rel_send_pending;
	char rel_send_req;
	char place;
	int prev;
	char count;
	short my_parent[5];
	uint8_t parent_ptr ;
	char dupe_cache[8];
	uint8_t dupe_ptr;
	uint8_t id_gen;
}
TOS_FRAME_END(AGRO_obj_frame);

char TOS_COMMAND(AGRO_INIT)(){
    //initialize sub components
   TOS_CALL_COMMAND(AGRO_SUB_INIT)();
   VAR(msg) = &VAR(data_buf);
   {
   	   VAR(my_parent)[0] = TOS_LOCAL_ADDRESS - 0x10;
   	   VAR(my_parent)[1] = TOS_LOCAL_ADDRESS - 0x1;
   	   VAR(my_parent)[2] = TOS_LOCAL_ADDRESS - 0x11;
   	   VAR(my_parent)[3] = TOS_LOCAL_ADDRESS - 0x20;
   	   VAR(my_parent)[4] = TOS_LOCAL_ADDRESS - 0x2;
	   if(TOS_LOCAL_ADDRESS == 0x200) VAR(my_parent)[0] = TOS_UART_ADDR;
	   VAR(parent_ptr) = 0;

   }
   VAR(dupe_ptr) = 0;
   VAR(data_send_pending) = 0;
   VAR(msg_send_pending) = 0;
   VAR(rel_send_pending) = 0;
   VAR(rel_send_req) = 0;
   VAR(rel_ptr) = &VAR(rel_buf);
   //set rate for sampling.
   VAR(set) = 0;
   VAR(route) = 0;
   VAR(count) = 0;

   VAR(max_strength) = 0;
   return 1;
}

char TOS_COMMAND(AGRO_START)(){
	return 1;
}

void update_connections(char source, unsigned int strength){
    //first off, update the local state to reflect being able to 
    //hear this sender.
    uint8_t i;
    char dupe = 0;
    uint8_t low_place = 0;
    uint16_t low_val = 0x7fff;

    for(i = 0; i < 3 && dupe == 0; i ++){
	if(VAR(dataBlock)[i].value < low_val){
		low_val = VAR(dataBlock)[i].value;
		low_place = i;
	}
	if(VAR(dataBlock)[i].nodeID == source){
		dupe = 1;
		VAR(dataBlock)[i].value = strength;
		
	}
    }
	
    if(dupe == 0 && VAR(dataBlock)[low_place].value < strength){
    	VAR(dataBlock)[low_place].value = strength;
    	VAR(dataBlock)[low_place].nodeID = source;
    }
    if(strength > VAR(max_strength)) {
	VAR(max_strength) = strength;
    }
}

TOS_MsgPtr TOS_MSG_EVENT(AGRO_DATA_MSG)(TOS_MsgPtr msg){
   agroDataPacket* pack = (agroDataPacket*)msg->data;	
   update_connections(pack->readings[0].nodeID, pack->readings[0].value);
   return msg;
}

char TOS_EVENT(AGRO_SUB_DATA_DEBUG)(short mag, short x, short y, short x_avg, short y_avg, char potx, char poty){
       agroDebugPacket* pack = (agroDebugPacket*)VAR(msg)->data;		
	pack->mag = mag;
	pack->x = x;
	pack->x_avg = x_avg;
	pack->y = y;
	pack->y_avg = y_avg;
	pack->potx = potx;
	pack->poty = poty;
        VAR(msg)->length = 16;
       VAR(msg_send_pending) = TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(TOS_BCAST_ADDR, 0x88, VAR(msg));
	return 1;
}



char TOS_EVENT(AGRO_SUB_DATA_READY)(short data){
	if(data > VAR(my_strength)) VAR(my_strength) = data;
	VAR(count) ++;
	if(VAR(count) == 8){
	    VAR(count) = 0;
	    if(VAR(id_gen) == 0) VAR(id_gen) = data;
	    if(VAR(my_strength) > VAR(max_strength) && VAR(my_strength) > MAG_THRESHOLD){
		uint8_t i;
    	    	TOS_CALL_COMMAND(AGRO_LED1_ON)();	
		agroDataPacket* pack = (agroDataPacket*)VAR(rel_ptr)->data;
		pack->pack_ID = VAR(id_gen);
		pack->from = TOS_LOCAL_ADDRESS;
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = VAR(my_strength);
		for(i = 1; i < 4; i ++){
        		pack->readings[i].value = VAR(dataBlock)[i-1].value;
        		pack->readings[i].nodeID = VAR(dataBlock)[i-1].nodeID;
        		VAR(dataBlock)[i-1].value = 0;
        		VAR(dataBlock)[i-1].nodeID = 0xff;
		}
		bar_foo();
	    }else{
    	    	TOS_CALL_COMMAND(AGRO_LED1_OFF)();
	    }
	    VAR(my_strength) = 0;
	    VAR(max_strength) = 0;
	    
	}else {
	  if(data > MAG_THRESHOLD && VAR(msg_send_pending) == 0){
		CLR_YELLOW_LED_PIN();
   		agroDataPacket* pack = (agroDataPacket*)VAR(msg)->data;		
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = data;
		//TIME to send out an data messgae.
		VAR(msg)->length = 6;
		VAR(msg_send_pending) = TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(AGRO_DATA_MSG), VAR(msg));
	   }else{
		SET_YELLOW_LED_PIN();
    	    	TOS_CALL_COMMAND(AGRO_LED1_OFF)();
	   }
	}
        return 1;
}

void advance_parent(){
	VAR(parent_ptr) ++;
	if(VAR(parent_ptr) >= 5) VAR(parent_ptr) = 0;
	if((VAR(my_parent)[VAR(parent_ptr)] & 0xcc || (VAR(my_parent)[VAR(parent_ptr)] == TOS_UART_ADDR)) != 0) advance_parent();

}
char TOS_EVENT(AGRO_SEND_DONE)(TOS_MsgPtr data){
	if(TOS_LOCAL_ADDRESS == 0x200) data->ack = 1;
	if(data == VAR(msg)) VAR(msg_send_pending) = 0;
	if(data == VAR(rel_ptr)){
		VAR(rel_send_pending) = 0;
		VAR(rel_cnt) ++;
		if((data->ack == 0) && VAR(rel_cnt) > 2) advance_parent();
	}
	if((data == VAR(rel_ptr) && VAR(rel_cnt) < 6 && data->ack == 0) ||
	   VAR(rel_send_req) == 1){
			VAR(rel_send_req) = 0;
		       ((agroDataPacket*)(VAR(rel_ptr)->data))->from = VAR(my_parent)[VAR(parent_ptr)];
			VAR(rel_send_pending) = TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], VAR(rel_ptr)->type, VAR(rel_ptr));	
	}
	return 1;
}

void bar_foo(){
	if(VAR(rel_send_pending) == 0){
		VAR(id_gen) ++;
		VAR(rel_cnt) = 0;
		VAR(rel_ptr)->length = 16;
		((agroDataPacket*)(VAR(rel_ptr)->data))->from = VAR(my_parent)[VAR(parent_ptr)];
				
		VAR(rel_send_pending) = TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], AM_MSG(AGRO_REL_MSG), VAR(rel_ptr));
		if(VAR(rel_send_pending) == 0) VAR(id_gen) --;
	}

}
char dupe_check(char id){
	uint8_t i;
	for(i = 0; i < 8; i ++){
	   if(VAR(dupe_cache)[i] == id) return 0;
	}
	VAR(dupe_cache)[VAR(dupe_ptr)++] = id;
	VAR(dupe_ptr) &= 0x7;
	return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(AGRO_REL_MSG)(TOS_MsgPtr msg){
	TOS_MsgPtr tmp = msg;
	if(dupe_check(((agroDataPacket*)(msg->data))->pack_ID) != 0 && msg->crc == 1){
		((agroDataPacket*)(msg->data))->from = TOS_LOCAL_ADDRESS;
		
	        tmp = VAR(rel_ptr);
		VAR(rel_cnt) = 0;
		VAR(rel_ptr) = msg;
		VAR(rel_ptr)->data[VAR(rel_ptr)->length++] = TOS_LOCAL_ADDRESS;
		VAR(rel_send_pending) = TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], VAR(rel_ptr)->type, VAR(rel_ptr));
		if(VAR(rel_send_pending) == 0){
			VAR(rel_send_req) = 1;
		}
	}
	return tmp;

}

