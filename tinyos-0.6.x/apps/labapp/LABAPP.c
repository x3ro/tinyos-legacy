#include "tos.h"
#include "LABAPP.h"
#include "dbg.h"

#define MAX_NODE_NUM 30
#define MAX_COST 400
#define MAX_HOPCOUNT 5

typedef struct{
	char source;
	char light_value; 
	char temp_value;
	char voltage_value;
}reading;

typedef struct {
	char level;
	char hop_count;
	reading hops[MAX_HOPCOUNT + 1];
	unsigned short cost;
	unsigned short seq_num;
}data_packet;

typedef struct {
	char seqno;
        char pot;	 //control over teh POT setting
        char send_timer_max;  //control over the rate to send
        char route_timer_max;  //control over the rate to send
        char initial_signal_quality;  //control over the rate to send
	short level_cost;
}flood_packet;

typedef struct {
	short sender;
	unsigned short seq_num;
	short level;
	unsigned short cost;
}link_update;

typedef struct {
	unsigned short last_seq_num;
	short avg_dist;
	short level;
	unsigned short cost;
}link_state_entry;


#define TOS_FRAME_TYPE LABAPP_obj_frame
TOS_FRAME_BEGIN(LABAPP_obj_frame) {
	TOS_Msg Send_buf;
	TOS_Msg forward_buf;
	TOS_Msg link_update_buf;
	TOS_MsgPtr msg;
	unsigned char parent;
	unsigned char level;
	unsigned short cost;
	unsigned char pot;
	char route_timer;
	char send_timer;
	char route_timer_max;
	char send_timer_max;
	char initial_signal_quality;
	int light_reading;
	int temp_reading;
	char voltage_reading;
	short level_cost;
	link_state_entry RX_link_state[MAX_NODE_NUM + 1];
	unsigned short seq_num;
	char readingPending;

	char RX_level;
	unsigned short RX_cost;
	char RX_source;
	unsigned short RX_seq_num;
	char RX_read_pending;
	char lastCmdSeqNo;
}
TOS_FRAME_END(LABAPP_obj_frame);

    //initialize sub components
void init_vars(){
   {
   //setup the send buffer
   	data_packet* pack = (data_packet*)VAR(Send_buf).data;
   	pack->hops[0].source = TOS_LOCAL_ADDRESS;
   	pack->hop_count = 1;
   }


   {
  	 link_update* pack = (link_update*)VAR(link_update_buf).data;
	 pack->sender = TOS_LOCAL_ADDRESS;
	 pack->seq_num = 1;
   }

   //set the forwarding pointer to the correct spot
   VAR(msg) = &VAR(forward_buf);
   VAR(parent) = 0xff;
   VAR(cost) = 0x3fff;
   VAR(route_timer) = 0;
   VAR(send_timer) = 0;
   VAR(level) = 0x7f;
   VAR(readingPending) = 0;

   VAR(pot) = 50;
   VAR(route_timer_max) = 10;
   VAR(seq_num) = 1;
   VAR(level_cost) = 5;
   VAR(initial_signal_quality) = 10;
   VAR(send_timer_max) = 10;
   {
	int i;
	for(i = 0; i <= MAX_NODE_NUM; i ++){
		VAR(RX_link_state)[i].level = 0x3ff;
		VAR(RX_link_state)[i].cost = 0x3fff;
		VAR(RX_link_state)[i].last_seq_num = 0;
		VAR(RX_link_state)[i].avg_dist = VAR(initial_signal_quality) << 3;
	}
   } 
   VAR(RX_read_pending) = 0;
   VAR(lastCmdSeqNo) = -1;
}

   //turn on the photo cell.
