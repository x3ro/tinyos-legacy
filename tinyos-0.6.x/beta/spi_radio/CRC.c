/* This component handles the packet abstraction on the network stack */

#include "tos.h"
#include "CRC.h"
#include "dbg.h"


#define TOS_FRAME_TYPE PACKET_obj_frame
TOS_FRAME_BEGIN(PACKET_obj_frame) {
	TOS_Msg* send_buf;
}
TOS_FRAME_END(PACKET_obj_frame);

int calcrc(char *ptr, int count)
{
    short crc;
    char i;

    crc = 0;
    while (--count >= 0)
    {
        crc = crc ^ (int) *ptr++ << 8;
        i = 8;
        do
        {
            if (crc & 0x8000)
                crc = crc << 1 ^ 0x1021;
            else
                crc = crc << 1;
        } while(--i);
    }
    return (crc);
}
char crc_check(TOS_MsgPtr data){
	return data->crc == calcrc((char*)data, sizeof(TOS_Msg) - 4);
}

TOS_TASK(calc_crc){
	VAR(send_buf)->crc = calcrc((char*)VAR(send_buf), sizeof(TOS_Msg) - 4);
}

char TOS_EVENT(PACKET_TX_PACKET_DONE)(TOS_MsgPtr data){
	return TOS_SIGNAL_EVENT(CRC_PACKET_TX_PACKET_DONE)(data);
}

TOS_MsgPtr TOS_EVENT(PACKET_RX_PACKET_DONE)(TOS_MsgPtr packet){
	if(crc_check(packet)){
		return TOS_SIGNAL_EVENT(CRC_PACKET_RX_PACKET_DONE)(packet);
	}else return packet;
}


/* Command to transmit a packet */
char TOS_COMMAND(CRC_PACKET_TX_PACKET)(TOS_MsgPtr msg){
	char ret = TOS_CALL_COMMAND(PACKET_TX_PACKET)(msg);
	if(ret){
		VAR(send_buf) = msg;
		TOS_POST_TASK(calc_crc);
	}
	return ret;
}

/* Command to control the power of the network stack */
void TOS_COMMAND(CRC_PACKET_POWER)(char mode){
     TOS_CALL_COMMAND(PACKET_POWER)(mode);
}


/* Initialization of this component */
char TOS_COMMAND(CRC_PACKET_INIT)(){
    TOS_CALL_COMMAND(PACKET_INIT)();
    return 1;
} 
