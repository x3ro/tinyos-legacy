#include "tos.h"
#include "AGRO.h"

#define MAG_THRESHOLD (VAR(magCutoff))
#define MIN_DISTANCE 0x3fff

typedef struct {
   char nodeID;
   unsigned int value;
} dataReading;

typedef struct {
   char type;
   char pack_ID;
   char to;
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

typedef struct {
  char magOn;
  char sounderOn;
  char pot;
  char setClock;
  char clockInterval;
  char clockScale;
  uint16_t minValidDistance;
  uint16_t magCutoff;
} CommandPacket;

void bar_foo();

#define TOS_FRAME_TYPE AGRO_obj_frame
TOS_FRAME_BEGIN(AGRO_obj_frame) {
	dataReading mag_dataBlock[4];
	dataReading acou_dataBlock[4];
	uint16_t max_strength;
	uint16_t my_strength;
	uint16_t min_distance;
	uint16_t min_valid_distance;
	uint16_t my_distance;
	uint16_t magCutoff;
	TOS_Msg mag_rel_buf;
	TOS_MsgPtr mag_rel_ptr;
	TOS_Msg acou_rel_buf;
	TOS_MsgPtr acou_rel_ptr;
	TOS_Msg data_buf;
	TOS_MsgPtr msg;
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
	char mag_running;
	char sounder_running;
	char new_distance;
}
TOS_FRAME_END(AGRO_obj_frame);

char TOS_COMMAND(AGRO_INIT)(){
    //initialize sub components
   VAR(mag_running) = 1;
   VAR(sounder_running) = 1;
   TOS_CALL_COMMAND(AGRO_SUB_INIT)();
   //set rate for sampling.
   VAR(count) = 0;
   VAR(max_strength) = 0;
   VAR(my_strength) = 0;
   VAR(msg) = &VAR(data_buf);
   VAR(mag_rel_ptr) = &VAR(mag_rel_buf);
   VAR(acou_rel_ptr) = &VAR(acou_rel_buf);
   VAR(min_valid_distance) = 0x50;
   VAR(my_distance) = 0x3fff;
   VAR(min_distance) = 0x7fff;
   VAR(magCutoff) = 0x1f;
   return 1;
}

char TOS_COMMAND(AGRO_START)(){
	return 1;
}

char TOS_COMMAND(AGRO_STOP)(){
	VAR(mag_running) = 0;
	VAR(sounder_running) = 0;
	return 1;
}

void update_mag_connections(char source, unsigned int strength){
    uint8_t i;
    char dupe = 0;
    uint8_t low_place = 0;
    uint16_t low_val = 0x7fff;

    for(i = 0; i < 3 && dupe == 0; i ++){
	if(VAR(mag_dataBlock)[i].value < low_val){
		low_val = VAR(mag_dataBlock)[i].value;
		low_place = i;
	}
	if(VAR(mag_dataBlock)[i].nodeID == source){
		dupe = 1;
		VAR(mag_dataBlock)[i].value = strength;
		
	}
    }
	
    if(dupe == 0 && VAR(mag_dataBlock)[low_place].value < strength){
    	VAR(mag_dataBlock)[low_place].value = strength;
    	VAR(mag_dataBlock)[low_place].nodeID = source;
    }
    if(strength > VAR(max_strength)) {
	VAR(max_strength) = strength;
    }
}

void update_distance_connections(char source, unsigned int distance){
    uint8_t i;
    char dupe = 0;
    uint8_t high_place = 0;
    uint16_t high_val = 0x000;
    for(i = 0; i < 3 && dupe == 0; i ++){
	if(VAR(mag_dataBlock)[i].value > high_val){
		high_val = VAR(acou_dataBlock)[i].value;
		high_place = i;
	}
	if(VAR(acou_dataBlock)[i].nodeID == source){
		dupe = 1;
		VAR(acou_dataBlock)[i].value = distance;
		
	}
    }
	
    if(dupe == 0 && VAR(acou_dataBlock)[high_place].value > distance){
    	VAR(acou_dataBlock)[high_place].value = distance;
    	VAR(acou_dataBlock)[high_place].nodeID = source;
    }
    if(distance < VAR(min_distance)) {
	VAR(min_distance) = distance;
    }
}

TOS_MsgPtr TOS_MSG_EVENT(AGRO_MAG_DATA_MSG)(TOS_MsgPtr msg){
   agroDataPacket* pack = (agroDataPacket*)msg->data;	
   if (msg->crc == 0) {return msg;}
   update_mag_connections(pack->readings[0].nodeID, pack->readings[0].value);
   return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(AGRO_DISTANCE_DATA_MSG)(TOS_MsgPtr msg){
   agroDataPacket* pack = (agroDataPacket*)msg->data;	
   if (msg->crc == 0) {return msg;}
   update_distance_connections(pack->readings[0].nodeID, pack->readings[0].value);
   return msg;
}

TOS_MsgPtr TOS_EVENT(AGRO_COMMAND_MSG)(TOS_MsgPtr data) {
  CommandPacket* command = (CommandPacket*)data->data;
  TOS_CALL_COMMAND(AGRO_LED3_TOGGLE)();
  if (data->crc == 0) {return data;}

  VAR(mag_running) = command->magOn;
  VAR(sounder_running) = command->sounderOn;
  if (VAR(mag_running)) {TOS_CALL_COMMAND(AGRO_LED1_TOGGLE)();}
  if (VAR(sounder_running)) {TOS_CALL_COMMAND(AGRO_LED2_TOGGLE)();}
  
  if (command->pot >= 0) {
    TOS_CALL_COMMAND(AGRO_SUB_SET_POT)(command->pot);
  }
  if (command->setClock) {
    TOS_CALL_COMMAND(AGRO_SUB_CLOCK_INIT)(command->clockInterval, command->clockScale);
  }
  if (command->minValidDistance) {
    VAR(min_valid_distance) = command->minValidDistance;
  }
  if (command->magCutoff) {
    VAR(magCutoff) = command->magCutoff;
  }
  return data;
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
       VAR(msg_send_pending) = 0;
	TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(0x7e, 0x88, VAR(msg));
	return 1;
}

char TOS_EVENT(AGRO_SUB_DISTANCE_DATA_READY)(short neighbor, short data){
	if(data < 0) return 1;
	if(VAR(sounder_running) == 0) return 1;
	if(data > VAR(min_valid_distance)) return 1;
	VAR(new_distance) = 1;
	VAR(my_distance) = data;

	return 1;
}

char TOS_EVENT(AGRO_SUB_DATA_READY)(short data){
		uint8_t i;
	if(VAR(id_gen) == 0) VAR(id_gen) = data;
	if(VAR(mag_running) == 0) {
		data = 0;
	}
	if(data > VAR(my_strength)) VAR(my_strength) = data;
	VAR(count) ++;
	if(VAR(count) == 8){
	    VAR(count) = 0;
	    if(VAR(my_strength) > VAR(max_strength) && VAR(my_strength) > VAR(magCutoff)){
	      TOS_CALL_COMMAND(AGRO_LED1_ON)();	
		agroDataPacket* pack = (agroDataPacket*)VAR(mag_rel_ptr)->data;
		pack->type = 0;
		pack->pack_ID = VAR(id_gen);
		pack->to = TOS_LOCAL_ADDRESS;
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = VAR(my_strength);
		for(i = 1; i < 4; i ++){
        		pack->readings[i].value = VAR(mag_dataBlock)[i-1].value;
        		pack->readings[i].nodeID = VAR(mag_dataBlock)[i-1].nodeID;
		}
		VAR(id_gen) ++;
		VAR(mag_rel_ptr)->length = 16;
		i = TOS_CALL_COMMAND(AGRO_REL_SEND_MSG)(0, 5, VAR(mag_rel_ptr));
		if(i == 0) VAR(id_gen) --;
	    }else{
	      TOS_CALL_COMMAND(AGRO_LED1_OFF)();
	    }
	    for(i = 1; i < 4; i ++){
        		VAR(mag_dataBlock)[i-1].value = 0;
        		VAR(mag_dataBlock)[i-1].nodeID = 0xff;
	    }
	    VAR(my_strength) = 0;
	    VAR(max_strength) = 0;
	    
	}if(VAR(count) == 4){
	    if(VAR(my_distance) < VAR(min_distance)){
		agroDataPacket* pack = (agroDataPacket*)VAR(acou_rel_ptr)->data;
		pack->type = 1;
		pack->pack_ID = VAR(id_gen);
		pack->to = TOS_LOCAL_ADDRESS;
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = VAR(my_distance);
		for(i = 1; i < 4; i ++){
        		pack->readings[i].value = VAR(acou_dataBlock)[i-1].value;
        		pack->readings[i].nodeID = VAR(acou_dataBlock)[i-1].nodeID;
        		VAR(acou_dataBlock)[i-1].value = 0x7555;
        		VAR(acou_dataBlock)[i-1].nodeID = 0xff;
		}
		VAR(id_gen) ++;
		VAR(acou_rel_ptr)->length = 16;
		i = TOS_CALL_COMMAND(AGRO_REL_SEND_MSG)(0, 5, VAR(acou_rel_ptr));
		if(i == 0) VAR(id_gen) --;
	    }
	    for(i = 1; i < 4; i ++){
        		VAR(acou_dataBlock)[i-1].value = 0x7555;
        		VAR(acou_dataBlock)[i-1].nodeID = 0xff;
	    }
	    VAR(min_distance) = 0x7fff;
	    VAR(my_distance) = 0x7fff;
	}else if(VAR(new_distance) == 1 && VAR(msg_send_pending) == 0){
		VAR(new_distance) = 0;
   		agroDataPacket* pack = (agroDataPacket*)VAR(msg)->data;		
		pack->type = 1;
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = VAR(my_distance);
		//TIME to send out an data messgae.
		VAR(msg)->length = 6;
		VAR(msg_send_pending) = 0;
		 TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(AGRO_DISTANCE_DATA_MSG), VAR(msg));
		
	}else {
	  if(data > VAR(magCutoff) && VAR(msg_send_pending) == 0){
		CLR_YELLOW_LED_PIN();
   		agroDataPacket* pack = (agroDataPacket*)VAR(msg)->data;		
		pack->readings[0].nodeID = TOS_LOCAL_ADDRESS;
		pack->readings[0].value = data;
		//TIME to send out an data messgae.
		VAR(msg)->length = 6;
		VAR(msg_send_pending) = 0;
		TOS_CALL_COMMAND(AGRO_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(AGRO_MAG_DATA_MSG), VAR(msg));
	   }else{
	     SET_YELLOW_LED_PIN();
	     	TOS_CALL_COMMAND(AGRO_LED1_OFF)();
	   }
	}
        return 1;
}