char TOS_COMMAND(LABAPP_INIT)(){

	printf("%d\n", sizeof(data_packet));

   init_vars();

   //initialize
   TOS_CALL_COMMAND(LABAPP_SUB_INIT)();
   TOS_COMMAND(LABAPP_SUB_CLOCK_INIT)(tick1ps);
   return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(SURGE_PARAMETER_UPDATE)(TOS_MsgPtr msg){
	flood_packet* pack = (flood_packet*)msg->data;
	if (VAR(lastCmdSeqNo) < pack->seqno)
	{
		VAR(lastCmdSeqNo) = pack->seqno;
		VAR(pot) = pack->pot;
		TOS_CALL_COMMAND(SURGE_POT_SET)(VAR(pot));
		VAR(route_timer_max) = pack->route_timer_max;
		VAR(send_timer_max) = pack->send_timer_max;
		VAR(initial_signal_quality) = pack->initial_signal_quality;
		VAR(level_cost) = pack->level_cost;
		TOS_CALL_COMMAND(LABAPP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(SURGE_PARAMETER_UPDATE), msg);
	}
	return msg;
}

char TOS_COMMAND(LABAPP_START)(){
	return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(RESET_HANDLER)(TOS_MsgPtr msg){ 
	flood_packet* pack = (flood_packet*)msg->data;
	if (VAR(lastCmdSeqNo) < pack->seqno)
	{
		VAR(lastCmdSeqNo) = pack->seqno;
		TOS_CALL_COMMAND(SURGE_LED_RED_OFF)();
		TOS_CALL_COMMAND(SURGE_LED_GREEN_OFF)();
		TOS_CALL_COMMAND(SURGE_LED_YELLOW_OFF)();
		init_vars();
		TOS_CALL_COMMAND(LABAPP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(RESET_HANDLER), msg);
	}
	return msg;
}
//TOS_MsgPtr TOS_MSG_EVENT(SURGE_LINK_STATE_UPDATE)(TOS_MsgPtr msg){
TOS_TASK(SURGE_LINK_STATE_UPDATE){
	unsigned short seq_num, prev, quality, diff;
	char level;
	short sender;
	unsigned short rxcost;
	VAR(RX_read_pending) = 1;
	sender = VAR(RX_source);
	seq_num = VAR(RX_seq_num);
	level = VAR(RX_level);
	rxcost = VAR(RX_cost);
	VAR(RX_read_pending) = 0;

	if(sender > MAX_NODE_NUM || sender < 0) {
		dbg(DBG_USR1, ("sender_error %d \n", sender));
		return;
	}
	prev = VAR(RX_link_state)[sender].last_seq_num;
	quality = VAR(RX_link_state)[sender].avg_dist;
	diff = seq_num - prev;
	if(diff > 50) diff = 50;
	if(diff < 0) diff = 50;
	quality -= quality >> 3;
	quality += diff;
	quality &= 0x3fff;
	VAR(RX_link_state)[sender].last_seq_num = seq_num;
	VAR(RX_link_state)[sender].avg_dist = quality;
	VAR(RX_link_state)[sender].level = level;
	VAR(RX_link_state)[sender].cost = rxcost;
	dbg(DBG_USR1, ("link_state_update source: %d, quality: %x, cost: %d\n", sender, quality, VAR(RX_cost)));
}


TOS_MsgPtr TOS_MSG_EVENT(DATA_MSG)(TOS_MsgPtr msg){
	TOS_MsgPtr tmp;
	data_packet* pack = (data_packet*)msg->data;
	dbg(DBG_USR1, ("link_state_update cost: %d\n", pack->cost));
	TOS_CALL_COMMAND(SURGE_LED_YELLOW_TOGGLE)();

	if (!VAR(RX_read_pending)) {
		// avoid race condition
		VAR(RX_level) = pack->level;
		VAR(RX_cost) = pack->cost;
		VAR(RX_source) = pack->hops[(int)pack->hop_count - 1].source;
		VAR(RX_seq_num) = pack->seq_num;
	}
	//do you need to forward the data?
	//if the message was to you and you have a parent.
	dbg(DBG_USR1, ("RX_MSG from: %x\n", pack->hops[(int)pack->hop_count - 1].source));
	if(pack->hops[(int)pack->hop_count].source == TOS_LOCAL_ADDRESS && VAR(parent) != 0xff && (pack->cost > VAR(cost))){
		dbg(DBG_USR1, ("forward_msg %d, %x\n", pack->hop_count, pack->hops[(int)pack->hop_count - 1].source));
	
		short i;
		short loop = 0;
		for (i = 0; i < pack->hop_count; i++)
			if (VAR(parent) == pack->hops[i].source) {
				loop = 1;
				break;
			}
		if (!loop) {
			// never send messages in a loop!
			pack->hops[(int)pack->hop_count].light_value = VAR(light_reading);
			pack->hops[(int)pack->hop_count].temp_value = VAR(temp_reading);
			pack->hops[(int)pack->hop_count].voltage_value = VAR(voltage_reading);
			pack->hop_count ++;
			pack->level = VAR(level);
			pack->cost = VAR(cost);

			//max out the hop count at MAX_HOPCOUNT - 1.
			if(pack->hop_count >= MAX_HOPCOUNT) pack->hop_count = MAX_HOPCOUNT - 1;
			pack->hops[(int)pack->hop_count].source = VAR(parent);
			VAR(send_timer) = VAR(send_timer_max) << 1;
			pack->seq_num = VAR(seq_num) ++;	
			TOS_CALL_COMMAND(SURGE_LED_RED_TOGGLE)();
			TOS_CALL_COMMAND(LABAPP_SUB_SEND_MSG)(TOS_BCAST_ADDR, 23, msg);
		}
	}
	tmp = VAR(msg);
	VAR(msg) = msg;
	TOS_POST_TASK(SURGE_LINK_STATE_UPDATE);
    	return tmp;
}





TOS_TASK(update_route){
		//update the route information.
		//wait for the route_timer to expire.....
		short best_conn_level = 0x7d;
		short best_conn_name = 0xff;
		short best_conn_cost = MAX_COST + 1;
		int i;
		if(VAR(route_timer) > 0){
			VAR(route_timer) --;
			return;
		}
		VAR(route_timer) = VAR(route_timer_max);
		for(i = 0; i <= MAX_NODE_NUM; i ++){
			unsigned short cost = VAR(RX_link_state)[i].cost;
			if (i == TOS_LOCAL_ADDRESS)
				continue; // never pick yourself as parent!
			cost += VAR(RX_link_state)[i].avg_dist + VAR(level_cost);
			dbg(DBG_USR2, ("route_update try %d, %d, %d, %d\n", i, cost, VAR(RX_link_state)[i].level, VAR(RX_link_state)[i].avg_dist));
			VAR(RX_link_state)[i].cost += 8;
			if (VAR(RX_link_state)[i].cost > MAX_COST)
				VAR(RX_link_state)[i].cost = MAX_COST;
			if(best_conn_cost > cost) {
				best_conn_name = i;
				best_conn_level = VAR(RX_link_state)[i].level;
				best_conn_cost = cost;
			}
		}
		VAR(parent) = best_conn_name;
		VAR(level) = best_conn_level + 1;
		VAR(cost) = best_conn_cost;
		dbg(DBG_USR1, ("route_update parent: %d, level: %d, cost: %d\n", VAR(parent), VAR(level), VAR(cost)));
}
			

void send_data(){
	//check to send packet
	if(VAR(cost) > MAX_COST) return;
	if(VAR(send_timer) > 0) VAR(send_timer) --;
	if(VAR(send_timer) <= 0){
	   VAR(send_timer) = VAR(send_timer_max);
  	   if(VAR(parent) != 0xff){
   		data_packet* pack = (data_packet*)VAR(Send_buf).data;
		dbg(DBG_USR1, ("sending data: %d, level: %d, cost: %d\n", VAR(parent), VAR(level), VAR(cost)));
   		pack->hops[1].source = VAR(parent);
		pack->cost = VAR(cost);
   		pack->level = VAR(level);
		pack->seq_num = VAR(seq_num) ++;	
		TOS_CALL_COMMAND(LABAPP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(DATA_MSG),&VAR(Send_buf));
		TOS_CALL_COMMAND(SURGE_LED_GREEN_TOGGLE)();
	   }
	}/*else if(VAR(send_timer) == (VAR(send_timer_max) >> 1)){
   		link_update* pack = (link_update*)VAR(link_update_buf).data;
		dbg(DBG_USR1, ("sending link: %d, level: %d, cost: %d\n", VAR(parent), VAR(level), VAR(cost)));
		pack->seq_num ++;	
		pack->level = VAR(level);	
		pack->cost = VAR(cost);	
		TOS_CALL_COMMAND(LABAPP_SUB_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(SURGE_LINK_STATE_UPDATE),&VAR(link_update_buf));
		
	}*/
}


void TOS_EVENT(LABAPP_SUB_CLOCK)(){
	//what to do on a clock tick.
	if (!VAR(readingPending))
	{
		TOS_CALL_COMMAND(SURGE_PHOTO_GET_DATA)();
		VAR(readingPending) = 1;
	}
	TOS_POST_TASK(update_route);
	send_data();
}



//testing reading form the local sensors.
//and keep the value that needs to be sent out in the packet
char TOS_EVENT(SURGE_PHOTO_DATA_READY)(short data){
	//we're only using 8 bit data.
	data_packet* pack = (data_packet*)VAR(Send_buf).data;

	int new_val = (data >> 2) & 0xff;
	int diff;
	
	diff = VAR(light_reading) - new_val;
	if(diff > 25 || diff < -25){
		VAR(send_timer) = 0;	
	}
	pack->hops[0].light_value = VAR(light_reading) = new_val;
	TOS_CALL_COMMAND(SURGE_TEMP_GET_DATA)();
	return 1;
}

char TOS_EVENT(SURGE_TEMP_DATA_READY)(short data){
	//we're only using 8 bit data.
	data_packet* pack = (data_packet*)VAR(Send_buf).data;

	int new_val = (data >> 2) & 0xff;
	int diff;
	
	diff = VAR(temp_reading) - new_val;
	if(diff > 25 || diff < -25){
		VAR(send_timer) = 0;	
	}
	pack->hops[0].temp_value = VAR(temp_reading) = new_val;
	TOS_CALL_COMMAND(SURGE_VOLTAGE_GET_DATA)();
	return 1;
}

char TOS_EVENT(SURGE_VOLTAGE_DATA_READY)(short data){
	//we're only using 8 bit data.
	data_packet* pack = (data_packet*)VAR(Send_buf).data;

	int new_val = (data >> 2) & 0xff;
	
	pack->hops[0].voltage_value = VAR(voltage_reading) = new_val;
	VAR(readingPending) = 0;
	return 1;
}

//don't worry too much about send_done.
char TOS_EVENT(SEND_DONE)(TOS_MsgPtr msg){
	return 1;
}

