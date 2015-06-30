#include "tos.h"
#include "SURGE_DEMO.h"

extern short TOS_LOCAL_ADDRESS;
#define LIGHT_PORT 1
#define MAX_NODE_NUM 15

typedef struct{
	char source;
	char value; 
}reading;
typedef struct{
	int count;
	int level; 
}history;
typedef struct {
	unsigned char level;
	unsigned char hop_count;
	reading hops[5];
	char neighbor_list[5];
        unsigned char pot;
        unsigned char CLOCK_MAX;
        unsigned char SECOND_CHANCE_MAX;
}data_packet;

void surge_reset_pot(char val){


}

void reset_pot(char val) {
    unsigned char i;
    for (i=0; i < 200; i++) {
        decrease_r();
    }
    for (i=0; i < val; i++) {
        increase_r();
    }
    SET_UD_PIN();
    SET_INC_PIN();
}

#define TOS_FRAME_TYPE SURGE_DEMO_obj_frame
TOS_FRAME_BEGIN(SURGE_DEMO_obj_frame) {
	TOS_Msg Send_buf;
	TOS_Msg forward_buf;
	TOS_MsgPtr msg;
	unsigned char parent;
	unsigned char level;
	unsigned char pot;
	unsigned char next_parent;
	unsigned char next_level;
	char route_timer;
	char second_chance;
	char SECOND_CHANCE_MAX;
	char send_timer;
	char clock_div;
	char CLOCK_MAX;
	int sensor_reading;
	unsigned char neighbor_list_place;
}
TOS_FRAME_END(SURGE_DEMO_obj_frame);

char TOS_COMMAND(SURGE_DEMO_INIT)(){
    //initialize sub components
   data_packet* pack = (data_packet*)VAR(Send_buf).data;
   VAR(msg) = &VAR(forward_buf);
   VAR(parent) = 0xff;
   VAR(next_parent) = 0xff;
   VAR(next_level) = 0xff;
   VAR(second_chance) = 0;
   VAR(SECOND_CHANCE_MAX) = 3;
   VAR(route_timer) = 0;
   VAR(send_timer) = 0;
   VAR(clock_div) = 0;
   pack->hops[0].source = TOS_LOCAL_ADDRESS;
   pack->hop_count = 1;
   VAR(level) = 0x7f;
   VAR(CLOCK_MAX) = 0x4;
   SET_PW1_PIN();
   TOS_CALL_COMMAND(SURGE_DEMO_SUB_INIT)();
   TOS_COMMAND(SURGE_DEMO_SUB_CLOCK_INIT)(70 - TOS_LOCAL_ADDRESS, 0x03);
   return 1;
}
char TOS_COMMAND(SURGE_DEMO_START)(){
	return 1;
}


//This handler responds to routing updates.
TOS_MsgPtr TOS_MSG_EVENT(RESET_HANDLER)(TOS_MsgPtr msg){ 
    TOS_CALL_COMMAND(DOT_LED1_OFF)();
    TOS_CALL_COMMAND(DOT_LED2_OFF)();
    TOS_CALL_COMMAND(DOT_LED3_OFF)();
    return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
	TOS_MsgPtr tmp;
	data_packet* pack = (data_packet*)msg->data;
	unsigned char source = pack->hops[pack->hop_count - 1].source;
	if(source < MAX_NODE_NUM && source != TOS_LOCAL_ADDRESS){
		data_packet* send_pack = (data_packet*)VAR(Send_buf).data;
		if(VAR(next_level) > pack->level && pack->level < 8){
			VAR(next_level) = pack->level;
			VAR(next_parent) = source;
		}
		if(VAR(next_level) == pack->level && VAR(parent) == source){
			VAR(next_parent) = source;		
		}
		send_pack->neighbor_list[VAR(neighbor_list_place)] = source;
		VAR(neighbor_list_place) ++;
		if(VAR(neighbor_list_place) == 5) VAR(neighbor_list_place) = 0;
	}
	if(pack->hops[(int)pack->hop_count].source == TOS_LOCAL_ADDRESS && VAR(parent) != 0xff){
		pack->hops[(int)pack->hop_count].value = VAR(sensor_reading);
		pack->hop_count ++;
		if(pack->level > VAR(level)){
			pack->level = VAR(level);
			if(pack->hop_count > 4) pack->hop_count = 4;
			pack->hops[(int)pack->hop_count].source = VAR(parent);
			VAR(send_timer) = 4;
	        	TOS_CALL_COMMAND(SURGE_DEMO_SUB_SEND_MSG)(0xff, 23, msg);		}
	}
	if(VAR(pot) == 0 && pack->pot > 60 && pack->pot < 80){	
   		data_packet* send_pack = (data_packet*)VAR(Send_buf).data;
		VAR(pot) = pack->pot;
		reset_pot(VAR(pot));
		send_pack->pot = VAR(pot);
		VAR(CLOCK_MAX) = send_pack->CLOCK_MAX = pack->CLOCK_MAX;
		VAR(SECOND_CHANCE_MAX) = send_pack->SECOND_CHANCE_MAX = pack->SECOND_CHANCE_MAX;
	}
	tmp = VAR(msg);
	VAR(msg) = msg;
    	return tmp;
}


void TOS_EVENT(SURGE_DEMO_SUB_CLOCK)(){
	TOS_CALL_COMMAND(GET_DATA)(LIGHT_PORT);
	TOS_CALL_COMMAND(DOT_LED1_ON)();
	if(VAR(clock_div) != 0) VAR(clock_div) --;
	else{
		VAR(clock_div) = VAR(CLOCK_MAX);
		if(VAR(route_timer) != 0) VAR(route_timer) --;
		if((VAR(route_timer) == 0 || VAR(parent) == 0xff)
		   && VAR(next_parent) != 0xff){
			VAR(route_timer) = 10;	
			if((VAR(next_level) + 1) < VAR(level)
			   || VAR(second_chance) == 0){
				VAR(parent) = VAR(next_parent);
				VAR(level) = VAR(next_level) + 1;
				VAR(next_level) = 0xff;
				VAR(next_parent) = 0xff;
				VAR(second_chance) = VAR(SECOND_CHANCE_MAX);
			}else{
				VAR(second_chance) --;
			}
		}
		if(VAR(send_timer) != 0) VAR(send_timer) --;
		if(VAR(send_timer) == 0 && VAR(parent) != 0xff){
			VAR(send_timer) = 2;
   			data_packet* pack = (data_packet*)VAR(Send_buf).data;
   			pack->hops[1].source = VAR(parent);
   			pack->level = VAR(level);
			TOS_CALL_COMMAND(SURGE_DEMO_SUB_SEND_MSG)(TOS_BCAST_ADDR, 23,&VAR(Send_buf));
			TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
		}
	}
}

//testing reading form the local sensors.
char TOS_EVENT(SURGE_DEMO_LIGHT_DATA_READY)(int data){
	int new_val = (data >> 2) & 0xff;
	int diff;
	TOS_CALL_COMMAND(DOT_LED1_OFF)();
	data_packet* pack = (data_packet*)VAR(Send_buf).data;
	diff = VAR(sensor_reading) - new_val;
	if(diff > 25 || diff < -25){
		VAR(send_timer) = 0;	
		TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
	}
	pack->hops[0].value = VAR(sensor_reading) = new_val;
	return 1;
}

char TOS_EVENT(SEND_DONE)(TOS_MsgPtr msg){
	return 1;
}

