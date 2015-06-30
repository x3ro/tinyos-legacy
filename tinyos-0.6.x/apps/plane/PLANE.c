#include "tos.h"
#include "PLANE.h"
#include "dbg.h"

/* Utility functions */
#define TOS_FRAME_TYPE PLANE_frame
TOS_FRAME_BEGIN(PLANE_frame) {
  int count;
  char getData;
  int log_line;
  int log_count;
  TOS_Msg inc_msg;  
  TOS_Msg read_msg;  
  TOS_MsgPtr msg;
}
TOS_FRAME_END(PLANE_frame);

char TOS_COMMAND(PLANE_INIT)(){
  VAR(count) = 0;
  VAR(getData) = 0;
  VAR(msg) = &VAR(inc_msg);
  TOS_CALL_COMMAND(PLANE_SUB_INIT)();
  TOS_CALL_COMMAND(COMM_INIT)();
  TOS_CALL_COMMAND(LOGGER_CLOCK_INIT)(255, 4);
  dbg(DBG_BOOT, ("PLANE initialized\n"));
  return 1;
}

char TOS_COMMAND(PLANE_START)(){
	TOS_CALL_COMMAND(COMM_SEND_MSG)(0xff,AM_MSG(PLANE_READ_MSG),&VAR(read_msg));
	return 1;
}

void TOS_EVENT(PLANE_CLOCK_EVENT)(){
    dbg(DBG_USR1, ("getting data\n"));
    if(VAR(getData) == 0){
      int i;
      for(i = 0; i < 12; i ++) VAR(read_msg).data[i] = 0xff;
      TOS_CALL_COMMAND(COMM_SEND_MSG)(0xff, 9,&VAR(read_msg));
      TOS_CALL_COMMAND(RED_LED_TOGGLE)();
    }

    VAR(getData) = 0;
    TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
}

char TOS_EVENT(PLANE_WRITE_LOG_DONE)(char success){
	dbg(DBG_USR1, ("LOG_WRITE_DONE\n"));
	return 1;
}
TOS_MsgPtr TOS_EVENT(PLANE_READ_MSG)(TOS_MsgPtr msg){
	char* data = msg->data;
	VAR(log_line) = data[1] & 0xff;
	VAR(log_line) |= data[0] << 8;
	VAR(log_count) = data[3] & 0xff;
	VAR(log_count) |= data[2] << 8;
        dbg(DBG_USR1, ("LOG_READ_START \n"));
    VAR(getData) = 1;
    TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
        TOS_CALL_COMMAND(PLANE_READ_LOG)((short)VAR(log_line),VAR(read_msg).data);
        return msg;
}
char TOS_EVENT(PLANE_MSG_SENT)(TOS_MsgPtr msg){
	if((msg == VAR(msg))) {
		dbg(DBG_USR1, ("data buffer free\n"));
	}else if(msg == &VAR(read_msg)) {
		VAR(log_line) ++;
		if(--VAR(log_count) > 0){
        		TOS_CALL_COMMAND(PLANE_READ_LOG)((short)VAR(log_line),VAR(read_msg).data);
		}
	}
	return 0;
}

char TOS_EVENT(PLANE_READ_LOG_DONE)(char* data, char success){
        dbg(DBG_USR1, ("LOG_READ_DONE\n"));
	data[11] = VAR(log_line);
	TOS_CALL_COMMAND(COMM_SEND_MSG)(0xff,0x36,&VAR(read_msg));
	return 1;
}

TOS_MsgPtr TOS_EVENT(PLANE_DATA_MSG)(TOS_MsgPtr msg){
	TOS_MsgPtr temp = VAR(msg);
	TOS_CALL_COMMAND(PLANE_WRITE_LOG)(msg->data);
	VAR(msg) = msg;
	VAR(count) ++;
        VAR(getData) = 1;
	return temp;	
}   

