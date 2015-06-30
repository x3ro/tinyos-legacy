#include "tos.h"
#include "REL_DEL.h"

#define MAX_LOCAL_BUF 0xf
#define MAX_BUF 0xf

typedef struct {
   char type;
   char pack_ID;
} agroDataPacket;


#define TOS_FRAME_TYPE REL_DEL_obj_frame
TOS_FRAME_BEGIN(REL_DEL_obj_frame) {
	uint8_t send_pending;
	uint8_t buf_head;
	uint8_t buf_tail;
	TOS_Msg data_buf[MAX_BUF];
	TOS_MsgPtr msg_ptrs[MAX_BUF];
	uint8_t local_buf_head;
	uint8_t local_buf_tail;
	short my_parent[8];
	uint8_t parent_ptr;
	char dupe_cache[8];
	uint8_t dupe_ptr;
	uint8_t rel_cnt;
	TOS_MsgPtr local_buf[MAX_LOCAL_BUF];
	TOS_MsgPtr cur_ptr;
}
TOS_FRAME_END(REL_DEL_obj_frame);

char TOS_COMMAND(REL_DEL_INIT)(){
    //initialize sub components
   {
	int i;
	for(i = 0; i < MAX_BUF; i ++){
   	   VAR(msg_ptrs)[i] = &VAR(data_buf)[i];
	}

   }

   {
        VAR(my_parent)[0] = TOS_LOCAL_ADDRESS - 0x10;
        VAR(my_parent)[1] = TOS_LOCAL_ADDRESS - 0x1;
        VAR(my_parent)[2] = TOS_LOCAL_ADDRESS - 0x11;
        VAR(my_parent)[3] = TOS_LOCAL_ADDRESS - 0x20;
        VAR(my_parent)[4] = TOS_LOCAL_ADDRESS - 0x2;
        if(TOS_LOCAL_ADDRESS == 0x200) VAR(my_parent)[0] = TOS_UART_ADDR;
        VAR(parent_ptr) = 0;

   }

   VAR(parent_ptr) = 0;
   VAR(rel_cnt) = 0;
   VAR(buf_head) = 0;
   VAR(buf_tail) = 0;
   VAR(local_buf_head) = 0;
   VAR(local_buf_tail) = 0;
   VAR(send_pending) = 0;
   //set rate for sampling.
   return 1;
}

void advance_parent(){
	VAR(parent_ptr) ++;
	if(VAR(parent_ptr) >= 5) VAR(parent_ptr) = 0;
	if(VAR(my_parent)[VAR(parent_ptr)] == TOS_UART_ADDR) return;
	if((VAR(my_parent)[VAR(parent_ptr)] ^ TOS_LOCAL_ADDRESS) & 0x88) advance_parent();

}


char TOS_EVENT(REL_DEL_SEND_DONE)(TOS_MsgPtr data){
	if(TOS_LOCAL_ADDRESS == 0x200) data->ack = 1;
	if(data == VAR(cur_ptr)){
		VAR(send_pending) = 0;
		VAR(rel_cnt) ++;
		VAR(cur_ptr)->data[2] = VAR(my_parent)[VAR(parent_ptr)];	
		if(data->ack == 0 && VAR(rel_cnt) < 6){
			if(VAR(rel_cnt) > 2) advance_parent();
			VAR(send_pending) = TOS_CALL_COMMAND(REL_DEL_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], VAR(cur_ptr)->type, VAR(cur_ptr));
			return 1;
		}
	
	}
	VAR(rel_cnt) = 0;
	if(VAR(local_buf_head) != VAR(local_buf_tail)){
		VAR(cur_ptr) = VAR(local_buf)[VAR(local_buf_head)];
		VAR(send_pending) = TOS_CALL_COMMAND(REL_DEL_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], VAR(cur_ptr)->type, VAR(cur_ptr));
		if(VAR(send_pending) == 1){
			VAR(local_buf_head) ++;
			if(VAR(local_buf_head) == MAX_LOCAL_BUF){
				VAR(local_buf_head) = 0;	
			}
		}
		return 1;
	}
	if(VAR(buf_head) != VAR(buf_tail)){
		VAR(cur_ptr) = VAR(msg_ptrs)[VAR(buf_head)];
		VAR(send_pending) = TOS_CALL_COMMAND(REL_DEL_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], VAR(cur_ptr)->type, VAR(cur_ptr));
		if(VAR(send_pending) == 1){
			VAR(buf_head) ++;
			if(VAR(buf_head) == MAX_BUF){
				VAR(buf_head) = 0;	
			}
		}
	}
	return 1;
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


TOS_MsgPtr TOS_MSG_EVENT(REL_DEL_REL_MSG)(TOS_MsgPtr msg){
	TOS_MsgPtr tmp = msg;
	char send_pend;
	if(dupe_check(((agroDataPacket*)(msg->data))->pack_ID) != 0 && msg->crc == 1){
		//this one needs to be forwarded.
	        tmp = VAR(msg_ptrs)[VAR(buf_tail)];
		VAR(msg_ptrs)[VAR(buf_tail)] = msg;
		VAR(buf_tail) ++;
		if(VAR(buf_tail) == MAX_BUF) VAR(buf_tail) = 0;
		msg->data[msg->length++] = TOS_LOCAL_ADDRESS;
		send_pend = TOS_CALL_COMMAND(REL_DEL_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], msg->type, msg);
		if(send_pend == 1){
			VAR(send_pending) = 1;
			VAR(rel_cnt) = 0;
			VAR(cur_ptr) = msg;
			VAR(buf_head) ++;
			if(VAR(buf_head) == MAX_BUF) VAR(buf_head) = 0;
		}
	}
	return tmp;

}

char TOS_COMMAND(REL_DEL_SEND_MSG)(short dest, char type, TOS_MsgPtr msg){
	VAR(local_buf)[VAR(local_buf_tail)] = msg;
	VAR(local_buf_tail) ++;
	if(VAR(local_buf_tail) == MAX_LOCAL_BUF) VAR(local_buf_tail) = 0;
	if(VAR(send_pending) == 0){
		msg->data[2] = VAR(my_parent)[VAR(parent_ptr)];	
		VAR(send_pending) = TOS_CALL_COMMAND(REL_DEL_SUB_SEND_MSG)(VAR(my_parent)[VAR(parent_ptr)], type, msg);
		if(VAR(send_pending) == 1){
			VAR(rel_cnt) = 0;
			VAR(cur_ptr) = msg;
			VAR(local_buf_head) ++;
			if(VAR(local_buf_head) == MAX_BUF) VAR(local_buf_head) = 0;
		}
		
	}
	return 1;
}
