#include "tos.h"
#include "TEST_FP.h"
#include "dbg.h"


#define TOS_FRAME_TYPE TEST_obj_frame
TOS_FRAME_BEGIN(TEST_obj_frame) {
  char state;
  TOS_Msg msg;  
}
TOS_FRAME_END(TEST_obj_frame);


char TOS_COMMAND(TEST_INIT)(void) {
  TOS_CALL_COMMAND(TEST_SUB_CLOCK_INIT)(tick1ps);
  TOS_CALL_COMMAND(TEST_SUB_INIT)();
  TOS_CALL_COMMAND(TEST_SUB_LED_INIT)();
  VAR(state) = 0;
  return 1;
}

char TOS_COMMAND(TEST_START)(void) {
  return 1;
}

char TOS_EVENT(TEST_SEND_DONE)(TOS_MsgPtr packet) {
  return 1;
}

void TOS_EVENT(TEST_CLOCK)(void) {
  float x = (float)12 + (float)VAR(state);
  float y = (float)31 + (float)VAR(state);
  float z = (float)171 + (float)VAR(state);
  float a = x / y;
  float b = x * y;
  float c = a / z;
  float d = (c / b) + (float).00002124;
  float e = c * z;
  float f = z * d * 10000.0;

  short a2 = (short)a;
  short b2 = (short)b;
  short c2 = (short)c;
  short d2 = (short)d;
  short e2 = (short)e;
  short f2 = (short)f;

  TOS_CALL_COMMAND(TEST_LED1_TOGGLE)();
  ((short*)VAR(msg).data)[0] = a2;
  ((short*)VAR(msg).data)[1] = b2;
  ((short*)VAR(msg).data)[2] = c2;
  ((short*)VAR(msg).data)[3] = d2;
  ((short*)VAR(msg).data)[4] = e2;
  ((short*)VAR(msg).data)[5] = f2;

  {
    int i;
    dbg(DBG_USR1, ("TEST_FP: Values: "));
    for (i = 0; i < 6; i++) {
      dbg_clear(DBG_USR1, ("%hi ",((short*)VAR(msg).data)[i]));
    }
    dbg_clear(DBG_USR1, ("\n"));
  }
  VAR(state)++;
  TOS_CALL_COMMAND(TEST_SUB_SEND_MSG)(TOS_UART_ADDR, 0x33, &VAR(msg));
}
