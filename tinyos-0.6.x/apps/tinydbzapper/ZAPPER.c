#include "ZAPPER.h"


#define TOS_FRAME_TYPE ZAPPER_frame
TOS_FRAME_BEGIN(ZAPPER_frame) {
  TOS_Msg buf;
}
TOS_FRAME_END(ZAPPER_frame);

char TOS_COMMAND(ZAPPER_INIT)() {
    *(short *)VAR(buf).data = -1;
    VAR(buf).data[2] = 'R';
    VAR(buf).data[3] = 'e';
    VAR(buf).data[4] = 's';
    VAR(buf).data[5] = 'e';
    VAR(buf).data[6] = 't';
    VAR(buf).data[7] = 0;
    return 1;
}

char TOS_COMMAND(ZAPPER_START)() {
    TOS_CALL_COMMAND(ZAPPER_SUB_SEND_MSG)((short)-1, (char)103, &VAR(buf));
    return 1;
}

char TOS_EVENT(ZAPPER_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
    if (READ_RED_LED_PIN())
	CLR_RED_LED_PIN();
    else
	SET_RED_LED_PIN();
    TOS_CALL_COMMAND(ZAPPER_SUB_SEND_MSG)((short)-1, (char)103, &VAR(buf));
    return 1;
}
